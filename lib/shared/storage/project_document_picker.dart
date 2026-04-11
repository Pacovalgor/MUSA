import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;

import 'musa_project_document.dart';

class ProjectDocumentPicker {
  static const _musaTypeGroup = XTypeGroup(
    label: 'Proyecto MUSA',
    extensions: ['musa'],
    uniformTypeIdentifiers: [
      MusaProjectDocument.uniformTypeIdentifier,
      'public.data',
    ],
  );

  const ProjectDocumentPicker();

  Future<String?> openProjectPath() async {
    final file = await openFile(
      acceptedTypeGroups: const [_musaTypeGroup],
      confirmButtonText: 'Abrir',
    );
    return file?.path;
  }

  Future<String?> chooseSaveProjectPath(
      {String suggestedName = 'Musa.musa'}) async {
    final location = await getSaveLocation(
      acceptedTypeGroups: const [_musaTypeGroup],
      suggestedName: suggestedName,
      confirmButtonText: 'Guardar',
      canCreateDirectories: true,
    );
    final path = location?.path;
    if (path == null || path.trim().isEmpty) return null;
    if (p.extension(path).toLowerCase() == MusaProjectDocument.extension) {
      return path;
    }
    return '$path${MusaProjectDocument.extension}';
  }
}
