import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../../modules/books/models/narrative_workspace.dart';

/// Encodes a complete MUSA workspace as one opaque `.musa` project document.
class MusaProjectDocument {
  static const extension = '.musa';
  static const formatIdentifier = 'com.musa.project';
  static const formatVersion = 1;
  static const manifestPath = 'manifest.json';
  static const workspacePath = 'workspace.json';

  const MusaProjectDocument();

  NarrativeWorkspace decodeWorkspace(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final manifestFile = archive.findFile(manifestPath);
    final workspaceFile = archive.findFile(workspacePath);

    if (manifestFile == null) {
      throw const MusaProjectDocumentException('Missing project manifest.');
    }
    if (workspaceFile == null) {
      throw const MusaProjectDocumentException('Missing workspace payload.');
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

    final workspaceJson = _decodeJsonFile(workspaceFile, workspacePath);
    return NarrativeWorkspace.fromJson(workspaceJson);
  }

  List<int> encodeWorkspace(NarrativeWorkspace workspace) {
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          manifestPath,
          const JsonEncoder.withIndent('  ').convert(
            {
              'format': formatIdentifier,
              'formatVersion': formatVersion,
              'workspacePath': workspacePath,
              'savedAt': DateTime.now().toUtc().toIso8601String(),
            },
          ),
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

  Future<NarrativeWorkspace> readWorkspace(File file) async {
    if (!await file.exists()) {
      throw FileSystemException('MUSA project file does not exist', file.path);
    }
    return decodeWorkspace(await file.readAsBytes());
  }

  Future<void> writeWorkspace(File file, NarrativeWorkspace workspace) async {
    final bytes = encodeWorkspace(workspace);
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
