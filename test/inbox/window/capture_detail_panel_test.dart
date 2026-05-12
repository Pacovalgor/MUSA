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
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';
import 'package:musa/ui/inbox/window/widgets/capture_detail_panel.dart';

void main() {
  testWidgets('detail panel creates creative card with corrected type',
      (tester) async {
    final now = DateTime.utc(2026, 5, 8, 10, 15);
    final tempRoot = Directory.systemTemp.createTempSync('musa_detail_');
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
      body: '¿Y si Diane no abrió la puerta?',
      creativeTypeHint: 'idea',
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
        inboxStorageProvider.overrideWithValue(storage),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CaptureDetailPanel(
            record: InboxCaptureRecord(
              path: '${tempRoot.path}/capture-1.json',
              status: InboxCaptureStatus.pending,
              capture: capture,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CaptureDetailPanel)),
    );
    await container.read(narrativeWorkspaceProvider.notifier).bootstrap();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('capture-detail-type-question')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-detail-create-card')));
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
