import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/inbox/models/inbox_capture.dart';
import 'package:musa/modules/inbox/models/inbox_capture_status.dart';

void main() {
  group('InboxCaptureStatus', () {
    test('values cover all expected states', () {
      expect(InboxCaptureStatus.values, [
        InboxCaptureStatus.pending,
        InboxCaptureStatus.processed,
        InboxCaptureStatus.discarded,
        InboxCaptureStatus.unreadable,
      ]);
    });
  });

  group('InboxCapture.fromJson / toJson', () {
    test('round-trip with kind=text', () {
      final original = InboxCapture(
        schemaVersion: 1,
        id: '550e8400-e29b-41d4-a716-446655440000',
        capturedAt: DateTime.utc(2026, 4, 25, 17, 32, 14),
        deviceLabel: 'iPhone de Paco',
        kind: InboxCaptureKind.text,
        body: 'Diane mira la pizarra.',
      );

      final json = original.toJson();
      final back = InboxCapture.fromJson(json);

      expect(back.id, original.id);
      expect(back.capturedAt, original.capturedAt);
      expect(back.kind, InboxCaptureKind.text);
      expect(back.body, 'Diane mira la pizarra.');
      expect(back.url, isNull);
      expect(back.title, isNull);
      expect(back.projectHint, isNull);
    });

    test('round-trip with kind=link', () {
      final original = InboxCapture(
        schemaVersion: 1,
        id: 'aaa',
        capturedAt: DateTime.utc(2026, 4, 25),
        deviceLabel: 'iPhone',
        kind: InboxCaptureKind.link,
        body: 'Para el cap del Tenderloin',
        url: 'https://nytimes.com/foo',
      );

      final json = original.toJson();
      expect(json['kind'], 'link');
      expect(json['url'], 'https://nytimes.com/foo');

      final back = InboxCapture.fromJson(json);
      expect(back.url, 'https://nytimes.com/foo');
      expect(back.kind, InboxCaptureKind.link);
    });

    test('round-trips creative card metadata', () {
      final original = InboxCapture(
        schemaVersion: 1,
        id: 'creative-meta',
        capturedAt: DateTime.utc(2026, 5, 8, 10, 15),
        deviceLabel: 'iPhone de Paco',
        kind: InboxCaptureKind.link,
        body: 'Referencia de puerta',
        url: 'https://example.com/door',
        creativeTypeHint: 'sketch',
        attachmentUri: '/tmp/reference.png',
        attachmentKind: 'image',
      );

      final json = original.toJson();
      expect(json['creativeTypeHint'], 'sketch');
      expect(json['attachmentUri'], '/tmp/reference.png');
      expect(json['attachmentKind'], 'image');

      final back = InboxCapture.fromJson(json);
      expect(back.creativeTypeHint, 'sketch');
      expect(back.attachmentUri, '/tmp/reference.png');
      expect(back.attachmentKind, 'image');
    });

    test('accepts old capture json without creative card metadata', () {
      final back = InboxCapture.fromJson(const {
        'schemaVersion': 1,
        'id': 'old-capture',
        'capturedAt': '2026-04-25T17:32:14Z',
        'deviceLabel': 'iPhone',
        'kind': 'text',
        'body': 'Idea antigua',
        'url': null,
        'title': null,
        'projectHint': null,
      });

      expect(back.creativeTypeHint, isNull);
      expect(back.attachmentUri, isNull);
      expect(back.attachmentKind, isNull);
    });

    test('serializes capturedAt in ISO8601 UTC ("Z")', () {
      final c = InboxCapture(
        schemaVersion: 1,
        id: 'x',
        capturedAt: DateTime.utc(2026, 4, 25, 17, 32, 14),
        deviceLabel: 'iPhone',
        kind: InboxCaptureKind.text,
        body: 'hi',
      );
      expect(c.toJson()['capturedAt'], '2026-04-25T17:32:14.000Z');
    });

    test('throws on schemaVersion > 1', () {
      final json = {
        'schemaVersion': 2,
        'id': 'x',
        'capturedAt': '2026-04-25T17:32:14Z',
        'deviceLabel': 'iPhone',
        'kind': 'text',
        'body': 'hi',
        'url': null,
        'title': null,
        'projectHint': null,
      };
      expect(
        () => InboxCapture.fromJson(json),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('throws on missing required fields', () {
      final json = {'schemaVersion': 1, 'id': 'x'};
      expect(
        () => InboxCapture.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('treats unknown kind as FormatException', () {
      final json = {
        'schemaVersion': 1,
        'id': 'x',
        'capturedAt': '2026-04-25T17:32:14Z',
        'deviceLabel': 'iPhone',
        'kind': 'voice',
        'body': '',
        'url': null,
        'title': null,
        'projectHint': null,
      };
      expect(
        () => InboxCapture.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
