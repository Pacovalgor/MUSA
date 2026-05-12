import 'dart:io';

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
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';
import 'package:musa/ui/inbox/window/widgets/capture_actions.dart';

void main() {
  test('acceptAsCreativeCard passes metadata and marks processed on success',
      () async {
    final now = DateTime.utc(2026, 5, 8, 10, 15);
    final tempRoot = Directory.systemTemp.createTempSync('musa_actions_');
    addTearDown(() {
      if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
    });
    final storage = InboxStorageService(rootDirectory: tempRoot);
    final capture = InboxCapture(
      schemaVersion: 1,
      id: 'capture-1',
      capturedAt: now,
      deviceLabel: 'iPhone de Paco',
      kind: InboxCaptureKind.text,
      body: 'Pregunta capturada',
      creativeTypeHint: 'question',
    );
    final file = await storage.write(capture);
    final repository = _MemoryWorkspaceRepository(NarrativeWorkspace(
      appSettings: const AppSettings(activeBookId: 'book-1'),
      books: [
        Book(id: 'book-1', title: 'Libro', createdAt: now, updatedAt: now),
      ],
    ));
    final container = ProviderContainer(overrides: [
      narrativeWorkspaceRepositoryProvider.overrideWithValue(repository),
      inboxStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
    await container.read(narrativeWorkspaceProvider.notifier).bootstrap();

    final ok = await CaptureActions.acceptAsCreativeCard(
      container.read,
      InboxCaptureRecord(
        path: file.path,
        status: InboxCaptureStatus.pending,
        capture: capture,
      ),
    );

    expect(ok, isTrue);
    expect(repository.workspace.creativeCards.single.type,
        CreativeCardType.question);
    final all = await storage.readAll();
    expect(all.single.status, InboxCaptureStatus.processed);
  });

  test('acceptAsCreativeCard leaves capture pending when no active book',
      () async {
    final now = DateTime.utc(2026, 5, 8, 10, 15);
    final tempRoot = Directory.systemTemp.createTempSync('musa_actions_');
    addTearDown(() {
      if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
    });
    final storage = InboxStorageService(rootDirectory: tempRoot);
    final capture = InboxCapture(
      schemaVersion: 1,
      id: 'capture-1',
      capturedAt: now,
      deviceLabel: 'iPhone de Paco',
      kind: InboxCaptureKind.text,
      body: 'Idea sin libro',
      creativeTypeHint: 'idea',
    );
    final file = await storage.write(capture);
    final repository = _MemoryWorkspaceRepository(const NarrativeWorkspace(
      appSettings: AppSettings(),
      books: [],
    ));
    final container = ProviderContainer(overrides: [
      narrativeWorkspaceRepositoryProvider.overrideWithValue(repository),
      inboxStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
    await container.read(narrativeWorkspaceProvider.notifier).bootstrap();

    final ok = await CaptureActions.acceptAsCreativeCard(
      container.read,
      InboxCaptureRecord(
        path: file.path,
        status: InboxCaptureStatus.pending,
        capture: capture,
      ),
    );

    expect(ok, isFalse);
    final all = await storage.readAll();
    expect(all.single.status, InboxCaptureStatus.pending);
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
