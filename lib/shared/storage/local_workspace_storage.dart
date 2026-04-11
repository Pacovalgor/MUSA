import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../modules/books/models/app_settings.dart';
import '../../modules/books/models/book.dart';
import '../../modules/books/models/narrative_workspace.dart';
import '../../modules/books/services/narrative_workspace_repository.dart';
import '../../modules/continuity/models/continuity_state.dart';
import '../../modules/manuscript/models/document.dart';
import '../../modules/models_runtime/models/model_profile.dart';
import '../../modules/musa/models/musa_profile.dart';
import '../utils/id_generator.dart';
import 'musa_project_document.dart';

/// Persists the full narrative workspace as one opaque `.musa` project file.
class LocalWorkspaceStorage implements NarrativeWorkspaceRepository {
  static const activeProjectPathKey = 'musa.activeProjectPath';
  static const recentProjectsKey = 'musa.recentProjects';
  static const _projectFileName = 'Musa.musa';
  static const _legacyWorkspaceFileName = 'musa_workspace.json';
  static const _maxRecentProjects = 10;

  const LocalWorkspaceStorage({
    this.projectFilePath,
    MusaProjectDocument projectDocument = const MusaProjectDocument(),
  }) : _projectDocument = projectDocument;

  final String? projectFilePath;
  final MusaProjectDocument _projectDocument;

  @override
  Future<NarrativeWorkspace> loadWorkspace() async {
    final target = await _projectFileTarget();
    final file = target.file;
    if (await file.exists()) {
      final workspace = await _projectDocument.readWorkspace(file);
      await rememberProject(file.path);
      return _normalizeWorkspace(workspace);
    }

    final legacyFile = await _legacyWorkspaceFile();
    if (!await legacyFile.exists()) {
      if (target.userSelected) {
        throw FileSystemException(
          'Selected MUSA project file does not exist',
          file.path,
        );
      }
      final seeded = _seedWorkspace();
      await saveWorkspace(seeded);
      return seeded;
    }

    final content = await legacyFile.readAsString();
    if (content.trim().isEmpty) {
      final seeded = _seedWorkspace();
      await saveWorkspace(seeded);
      return seeded;
    }

    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final workspace = _normalizeWorkspace(NarrativeWorkspace.fromJson(decoded));
    await saveWorkspace(workspace);
    return workspace;
  }

  @override
  Future<void> saveWorkspace(NarrativeWorkspace workspace) async {
    final file = await _projectFile();
    await _projectDocument.writeWorkspace(file, workspace);
    await rememberProject(file.path);
  }

  Future<NarrativeWorkspace> loadProjectFile(String path) async {
    final workspace = await _projectDocument.readWorkspace(File(path));
    return _normalizeWorkspace(workspace);
  }

  Future<MusaProjectManifest> readProjectManifest(String path) {
    return _projectDocument.readManifest(File(path));
  }

  Future<void> saveWorkspaceAs(
      String path, NarrativeWorkspace workspace) async {
    await _projectDocument.writeWorkspace(
      File(path),
      workspace,
      preserveProjectIdentity: false,
    );
    await selectProjectFile(path);
    await rememberProject(path);
  }

  Future<NarrativeWorkspace> createNewProjectFile(String path) async {
    final workspace = _seedWorkspace();
    await _projectDocument.writeWorkspace(
      File(path),
      workspace,
      preserveProjectIdentity: false,
    );
    await selectProjectFile(path);
    await rememberProject(path);
    return workspace;
  }

  Future<void> selectProjectFile(String path) async {
    if (projectFilePath != null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(activeProjectPathKey, path);
  }

  Future<void> clearSelectedProjectFile() async {
    if (projectFilePath != null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(activeProjectPathKey);
  }

  Future<String> activeProjectPath() async {
    return (await _projectFile()).path;
  }

  Future<List<RecentProject>> recentProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(recentProjectsKey) ?? const [];
    final results = <RecentProject>[];

    for (final raw in rawItems) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          results.add(RecentProject.fromJson(decoded));
        }
      } catch (_) {
        // Ignore invalid historical entries.
      }
    }

    return results;
  }

  Future<void> rememberProject(String path) async {
    final file = File(path);
    if (!await file.exists()) return;

    final manifest = await _projectDocument.readManifest(file);
    final now = DateTime.now().toUtc();
    final updated = RecentProject(
      projectId: manifest.projectId,
      name: manifest.projectName,
      path: path,
      lastOpenedAt: now,
      updatedAt: manifest.updatedAt,
    );
    final current = await recentProjects();
    final deduplicated = [
      updated,
      ...current.where((item) => item.path != path),
    ].take(_maxRecentProjects).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      recentProjectsKey,
      deduplicated
          .map((item) => jsonEncode(item.toJson()))
          .toList(growable: false),
    );
  }

  Future<File> projectFile() => _projectFile();

  Future<File> _projectFile() async {
    return (await _projectFileTarget()).file;
  }

  Future<_ProjectFileTarget> _projectFileTarget() async {
    if (projectFilePath != null) {
      return _ProjectFileTarget(File(projectFilePath!), userSelected: true);
    }
    final prefs = await SharedPreferences.getInstance();
    final activePath = prefs.getString(activeProjectPathKey);
    if (activePath != null && activePath.trim().isNotEmpty) {
      return _ProjectFileTarget(File(activePath), userSelected: true);
    }
    final directory = await getApplicationSupportDirectory();
    final musaDirectory = Directory(p.join(directory.path, 'musa'));
    return _ProjectFileTarget(
      File(p.join(musaDirectory.path, _projectFileName)),
    );
  }

  Future<File> _legacyWorkspaceFile() async {
    if (projectFilePath != null) {
      return File(
          p.join(p.dirname(projectFilePath!), _legacyWorkspaceFileName));
    }
    final directory = await getApplicationSupportDirectory();
    final musaDirectory = Directory(p.join(directory.path, 'musa'));
    return File(p.join(musaDirectory.path, _legacyWorkspaceFileName));
  }

  /// Repairs legacy or partially populated workspaces after deserialization.
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

  /// Creates the first local workspace so the user can start writing immediately.
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

class _ProjectFileTarget {
  const _ProjectFileTarget(this.file, {this.userSelected = false});

  final File file;
  final bool userSelected;
}

class RecentProject {
  const RecentProject({
    required this.projectId,
    required this.name,
    required this.path,
    required this.lastOpenedAt,
    required this.updatedAt,
  });

  final String projectId;
  final String name;
  final String path;
  final DateTime lastOpenedAt;
  final DateTime updatedAt;

  factory RecentProject.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();
    return RecentProject(
      projectId: json['projectId'] as String? ?? '',
      name: json['name'] as String? ?? 'Musa',
      path: json['path'] as String? ?? '',
      lastOpenedAt:
          DateTime.tryParse(json['lastOpenedAt'] as String? ?? '')?.toUtc() ??
              now,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toUtc() ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'name': name,
        'path': path,
        'lastOpenedAt': lastOpenedAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };
}
