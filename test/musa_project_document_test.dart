import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/app_settings.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_workspace.dart';
import 'package:musa/modules/manuscript/models/document.dart';
import 'package:musa/shared/storage/local_workspace_storage.dart';
import 'package:musa/shared/storage/musa_project_document.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('encodes the workspace as a single opaque .musa document', () {
    final workspace = _workspace();
    const document = MusaProjectDocument();

    final encoded = document.encodeWorkspace(workspace);
    final decoded = document.decodeWorkspace(encoded);
    final manifest = document.decodeManifest(encoded);

    expect(encoded, isNotEmpty);
    expect(manifest.formatVersion, MusaProjectDocument.formatVersion);
    expect(manifest.appVersion, MusaProjectDocument.appVersion);
    expect(manifest.projectName, 'Libro sincronizable');
    expect(manifest.activeBookId, 'book-1');
    expect(manifest.bookCount, 1);
    expect(decoded.books.single.title, 'Libro sincronizable');
    expect(decoded.documents.single.content, 'Texto dentro del proyecto.');
    expect(decoded.selectedDocumentId, 'document-1');
  });

  test('persists workspace to a .musa file', () async {
    final directory = await Directory.systemTemp.createTemp('musa_project_');
    addTearDown(() => directory.delete(recursive: true));

    final projectFile = File('${directory.path}/MiProyecto.musa');
    final storage = LocalWorkspaceStorage(projectFilePath: projectFile.path);

    await storage.saveWorkspace(_workspace());
    expect(await projectFile.exists(), isTrue);

    final manifest = await storage.readProjectManifest(projectFile.path);
    final loaded = await storage.loadWorkspace();
    final recents = await storage.recentProjects();
    expect(manifest.projectName, 'Libro sincronizable');
    expect(loaded.books.single.title, 'Libro sincronizable');
    expect(loaded.documents.single.title, 'Apertura');
    expect(recents.single.path, projectFile.path);
  });

  test('blocks saving over a project changed outside this app', () async {
    final directory = await Directory.systemTemp.createTemp('musa_project_');
    addTearDown(() => directory.delete(recursive: true));

    final projectFile = File('${directory.path}/MiProyecto.musa');
    final storage = LocalWorkspaceStorage(projectFilePath: projectFile.path);

    await storage.saveWorkspace(_workspace());
    await storage.loadWorkspace();

    await const MusaProjectDocument().writeWorkspace(
      projectFile,
      _workspace(title: 'Cambio externo'),
      preserveProjectIdentity: true,
    );

    expect(
      () => storage.saveWorkspace(_workspace(title: 'Cambio local')),
      throwsA(isA<ProjectFileConflictException>()),
    );
  });

  test('migrates legacy workspace JSON into a .musa project file', () async {
    final directory = await Directory.systemTemp.createTemp('musa_project_');
    addTearDown(() => directory.delete(recursive: true));

    final projectFile = File('${directory.path}/MiProyecto.musa');
    final legacyFile = File('${directory.path}/musa_workspace.json');
    await legacyFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(_workspace().toJson()),
    );

    final storage = LocalWorkspaceStorage(projectFilePath: projectFile.path);

    final loaded = await storage.loadWorkspace();
    expect(loaded.books.single.title, 'Libro sincronizable');
    expect(await projectFile.exists(), isTrue);
  });

  test('rejects a project document without a MUSA manifest', () {
    const document = MusaProjectDocument();

    expect(
      () => document.decodeWorkspace(const [1, 2, 3, 4]),
      throwsA(isA<FormatException>()),
    );
  });
}

NarrativeWorkspace _workspace({String title = 'Libro sincronizable'}) {
  final now = DateTime(2026, 4, 10, 12);
  const bookId = 'book-1';
  const documentId = 'document-1';

  return NarrativeWorkspace(
    appSettings: const AppSettings(activeBookId: bookId),
    books: [
      Book(
        id: bookId,
        title: title,
        status: BookStatus.active,
        createdAt: now,
        updatedAt: now,
      ),
    ],
    documents: [
      Document(
        id: documentId,
        bookId: bookId,
        title: 'Apertura',
        orderIndex: 0,
        content: 'Texto dentro del proyecto.',
        wordCount: 4,
        createdAt: now,
        updatedAt: now,
      ),
    ],
    selectedDocumentId: documentId,
  );
}
