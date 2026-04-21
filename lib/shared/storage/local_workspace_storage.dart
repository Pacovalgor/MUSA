import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
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
  static const _projectFingerprintKeyPrefix = 'musa.projectFingerprint.';
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
      try {
        final workspace = await _projectDocument.readWorkspace(file);
        await _rememberProjectFingerprint(file);
        await rememberProject(file.path);
        return _normalizeWorkspace(workspace);
      } on FileSystemException catch (error) {
        if (!target.userSelected || !_isPermissionDenied(error)) {
          rethrow;
        }
        debugPrint(
          '[OPEN_PROJECT] Stored project path is not accessible, using local sandbox project instead: ${file.path}',
        );
        await clearSelectedProjectFile();
        return loadWorkspace();
      }
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
    debugPrint('[SAVE_WORKSPACE] Using path: ${file.path}');
    await _assertProjectUnchanged(file);

    // 1. Create simple backup before overwriting
    await _createBackup(file);

    // 2. Perform write
    await _projectDocument.writeWorkspace(file, workspace);

    // 3. Post-write validation: reload and verify it's readable
    try {
      await _projectDocument.readWorkspace(file);
    } catch (e) {
      debugPrint('[SAVE_WORKSPACE_CRITICAL_FAILURE] Validation failed: $e');
      throw FileSystemException(
          'Error crítico de validación tras escritura. El archivo podría estar corrupto.',
          file.path);
    }

    await _rememberProjectFingerprint(file);
    await rememberProject(file.path);
  }

  Future<void> _createBackup(File file) async {
    if (!await file.exists()) return;
    try {
      final backupPath = '${file.path}.bak';
      await file.copy(backupPath);
    } catch (e) {
      debugPrint('[SAVE_WORKSPACE_BACKUP_WARNING] Could not create backup: $e');
      // We continue even if backup fails, prioritizing the save attempt
    }
  }

  Future<NarrativeWorkspace> loadProjectFile(String path) async {
    final file = File(path);
    final workspace = await _projectDocument.readWorkspace(file);
    await _rememberProjectFingerprint(file);
    return _normalizeWorkspace(workspace);
  }

  Future<NarrativeWorkspace> importProjectFile(Uint8List fileBytes) async {
    debugPrint(
        '[OPEN_PROJECT] Received ${fileBytes.length} bytes from native picker');
    final activePathBefore = await activeProjectPath();
    debugPrint('[OPEN_PROJECT] Active path BEFORE import: $activePathBefore');

    // STEP 0: Force canonical path into SharedPreferences IMMEDIATELY.
    // Must happen BEFORE any file operations so that if any write is triggered
    // (e.g. autosave, editor _persist) it uses the sandbox path, not Downloads.
    final canonicalPath = await _canonicalProjectPath();
    debugPrint('[OPEN_PROJECT] Canonical target path: $canonicalPath');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(activeProjectPathKey, canonicalPath);
    debugPrint('[OPEN_PROJECT] Active path set to canonical BEFORE write');

    // STEP 1: Write bytes to sandbox (no external path access needed).
    final target = File(canonicalPath);
    await target.parent.create(recursive: true);
    debugPrint(
        '[OPEN_PROJECT] Write START: ${fileBytes.length} bytes -> $canonicalPath');
    await target.writeAsBytes(fileBytes);
    debugPrint('[OPEN_PROJECT] Write END: ${fileBytes.length} bytes written');

    // STEP 2: Validate the copied file (all reads within sandbox)
    debugPrint('[OPEN_PROJECT] Validating from: $canonicalPath');
    await _projectDocument.readManifest(target);
    await _projectDocument.readWorkspace(target);

    // STEP 3: Persist fingerprint and remember in recent projects
    await _rememberProjectFingerprint(target);
    await rememberProject(target.path);

    // STEP 4: Load and return workspace
    debugPrint('[OPEN_PROJECT] Loading workspace from: $canonicalPath');
    final workspace = await _projectDocument.readWorkspace(target);
    final normalized = _normalizeWorkspace(workspace);
    debugPrint(
        '[OPEN_PROJECT] Workspace loaded OK, books: ${normalized.books.length}');
    debugPrint(
        '[OPEN_PROJECT] Active path AFTER import: ${await activeProjectPath()}');
    return normalized;
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
    await _rememberProjectFingerprint(File(path));
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
    await _rememberProjectFingerprint(File(path));
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

  Future<void> _assertProjectUnchanged(File file) async {
    if (!await file.exists()) return;
    final prefs = await SharedPreferences.getInstance();
    final knownFingerprint = prefs.getString(_projectFingerprintKey(file.path));
    if (knownFingerprint == null || knownFingerprint.isEmpty) return;

    final currentFingerprint = await _fingerprintFile(file);
    if (currentFingerprint != knownFingerprint) {
      throw ProjectFileConflictException(file.path);
    }
  }

  Future<void> _rememberProjectFingerprint(File file) async {
    if (!await file.exists()) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _projectFingerprintKey(file.path),
      await _fingerprintFile(file),
    );
  }

  Future<String> _fingerprintFile(File file) async {
    final digest = sha256.convert(await file.readAsBytes());
    return digest.toString();
  }

  String _projectFingerprintKey(String path) {
    return '$_projectFingerprintKeyPrefix${base64Url.encode(utf8.encode(path))}';
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

  Future<String> _canonicalProjectPath() async {
    final directory = await getApplicationSupportDirectory();
    return p.join(directory.path, 'musa', _projectFileName);
  }

  bool _isPermissionDenied(FileSystemException error) {
    return error.osError?.errorCode == 1 || error is PathAccessException;
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

class ProjectFileConflictException implements Exception {
  const ProjectFileConflictException(this.path);

  final String path;

  @override
  String toString() {
    return 'El proyecto cambió fuera de MUSA. Abre la versión actual antes de guardar: $path';
  }
}
