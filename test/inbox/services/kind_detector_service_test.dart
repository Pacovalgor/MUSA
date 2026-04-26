import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/inbox/models/inbox_capture.dart';
import 'package:musa/modules/inbox/services/kind_detector_service.dart';

void main() {
  const detector = KindDetectorService();

  group('detect — kind=text', () {
    test('plain text without URL', () {
      final r = detector.detect('Diane mira la pizarra');
      expect(r.kind, InboxCaptureKind.text);
      expect(r.url, isNull);
      expect(r.body, 'Diane mira la pizarra');
    });

    test('empty string is treated as text with empty body', () {
      final r = detector.detect('');
      expect(r.kind, InboxCaptureKind.text);
      expect(r.body, '');
    });

    test('mailto: is NOT a link in Ola 1 (only http/https/file)', () {
      final r = detector.detect('mailto:foo@bar.com');
      expect(r.kind, InboxCaptureKind.text);
    });

    test('domain without scheme is NOT a link', () {
      final r = detector.detect('nytimes.com');
      expect(r.kind, InboxCaptureKind.text);
    });
  });

  group('detect — kind=link (URL pura)', () {
    test('https URL alone, body becomes empty', () {
      final r = detector.detect('https://nytimes.com/foo');
      expect(r.kind, InboxCaptureKind.link);
      expect(r.url, 'https://nytimes.com/foo');
      expect(r.body, '');
    });

    test('http URL alone', () {
      final r = detector.detect('http://example.org');
      expect(r.kind, InboxCaptureKind.link);
      expect(r.url, 'http://example.org');
    });

    test('file:// URL alone', () {
      final r = detector.detect('file:///tmp/x.txt');
      expect(r.kind, InboxCaptureKind.link);
      expect(r.url, 'file:///tmp/x.txt');
    });

    test('URL with query parameters', () {
      const url = 'https://nytimes.com/path?id=1&q=hola%20mundo';
      final r = detector.detect(url);
      expect(r.kind, InboxCaptureKind.link);
      expect(r.url, url);
    });

    test('URL surrounded by whitespace gets trimmed', () {
      final r = detector.detect('   https://example.com   ');
      expect(r.kind, InboxCaptureKind.link);
      expect(r.url, 'https://example.com');
      expect(r.body, '');
    });
  });

  group('detect — kind=link (URL con texto)', () {
    test('URL preceded by comment, body keeps full text', () {
      final r = detector.detect('Para el cap del Tenderloin: https://nytimes.com/x');
      expect(r.kind, InboxCaptureKind.link);
      expect(r.url, 'https://nytimes.com/x');
      expect(r.body, 'Para el cap del Tenderloin: https://nytimes.com/x');
    });

    test('multiple URLs: extracts only the FIRST', () {
      final r = detector.detect('Comparar https://a.com con https://b.com');
      expect(r.kind, InboxCaptureKind.link);
      expect(r.url, 'https://a.com');
    });
  });
}
