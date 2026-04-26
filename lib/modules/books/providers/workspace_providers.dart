import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/storage/local_workspace_storage.dart';
import '../../../shared/storage/project_document_picker.dart';
import '../../../shared/utils/id_generator.dart';
import '../../characters/models/character.dart';
import '../../characters/models/character_autofill_draft.dart';
import '../../continuity/models/continuity_state.dart';
import '../../manuscript/models/document.dart';
import '../../notes/models/note.dart';
import '../../notes/models/voice_memo.dart';
import '../../scenarios/models/scenario.dart';
import '../../scenarios/models/scenario_autofill_draft.dart';
import '../models/app_settings.dart';
import '../models/book.dart';
import '../models/musa_settings.dart';
import '../models/narrative_copilot.dart';
import '../models/narrative_workspace.dart';
import '../models/typography_settings.dart';
import '../models/workspace_snapshot.dart';
import '../models/writing_settings.dart';
import '../services/narrative_memory_updater.dart';
import '../services/narrative_workspace_repository.dart';
import '../services/story_state_updater.dart';

/// Repository used to load and persist the canonical workspace aggregate.
final narrativeWorkspaceRepositoryProvider = Provider<NarrativeWorkspaceRepository>((ref) {
  return const LocalWorkspaceStorage();
});

/// Status of the workspace persistence process.
enum WorkspacePersistenceStatus {
  idle,
  saving,
  saved,
  error,
  conflict,
}

/// Exposes the current status of the workspace persistence.
final workspacePersistenceProvider = StateProvider<WorkspacePersistenceStatus>((ref) => WorkspacePersistenceStatus.idle);

final projectDocumentPickerProvider = Provider<ProjectDocumentPicker>((ref) {
  return const ProjectDocumentPicker();
});

final activeProjectPathProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(narrativeWorkspaceRepositoryProvider);
  if (repository is LocalWorkspaceStorage) {
    ref.watch(narrativeWorkspaceProvider);
    return repository.activeProjectPath();
  }
  return '';
});

final recentProjectsProvider = FutureProvider<List<RecentProject>>((ref) async {
  final repository = ref.watch(narrativeWorkspaceRepositoryProvider);
  if (repository is LocalWorkspaceStorage) {
    ref.watch(narrativeWorkspaceProvider);
    return repository.recentProjects();
  }
  return const [];
});

/// Owns the full workspace state and all write operations against it.
class NarrativeWorkspaceNotifier extends StateNotifier<AsyncValue<NarrativeWorkspace>> {
  NarrativeWorkspaceNotifier(
    this._ref,
    this._repository, {
    NarrativeMemoryUpdater narrativeMemoryUpdater = const NarrativeMemoryUpdater(),
    StoryStateUpdater storyStateUpdater = const StoryStateUpdater(),
  })  : _narrativeMemoryUpdater = narrativeMemoryUpdater,
        _storyStateUpdater = storyStateUpdater,
        super(const AsyncValue.loading()) {
    unawaited(bootstrap());
  }

  final Ref _ref;
  final NarrativeWorkspaceRepository _repository;
  final NarrativeMemoryUpdater _narrativeMemoryUpdater;
  final StoryStateUpdater _storyStateUpdater;

  /// Loads the local workspace on startup and exposes it to the rest of the app.
  Future<void> bootstrap() async {
    try {
      final workspace = await _repository.loadWorkspace();
      state = AsyncValue.data(workspace);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> _persist(NarrativeWorkspace workspace) async {
    state = AsyncValue.data(workspace);

    _ref.read(workspacePersistenceProvider.notifier).state = WorkspacePersistenceStatus.saving;

    try {
      await _repository.saveWorkspace(workspace);
      _ref.read(workspacePersistenceProvider.notifier).state = WorkspacePersistenceStatus.saved;
    } catch (error) {
      debugPrint('[WORKSPACE_PERSIST_ERROR] $error');

      final status = error is ProjectFileConflictException ? WorkspacePersistenceStatus.conflict : WorkspacePersistenceStatus.error;

      _ref.read(workspacePersistenceProvider.notifier).state = status;

      // We explicitly don't set state to AsyncValue.error here to avoid
      // breaking the UI/editor session due to a write failure.
    }
  }

  Future<void> openProjectFile(Uint8List fileBytes) async {
    final repository = _repository;
    if (repository is! LocalWorkspaceStorage) return;

    state = const AsyncValue.loading();
    try {
      final workspace = await repository.importProjectFile(fileBytes);
      state = AsyncValue.data(workspace);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> saveProjectFileAs(String path) async {
    final workspace = state.value;
    final repository = _repository;
    if (workspace == null || repository is! LocalWorkspaceStorage) return;

    await repository.saveWorkspaceAs(path, workspace);
    state = AsyncValue.data(workspace);
  }

  Future<void> createProjectFile(String path) async {
    final repository = _repository;
    if (repository is! LocalWorkspaceStorage) return;

    state = const AsyncValue.loading();
    try {
      final workspace = await repository.createNewProjectFile(path);
      state = AsyncValue.data(workspace);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> useLocalProjectFile() async {
    final repository = _repository;
    if (repository is! LocalWorkspaceStorage) return;

    state = const AsyncValue.loading();
    try {
      await repository.clearSelectedProjectFile();
      final workspace = await repository.loadWorkspace();
      state = AsyncValue.data(workspace);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> importProjectFile(Uint8List fileBytes) async {
    final repository = _repository;
    if (repository is! LocalWorkspaceStorage) return;

    state = const AsyncValue.loading();
    try {
      final workspace = await repository.importProjectFile(fileBytes);
      state = AsyncValue.data(workspace);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Switches the editor focus to a manuscript document.
  Future<void> selectDocument(String documentId) async {
    final workspace = state.value;
    if (workspace == null) return;
    final isAlreadyActive = workspace.selectedDocumentId == documentId && workspace.editorMode == WorkspaceEditorMode.document;
    if (isAlreadyActive) return;
    await _persist(
      workspace.copyWith(
        selectedDocumentId: documentId,
        clearSelectedNoteId: true,
        clearSelectedCharacterId: true,
        clearSelectedScenarioId: true,
        editorMode: WorkspaceEditorMode.document,
      ),
    );
  }

  /// Switches the editor focus to a note.
  Future<void> selectNote(String noteId) async {
    final workspace = state.value;
    if (workspace == null) return;
    final isAlreadyActive = workspace.selectedNoteId == noteId && workspace.editorMode == WorkspaceEditorMode.note;
    if (isAlreadyActive) return;
    await _persist(
      workspace.copyWith(
        selectedNoteId: noteId,
        clearSelectedCharacterId: true,
        clearSelectedScenarioId: true,
        editorMode: WorkspaceEditorMode.note,
      ),
    );
  }

  /// Marks a note as selected without forcing the note editor surface.
  Future<void> focusNoteInInspector(String noteId) async {
    final workspace = state.value;
    if (workspace == null) return;
    if (workspace.selectedNoteId == noteId && workspace.editorMode != WorkspaceEditorMode.note) {
      return;
    }

    await _persist(
      workspace.copyWith(
        selectedNoteId: noteId,
      ),
    );
  }

  /// Clears the current note selection.
  Future<void> clearSelectedNote() async {
    final workspace = state.value;
    if (workspace == null || workspace.selectedNoteId == null) return;
    await _persist(
      workspace.copyWith(
        clearSelectedNoteId: true,
      ),
    );
  }

  /// Switches the editor focus to a character sheet.
  Future<void> selectCharacter(String characterId) async {
    final workspace = state.value;
    if (workspace == null) return;
    final isAlreadyActive = workspace.selectedCharacterId == characterId && workspace.editorMode == WorkspaceEditorMode.character;
    if (isAlreadyActive) return;
    await _persist(
      workspace.copyWith(
        selectedCharacterId: characterId,
        clearSelectedScenarioId: true,
        editorMode: WorkspaceEditorMode.character,
      ),
    );
  }

  /// Switches the editor focus to a scenario sheet.
  Future<void> selectScenario(String scenarioId) async {
    final workspace = state.value;
    if (workspace == null) return;
    final isAlreadyActive = workspace.selectedScenarioId == scenarioId && workspace.editorMode == WorkspaceEditorMode.scenario;
    if (isAlreadyActive) return;
    await _persist(
      workspace.copyWith(
        selectedScenarioId: scenarioId,
        clearSelectedCharacterId: true,
        editorMode: WorkspaceEditorMode.scenario,
      ),
    );
  }

  /// Activates a book and rebinds the current selection to its first document.
  Future<void> selectBook(String bookId) async {
    final workspace = state.value;
    if (workspace == null) {
      return;
    }
    if (workspace.appSettings.activeBookId == bookId) {
      await openActiveBookView();
      return;
    }

    final bookDocuments = workspace.documents.where((document) => document.bookId == bookId).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final selectedDocumentId = bookDocuments.isEmpty ? null : bookDocuments.first.id;

    await _persist(
      workspace.copyWith(
        appSettings: workspace.appSettings.copyWith(activeBookId: bookId),
        selectedDocumentId: selectedDocumentId,
        clearSelectedNoteId: true,
        clearSelectedCharacterId: true,
        clearSelectedScenarioId: true,
        editorMode: WorkspaceEditorMode.book,
      ),
    );
  }

  /// Opens the high-level book view instead of a specific entity sheet.
  Future<void> openActiveBookView() async {
    final workspace = state.value;
    if (workspace == null || workspace.activeBook == null) return;
    if (workspace.editorMode == WorkspaceEditorMode.book) return;

    await _persist(
      workspace.copyWith(
        editorMode: WorkspaceEditorMode.book,
        clearSelectedNoteId: true,
        clearSelectedCharacterId: true,
        clearSelectedScenarioId: true,
      ),
    );
  }

  Future<void> updateBookTitle(String bookId, String title) async {
    final workspace = state.value;
    if (workspace == null) return;

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;

    final now = DateTime.now();
    final updatedBooks = workspace.books.map((book) {
      if (book.id != bookId) return book;
      return book.copyWith(title: trimmedTitle, updatedAt: now);
    }).toList();

    await _persist(workspace.copyWith(books: updatedBooks));
  }

  Future<void> updateBookDetails({
    required String bookId,
    String? title,
    String? subtitle,
    bool clearSubtitle = false,
    String? summary,
    String? toneNotes,
    BookNarrativeProfile? narrativeProfile,
  }) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    final updatedBooks = workspace.books.map((book) {
      if (book.id != bookId) return book;
      return book.copyWith(
        title: title,
        subtitle: subtitle,
        clearSubtitle: clearSubtitle,
        summary: summary,
        toneNotes: toneNotes,
        narrativeProfile: narrativeProfile,
        updatedAt: now,
      );
    }).toList();

    await _persist(workspace.copyWith(books: updatedBooks));
  }

  Future<void> updateBookNarrativeProfile({
    required String bookId,
    required BookNarrativeProfile narrativeProfile,
  }) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    final updatedBooks = workspace.books.map((book) {
      if (book.id != bookId) return book;
      return book.copyWith(
        narrativeProfile: narrativeProfile,
        updatedAt: now,
      );
    }).toList();

    await _persist(workspace.copyWith(books: updatedBooks));
    await recalculateNarrativeCopilot(bookId: bookId);
  }

  Future<void> recalculateNarrativeCopilot({
    String? bookId,
    StoryStateInput input = const StoryStateInput(),
  }) async {
    final workspace = state.value;
    if (workspace == null) return;

    final targetBook = bookId == null
        ? workspace.activeBook
        : workspace.books.cast<Book?>().firstWhere(
              (book) => book?.id == bookId,
              orElse: () => null,
            );
    if (targetBook == null) return;

    final now = DateTime.now();
    final documents = workspace.documents.where((document) => document.bookId == targetBook.id).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final previousMemory = workspace.narrativeMemories.cast<NarrativeMemory?>().firstWhere(
          (memory) => memory?.bookId == targetBook.id,
          orElse: () => null,
        );
    final previousStoryState = workspace.storyStates.cast<StoryState?>().firstWhere(
          (storyState) => storyState?.bookId == targetBook.id,
          orElse: () => null,
        );

    final memory = _narrativeMemoryUpdater.update(
      bookId: targetBook.id,
      documents: documents,
      previous: previousMemory,
      now: now,
    );
    final storyState = _storyStateUpdater.update(
      book: targetBook,
      documents: documents,
      memory: memory,
      previous: previousStoryState,
      now: now,
      input: input,
    );

    await _persist(
      workspace.copyWith(
        narrativeMemories: _replaceByBookId<NarrativeMemory>(
          workspace.narrativeMemories,
          memory,
          (item) => item.bookId,
        ),
        storyStates: _replaceByBookId<StoryState>(
          workspace.storyStates,
          storyState,
          (item) => item.bookId,
        ),
      ),
    );
  }

  Future<void> reorderActiveBookDocuments(List<String> orderedDocumentIds) async {
    final workspace = state.value;
    final activeBookId = workspace?.activeBook?.id;
    if (workspace == null || activeBookId == null) return;

    final activeDocuments = workspace.documents.where((document) => document.bookId == activeBookId).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    if (activeDocuments.length != orderedDocumentIds.length) return;
    final activeIds = activeDocuments.map((document) => document.id).toSet();
    if (!orderedDocumentIds.every(activeIds.contains)) return;

    final now = DateTime.now();
    final positionById = <String, int>{
      for (var i = 0; i < orderedDocumentIds.length; i++) orderedDocumentIds[i]: i,
    };

    final updatedDocuments = workspace.documents.map((document) {
      if (document.bookId != activeBookId) return document;
      final nextIndex = positionById[document.id];
      if (nextIndex == null || nextIndex == document.orderIndex) {
        return document;
      }
      return document.copyWith(orderIndex: nextIndex, updatedAt: now);
    }).toList();

    await _persist(
      workspace.copyWith(
        documents: updatedDocuments,
        books: _touchActiveBook(workspace.books, activeBookId, now),
      ),
    );
  }

  Future<void> updateDocumentTitle(String documentId, String title) async {
    final workspace = state.value;
    if (workspace == null) return;

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;

    final now = DateTime.now();
    final updatedDocuments = workspace.documents.map((document) {
      if (document.id != documentId) return document;
      return document.copyWith(title: trimmedTitle, updatedAt: now);
    }).toList();

    await _persist(
      workspace.copyWith(
        documents: updatedDocuments,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  Future<void> updateDocumentContent(String documentId, String content) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    final wordCount = _wordCount(content);
    final updatedDocuments = workspace.documents.map((document) {
      if (document.id != documentId) return document;
      return document.copyWith(
        content: content,
        wordCount: wordCount,
        updatedAt: now,
      );
    }).toList();

    await _persist(
      workspace.copyWith(
        documents: updatedDocuments,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  Future<void> createNote({
    String title = 'Nueva nota',
    NoteKind kind = NoteKind.loose,
  }) async {
    final workspace = state.value;
    final activeBook = workspace?.activeBook;
    if (workspace == null || activeBook == null) return;

    final now = DateTime.now();
    final newNote = Note(
      id: generateEntityId('note'),
      bookId: activeBook.id,
      title: title.trim().isEmpty ? null : title.trim(),
      kind: kind,
      status: NoteStatus.inbox,
      createdAt: now,
      updatedAt: now,
    );

    await _persist(
      workspace.copyWith(
        notes: [...workspace.notes, newNote],
        books: _touchActiveBook(workspace.books, activeBook.id, now),
        selectedNoteId: newNote.id,
        clearSelectedCharacterId: true,
        clearSelectedScenarioId: true,
        editorMode: WorkspaceEditorMode.note,
      ),
    );
  }

  /// Crea una `Note` cuyo origen es una captura del inbox.
  ///
  /// La nota llega a la bandeja del libro activo con `kind = NoteKind.loose`
  /// y `status = NoteStatus.inbox`. El `body` es lo que el usuario aceptó
  /// (texto, o texto + URL si era kind=link). El `title` se infiere de la
  /// primera línea no vacía si existe.
  Future<Note?> addNoteFromInbox({
    required String body,
    required String? url,
    required DateTime capturedAt,
    required String deviceLabel,
  }) async {
    final workspace = state.value;
    final activeBook = workspace?.activeBook;
    if (workspace == null || activeBook == null) return null;

    final fullContent = url == null || url.isEmpty
        ? body
        : (body.isEmpty ? url : '$body\n\n$url');

    String inferredTitle = '';
    for (final raw in fullContent.split('\n')) {
      final line = raw.trim();
      if (line.isNotEmpty) {
        inferredTitle = line.length > 80 ? '${line.substring(0, 77)}…' : line;
        break;
      }
    }

    final now = DateTime.now();
    final newNote = Note(
      id: generateEntityId('note'),
      bookId: activeBook.id,
      title: inferredTitle.isEmpty ? null : inferredTitle,
      content: fullContent,
      kind: NoteKind.loose,
      status: NoteStatus.inbox,
      createdAt: capturedAt,
      updatedAt: now,
    );

    await _persist(
      workspace.copyWith(
        notes: [...workspace.notes, newNote],
        books: _touchActiveBook(workspace.books, activeBook.id, now),
      ),
    );
    return newNote;
  }

  Future<Note?> createWorkflowNote({
    required String title,
    required String content,
    required EditorialWorkflowType workflowType,
    required String workflowDirectionKey,
    required String sourceDocumentId,
    required String sourceDocumentTitle,
  }) async {
    final workspace = state.value;
    final activeBook = workspace?.activeBook;
    if (workspace == null || activeBook == null) return null;

    final now = DateTime.now();
    final newNote = Note(
      id: generateEntityId('note'),
      bookId: activeBook.id,
      title: title.trim().isEmpty ? null : title.trim(),
      content: content.trim(),
      kind: NoteKind.structural,
      status: NoteStatus.inbox,
      createdAt: now,
      updatedAt: now,
      documentIds: [sourceDocumentId],
      workflowType: workflowType,
      workflowDirectionKey: workflowDirectionKey,
      sourceDocumentId: sourceDocumentId,
      sourceDocumentTitle: sourceDocumentTitle,
    );

    await _persist(
      workspace.copyWith(
        notes: [...workspace.notes, newNote],
        books: _touchActiveBook(workspace.books, activeBook.id, now),
        selectedNoteId: newNote.id,
        clearSelectedCharacterId: true,
        clearSelectedScenarioId: true,
        editorMode: WorkspaceEditorMode.note,
      ),
    );

    return newNote;
  }

  Future<void> createAnchoredNote({
    required String anchorTextSnapshot,
    required int anchorStartOffset,
    required int anchorEndOffset,
    String? currentDocumentId,
    NoteOpenBehavior openBehavior = NoteOpenBehavior.sidebar,
  }) async {
    final workspace = state.value;
    final activeBook = workspace?.activeBook;
    if (workspace == null || activeBook == null) return;

    final now = DateTime.now();
    final newNote = Note(
      id: generateEntityId('note'),
      bookId: activeBook.id,
      title: 'Nota vinculada',
      kind: NoteKind.idea,
      status: NoteStatus.linked,
      createdAt: now,
      updatedAt: now,
      anchorTextSnapshot: anchorTextSnapshot,
      anchorStartOffset: anchorStartOffset,
      anchorEndOffset: anchorEndOffset,
      anchorState: NoteAnchorState.exact,
      documentIds: currentDocumentId != null ? [currentDocumentId] : const [],
    );

    await _persist(
      workspace.copyWith(
        notes: [...workspace.notes, newNote],
        books: _touchActiveBook(workspace.books, activeBook.id, now),
        selectedNoteId: newNote.id,
        clearSelectedCharacterId: true,
        clearSelectedScenarioId: true,
        editorMode: openBehavior == NoteOpenBehavior.inspector ? workspace.editorMode : WorkspaceEditorMode.note,
      ),
    );
  }

  Future<void> reconcileAnchoredNotes(
    List<NoteAnchorResolution> resolutions,
  ) async {
    final workspace = state.value;
    if (workspace == null || resolutions.isEmpty) return;

    final resolutionById = <String, NoteAnchorResolution>{
      for (final resolution in resolutions) resolution.noteId: resolution,
    };

    var changed = false;
    final updatedNotes = workspace.notes.map((note) {
      final resolution = resolutionById[note.id];
      if (resolution == null) return note;

      final nextSnapshot = resolution.resolvedTextSnapshot ?? note.anchorTextSnapshot;
      final nextStart = resolution.resolvedStartOffset ?? note.anchorStartOffset;
      final nextEnd = resolution.resolvedEndOffset ?? note.anchorEndOffset;
      final nextState = resolution.state;

      if (nextSnapshot == note.anchorTextSnapshot &&
          nextStart == note.anchorStartOffset &&
          nextEnd == note.anchorEndOffset &&
          nextState == note.anchorState) {
        return note;
      }

      changed = true;
      return note.copyWith(
        anchorTextSnapshot: nextSnapshot,
        anchorStartOffset: nextStart,
        anchorEndOffset: nextEnd,
        anchorState: nextState,
      );
    }).toList();

    if (!changed) return;

    await _persist(
      workspace.copyWith(
        notes: updatedNotes,
      ),
    );
  }

  Future<Character?> createCharacter({
    String name = 'Nuevo personaje',
    String role = '',
    String summary = '',
    String voice = '',
    String motivation = '',
    String internalConflict = '',
    String whatTheyHide = '',
    String currentState = '',
    String notes = '',
    bool isProtagonist = false,
    bool linkToSelectedDocument = false,
    bool selectAfterCreate = true,
  }) async {
    final workspace = state.value;
    final activeBook = workspace?.activeBook;
    if (workspace == null || activeBook == null) return null;

    final now = DateTime.now();
    final newCharacter = Character(
      id: generateEntityId('character'),
      bookId: activeBook.id,
      name: name.trim(),
      role: role.trim(),
      summary: summary.trim(),
      voice: voice.trim(),
      motivation: motivation.trim(),
      internalConflict: internalConflict.trim(),
      whatTheyHide: whatTheyHide.trim(),
      currentState: currentState.trim(),
      notes: notes.trim(),
      isProtagonist: isProtagonist,
      createdAt: now,
      updatedAt: now,
    );
    final updatedDocuments = linkToSelectedDocument && workspace.selectedDocumentId != null
        ? workspace.documents.map((document) {
            if (document.id != workspace.selectedDocumentId) {
              return document;
            }
            if (document.characterIds.contains(newCharacter.id)) {
              return document;
            }
            return document.copyWith(
              characterIds: [...document.characterIds, newCharacter.id],
              updatedAt: now,
            );
          }).toList()
        : workspace.documents;

    await _persist(
      workspace.copyWith(
        characters: [...workspace.characters, newCharacter],
        documents: updatedDocuments,
        books: _touchActiveBook(workspace.books, activeBook.id, now),
        selectedCharacterId: selectAfterCreate ? newCharacter.id : workspace.selectedCharacterId,
        clearSelectedScenarioId: selectAfterCreate && workspace.selectedScenarioId != null,
        editorMode: selectAfterCreate ? WorkspaceEditorMode.character : workspace.editorMode,
      ),
    );

    return newCharacter;
  }

  Future<void> updateCharacter(Character character) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    final updatedCharacters = workspace.characters.map((item) {
      if (item.id != character.id) return item;
      return character.copyWith(updatedAt: now);
    }).toList();

    await _persist(
      workspace.copyWith(
        characters: updatedCharacters,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  Future<void> mergeCharacterAutofillDraft({
    required String characterId,
    required CharacterAutofillDraft draft,
    bool onlyFillEmpty = true,
  }) async {
    final workspace = state.value;
    if (workspace == null || draft.isEmpty) return;

    final now = DateTime.now();
    var changed = false;
    final updatedCharacters = workspace.characters.map((item) {
      if (item.id != characterId) return item;
      final merged = draft.mergeInto(item, onlyFillEmpty: onlyFillEmpty);
      final hasDifferences = merged.summary != item.summary ||
          merged.voice != item.voice ||
          merged.motivation != item.motivation ||
          merged.internalConflict != item.internalConflict ||
          merged.whatTheyHide != item.whatTheyHide ||
          merged.currentState != item.currentState ||
          merged.role != item.role ||
          merged.notes != item.notes;
      if (!hasDifferences) {
        return item;
      }
      changed = true;
      return merged.copyWith(updatedAt: now);
    }).toList();

    if (!changed) return;

    await _persist(
      workspace.copyWith(
        characters: updatedCharacters,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  Future<void> enrichCharacterFromDraft({
    required String characterId,
    required CharacterAutofillDraft draft,
    required String sourceDocumentTitle,
  }) async {
    final workspace = state.value;
    if (workspace == null || draft.isEmpty) return;

    final now = DateTime.now();
    var changed = false;
    final updatedCharacters = workspace.characters.map((item) {
      if (item.id != characterId) return item;

      final filled = draft.mergeInto(item, onlyFillEmpty: true);
      final enrichmentNote = _buildEnrichmentNote(
        current: item,
        draft: draft,
        sourceDocumentTitle: sourceDocumentTitle,
      );
      final mergedNotes = _mergeNotes(filled.notes, enrichmentNote);
      final merged = filled.copyWith(notes: mergedNotes);

      final hasDifferences = merged.summary != item.summary ||
          merged.voice != item.voice ||
          merged.motivation != item.motivation ||
          merged.internalConflict != item.internalConflict ||
          merged.whatTheyHide != item.whatTheyHide ||
          merged.currentState != item.currentState ||
          merged.role != item.role ||
          merged.notes != item.notes;
      if (!hasDifferences) {
        return item;
      }
      changed = true;
      return merged.copyWith(updatedAt: now);
    }).toList();

    if (!changed) return;

    await _persist(
      workspace.copyWith(
        characters: updatedCharacters,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  String _buildEnrichmentNote({
    required Character current,
    required CharacterAutofillDraft draft,
    required String sourceDocumentTitle,
  }) {
    final additions = <String>[];
    final incoming = draft.nonEmptyFields();

    void maybeAdd(String label, String currentValue) {
      final next = incoming[label];
      if (next == null || next.isEmpty || currentValue.trim().isEmpty) return;
      final normalizedCurrent = currentValue.trim().toLowerCase();
      final normalizedNext = next.trim().toLowerCase();
      if (normalizedCurrent.contains(normalizedNext) || normalizedNext.contains(normalizedCurrent)) {
        return;
      }
      additions.add('$label: $next');
    }

    maybeAdd('Quién es', current.summary);
    maybeAdd('Cómo habla', current.voice);
    maybeAdd('Qué quiere', current.motivation);
    maybeAdd('Qué lo fractura', current.internalConflict);
    maybeAdd('Qué oculta', current.whatTheyHide);
    maybeAdd('Estado actual', current.currentState);
    maybeAdd('Rol', current.role);

    if (additions.isEmpty) return '';

    return 'Actualizado con un fragmento de "$sourceDocumentTitle": ${additions.join(' | ')}';
  }

  String _mergeNotes(String currentNotes, String extraNote) {
    final trimmedExtra = extraNote.trim();
    if (trimmedExtra.isEmpty) return currentNotes;
    final trimmedCurrent = currentNotes.trim();
    if (trimmedCurrent.isEmpty) return trimmedExtra;
    if (trimmedCurrent.contains(trimmedExtra)) return trimmedCurrent;
    return '$trimmedCurrent\n\n$trimmedExtra';
  }

  Future<void> renameCharacter(String characterId, String name) async {
    final workspace = state.value;
    if (workspace == null) return;

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    Character? current;
    for (final item in workspace.characters) {
      if (item.id == characterId) {
        current = item;
        break;
      }
    }
    if (current == null) return;

    await updateCharacter(current.copyWith(name: trimmedName));
  }

  Future<Scenario?> createScenario({
    String name = 'Escenario nuevo',
    String role = '',
    String summary = '',
    String atmosphere = '',
    String importance = '',
    String whatItHides = '',
    String currentState = '',
    String notes = '',
    bool linkToSelectedDocument = false,
    bool selectAfterCreate = true,
  }) async {
    final workspace = state.value;
    final activeBook = workspace?.activeBook;
    if (workspace == null || activeBook == null) return null;

    final now = DateTime.now();
    final newScenario = Scenario(
      id: generateEntityId('scenario'),
      bookId: activeBook.id,
      name: name.trim().isEmpty ? 'Escenario nuevo' : name.trim(),
      role: role.trim(),
      summary: summary.trim(),
      atmosphere: atmosphere.trim(),
      importance: importance.trim(),
      whatItHides: whatItHides.trim(),
      currentState: currentState.trim(),
      notes: notes.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final updatedDocuments = linkToSelectedDocument && workspace.selectedDocumentId != null
        ? workspace.documents.map((document) {
            if (document.id != workspace.selectedDocumentId) {
              return document;
            }
            if (document.scenarioIds.contains(newScenario.id)) {
              return document;
            }
            return document.copyWith(
              scenarioIds: [...document.scenarioIds, newScenario.id],
              updatedAt: now,
            );
          }).toList()
        : workspace.documents;

    await _persist(
      workspace.copyWith(
        scenarios: [...workspace.scenarios, newScenario],
        documents: updatedDocuments,
        books: _touchActiveBook(workspace.books, activeBook.id, now),
        selectedScenarioId: selectAfterCreate ? newScenario.id : workspace.selectedScenarioId,
        clearSelectedCharacterId: selectAfterCreate && workspace.selectedCharacterId != null,
        editorMode: selectAfterCreate ? WorkspaceEditorMode.scenario : workspace.editorMode,
      ),
    );

    return newScenario;
  }

  Future<void> updateScenario(Scenario scenario) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    final updatedScenarios = workspace.scenarios.map((item) {
      if (item.id != scenario.id) return item;
      return scenario.copyWith(updatedAt: now);
    }).toList();

    await _persist(
      workspace.copyWith(
        scenarios: updatedScenarios,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  Future<void> mergeScenarioAutofillDraft({
    required String scenarioId,
    required ScenarioAutofillDraft draft,
    bool onlyFillEmpty = true,
  }) async {
    final workspace = state.value;
    if (workspace == null || draft.isEmpty) return;

    final now = DateTime.now();
    var changed = false;
    final updatedScenarios = workspace.scenarios.map((item) {
      if (item.id != scenarioId) return item;
      final merged = draft.mergeInto(item, onlyFillEmpty: onlyFillEmpty);
      final hasDifferences = merged.summary != item.summary ||
          merged.atmosphere != item.atmosphere ||
          merged.importance != item.importance ||
          merged.whatItHides != item.whatItHides ||
          merged.currentState != item.currentState ||
          merged.role != item.role ||
          merged.notes != item.notes;
      if (!hasDifferences) return item;
      changed = true;
      return merged.copyWith(updatedAt: now);
    }).toList();

    if (!changed) return;

    await _persist(
      workspace.copyWith(
        scenarios: updatedScenarios,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  Future<void> enrichScenarioFromDraft({
    required String scenarioId,
    required ScenarioAutofillDraft draft,
    required String sourceDocumentTitle,
  }) async {
    final workspace = state.value;
    if (workspace == null || draft.isEmpty) return;

    final now = DateTime.now();
    var changed = false;
    final updatedScenarios = workspace.scenarios.map((item) {
      if (item.id != scenarioId) return item;

      final filled = draft.mergeInto(item, onlyFillEmpty: true);
      final enrichmentNote = _buildScenarioEnrichmentNote(
        current: item,
        draft: draft,
        sourceDocumentTitle: sourceDocumentTitle,
      );
      final mergedNotes = _mergeNotes(filled.notes, enrichmentNote);
      final merged = filled.copyWith(notes: mergedNotes);

      final hasDifferences = merged.summary != item.summary ||
          merged.atmosphere != item.atmosphere ||
          merged.importance != item.importance ||
          merged.whatItHides != item.whatItHides ||
          merged.currentState != item.currentState ||
          merged.role != item.role ||
          merged.notes != item.notes;
      if (!hasDifferences) return item;
      changed = true;
      return merged.copyWith(updatedAt: now);
    }).toList();

    if (!changed) return;

    await _persist(
      workspace.copyWith(
        scenarios: updatedScenarios,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  String _buildScenarioEnrichmentNote({
    required Scenario current,
    required ScenarioAutofillDraft draft,
    required String sourceDocumentTitle,
  }) {
    final additions = <String>[];
    final incoming = draft.nonEmptyFields();

    void maybeAdd(String label, String currentValue) {
      final next = incoming[label];
      if (next == null || next.isEmpty || currentValue.trim().isEmpty) return;
      final normalizedCurrent = currentValue.trim().toLowerCase();
      final normalizedNext = next.trim().toLowerCase();
      if (normalizedCurrent.contains(normalizedNext) || normalizedNext.contains(normalizedCurrent)) {
        return;
      }
      additions.add('$label: $next');
    }

    maybeAdd('Qué es este lugar', current.summary);
    maybeAdd('Qué ambiente tiene', current.atmosphere);
    maybeAdd('Por qué importa', current.importance);
    maybeAdd('Qué oculta', current.whatItHides);
    maybeAdd('Estado actual', current.currentState);
    maybeAdd('Función en la historia', current.role);

    if (additions.isEmpty) return '';
    return 'Actualizado con un fragmento de "$sourceDocumentTitle": ${additions.join(' | ')}';
  }

  Future<void> deleteCharacter(String characterId) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    final remainingCharacters = workspace.characters.where((item) => item.id != characterId).toList();
    final updatedDocuments = workspace.documents.map((document) {
      if (!document.characterIds.contains(characterId)) return document;
      return document.copyWith(
        characterIds: document.characterIds.where((id) => id != characterId).toList(),
        updatedAt: now,
      );
    }).toList();
    final activeBookId = workspace.activeBook?.id;
    final activeBookCharacters = remainingCharacters.where((item) => item.bookId == activeBookId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final wasSelected = workspace.selectedCharacterId == characterId;
    final nextCharacterId = wasSelected && activeBookCharacters.isNotEmpty ? activeBookCharacters.first.id : null;

    await _persist(
      workspace.copyWith(
        characters: remainingCharacters,
        documents: updatedDocuments,
        books: _touchActiveBook(workspace.books, activeBookId, now),
        selectedCharacterId: nextCharacterId,
        clearSelectedCharacterId: wasSelected && nextCharacterId == null,
        editorMode:
            wasSelected ? (workspace.selectedNote != null ? WorkspaceEditorMode.note : WorkspaceEditorMode.document) : workspace.editorMode,
      ),
    );
  }

  Future<void> renameScenario(String scenarioId, String name) async {
    final workspace = state.value;
    if (workspace == null) return;

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    Scenario? current;
    for (final item in workspace.scenarios) {
      if (item.id == scenarioId) {
        current = item;
        break;
      }
    }
    if (current == null) return;

    await updateScenario(current.copyWith(name: trimmedName));
  }

  Future<void> deleteScenario(String scenarioId) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    final remainingScenarios = workspace.scenarios.where((item) => item.id != scenarioId).toList();
    final updatedDocuments = workspace.documents.map((document) {
      if (!document.scenarioIds.contains(scenarioId)) return document;
      return document.copyWith(
        scenarioIds: document.scenarioIds.where((id) => id != scenarioId).toList(),
        updatedAt: now,
      );
    }).toList();
    final activeBookId = workspace.activeBook?.id;
    final activeBookScenarios = remainingScenarios.where((item) => item.bookId == activeBookId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final wasSelected = workspace.selectedScenarioId == scenarioId;
    final nextScenarioId = wasSelected && activeBookScenarios.isNotEmpty ? activeBookScenarios.first.id : null;

    await _persist(
      workspace.copyWith(
        scenarios: remainingScenarios,
        documents: updatedDocuments,
        books: _touchActiveBook(workspace.books, activeBookId, now),
        selectedScenarioId: nextScenarioId,
        clearSelectedScenarioId: wasSelected && nextScenarioId == null,
        editorMode: wasSelected ? WorkspaceEditorMode.document : workspace.editorMode,
      ),
    );
  }

  Future<void> deleteDocument(String documentId) async {
    final workspace = state.value;
    final activeBookId = workspace?.activeBook?.id;
    if (workspace == null || activeBookId == null) return;

    final now = DateTime.now();
    final remaining = workspace.documents.where((doc) => doc.id != documentId).toList();

    // Reindex documents for the active book to keep orderIndex contiguous
    final bookDocs = remaining.where((doc) => doc.bookId == activeBookId).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final reindexed = <Document>[];
    for (var i = 0; i < bookDocs.length; i++) {
      final doc = bookDocs[i];
      reindexed.add(doc.orderIndex != i ? doc.copyWith(orderIndex: i, updatedAt: now) : doc);
    }
    final updatedDocuments = [
      ...remaining.where((doc) => doc.bookId != activeBookId),
      ...reindexed,
    ];

    final wasSelected = workspace.selectedDocumentId == documentId;
    final nextDocumentId = wasSelected && reindexed.isNotEmpty ? reindexed.first.id : null;

    await _persist(
      workspace.copyWith(
        documents: updatedDocuments,
        books: _touchActiveBook(workspace.books, activeBookId, now),
        selectedDocumentId: wasSelected ? nextDocumentId : workspace.selectedDocumentId,
        clearSelectedDocumentId: wasSelected && nextDocumentId == null,
      ),
    );
  }

  Future<void> linkCharacterToDocument({
    required String documentId,
    required String characterId,
  }) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    var changed = false;
    final updatedDocuments = workspace.documents.map((document) {
      if (document.id != documentId) return document;
      if (document.characterIds.contains(characterId)) return document;
      changed = true;
      return document.copyWith(
        characterIds: [...document.characterIds, characterId],
        updatedAt: now,
      );
    }).toList();

    if (!changed) return;

    await _persist(
      workspace.copyWith(
        documents: updatedDocuments,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  Future<void> linkScenarioToDocument({
    required String documentId,
    required String scenarioId,
  }) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    var changed = false;
    final updatedDocuments = workspace.documents.map((document) {
      if (document.id != documentId) return document;
      if (document.scenarioIds.contains(scenarioId)) return document;
      changed = true;
      return document.copyWith(
        scenarioIds: [...document.scenarioIds, scenarioId],
        updatedAt: now,
      );
    }).toList();

    if (!changed) return;

    await _persist(
      workspace.copyWith(
        documents: updatedDocuments,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  Future<void> unlinkCharacterFromDocument({
    required String documentId,
    required String characterId,
  }) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    var changed = false;
    final updatedDocuments = workspace.documents.map((document) {
      if (document.id != documentId) return document;
      if (!document.characterIds.contains(characterId)) return document;
      changed = true;
      return document.copyWith(
        characterIds: document.characterIds.where((id) => id != characterId).toList(),
        updatedAt: now,
      );
    }).toList();

    if (!changed) return;

    await _persist(
      workspace.copyWith(
        documents: updatedDocuments,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  Future<void> unlinkScenarioFromDocument({
    required String documentId,
    required String scenarioId,
  }) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    var changed = false;
    final updatedDocuments = workspace.documents.map((document) {
      if (document.id != documentId) return document;
      if (!document.scenarioIds.contains(scenarioId)) return document;
      changed = true;
      return document.copyWith(
        scenarioIds: document.scenarioIds.where((id) => id != scenarioId).toList(),
        updatedAt: now,
      );
    }).toList();

    if (!changed) return;

    await _persist(
      workspace.copyWith(
        documents: updatedDocuments,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  Future<void> updateNoteTitle(String noteId, String title) async {
    final workspace = state.value;
    if (workspace == null) return;

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;

    final now = DateTime.now();
    final updatedNotes = workspace.notes.map((note) {
      if (note.id != noteId) return note;
      return note.copyWith(title: trimmedTitle, updatedAt: now);
    }).toList();

    await _persist(
      workspace.copyWith(
        notes: updatedNotes,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  Future<void> updateNoteContent(String noteId, String content) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    final updatedNotes = workspace.notes.map((note) {
      if (note.id != noteId) return note;
      return note.copyWith(content: content, updatedAt: now);
    }).toList();

    await _persist(
      workspace.copyWith(
        notes: updatedNotes,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  Future<void> updateNoteStatus(String noteId, NoteStatus status) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    final updatedNotes = workspace.notes.map((note) {
      if (note.id != noteId) return note;
      return note.copyWith(status: status, updatedAt: now);
    }).toList();

    await _persist(
      workspace.copyWith(
        notes: updatedNotes,
        books: _touchActiveBook(workspace.books, workspace.activeBook?.id, now),
      ),
    );
  }

  Future<WorkspaceSnapshot?> createSnapshot({
    String? label,
  }) async {
    final workspace = state.value;
    final activeBook = workspace?.activeBook;
    if (workspace == null || activeBook == null) return null;

    final now = DateTime.now();
    final snapshot = WorkspaceSnapshot(
      id: generateEntityId('snapshot'),
      bookId: activeBook.id,
      label: (label?.trim().isNotEmpty ?? false)
          ? label!.trim()
          : 'Estado guardado ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      createdAt: now,
      payload: workspace.copyWith(snapshots: const []).toJson(),
    );

    await _persist(
      workspace.copyWith(
        snapshots: [...workspace.snapshots, snapshot],
        books: _touchActiveBook(workspace.books, activeBook.id, now),
      ),
    );

    return snapshot;
  }

  Future<void> restoreSnapshot(String snapshotId) async {
    final workspace = state.value;
    if (workspace == null) return;

    WorkspaceSnapshot? snapshot;
    for (final item in workspace.snapshots) {
      if (item.id == snapshotId) {
        snapshot = item;
        break;
      }
    }
    if (snapshot == null) return;

    final restored = NarrativeWorkspace.fromJson(snapshot.payload).copyWith(
      snapshots: workspace.snapshots,
    );
    state = AsyncValue.data(restored);
    await _repository.saveWorkspace(restored);
  }

  Future<void> deleteNote(String noteId) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    final activeBookId = workspace.activeBook?.id;
    final remainingNotes = workspace.notes.where((note) => note.id != noteId).toList();
    final activeBookNotes = remainingNotes.where((note) => note.bookId == activeBookId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final activeBookDocuments = workspace.documents.where((document) => document.bookId == activeBookId).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final wasSelected = workspace.selectedNoteId == noteId;
    final nextNoteId = wasSelected && activeBookNotes.isNotEmpty ? activeBookNotes.first.id : null;
    final nextDocumentId = activeBookDocuments.isNotEmpty
        ? (workspace.selectedDocumentId != null &&
                activeBookDocuments.any(
                  (document) => document.id == workspace.selectedDocumentId,
                )
            ? workspace.selectedDocumentId
            : activeBookDocuments.first.id)
        : null;

    await _persist(
      workspace.copyWith(
        notes: remainingNotes,
        books: _touchActiveBook(workspace.books, activeBookId, now),
        selectedNoteId: nextNoteId,
        clearSelectedNoteId: wasSelected && nextNoteId == null,
        selectedDocumentId: nextDocumentId,
        clearSelectedDocumentId: nextDocumentId == null,
        editorMode: wasSelected ? (nextNoteId != null ? WorkspaceEditorMode.note : WorkspaceEditorMode.document) : workspace.editorMode,
      ),
    );
  }

  Future<void> createVoiceMemoStub({
    String title = 'Nueva nota oral',
  }) async {
    final workspace = state.value;
    final activeBook = workspace?.activeBook;
    if (workspace == null || activeBook == null) return;

    final now = DateTime.now();
    final voiceMemo = VoiceMemo(
      id: generateEntityId('voice-memo'),
      bookId: activeBook.id,
      title: title.trim().isEmpty ? null : title.trim(),
      audioPath: '',
      createdAt: now,
      summary: 'Pendiente de captura o importación.',
    );

    await _persist(
      workspace.copyWith(
        voiceMemos: [...workspace.voiceMemos, voiceMemo],
        books: _touchActiveBook(workspace.books, activeBook.id, now),
      ),
    );
  }

  Future<void> addDocument({
    String title = 'Nuevo documento',
    DocumentKind kind = DocumentKind.chapter,
    bool selectAfterCreate = true,
  }) async {
    final workspace = state.value;
    final activeBook = workspace?.activeBook;
    if (workspace == null || activeBook == null) return;

    final now = DateTime.now();
    final newDocument = Document(
      id: generateEntityId('document'),
      bookId: activeBook.id,
      title: title,
      kind: kind,
      orderIndex: workspace.activeBookDocuments.length,
      createdAt: now,
      updatedAt: now,
    );

    await _persist(
      workspace.copyWith(
        documents: [...workspace.documents, newDocument],
        books: _touchActiveBook(workspace.books, activeBook.id, now),
        selectedDocumentId: selectAfterCreate ? newDocument.id : workspace.selectedDocumentId,
        clearSelectedNoteId: selectAfterCreate,
        clearSelectedCharacterId: selectAfterCreate,
        clearSelectedScenarioId: selectAfterCreate,
        editorMode: selectAfterCreate ? WorkspaceEditorMode.document : workspace.editorMode,
      ),
    );
  }

  Future<void> createBook({
    String title = 'Nuevo libro',
    String firstDocumentTitle = 'Apertura',
  }) async {
    final workspace = state.value;
    if (workspace == null) return;

    final now = DateTime.now();
    final bookId = generateEntityId('book');
    final documentId = generateEntityId('document');

    final book = Book(
      id: bookId,
      title: title,
      status: BookStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    final document = Document(
      id: documentId,
      bookId: bookId,
      title: firstDocumentTitle,
      orderIndex: 0,
      createdAt: now,
      updatedAt: now,
    );
    final continuity = ContinuityState(
      bookId: bookId,
      lastUpdatedAt: now,
    );

    await _persist(
      workspace.copyWith(
        appSettings: workspace.appSettings.copyWith(activeBookId: bookId),
        books: [...workspace.books, book],
        documents: [...workspace.documents, document],
        continuityStates: [...workspace.continuityStates, continuity],
        selectedDocumentId: documentId,
        clearSelectedNoteId: true,
        clearSelectedCharacterId: true,
        clearSelectedScenarioId: true,
        editorMode: WorkspaceEditorMode.document,
      ),
    );
  }

  Future<void> updateWritingSettings(WritingSettings writingSettings) async {
    final workspace = state.value;
    if (workspace == null) return;

    await _persist(
      workspace.copyWith(
        appSettings: workspace.appSettings.copyWith(writingSettings: writingSettings),
      ),
    );
  }

  Future<void> updateMusaSettings(MusaSettings musaSettings) async {
    final workspace = state.value;
    if (workspace == null) return;

    await _persist(
      workspace.copyWith(
        appSettings: workspace.appSettings.copyWith(musaSettings: musaSettings),
      ),
    );
  }

  Future<void> updateTypographySettings(
    TypographySettings typographySettings,
  ) async {
    final workspace = state.value;
    if (workspace == null) return;

    await _persist(
      workspace.copyWith(
        appSettings: workspace.appSettings.copyWith(
          typographySettings: typographySettings,
        ),
      ),
    );
  }

  Future<void> updateAppSettings(AppSettings appSettings) async {
    final workspace = state.value;
    if (workspace == null) return;

    await _persist(
      workspace.copyWith(
        appSettings: appSettings,
      ),
    );
  }

  List<T> _replaceByBookId<T>(
    List<T> items,
    T replacement,
    String Function(T item) bookIdOf,
  ) {
    var replaced = false;
    final results = items.map((item) {
      if (bookIdOf(item) != bookIdOf(replacement)) return item;
      replaced = true;
      return replacement;
    }).toList();
    if (!replaced) results.add(replacement);
    return results;
  }

  List<Book> _touchActiveBook(List<Book> books, String? bookId, DateTime now) {
    if (bookId == null) return books;
    return books.map((book) {
      if (book.id != bookId) return book;
      return book.copyWith(updatedAt: now);
    }).toList();
  }

  int _wordCount(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }
}

final narrativeWorkspaceProvider = StateNotifierProvider<NarrativeWorkspaceNotifier, AsyncValue<NarrativeWorkspace>>((ref) {
  final repository = ref.watch(narrativeWorkspaceRepositoryProvider);
  return NarrativeWorkspaceNotifier(ref, repository);
});

/// List of books available in the loaded workspace.
final booksProvider = Provider<List<Book>>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.books ?? const [];
});

/// Currently active book resolved from app settings.
final activeBookProvider = Provider<Book?>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.activeBook;
});

/// Global settings snapshot consumed across theme and editing surfaces.
final appSettingsProvider = Provider<AppSettings>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.appSettings ?? const AppSettings();
});

/// Musa-specific preferences extracted from app settings.
final musaSettingsProvider = Provider<MusaSettings>((ref) {
  return ref.watch(appSettingsProvider).musaSettings;
});

/// Typography configuration derived from the current workspace settings.
final typographySettingsProvider = Provider<TypographySettings>((ref) {
  return ref.watch(appSettingsProvider).typographySettings;
});

/// Writing-surface preferences consumed by editor widgets and controllers.
final writingSettingsProvider = Provider<WritingSettings>((ref) {
  return ref.watch(appSettingsProvider).writingSettings;
});

/// Active editor mode for the current workspace selection.
final editorModeProvider = Provider<WorkspaceEditorMode>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.editorMode ?? WorkspaceEditorMode.document;
});
