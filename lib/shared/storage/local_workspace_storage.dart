import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../modules/books/models/app_settings.dart';
import '../../modules/books/models/book.dart';
import '../../modules/books/models/narrative_workspace.dart';
import '../../modules/books/services/narrative_workspace_repository.dart';
import '../../modules/continuity/models/continuity_state.dart';
import '../../modules/manuscript/models/document.dart';
import '../../modules/models_runtime/models/model_profile.dart';
import '../../modules/musa/models/musa_profile.dart';
import '../utils/id_generator.dart';

class LocalWorkspaceStorage implements NarrativeWorkspaceRepository {
  static const _workspaceFileName = 'musa_workspace.json';

  @override
  Future<NarrativeWorkspace> loadWorkspace() async {
    final file = await _workspaceFile();
    if (!await file.exists()) {
      final seeded = _seedWorkspace();
      await saveWorkspace(seeded);
      return seeded;
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      final seeded = _seedWorkspace();
      await saveWorkspace(seeded);
      return seeded;
    }

    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final workspace = NarrativeWorkspace.fromJson(decoded);
    return _normalizeWorkspace(workspace);
  }

  @override
  Future<void> saveWorkspace(NarrativeWorkspace workspace) async {
    final file = await _workspaceFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(workspace.toJson()),
    );
  }

  Future<File> _workspaceFile() async {
    final directory = await getApplicationSupportDirectory();
    final musaDirectory = Directory(p.join(directory.path, 'musa'));
    return File(p.join(musaDirectory.path, _workspaceFileName));
  }

  NarrativeWorkspace _normalizeWorkspace(NarrativeWorkspace workspace) {
    if (workspace.books.isNotEmpty && workspace.documents.isNotEmpty) {
      final normalizedActiveBookId =
          workspace.appSettings.activeBookId ?? workspace.books.first.id;
      final activeDocuments = workspace.documents
          .where((document) => document.bookId == normalizedActiveBookId)
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      final selectedDocumentId = workspace.selectedDocumentId ??
          (activeDocuments.isEmpty ? null : activeDocuments.first.id);
      final activeCharacters = workspace.characters
          .where((character) => character.bookId == normalizedActiveBookId)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final selectedCharacterId = workspace.selectedCharacterId == null
          ? null
          : activeCharacters.any(
                  (character) => character.id == workspace.selectedCharacterId)
              ? workspace.selectedCharacterId
              : null;
      final activeScenarios = workspace.scenarios
          .where((scenario) => scenario.bookId == normalizedActiveBookId)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final selectedScenarioId = workspace.selectedScenarioId == null
          ? null
          : activeScenarios.any(
                  (scenario) => scenario.id == workspace.selectedScenarioId)
              ? workspace.selectedScenarioId
              : null;
      final editorMode =
          workspace.editorMode == WorkspaceEditorMode.character &&
                  selectedCharacterId == null
              ? WorkspaceEditorMode.document
              : workspace.editorMode == WorkspaceEditorMode.scenario &&
                      selectedScenarioId == null
                  ? WorkspaceEditorMode.document
                  : workspace.editorMode;
      return workspace.copyWith(
        appSettings: workspace.appSettings
            .copyWith(activeBookId: normalizedActiveBookId),
        selectedDocumentId: selectedDocumentId,
        selectedCharacterId: selectedCharacterId,
        clearSelectedCharacterId: workspace.selectedCharacterId != null &&
            selectedCharacterId == null,
        selectedScenarioId: selectedScenarioId,
        clearSelectedScenarioId:
            workspace.selectedScenarioId != null && selectedScenarioId == null,
        editorMode: editorMode,
      );
    }

    return _seedWorkspace();
  }

  NarrativeWorkspace _seedWorkspace() {
    final now = DateTime.now();
    final bookId = generateEntityId('book');
    final documentId = generateEntityId('document');

    final book = Book(
      id: bookId,
      title: 'Libro I',
      subtitle: 'Borrador inicial',
      status: BookStatus.active,
      createdAt: now,
      updatedAt: now,
      summary:
          'Primer libro creado automáticamente para entrar directo al manuscrito.',
      toneNotes: 'Íntimo, preciso, sensorial.',
    );

    final document = Document(
      id: documentId,
      bookId: bookId,
      title: 'Apertura',
      kind: DocumentKind.chapter,
      orderIndex: 0,
      content: '',
      wordCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    final continuity = ContinuityState(
      bookId: bookId,
      projectSummary:
          'Libro inicial listo para escritura inmediata. El sistema debe preservar continuidad, tono y relaciones desde el primer gesto.',
      currentTensionLevel: 'embrionaria',
      openQuestions: const ['Que detonará la primera fractura narrativa?'],
      lastUpdatedAt: now,
    );

    return NarrativeWorkspace(
      appSettings: AppSettings(activeBookId: bookId),
      books: [book],
      documents: [document],
      continuityStates: [continuity],
      musaProfiles: const [
        MusaProfile(
          id: 'musa-style',
          name: 'Musa de Estilo',
          kind: MusaProfileKind.style,
          description: 'Refina ritmo, precisión y cadencia.',
          promptTemplate:
              'Refina el estilo sin traicionar la intención del autor.',
        ),
        MusaProfile(
          id: 'musa-tension',
          name: 'Musa de Tensión',
          kind: MusaProfileKind.tension,
          description: 'Incrementa presión dramática y subtexto.',
          promptTemplate:
              'Eleva la tensión desde el contexto global del libro.',
        ),
        MusaProfile(
          id: 'musa-continuity',
          name: 'Musa de Continuidad',
          kind: MusaProfileKind.continuity,
          description: 'Protege hechos, motivos y coherencia interna.',
          promptTemplate: 'Revisa continuidad antes de proponer cambios.',
        ),
      ],
      modelProfiles: const [
        ModelProfile(
          id: 'local-lite',
          displayName: 'Local Lite',
          family: ModelFamily.lite,
          filename: 'local-lite.gguf',
          isDefault: true,
        ),
      ],
      selectedDocumentId: documentId,
    );
  }
}
