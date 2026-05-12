import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/app_settings.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_workspace.dart';
import 'package:musa/modules/books/providers/workspace_providers.dart';
import 'package:musa/modules/books/services/narrative_workspace_repository.dart';
import 'package:musa/modules/creative/models/creative_card.dart';
import 'package:musa/modules/inbox/models/inbox_capture.dart';
import 'package:musa/modules/inbox/models/inbox_capture_status.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/services/inbox_bookmark_service.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';
import 'package:musa/ui/inbox/popover/inbox_popover.dart';

void main() {
  testWidgets('popover can create creative card quickly', (tester) async {
    final now = DateTime.utc(2026, 5, 8, 10, 15);
    final tempRoot = Directory.systemTemp.createTempSync('musa_popover_');
    addTearDown(() {
      if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
    });
    final storage = _MemoryInboxStorageService(rootDirectory: tempRoot);
    final capture = InboxCapture(
      schemaVersion: 1,
      id: 'capture-1',
      capturedAt: now,
      deviceLabel: 'iPhone de Paco',
      kind: InboxCaptureKind.text,
      body: 'Pregunta capturada',
      creativeTypeHint: 'question',
    );
    final record = InboxCaptureRecord(
      path: '${tempRoot.path}/capture-1.json',
      status: InboxCaptureStatus.pending,
      capture: capture,
    );
    final repository = _MemoryWorkspaceRepository(NarrativeWorkspace(
      appSettings: const AppSettings(activeBookId: 'book-1'),
      books: [
        Book(id: 'book-1', title: 'Libro', createdAt: now, updatedAt: now),
      ],
    ));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        narrativeWorkspaceRepositoryProvider.overrideWithValue(repository),
        inboxFolderProvider.overrideWith(
          (ref) => _HealthyInboxFolderNotifier(tempRoot.path),
        ),
        inboxStorageProvider.overrideWithValue(storage),
        inboxPendingCapturesProvider.overrideWith((ref) async => [record]),
      ],
      child: const MaterialApp(home: Scaffold(body: InboxPopover())),
    ));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(InboxPopover)),
    );
    await container.read(narrativeWorkspaceProvider.notifier).bootstrap();
    await tester.pump();

    await tester
        .tap(find.byKey(const Key('inbox-popover-create-card-capture-1')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(repository.workspace.creativeCards.single.type,
        CreativeCardType.question);
  });
}

class _MemoryWorkspaceRepository implements NarrativeWorkspaceRepository {
  _MemoryWorkspaceRepository(this.workspace);

  NarrativeWorkspace workspace;

  @override
  Future<NarrativeWorkspace> loadWorkspace() async => workspace;

  @override
  Future<void> saveWorkspace(NarrativeWorkspace workspace) async {
    this.workspace = workspace;
  }
}

class _MemoryInboxStorageService extends InboxStorageService {
  _MemoryInboxStorageService({required super.rootDirectory});

  @override
  Future<void> markProcessed(File file) async {}
}

class _HealthyInboxFolderNotifier extends InboxFolderNotifier {
  _HealthyInboxFolderNotifier(String path) : super(_FakeBookmarkService(path));
}

class _FakeBookmarkService extends InboxBookmarkService {
  _FakeBookmarkService(this.path);

  final String path;

  @override
  Future<InboxBookmarkResolution?> loadAndResolve() async =>
      InboxBookmarkResolution(path: path, stale: false);

  @override
  Future<String?> lastKnownPath() async => path;
}
