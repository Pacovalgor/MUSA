import '../../characters/models/character.dart';
import '../../characters/models/character_relation.dart';
import '../../continuity/models/continuity_state.dart';
import '../../continuity/models/timeline_event.dart';
import '../../creative/models/creative_card.dart';
import '../../manuscript/models/document.dart';
import '../../manuscript/models/document_revision.dart';
import '../../manuscript/models/scene_reference.dart';
import '../../models_runtime/models/installed_model.dart';
import '../../models_runtime/models/model_profile.dart';
import '../../musa/models/musa_chunk.dart';
import '../../musa/models/musa_profile.dart';
import '../../musa/models/musa_session.dart';
import '../../musa/models/musa_suggestion.dart';
import '../../notes/models/note.dart';
import '../../notes/models/voice_memo.dart';
import '../../scenarios/models/scenario.dart';
import 'app_settings.dart';
import 'book.dart';
import 'narrative_copilot.dart';
import 'workspace_snapshot.dart';

/// Identifies which editorial surface is currently active in the workspace.
enum WorkspaceEditorMode { book, document, note, character, scenario }

/// Canonical in-memory representation of the user's full local writing workspace.
class NarrativeWorkspace {
  final AppSettings appSettings;
  final List<Book> books;
  final List<Document> documents;
  final List<DocumentRevision> documentRevisions;
  final List<SceneReference> sceneReferences;
  final List<Note> notes;
  final List<VoiceMemo> voiceMemos;
  final List<CreativeCard> creativeCards;
  final List<Character> characters;
  final List<CharacterRelation> characterRelations;
  final List<Scenario> scenarios;
  final List<ContinuityState> continuityStates;
  final List<TimelineEvent> timelineEvents;
  final List<MusaProfile> musaProfiles;
  final List<MusaSession> musaSessions;
  final List<MusaChunk> musaChunks;
  final List<MusaSuggestion> musaSuggestions;
  final List<ModelProfile> modelProfiles;
  final List<InstalledModel> installedModels;
  final List<WorkspaceSnapshot> snapshots;
  final List<StoryState> storyStates;
  final List<NarrativeMemory> narrativeMemories;
  final String? selectedDocumentId;
  final String? selectedNoteId;
  final String? selectedCharacterId;
  final String? selectedScenarioId;
  final WorkspaceEditorMode? _editorMode;

  const NarrativeWorkspace({
    required this.appSettings,
    this.books = const [],
    this.documents = const [],
    this.documentRevisions = const [],
    this.sceneReferences = const [],
    this.notes = const [],
    this.voiceMemos = const [],
    this.creativeCards = const [],
    this.characters = const [],
    this.characterRelations = const [],
    this.scenarios = const [],
    this.continuityStates = const [],
    this.timelineEvents = const [],
    this.musaProfiles = const [],
    this.musaSessions = const [],
    this.musaChunks = const [],
    this.musaSuggestions = const [],
    this.modelProfiles = const [],
    this.installedModels = const [],
    this.snapshots = const [],
    this.storyStates = const [],
    this.narrativeMemories = const [],
    this.selectedDocumentId,
    this.selectedNoteId,
    this.selectedCharacterId,
    this.selectedScenarioId,
    WorkspaceEditorMode? editorMode,
  }) : _editorMode = editorMode;

  WorkspaceEditorMode get editorMode =>
      _editorMode ?? WorkspaceEditorMode.document;

  /// Returns the currently active book, falling back to the first available one.
  Book? get activeBook {
    final activeBookId = appSettings.activeBookId;
    if (activeBookId == null) return books.isEmpty ? null : books.first;
    for (final book in books) {
      if (book.id == activeBookId) return book;
    }
    return books.isEmpty ? null : books.first;
  }

  List<Document> get activeBookDocuments {
    final book = activeBook;
    if (book == null) return const [];
    final results = documents
        .where((document) => document.bookId == book.id)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return results;
  }

  Document? get selectedDocument {
    final docs = activeBookDocuments;
    if (docs.isEmpty) return null;
    for (final document in docs) {
      if (document.id == selectedDocumentId) {
        return document;
      }
    }
    return docs.first;
  }

  List<Note> get activeBookNotes {
    final book = activeBook;
    if (book == null) return const [];
    final results = notes.where((note) => note.bookId == book.id).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  List<CreativeCard> get activeBookCreativeCards {
    final book = activeBook;
    if (book == null) return const [];
    final results = creativeCards
        .where((card) => card.bookId == book.id)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  Note? get selectedNote {
    final activeNotes = activeBookNotes;
    if (activeNotes.isEmpty) return null;
    for (final note in activeNotes) {
      if (note.id == selectedNoteId) return note;
    }
    return activeNotes.first;
  }

  List<Character> get activeBookCharacters {
    final book = activeBook;
    if (book == null) return const [];
    final results = characters
        .where((character) => character.bookId == book.id)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  Character? get selectedCharacter {
    final activeCharacters = activeBookCharacters;
    if (activeCharacters.isEmpty) return null;
    for (final character in activeCharacters) {
      if (character.id == selectedCharacterId) return character;
    }
    return activeCharacters.first;
  }

  List<Scenario> get activeBookScenarios {
    final book = activeBook;
    if (book == null) return const [];
    final results = scenarios
        .where((scenario) => scenario.bookId == book.id)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  List<WorkspaceSnapshot> get activeBookSnapshots {
    final book = activeBook;
    if (book == null) return const [];
    final results = snapshots
        .where((snapshot) => snapshot.bookId == book.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  Scenario? get selectedScenario {
    final activeScenarios = activeBookScenarios;
    if (activeScenarios.isEmpty) return null;
    for (final scenario in activeScenarios) {
      if (scenario.id == selectedScenarioId) return scenario;
    }
    return activeScenarios.first;
  }

  ContinuityState? get activeContinuityState {
    final book = activeBook;
    if (book == null) return null;
    for (final state in continuityStates) {
      if (state.bookId == book.id) return state;
    }
    return null;
  }

  StoryState? get activeStoryState {
    final book = activeBook;
    if (book == null) return null;
    for (final state in storyStates) {
      if (state.bookId == book.id) return state;
    }
    return null;
  }

  NarrativeMemory? get activeNarrativeMemory {
    final book = activeBook;
    if (book == null) return null;
    for (final memory in narrativeMemories) {
      if (memory.bookId == book.id) return memory;
    }
    return null;
  }

  NarrativeWorkspace copyWith({
    AppSettings? appSettings,
    List<Book>? books,
    List<Document>? documents,
    List<DocumentRevision>? documentRevisions,
    List<SceneReference>? sceneReferences,
    List<Note>? notes,
    List<VoiceMemo>? voiceMemos,
    List<CreativeCard>? creativeCards,
    List<Character>? characters,
    List<CharacterRelation>? characterRelations,
    List<Scenario>? scenarios,
    List<ContinuityState>? continuityStates,
    List<TimelineEvent>? timelineEvents,
    List<MusaProfile>? musaProfiles,
    List<MusaSession>? musaSessions,
    List<MusaChunk>? musaChunks,
    List<MusaSuggestion>? musaSuggestions,
    List<ModelProfile>? modelProfiles,
    List<InstalledModel>? installedModels,
    List<WorkspaceSnapshot>? snapshots,
    List<StoryState>? storyStates,
    List<NarrativeMemory>? narrativeMemories,
    String? selectedDocumentId,
    bool clearSelectedDocumentId = false,
    String? selectedNoteId,
    bool clearSelectedNoteId = false,
    String? selectedCharacterId,
    bool clearSelectedCharacterId = false,
    String? selectedScenarioId,
    bool clearSelectedScenarioId = false,
    WorkspaceEditorMode? editorMode,
  }) {
    return NarrativeWorkspace(
      appSettings: appSettings ?? this.appSettings,
      books: books ?? this.books,
      documents: documents ?? this.documents,
      documentRevisions: documentRevisions ?? this.documentRevisions,
      sceneReferences: sceneReferences ?? this.sceneReferences,
      notes: notes ?? this.notes,
      voiceMemos: voiceMemos ?? this.voiceMemos,
      creativeCards: creativeCards ?? this.creativeCards,
      characters: characters ?? this.characters,
      characterRelations: characterRelations ?? this.characterRelations,
      scenarios: scenarios ?? this.scenarios,
      continuityStates: continuityStates ?? this.continuityStates,
      timelineEvents: timelineEvents ?? this.timelineEvents,
      musaProfiles: musaProfiles ?? this.musaProfiles,
      musaSessions: musaSessions ?? this.musaSessions,
      musaChunks: musaChunks ?? this.musaChunks,
      musaSuggestions: musaSuggestions ?? this.musaSuggestions,
      modelProfiles: modelProfiles ?? this.modelProfiles,
      installedModels: installedModels ?? this.installedModels,
      snapshots: snapshots ?? this.snapshots,
      storyStates: storyStates ?? this.storyStates,
      narrativeMemories: narrativeMemories ?? this.narrativeMemories,
      selectedDocumentId: clearSelectedDocumentId
          ? null
          : (selectedDocumentId ?? this.selectedDocumentId),
      selectedNoteId:
          clearSelectedNoteId ? null : (selectedNoteId ?? this.selectedNoteId),
      selectedCharacterId: clearSelectedCharacterId
          ? null
          : (selectedCharacterId ?? this.selectedCharacterId),
      selectedScenarioId: clearSelectedScenarioId
          ? null
          : (selectedScenarioId ?? this.selectedScenarioId),
      editorMode: editorMode ?? this.editorMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'appSettings': appSettings.toJson(),
        'books': books.map((item) => item.toJson()).toList(),
        'documents': documents.map((item) => item.toJson()).toList(),
        'documentRevisions':
            documentRevisions.map((item) => item.toJson()).toList(),
        'sceneReferences':
            sceneReferences.map((item) => item.toJson()).toList(),
        'notes': notes.map((item) => item.toJson()).toList(),
        'voiceMemos': voiceMemos.map((item) => item.toJson()).toList(),
        'creativeCards': creativeCards.map((item) => item.toJson()).toList(),
        'characters': characters.map((item) => item.toJson()).toList(),
        'characterRelations':
            characterRelations.map((item) => item.toJson()).toList(),
        'scenarios': scenarios.map((item) => item.toJson()).toList(),
        'continuityStates':
            continuityStates.map((item) => item.toJson()).toList(),
        'timelineEvents': timelineEvents.map((item) => item.toJson()).toList(),
        'musaProfiles': musaProfiles.map((item) => item.toJson()).toList(),
        'musaSessions': musaSessions.map((item) => item.toJson()).toList(),
        'musaChunks': musaChunks.map((item) => item.toJson()).toList(),
        'musaSuggestions':
            musaSuggestions.map((item) => item.toJson()).toList(),
        'modelProfiles': modelProfiles.map((item) => item.toJson()).toList(),
        'installedModels':
            installedModels.map((item) => item.toJson()).toList(),
        'snapshots': snapshots.map((item) => item.toJson()).toList(),
        'storyStates': storyStates.map((item) => item.toJson()).toList(),
        'narrativeMemories':
            narrativeMemories.map((item) => item.toJson()).toList(),
        'selectedDocumentId': selectedDocumentId,
        'selectedNoteId': selectedNoteId,
        'selectedCharacterId': selectedCharacterId,
        'selectedScenarioId': selectedScenarioId,
        'editorMode': editorMode.name,
      };

  factory NarrativeWorkspace.fromJson(Map<String, dynamic> json) =>
      NarrativeWorkspace(
        appSettings: AppSettings.fromJson(
          json['appSettings'] as Map<String, dynamic>? ?? const {},
        ),
        books: (json['books'] as List? ?? const [])
            .map((item) => Book.fromJson(item as Map<String, dynamic>))
            .toList(),
        documents: (json['documents'] as List? ?? const [])
            .map((item) => Document.fromJson(item as Map<String, dynamic>))
            .toList(),
        documentRevisions: (json['documentRevisions'] as List? ?? const [])
            .map((item) =>
                DocumentRevision.fromJson(item as Map<String, dynamic>))
            .toList(),
        sceneReferences: (json['sceneReferences'] as List? ?? const [])
            .map(
                (item) => SceneReference.fromJson(item as Map<String, dynamic>))
            .toList(),
        notes: (json['notes'] as List? ?? const [])
            .map((item) => Note.fromJson(item as Map<String, dynamic>))
            .toList(),
        voiceMemos: (json['voiceMemos'] as List? ?? const [])
            .map((item) => VoiceMemo.fromJson(item as Map<String, dynamic>))
            .toList(),
        creativeCards: (json['creativeCards'] as List? ?? const [])
            .map((item) => CreativeCard.fromJson(item as Map<String, dynamic>))
            .toList(),
        characters: (json['characters'] as List? ?? const [])
            .map((item) => Character.fromJson(item as Map<String, dynamic>))
            .toList(),
        characterRelations: (json['characterRelations'] as List? ?? const [])
            .map((item) =>
                CharacterRelation.fromJson(item as Map<String, dynamic>))
            .toList(),
        scenarios: (json['scenarios'] as List? ?? const [])
            .map((item) => Scenario.fromJson(item as Map<String, dynamic>))
            .toList(),
        continuityStates: (json['continuityStates'] as List? ?? const [])
            .map((item) =>
                ContinuityState.fromJson(item as Map<String, dynamic>))
            .toList(),
        timelineEvents: (json['timelineEvents'] as List? ?? const [])
            .map((item) => TimelineEvent.fromJson(item as Map<String, dynamic>))
            .toList(),
        musaProfiles: (json['musaProfiles'] as List? ?? const [])
            .map((item) => MusaProfile.fromJson(item as Map<String, dynamic>))
            .toList(),
        musaSessions: (json['musaSessions'] as List? ?? const [])
            .map((item) => MusaSession.fromJson(item as Map<String, dynamic>))
            .toList(),
        musaChunks: (json['musaChunks'] as List? ?? const [])
            .map((item) => MusaChunk.fromJson(item as Map<String, dynamic>))
            .toList(),
        musaSuggestions: (json['musaSuggestions'] as List? ?? const [])
            .map(
                (item) => MusaSuggestion.fromJson(item as Map<String, dynamic>))
            .toList(),
        modelProfiles: (json['modelProfiles'] as List? ?? const [])
            .map((item) => ModelProfile.fromJson(item as Map<String, dynamic>))
            .toList(),
        installedModels: (json['installedModels'] as List? ?? const [])
            .map(
                (item) => InstalledModel.fromJson(item as Map<String, dynamic>))
            .toList(),
        snapshots: (json['snapshots'] as List? ?? const [])
            .map((item) =>
                WorkspaceSnapshot.fromJson(item as Map<String, dynamic>))
            .toList(),
        storyStates: (json['storyStates'] as List? ?? const [])
            .map((item) => StoryState.fromJson(item as Map<String, dynamic>))
            .toList(),
        narrativeMemories: (json['narrativeMemories'] as List? ?? const [])
            .map((item) =>
                NarrativeMemory.fromJson(item as Map<String, dynamic>))
            .toList(),
        selectedDocumentId: json['selectedDocumentId'] as String?,
        selectedNoteId: json['selectedNoteId'] as String?,
        selectedCharacterId: json['selectedCharacterId'] as String?,
        selectedScenarioId: json['selectedScenarioId'] as String?,
        editorMode: WorkspaceEditorMode.values.firstWhere(
          (value) => value.name == json['editorMode'],
          orElse: () => WorkspaceEditorMode.document,
        ),
      );
}
