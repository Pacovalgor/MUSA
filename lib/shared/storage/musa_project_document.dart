import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../../modules/books/models/narrative_workspace.dart';

/// Encodes a complete MUSA workspace as one opaque `.musa` project document.
class MusaProjectDocument {
  static const extension = '.musa';
  static const formatIdentifier = 'com.musa.project';
  static const uniformTypeIdentifier = 'com.musa.project';
  static const formatVersion = 1;
  static const workspaceSchemaVersion = 1;
  static const appVersion = '1.0.0+1';
  static const manifestPath = 'manifest.json';
  static const workspacePath = 'workspace.json';

  const MusaProjectDocument();

  NarrativeWorkspace decodeWorkspace(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    decodeManifestFromArchive(archive);
    final workspaceFile = archive.findFile(workspacePath);

    if (workspaceFile == null) {
      throw const MusaProjectDocumentException('Missing workspace payload.');
    }

    final workspaceJson = _decodeJsonFile(workspaceFile, workspacePath);
    return NarrativeWorkspace.fromJson(workspaceJson);
  }

  MusaProjectManifest decodeManifest(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    return decodeManifestFromArchive(archive);
  }

  MusaProjectManifest decodeManifestFromArchive(Archive archive) {
    final manifestFile = archive.findFile(manifestPath);

    if (manifestFile == null) {
      throw const MusaProjectDocumentException('Missing project manifest.');
    }

    final manifest = _decodeJsonFile(manifestFile, manifestPath);
    if (manifest['format'] != formatIdentifier) {
      throw MusaProjectDocumentException(
        'Unsupported project format: ${manifest['format']}.',
      );
    }
    if (manifest['formatVersion'] != formatVersion) {
      throw MusaProjectDocumentException(
        'Unsupported project version: ${manifest['formatVersion']}.',
      );
    }

    return MusaProjectManifest.fromJson(manifest);
  }

  List<int> encodeWorkspace(
    NarrativeWorkspace workspace, {
    MusaProjectManifest? previousManifest,
    bool preserveProjectIdentity = true,
  }) {
    final manifest = MusaProjectManifest.fromWorkspace(
      workspace,
      previousManifest: previousManifest,
      preserveProjectIdentity: preserveProjectIdentity,
    );
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          manifestPath,
          const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
        ),
      )
      ..addFile(
        ArchiveFile.string(
          workspacePath,
          const JsonEncoder.withIndent('  ').convert(workspace.toJson()),
        ),
      );

    return ZipEncoder().encodeBytes(archive);
  }

  Future<MusaProjectManifest> readManifest(File file) async {
    if (!await file.exists()) {
      throw FileSystemException('MUSA project file does not exist', file.path);
    }
    return decodeManifest(await file.readAsBytes());
  }

  Future<NarrativeWorkspace> readWorkspace(File file) async {
    if (!await file.exists()) {
      throw FileSystemException('MUSA project file does not exist', file.path);
    }
    return decodeWorkspace(await file.readAsBytes());
  }

  Future<void> writeWorkspace(
    File file,
    NarrativeWorkspace workspace, {
    bool preserveProjectIdentity = true,
  }) async {
    final previousManifest = preserveProjectIdentity && await file.exists()
        ? await readManifest(file)
        : null;
    final bytes = encodeWorkspace(
      workspace,
      previousManifest: previousManifest,
      preserveProjectIdentity: preserveProjectIdentity,
    );
    await file.parent.create(recursive: true);

    final tempFile = File(
      '${file.path}.tmp-$pid-${DateTime.now().microsecondsSinceEpoch}',
    );

    try {
      await tempFile.writeAsBytes(bytes, flush: true);
      await tempFile.rename(file.path);
    } catch (_) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  Map<String, dynamic> _decodeJsonFile(ArchiveFile file, String name) {
    final content = file.readBytes();
    if (content == null) {
      throw MusaProjectDocumentException('Empty project file entry: $name.');
    }
    final decoded = jsonDecode(utf8.decode(content));
    if (decoded is! Map<String, dynamic>) {
      throw MusaProjectDocumentException('Invalid project file entry: $name.');
    }
    return decoded;
  }
}

class MusaProjectDocumentException extends FormatException {
  const MusaProjectDocumentException(super.message);
}

class MusaProjectManifest {
  const MusaProjectManifest({
    required this.format,
    required this.formatVersion,
    required this.workspaceSchemaVersion,
    required this.appVersion,
    required this.projectId,
    required this.projectName,
    required this.createdAt,
    required this.updatedAt,
    required this.workspacePath,
    required this.activeBookId,
    required this.bookCount,
  });

  final String format;
  final int formatVersion;
  final int workspaceSchemaVersion;
  final String appVersion;
  final String projectId;
  final String projectName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String workspacePath;
  final String? activeBookId;
  final int bookCount;

  factory MusaProjectManifest.fromWorkspace(
    NarrativeWorkspace workspace, {
    MusaProjectManifest? previousManifest,
    bool preserveProjectIdentity = true,
  }) {
    final now = DateTime.now().toUtc();
    final activeBook = workspace.activeBook;
    final firstBook = workspace.books.isEmpty ? null : workspace.books.first;
    final projectName = (activeBook?.title ?? firstBook?.title ?? 'Musa')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    final previous = preserveProjectIdentity ? previousManifest : null;

    return MusaProjectManifest(
      format: MusaProjectDocument.formatIdentifier,
      formatVersion: MusaProjectDocument.formatVersion,
      workspaceSchemaVersion: MusaProjectDocument.workspaceSchemaVersion,
      appVersion: MusaProjectDocument.appVersion,
      projectId: previous?.projectId ?? _generateProjectId(now),
      projectName: projectName.isEmpty ? 'Musa' : projectName,
      createdAt: previous?.createdAt ?? _workspaceCreatedAt(workspace) ?? now,
      updatedAt: now,
      workspacePath: MusaProjectDocument.workspacePath,
      activeBookId: workspace.appSettings.activeBookId ?? activeBook?.id,
      bookCount: workspace.books.length,
    );
  }

  factory MusaProjectManifest.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();
    final legacySavedAt = _parseDate(json['savedAt'] as String?) ?? now;
    return MusaProjectManifest(
      format: json['format'] as String? ?? MusaProjectDocument.formatIdentifier,
      formatVersion:
          json['formatVersion'] as int? ?? MusaProjectDocument.formatVersion,
      workspaceSchemaVersion: json['workspaceSchemaVersion'] as int? ??
          MusaProjectDocument.workspaceSchemaVersion,
      appVersion: json['appVersion'] as String? ?? 'unknown',
      projectId: json['projectId'] as String? ?? _generateProjectId(now),
      projectName: json['projectName'] as String? ?? 'Musa',
      createdAt: _parseDate(json['createdAt'] as String?) ?? legacySavedAt,
      updatedAt: _parseDate(json['updatedAt'] as String?) ?? legacySavedAt,
      workspacePath:
          json['workspacePath'] as String? ?? MusaProjectDocument.workspacePath,
      activeBookId: json['activeBookId'] as String?,
      bookCount: json['bookCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'format': format,
        'formatVersion': formatVersion,
        'workspaceSchemaVersion': workspaceSchemaVersion,
        'appVersion': appVersion,
        'projectId': projectId,
        'projectName': projectName,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'workspacePath': workspacePath,
        'activeBookId': activeBookId,
        'bookCount': bookCount,
      };

  static String _generateProjectId(DateTime now) {
    return 'project-${now.microsecondsSinceEpoch}';
  }

  static DateTime? _workspaceCreatedAt(NarrativeWorkspace workspace) {
    final dates = [
      for (final book in workspace.books) book.createdAt,
      for (final document in workspace.documents) document.createdAt,
    ];
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first.toUtc();
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }
}
