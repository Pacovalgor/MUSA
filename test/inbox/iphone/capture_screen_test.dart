import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/inbox/models/inbox_capture.dart';
import 'package:musa/modules/inbox/models/inbox_capture_status.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/services/inbox_bookmark_service.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';
import 'package:musa/ui/inbox/iphone/capture_screen.dart';
import 'package:musa/ui/inbox/iphone/inbox_settings_screen.dart';

void main() {
  testWidgets('capture screen writes selected creative type hint',
      (tester) async {
    final tempRoot = Directory.systemTemp.createTempSync('musa_capture_ui_');
    addTearDown(() {
      if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
    });
    final storage = _MemoryInboxStorageService(rootDirectory: tempRoot);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        inboxFolderProvider.overrideWith(
          (ref) => _HealthyInboxFolderNotifier(tempRoot.path),
        ),
        inboxStorageProvider.overrideWithValue(storage),
        inboxDeviceLabelProvider.overrideWith((ref) async => 'iPhone de Paco'),
      ],
      child: const MaterialApp(home: CaptureScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      '¿Y si Diane no abrió la puerta?',
    );
    await tester.tap(find.byKey(const Key('iphone-capture-type-question')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('iphone-capture-save-button')));
    await tester.pump(const Duration(seconds: 1));

    final captures = await storage.readAll();
    expect(captures, hasLength(1));
    expect(captures.single.parseError, isNull);
    expect(captures.single.capture!.creativeTypeHint, 'question');
    expect(captures.single.capture!.deviceLabel, 'iPhone de Paco');
  });
}

class _MemoryInboxStorageService extends InboxStorageService {
  _MemoryInboxStorageService({required super.rootDirectory});

  final List<InboxCaptureRecord> _records = [];

  @override
  Future<File> write(InboxCapture capture) async {
    final file = File('${rootDirectory.path}/${capture.id}.json');
    _records.add(InboxCaptureRecord(
      path: file.path,
      status: InboxCaptureStatus.pending,
      capture: capture,
    ));
    return file;
  }

  @override
  Future<List<InboxCaptureRecord>> readAll() async => List.of(_records);
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
