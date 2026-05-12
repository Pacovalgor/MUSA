import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/inbox/models/inbox_capture.dart';
import 'package:musa/modules/inbox/models/inbox_capture_status.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempRoot;
  late InboxStorageService storage;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('musa_inbox_test_');
    storage = InboxStorageService(rootDirectory: tempRoot);
  });

  tearDown(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  InboxCapture makeCapture({
    String id = '550e8400-e29b-41d4-a716-446655440000',
    DateTime? capturedAt,
    InboxCaptureKind kind = InboxCaptureKind.text,
    String body = 'hello',
    String? url,
  }) {
    return InboxCapture(
      schemaVersion: 1,
      id: id,
      capturedAt: capturedAt ?? DateTime.utc(2026, 4, 25, 17, 32, 14),
      deviceLabel: 'iPhone test',
      kind: kind,
      body: body,
      url: url,
    );
  }

  group('write', () {
    test('writes capture in MUSA-Inbox/<localDate>/<HH-MM-SS>-<id>.json',
        () async {
      final capture =
          makeCapture(capturedAt: DateTime.utc(2026, 4, 25, 17, 32, 14));
      final file = await storage.write(capture);

      expect(file.existsSync(), isTrue);
      final relPath = p.relative(file.path, from: tempRoot.path);
      expect(relPath.startsWith('MUSA-Inbox/'), isTrue);
      expect(p.basename(file.path), endsWith('${capture.id}.json'));

      final json = jsonDecode(await file.readAsString());
      expect(json['id'], capture.id);
    });

    test('writes and reads creative metadata unchanged', () async {
      final capture = makeCapture(
        id: 'creative-meta',
        body: 'Imagen de escalera',
        url: 'file:///tmp/stair.png',
      ).copyWith(
        creativeTypeHint: 'image',
        attachmentUri: 'file:///tmp/stair.png',
        attachmentKind: 'image',
      );

      await storage.write(capture);

      final all = await storage.readAll();
      final stored = all.single.capture!;
      expect(stored.creativeTypeHint, 'image');
      expect(stored.attachmentUri, 'file:///tmp/stair.png');
      expect(stored.attachmentKind, 'image');
    });
  });

  group('read', () {
    test('reads valid capture and reports status=pending', () async {
      final capture = makeCapture();
      await storage.write(capture);

      final all = await storage.readAll();
      expect(all.length, 1);
      expect(all.first.capture!.id, capture.id);
      expect(all.first.status, InboxCaptureStatus.pending);
    });

    test('reports status=processed when file is in processed/', () async {
      final capture = makeCapture();
      final file = await storage.write(capture);
      await storage.markProcessed(file);

      final all = await storage.readAll();
      expect(all.first.status, InboxCaptureStatus.processed);
    });

    test('reports status=discarded when file is in discarded/', () async {
      final capture = makeCapture();
      final file = await storage.write(capture);
      await storage.markDiscarded(file);

      final all = await storage.readAll();
      expect(all.first.status, InboxCaptureStatus.discarded);
    });

    test('files with corrupted JSON are reported as unreadable', () async {
      final dir = Directory(p.join(tempRoot.path, 'MUSA-Inbox', '2026-04-25'))
        ..createSync(recursive: true);
      File(p.join(dir.path, '17-32-14-broken.json'))
          .writeAsStringSync('{not json');

      final all = await storage.readAll();
      expect(all.length, 1);
      expect(all.first.status, InboxCaptureStatus.unreadable);
      expect(all.first.capture, isNull);
    });

    test('files with schemaVersion > currentSchemaVersion are unreadable',
        () async {
      final dir = Directory(p.join(tempRoot.path, 'MUSA-Inbox', '2026-04-25'))
        ..createSync(recursive: true);
      File(p.join(dir.path, '17-32-14-future.json'))
          .writeAsStringSync(jsonEncode({
        'schemaVersion': 99,
        'id': 'x',
        'capturedAt': '2026-04-25T17:32:14Z',
        'deviceLabel': 'iPhone',
        'kind': 'text',
        'body': 'from the future',
      }));

      final all = await storage.readAll();
      expect(all.first.status, InboxCaptureStatus.unreadable);
    });

    test('readPending returns only pending captures', () async {
      final c1 = makeCapture(id: 'a');
      final c2 = makeCapture(id: 'b');
      final f1 = await storage.write(c1);
      await storage.write(c2);
      await storage.markProcessed(f1);

      final pending = await storage.readPending();
      expect(pending.length, 1);
      expect(pending.first.capture!.id, 'b');
    });
  });

  group('move', () {
    test('markProcessed moves to processed/ keeping name', () async {
      final f = await storage.write(makeCapture());
      final basename = p.basename(f.path);

      await storage.markProcessed(f);
      expect(f.existsSync(), isFalse);
      final processedFile =
          File(p.join(tempRoot.path, 'MUSA-Inbox', 'processed', basename));
      expect(processedFile.existsSync(), isTrue);
    });

    test('markDiscarded moves to discarded/ keeping name', () async {
      final f = await storage.write(makeCapture());
      final basename = p.basename(f.path);

      await storage.markDiscarded(f);
      final discardedFile =
          File(p.join(tempRoot.path, 'MUSA-Inbox', 'discarded', basename));
      expect(discardedFile.existsSync(), isTrue);
    });
  });

  group('availability', () {
    test('isAccessible returns false for non-existent root', () async {
      final missing = Directory(p.join(tempRoot.path, 'no-existe'));
      final s = InboxStorageService(rootDirectory: missing);
      expect(await s.isAccessible(), isFalse);
    });

    test('isAccessible returns true for writable root', () async {
      expect(await storage.isAccessible(), isTrue);
    });
  });
}
