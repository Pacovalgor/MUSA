# Captura iPhone → Bandeja en Mac (Ola 1) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el slice vertical "captura iPhone → bandeja Mac": el iPhone deposita capturas (text/link) como archivos `.json` en una carpeta del filesystem que el usuario elige; el Mac las muestra en un popover de toolbar + ventana de gestión, donde se pueden aceptar como `Note`, expandir-y-editar, o descartar.

**Architecture:** Transporte agnóstico vía filesystem (cada captura = un `.json` con UUID; carpeta sincronizada por iCloud/Drive/OneDrive/etc. fuera del control de MUSA). Un módulo nuevo `lib/modules/inbox/` con modelos `@immutable`, servicios y providers Riverpod. UI Mac vía un botón nuevo en la toolbar de `main_screen.dart`, popover y pantalla full-screen (`Navigator.push`). UI iPhone reemplaza el tab "Captura" del `CaptureToolShell` existente. Bookmarks de seguridad de iOS/macOS via method channel Swift (`musa/inbox_bookmark`).

**Tech Stack:** Flutter 3.x · Dart 3.x · Riverpod (clásico) · `path` · `path_provider` · `shared_preferences` · `uuid` (NUEVO) · Swift method channels

---

## Tabla de tareas

| # | Tarea | Estimación |
|---|---|---|
| 1 | Setup: dependencia `uuid` | 0.1 d |
| 2 | Modelos `InboxCaptureStatus` + `InboxCapture` | 0.4 d |
| 3 | `KindDetectorService` | 0.4 d |
| 4 | `InboxStorageService` | 1.0 d |
| 5 | Swift channel macOS (`InboxBookmarkChannel`) | 0.5 d |
| 6 | Swift channel iOS (`InboxBookmarkChannel`) | 0.3 d |
| 7 | `InboxBookmarkService` (Dart) | 0.3 d |
| 8 | Providers Riverpod (folder, captures, history) | 0.5 d |
| 9 | Hook en `NarrativeWorkspaceNotifier`: `addNoteFromInbox` | 0.3 d |
| 10 | iPhone — `CaptureScreen` | 0.6 d |
| 11 | iPhone — `HistoryScreen` | 0.4 d |
| 12 | iPhone — `OnboardingScreen` | 0.4 d |
| 13 | iPhone — Settings | 0.3 d |
| 14 | Modificación de `CaptureToolShell` (sub-tabs) | 0.3 d |
| 15 | Mac — `InboxToolbarButton` (insertion en `_buildTopBar`) | 0.3 d |
| 16 | Mac — `InboxPopover` | 0.4 d |
| 17 | Mac — `InboxManagementScreen` (lista + detalle) | 0.6 d |
| 18 | Mac — Acciones (aceptar / expandir-editar / descartar) | 0.4 d |
| 19 | Mac — Watcher FSEvents (debounce 250 ms) | 0.4 d |
| 20 | Mac — Atajo `⌘⇧B` + entrada de menú "Ver" | 0.2 d |
| 21 | Mac — Settings + Onboarding | 0.4 d |
| 22 | Verificación final + manual smoke | 0.4 d |

**Total: ~9 días en estimación pesimista, ~5-7 días si hay foco continuo.**

---

## Task 1: Setup — dependencia `uuid`

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Añadir `uuid` al pubspec**

Editar `pubspec.yaml`, en la sección `dependencies:` (justo después de `crypto: ^3.0.3`):

```yaml
  crypto: ^3.0.3
  uuid: ^4.4.0
  printing: ^5.14.3
```

- [ ] **Step 2: Resolver dependencias**

Ejecutar:
```bash
flutter pub get
```
Expected: `Got dependencies!` o `Resolving dependencies... Got dependencies!` sin errores.

- [ ] **Step 3: Smoke test que la lib carga**

Crear archivo temporal `tmp/uuid_smoke.dart`:
```dart
import 'package:uuid/uuid.dart';

void main() {
  final id = const Uuid().v4();
  assert(id.length == 36, 'Expected 36 chars, got ${id.length}');
  print('OK $id');
}
```

Ejecutar:
```bash
mkdir -p tmp && dart run tmp/uuid_smoke.dart
```
Expected: imprime `OK <uuid>` y termina con código 0.

- [ ] **Step 4: Limpiar tmp y commitear**

```bash
rm tmp/uuid_smoke.dart
git add pubspec.yaml pubspec.lock
git commit -m "chore: añadir uuid ^4.4.0 para identificadores de capturas inbox"
```

---

## Task 2: Modelos `InboxCaptureStatus` + `InboxCapture`

**Files:**
- Create: `lib/modules/inbox/models/inbox_capture_status.dart`
- Create: `lib/modules/inbox/models/inbox_capture.dart`
- Test: `test/inbox/models/inbox_capture_test.dart`

- [ ] **Step 1: Test del enum status (escribirlo primero)**

Crear `test/inbox/models/inbox_capture_test.dart`:

```dart
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
```

- [ ] **Step 2: Run tests — esperar fallo de compilación**

Ejecutar:
```bash
flutter test test/inbox/models/inbox_capture_test.dart
```
Expected: error `Target of URI doesn't exist: '...inbox_capture.dart'` — los modelos no existen aún.

- [ ] **Step 3: Implementar `InboxCaptureStatus`**

Crear `lib/modules/inbox/models/inbox_capture_status.dart`:

```dart
/// Estado de una captura desde el punto de vista del filesystem.
///
/// `pending`: archivo en `MUSA-Inbox/<fecha>/`.
/// `processed`: archivo movido a `MUSA-Inbox/processed/`.
/// `discarded`: archivo movido a `MUSA-Inbox/discarded/`.
/// `unreadable`: archivo presente pero JSON inválido / schemaVersion > 1.
enum InboxCaptureStatus {
  pending,
  processed,
  discarded,
  unreadable,
}
```

- [ ] **Step 4: Implementar `InboxCapture`**

Crear `lib/modules/inbox/models/inbox_capture.dart`:

```dart
import 'package:flutter/foundation.dart';

/// Tipo de contenido de la captura. Ola 1 sólo expone text y link.
/// Olas posteriores añadirán voice (Ola 2) e image (Ola 3).
enum InboxCaptureKind { text, link }

/// Captura editorial inmutable depositada por un dispositivo en la carpeta
/// sincronizada y leída por el Mac (o por el propio iPhone para historial).
@immutable
class InboxCapture {
  const InboxCapture({
    required this.schemaVersion,
    required this.id,
    required this.capturedAt,
    required this.deviceLabel,
    required this.kind,
    required this.body,
    this.url,
    this.title,
    this.projectHint,
  });

  final int schemaVersion;
  final String id;
  final DateTime capturedAt; // siempre UTC
  final String deviceLabel;
  final InboxCaptureKind kind;
  final String body;
  final String? url;
  final String? title;
  final String? projectHint;

  /// Schema version soportada por esta versión del cliente.
  static const int currentSchemaVersion = 1;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
        'deviceLabel': deviceLabel,
        'kind': kind.name,
        'body': body,
        'url': url,
        'title': title,
        'projectHint': projectHint,
      };

  factory InboxCapture.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version is! int) {
      throw const FormatException('schemaVersion ausente o no es int');
    }
    if (version > currentSchemaVersion) {
      throw UnsupportedError(
        'schemaVersion $version no soportada por este cliente '
        '(máximo soportado: $currentSchemaVersion)',
      );
    }
    final id = json['id'];
    final capturedAtRaw = json['capturedAt'];
    final deviceLabel = json['deviceLabel'];
    final kindRaw = json['kind'];
    final body = json['body'];
    if (id is! String ||
        capturedAtRaw is! String ||
        deviceLabel is! String ||
        kindRaw is! String ||
        body is! String) {
      throw const FormatException('Campos requeridos ausentes o de tipo erróneo');
    }
    final kind = InboxCaptureKind.values.firstWhere(
      (k) => k.name == kindRaw,
      orElse: () =>
          throw FormatException('kind desconocido en Ola 1: "$kindRaw"'),
    );
    return InboxCapture(
      schemaVersion: version,
      id: id,
      capturedAt: DateTime.parse(capturedAtRaw).toUtc(),
      deviceLabel: deviceLabel,
      kind: kind,
      body: body,
      url: json['url'] as String?,
      title: json['title'] as String?,
      projectHint: json['projectHint'] as String?,
    );
  }

  InboxCapture copyWith({
    String? body,
    String? url,
    String? title,
  }) {
    return InboxCapture(
      schemaVersion: schemaVersion,
      id: id,
      capturedAt: capturedAt,
      deviceLabel: deviceLabel,
      kind: kind,
      body: body ?? this.body,
      url: url ?? this.url,
      title: title ?? this.title,
      projectHint: projectHint,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is InboxCapture && other.id == id && other.capturedAt == capturedAt;

  @override
  int get hashCode => Object.hash(id, capturedAt);
}
```

- [ ] **Step 5: Run tests — deben pasar**

```bash
flutter test test/inbox/models/inbox_capture_test.dart
```
Expected: `+6: All tests passed!` (6 tests del grupo).

- [ ] **Step 6: Commit**

```bash
git add lib/modules/inbox/models/ test/inbox/models/
git commit -m "feat(inbox): modelo InboxCapture inmutable con (de)serialización JSON"
```

---

## Task 3: `KindDetectorService`

**Files:**
- Create: `lib/modules/inbox/services/kind_detector_service.dart`
- Test: `test/inbox/services/kind_detector_service_test.dart`

- [ ] **Step 1: Test (escribirlo primero)**

Crear `test/inbox/services/kind_detector_service_test.dart`:

```dart
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
```

- [ ] **Step 2: Run tests — falla (clase inexistente)**

```bash
flutter test test/inbox/services/kind_detector_service_test.dart
```
Expected: `Target of URI doesn't exist: '...kind_detector_service.dart'`.

- [ ] **Step 3: Implementar `KindDetectorService`**

Crear `lib/modules/inbox/services/kind_detector_service.dart`:

```dart
import 'package:musa/modules/inbox/models/inbox_capture.dart';

/// Resultado de la detección de kind a partir del input crudo del usuario.
class KindDetectionResult {
  const KindDetectionResult({
    required this.kind,
    required this.body,
    this.url,
  });
  final InboxCaptureKind kind;
  final String body;
  final String? url;
}

/// Detecta si el input es texto, link puro, o texto con URL embebida.
///
/// Reglas (Ola 1):
/// 1. Si el input trimeado es UNA URL válida (http/https/file): kind=link,
///    url=trimeado, body="" (la URL "es" la captura).
/// 2. Si el input contiene una URL pero no es solo eso: kind=link,
///    url=la primera URL extraída, body=input completo (el comentario rodea
///    la URL).
/// 3. En cualquier otro caso: kind=text, url=null, body=input.
class KindDetectorService {
  const KindDetectorService();

  static final RegExp _urlPattern = RegExp(
    r'(https?|file)://[^\s<>" -]+',
    caseSensitive: false,
  );

  KindDetectionResult detect(String rawInput) {
    final trimmed = rawInput.trim();

    if (_isFullUrl(trimmed)) {
      return KindDetectionResult(
        kind: InboxCaptureKind.link,
        body: '',
        url: trimmed,
      );
    }

    final match = _urlPattern.firstMatch(rawInput);
    if (match != null) {
      return KindDetectionResult(
        kind: InboxCaptureKind.link,
        body: rawInput,
        url: match.group(0),
      );
    }

    return KindDetectionResult(
      kind: InboxCaptureKind.text,
      body: rawInput,
      url: null,
    );
  }

  bool _isFullUrl(String s) {
    if (s.isEmpty) return false;
    final m = _urlPattern.firstMatch(s);
    return m != null && m.start == 0 && m.end == s.length;
  }
}
```

- [ ] **Step 4: Run tests — pasan**

```bash
flutter test test/inbox/services/kind_detector_service_test.dart
```
Expected: `+11: All tests passed!`.

- [ ] **Step 5: Commit**

```bash
git add lib/modules/inbox/services/kind_detector_service.dart test/inbox/services/kind_detector_service_test.dart
git commit -m "feat(inbox): KindDetectorService — distingue text/link y extrae URL"
```

---

## Task 4: `InboxStorageService`

Capa que sabe leer, escribir y mover archivos `.json` de captura sobre una `Directory` raíz dada.

**Files:**
- Create: `lib/modules/inbox/services/inbox_storage_service.dart`
- Test: `test/inbox/services/inbox_storage_service_test.dart`

- [ ] **Step 1: Test (FS temporal)**

Crear `test/inbox/services/inbox_storage_service_test.dart`:

```dart
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

  InboxCapture _capture({
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
    test('writes capture in MUSA-Inbox/<localDate>/<HH-MM-SS>-<id>.json', () async {
      final capture = _capture(capturedAt: DateTime.utc(2026, 4, 25, 17, 32, 14));
      final file = await storage.write(capture);

      expect(file.existsSync(), isTrue);
      final relPath = p.relative(file.path, from: tempRoot.path);
      // Subcarpeta por fecha local; check solo que tiene el shape.
      expect(relPath.startsWith('MUSA-Inbox/'), isTrue);
      expect(p.basename(file.path),
          endsWith('${capture.id}.json'));

      final json = jsonDecode(await file.readAsString());
      expect(json['id'], capture.id);
    });
  });

  group('read', () {
    test('reads valid capture and reports status=pending', () async {
      final capture = _capture();
      await storage.write(capture);

      final all = await storage.readAll();
      expect(all.length, 1);
      expect(all.first.capture.id, capture.id);
      expect(all.first.status, InboxCaptureStatus.pending);
    });

    test('reports status=processed when file is in processed/', () async {
      final capture = _capture();
      final file = await storage.write(capture);
      await storage.markProcessed(file);

      final all = await storage.readAll();
      expect(all.first.status, InboxCaptureStatus.processed);
    });

    test('reports status=discarded when file is in discarded/', () async {
      final capture = _capture();
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

    test('files with schemaVersion > currentSchemaVersion are unreadable', () async {
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
      final c1 = _capture(id: 'a');
      final c2 = _capture(id: 'b');
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
      final f = await storage.write(_capture());
      final basename = p.basename(f.path);

      await storage.markProcessed(f);
      expect(f.existsSync(), isFalse);
      final processedFile = File(p.join(
          tempRoot.path, 'MUSA-Inbox', 'processed', basename));
      expect(processedFile.existsSync(), isTrue);
    });

    test('markDiscarded moves to discarded/ keeping name', () async {
      final f = await storage.write(_capture());
      final basename = p.basename(f.path);

      await storage.markDiscarded(f);
      final discardedFile = File(p.join(
          tempRoot.path, 'MUSA-Inbox', 'discarded', basename));
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
```

- [ ] **Step 2: Run tests — falla (clase inexistente)**

```bash
flutter test test/inbox/services/inbox_storage_service_test.dart
```
Expected: error de compilación.

- [ ] **Step 3: Implementar `InboxStorageService`**

Crear `lib/modules/inbox/services/inbox_storage_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:musa/modules/inbox/models/inbox_capture.dart';
import 'package:musa/modules/inbox/models/inbox_capture_status.dart';
import 'package:path/path.dart' as p;

/// Una captura tal y como vive en el filesystem (puede estar legible o no).
class InboxCaptureRecord {
  const InboxCaptureRecord({
    required this.path,
    required this.status,
    this.capture,
    this.rawContent,
    this.parseError,
  });

  /// Path absoluto del archivo `.json`.
  final String path;
  final InboxCaptureStatus status;

  /// Captura parseada. `null` si `status == unreadable`.
  final InboxCapture? capture;

  /// Contenido bruto del archivo (sólo poblado si `unreadable`).
  final String? rawContent;
  final String? parseError;
}

/// Acceso al filesystem para la bandeja: leer, escribir y mover capturas.
///
/// La carpeta raíz pasada en el constructor es la elegida por el usuario
/// (NO ya con `MUSA-Inbox/` apendido). El servicio gestiona internamente
/// la subcarpeta `MUSA-Inbox/`.
class InboxStorageService {
  InboxStorageService({required this.rootDirectory});

  final Directory rootDirectory;

  static const String _inboxFolder = 'MUSA-Inbox';
  static const String _processedFolder = 'processed';
  static const String _discardedFolder = 'discarded';

  Directory get _inbox =>
      Directory(p.join(rootDirectory.path, _inboxFolder));
  Directory get _processed =>
      Directory(p.join(_inbox.path, _processedFolder));
  Directory get _discarded =>
      Directory(p.join(_inbox.path, _discardedFolder));

  /// `true` si la raíz existe y es escribible (escribe + lee + borra un
  /// `.musa-test`).
  Future<bool> isAccessible() async {
    if (!rootDirectory.existsSync()) return false;
    try {
      final probe =
          File(p.join(rootDirectory.path, '.musa-inbox-probe-${_now()}'));
      probe.writeAsStringSync('probe', flush: true);
      probe.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Escribe una captura en `MUSA-Inbox/<fecha-local>/<HH-MM-SS>-<id>.json`
  /// y devuelve el `File` resultante.
  Future<File> write(InboxCapture capture) async {
    final localDate = capture.capturedAt.toLocal();
    final dateFolder = _formatDate(localDate);
    final timePrefix = _formatTime(localDate);

    final dir = Directory(p.join(_inbox.path, dateFolder));
    dir.createSync(recursive: true);

    final filename = '$timePrefix-${capture.id}.json';
    final file = File(p.join(dir.path, filename));

    final encoded = const JsonEncoder.withIndent('  ').convert(capture.toJson());
    await file.writeAsString('$encoded\n', flush: true);
    return file;
  }

  /// Lee todas las capturas conocidas en MUSA-Inbox (pendientes + processed +
  /// discarded), reportando estado por carpeta.
  Future<List<InboxCaptureRecord>> readAll() async {
    if (!_inbox.existsSync()) return const [];
    final out = <InboxCaptureRecord>[];

    // Pending: subcarpetas por fecha (todo lo que no sea processed/discarded).
    for (final entity in _inbox.listSync()) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (name == _processedFolder || name == _discardedFolder) continue;
      _collectFromFolder(entity, InboxCaptureStatus.pending, out);
    }

    // Processed.
    if (_processed.existsSync()) {
      _collectFromFolder(_processed, InboxCaptureStatus.processed, out);
    }
    // Discarded.
    if (_discarded.existsSync()) {
      _collectFromFolder(_discarded, InboxCaptureStatus.discarded, out);
    }
    return out;
  }

  Future<List<InboxCaptureRecord>> readPending() async {
    final all = await readAll();
    return all
        .where((r) => r.status == InboxCaptureStatus.pending)
        .toList();
  }

  Future<void> markProcessed(File file) =>
      _moveTo(file, _processed);

  Future<void> markDiscarded(File file) =>
      _moveTo(file, _discarded);

  Future<void> _moveTo(File file, Directory destination) async {
    destination.createSync(recursive: true);
    final newPath = p.join(destination.path, p.basename(file.path));
    try {
      await file.rename(newPath);
    } on FileSystemException {
      // Cross-volume rename can fail. Fallback to copy + delete.
      await file.copy(newPath);
      await file.delete();
    }
  }

  void _collectFromFolder(
    Directory folder,
    InboxCaptureStatus status,
    List<InboxCaptureRecord> out,
  ) {
    for (final f in folder.listSync()) {
      if (f is! File) continue;
      if (!f.path.endsWith('.json')) continue;
      InboxCapture? parsed;
      String? rawContent;
      String? parseError;
      try {
        final raw = f.readAsStringSync();
        rawContent = raw;
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Top-level JSON no es objeto');
        }
        parsed = InboxCapture.fromJson(decoded);
      } catch (e) {
        parseError = e.toString();
      }
      out.add(InboxCaptureRecord(
        path: f.path,
        status: parsed == null ? InboxCaptureStatus.unreadable : status,
        capture: parsed,
        rawContent: parsed == null ? rawContent : null,
        parseError: parseError,
      ));
    }
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_2(d.month)}-${_2(d.day)}';

  static String _formatTime(DateTime d) =>
      '${_2(d.hour)}-${_2(d.minute)}-${_2(d.second)}';

  static String _2(int n) => n.toString().padLeft(2, '0');

  static int _now() => DateTime.now().microsecondsSinceEpoch;
}
```

- [ ] **Step 4: Run tests — pasan todos**

```bash
flutter test test/inbox/services/inbox_storage_service_test.dart
```
Expected: `+9: All tests passed!`.

- [ ] **Step 5: Commit**

```bash
git add lib/modules/inbox/services/inbox_storage_service.dart test/inbox/services/inbox_storage_service_test.dart
git commit -m "feat(inbox): InboxStorageService — read/write/mover sobre carpeta sincronizada"
```

---

## Task 5: Swift channel macOS — `InboxBookmarkChannel`

Resuelve security-scoped bookmarks: dada una URL elegida por `NSOpenPanel`, devuelve datos serializables; dado el blob, lo resuelve y devuelve la ruta accesible.

**Files:**
- Create: `macos/Runner/InboxBookmarkChannel.swift`
- Modify: `macos/Runner/AppDelegate.swift`

- [ ] **Step 1: Crear `InboxBookmarkChannel.swift`**

Crear `macos/Runner/InboxBookmarkChannel.swift`:

```swift
import FlutterMacOS
import AppKit

/// Method channel para gestionar security-scoped bookmarks en macOS.
///
/// API:
/// - `pickFolder` → `{ "bookmark": <base64>, "path": <string> }` o `null` si cancela.
/// - `resolveBookmark(bookmark: <base64>)` → `{ "path": <string>, "stale": <bool> }`
///   o lanza `FlutterError` si no se puede resolver.
/// - `writeFileAtBookmark(bookmark, relativePath, contents)` → `{ "path": <string> }`.
final class InboxBookmarkChannel: NSObject {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "musa/inbox_bookmark",
      binaryMessenger: messenger
    )
    super.init()
    channel.setMethodCallHandler(handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickFolder":
      pickFolder(result: result)
    case "resolveBookmark":
      resolveBookmark(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pickFolder(result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.message = "Elige la carpeta donde MUSA guardará y leerá tus capturas"
    panel.prompt = "Elegir carpeta"

    panel.begin { response in
      guard response == .OK, let url = panel.url else {
        result(nil)
        return
      }
      do {
        let bookmark = try url.bookmarkData(
          options: [.withSecurityScope],
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
        result([
          "bookmark": FlutterStandardTypedData(bytes: bookmark),
          "path": url.path,
        ])
      } catch {
        result(FlutterError(
          code: "BOOKMARK_FAILED",
          message: "No se pudo crear bookmark: \(error.localizedDescription)",
          details: nil
        ))
      }
    }
  }

  private func resolveBookmark(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let blob = args["bookmark"] as? FlutterStandardTypedData
    else {
      result(FlutterError(code: "BAD_ARGS", message: "missing bookmark", details: nil))
      return
    }
    var stale = false
    do {
      let url = try URL(
        resolvingBookmarkData: blob.data,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &stale
      )
      // Iniciamos acceso. Lo dejamos abierto durante la sesión.
      _ = url.startAccessingSecurityScopedResource()
      result([
        "path": url.path,
        "stale": stale,
      ])
    } catch {
      result(FlutterError(
        code: "BOOKMARK_INVALID",
        message: error.localizedDescription,
        details: nil
      ))
    }
  }
}
```

- [ ] **Step 2: Registrar el canal en `AppDelegate.swift`**

Editar `macos/Runner/AppDelegate.swift`. Buscar el final de la clase `AppDelegate` (justo antes del último `}`) y la función `applicationShouldTerminateAfterLastWindowClosed`. Añadir una nueva propiedad y registro:

```swift
// Cerca del top de la clase, junto a appMenuChannel:
private var inboxBookmarkChannel: InboxBookmarkChannel?

// Override applicationDidFinishLaunching o applicationDidBecomeActive (aquí
// va bien ahí; si la clase actual no lo override, añadirlo):
override func applicationDidFinishLaunching(_ notification: Notification) {
  super.applicationDidFinishLaunching(notification)
  if let messenger = (mainFlutterWindow?.contentViewController as? FlutterViewController)?.engine.binaryMessenger {
    inboxBookmarkChannel = InboxBookmarkChannel(messenger: messenger)
  }
}
```

> **Nota:** si la clase ya hace el setup en otra parte (por ejemplo en `MainFlutterWindow.swift`), preferir registrar el canal allí donde haya un `FlutterViewController` accesible. Comprueba antes de pegar.

- [ ] **Step 3: Verificar el build de macOS**

```bash
flutter build macos --debug 2>&1 | tail -20
```
Expected: build OK, sin errores Swift.

- [ ] **Step 4: Commit**

```bash
git add macos/Runner/
git commit -m "feat(inbox): canal Swift macOS para security-scoped bookmarks"
```

---

## Task 6: Swift channel iOS — `InboxBookmarkChannel`

**Files:**
- Create: `ios/Runner/InboxBookmarkChannel.swift`
- Modify: `ios/Runner/AppDelegate.swift`

- [ ] **Step 1: Crear `InboxBookmarkChannel.swift` (iOS)**

Crear `ios/Runner/InboxBookmarkChannel.swift`:

```swift
import Flutter
import UIKit
import UniformTypeIdentifiers

final class InboxBookmarkChannel: NSObject, UIDocumentPickerDelegate {
  private let channel: FlutterMethodChannel
  private weak var rootViewController: UIViewController?
  private var pendingResult: FlutterResult?

  init(messenger: FlutterBinaryMessenger, rootViewController: UIViewController?) {
    self.channel = FlutterMethodChannel(
      name: "musa/inbox_bookmark",
      binaryMessenger: messenger
    )
    self.rootViewController = rootViewController
    super.init()
    channel.setMethodCallHandler(handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickFolder": pickFolder(result: result)
    case "resolveBookmark": resolveBookmark(call: call, result: result)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func pickFolder(result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(code: "BUSY", message: "Picker already open", details: nil))
      return
    }
    pendingResult = result

    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    } else {
      picker = UIDocumentPickerViewController(documentTypes: ["public.folder"], in: .open)
    }
    picker.allowsMultipleSelection = false
    picker.delegate = self
    rootViewController?.present(picker, animated: true)
  }

  private func resolveBookmark(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let blob = args["bookmark"] as? FlutterStandardTypedData
    else {
      result(FlutterError(code: "BAD_ARGS", message: "missing bookmark", details: nil))
      return
    }
    var stale = false
    do {
      let url = try URL(
        resolvingBookmarkData: blob.data,
        options: [],
        relativeTo: nil,
        bookmarkDataIsStale: &stale
      )
      _ = url.startAccessingSecurityScopedResource()
      result(["path": url.path, "stale": stale])
    } catch {
      result(FlutterError(code: "BOOKMARK_INVALID", message: error.localizedDescription, details: nil))
    }
  }

  // MARK: - UIDocumentPickerDelegate

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first, let result = pendingResult else { return }
    pendingResult = nil
    do {
      _ = url.startAccessingSecurityScopedResource()
      let bookmark = try url.bookmarkData()
      result([
        "bookmark": FlutterStandardTypedData(bytes: bookmark),
        "path": url.path,
      ])
    } catch {
      result(FlutterError(code: "BOOKMARK_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingResult?(nil)
    pendingResult = nil
  }
}
```

- [ ] **Step 2: Registrar canal en `ios/Runner/AppDelegate.swift`**

Abrir `ios/Runner/AppDelegate.swift` y añadir antes del último `}` de la clase:

```swift
private var inboxBookmarkChannel: InboxBookmarkChannel?

override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
) -> Bool {
  GeneratedPluginRegistrant.register(with: self)
  if let controller = window?.rootViewController as? FlutterViewController {
    inboxBookmarkChannel = InboxBookmarkChannel(
      messenger: controller.binaryMessenger,
      rootViewController: controller
    )
  }
  return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
```

> Si ya existe un `application(_:didFinishLaunchingWithOptions:)`, fusiona la inicialización dentro respetando el `super` y la llamada al registrant.

- [ ] **Step 3: Verificar build iOS**

```bash
flutter build ios --simulator --no-codesign 2>&1 | tail -20
```
Expected: build OK.

- [ ] **Step 4: Commit**

```bash
git add ios/Runner/
git commit -m "feat(inbox): canal Swift iOS para document picker + security-scoped bookmarks"
```

---

## Task 7: `InboxBookmarkService` (Dart)

Wrapper Dart sobre el method channel `musa/inbox_bookmark` y persistencia del blob en `shared_preferences`.

**Files:**
- Create: `lib/modules/inbox/services/inbox_bookmark_service.dart`

- [ ] **Step 1: Implementar el servicio**

Crear `lib/modules/inbox/services/inbox_bookmark_service.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InboxBookmarkResult {
  const InboxBookmarkResult({required this.path, required this.bookmark});
  final String path;
  final Uint8List bookmark;
}

class InboxBookmarkResolution {
  const InboxBookmarkResolution({required this.path, required this.stale});
  final String path;
  final bool stale;
}

/// Servicio cross-platform para abrir un picker de carpeta y persistir el
/// security-scoped bookmark.
class InboxBookmarkService {
  InboxBookmarkService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('musa/inbox_bookmark');

  final MethodChannel _channel;

  static const String _prefsKey = 'inbox.bookmark.v1';
  static const String _prefsPathKey = 'inbox.bookmark.path.v1';

  bool get isPlatformSupported => Platform.isMacOS || Platform.isIOS;

  /// Lanza el picker nativo. Devuelve null si el usuario cancela.
  Future<InboxBookmarkResult?> pickFolder() async {
    if (!isPlatformSupported) return null;
    final raw = await _channel.invokeMethod<dynamic>('pickFolder');
    if (raw == null) return null;
    final m = Map<String, dynamic>.from(raw as Map);
    final blob = m['bookmark'];
    final path = m['path'] as String;
    final bytes = blob is Uint8List
        ? blob
        : Uint8List.fromList((blob as List).cast<int>());
    return InboxBookmarkResult(path: path, bookmark: bytes);
  }

  /// Resuelve un blob persistido y comienza el acceso security-scoped.
  Future<InboxBookmarkResolution> resolve(Uint8List bookmark) async {
    final raw = await _channel.invokeMethod<dynamic>(
      'resolveBookmark',
      {'bookmark': bookmark},
    );
    final m = Map<String, dynamic>.from(raw as Map);
    return InboxBookmarkResolution(
      path: m['path'] as String,
      stale: m['stale'] as bool,
    );
  }

  Future<void> persist(InboxBookmarkResult bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    // SharedPreferences no soporta Uint8List nativo: serializamos a base64.
    await prefs.setString(_prefsKey, _toBase64(bookmark.bookmark));
    await prefs.setString(_prefsPathKey, bookmark.path);
  }

  Future<InboxBookmarkResolution?> loadAndResolve() async {
    if (!isPlatformSupported) return null;
    final prefs = await SharedPreferences.getInstance();
    final blobB64 = prefs.getString(_prefsKey);
    if (blobB64 == null) return null;
    final bytes = _fromBase64(blobB64);
    try {
      return await resolve(bytes);
    } on PlatformException {
      // Bookmark inválido. Lo dejamos en prefs por si se quiere mostrar el
      // path antiguo, pero no resolvemos.
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_prefsPathKey);
  }

  Future<String?> lastKnownPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsPathKey);
  }

  static String _toBase64(Uint8List bytes) =>
      // ignore: prefer_collection_literals
      const Base64Encoder().convert(bytes);
  static Uint8List _fromBase64(String s) =>
      Uint8List.fromList(const Base64Decoder().convert(s));
}
```

- [ ] **Step 2: Smoke test (compila al menos)**

```bash
flutter analyze lib/modules/inbox/services/inbox_bookmark_service.dart
```
Expected: `No issues found!` o sólo warnings menores.

- [ ] **Step 3: Commit**

```bash
git add lib/modules/inbox/services/inbox_bookmark_service.dart
git commit -m "feat(inbox): InboxBookmarkService — picker + persistencia base64 del bookmark"
```

---

## Task 8: Providers Riverpod

Tres providers con responsabilidades separadas: la carpeta y su estado, las capturas pendientes (Mac), y el historial del iPhone.

**Files:**
- Create: `lib/modules/inbox/providers/inbox_folder_provider.dart`
- Create: `lib/modules/inbox/providers/inbox_captures_provider.dart`
- Create: `lib/modules/inbox/providers/inbox_history_provider.dart`

- [ ] **Step 1: `inbox_folder_provider.dart`**

Crear `lib/modules/inbox/providers/inbox_folder_provider.dart`:

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/services/inbox_bookmark_service.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';

enum InboxFolderHealth { unconfigured, healthy, unreachable }

class InboxFolderState {
  const InboxFolderState({
    required this.health,
    this.path,
  });
  final InboxFolderHealth health;
  final String? path;
}

final inboxBookmarkServiceProvider =
    Provider<InboxBookmarkService>((ref) => InboxBookmarkService());

class InboxFolderNotifier extends StateNotifier<InboxFolderState> {
  InboxFolderNotifier(this._bookmarks)
      : super(const InboxFolderState(health: InboxFolderHealth.unconfigured)) {
    _initialize();
  }

  final InboxBookmarkService _bookmarks;

  Future<void> _initialize() async {
    final resolved = await _bookmarks.loadAndResolve();
    if (resolved == null) {
      final lastPath = await _bookmarks.lastKnownPath();
      state = InboxFolderState(
        health: lastPath == null
            ? InboxFolderHealth.unconfigured
            : InboxFolderHealth.unreachable,
        path: lastPath,
      );
      return;
    }
    state = InboxFolderState(
      health: InboxFolderHealth.healthy,
      path: resolved.path,
    );
  }

  Future<bool> chooseNewFolder() async {
    final picked = await _bookmarks.pickFolder();
    if (picked == null) return false;
    await _bookmarks.persist(picked);
    state = InboxFolderState(
      health: InboxFolderHealth.healthy,
      path: picked.path,
    );
    return true;
  }

  Future<void> recheck() => _initialize();
}

final inboxFolderProvider =
    StateNotifierProvider<InboxFolderNotifier, InboxFolderState>(
  (ref) => InboxFolderNotifier(ref.watch(inboxBookmarkServiceProvider)),
);

/// Storage construido sobre la carpeta actual.
/// Devuelve null si la carpeta no es saludable.
final inboxStorageProvider = Provider<InboxStorageService?>((ref) {
  final folder = ref.watch(inboxFolderProvider);
  if (folder.health != InboxFolderHealth.healthy || folder.path == null) {
    return null;
  }
  return InboxStorageService(rootDirectory: Directory(folder.path!));
});
```

- [ ] **Step 2: `inbox_captures_provider.dart`**

Crear `lib/modules/inbox/providers/inbox_captures_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';

/// Tick que fuerza recarga; se incrementa al pull-to-refresh, al detectar
/// FSEvent en Mac, o tras una acción (aceptar/descartar).
final inboxRefreshTickProvider = StateProvider<int>((_) => 0);

void bumpInboxRefreshTick(WidgetRef ref) {
  ref.read(inboxRefreshTickProvider.notifier).state++;
}

/// Capturas pendientes (sólo `MUSA-Inbox/<fecha>/`), ordenadas por
/// `capturedAt` desc. Sólo poblado cuando la carpeta es healthy.
final inboxPendingCapturesProvider =
    FutureProvider<List<InboxCaptureRecord>>((ref) async {
  ref.watch(inboxRefreshTickProvider);
  final storage = ref.watch(inboxStorageProvider);
  if (storage == null) return const [];
  final list = await storage.readPending();
  list.sort((a, b) {
    final ac = a.capture?.capturedAt;
    final bc = b.capture?.capturedAt;
    if (ac == null || bc == null) return 0;
    return bc.compareTo(ac);
  });
  return list;
});
```

- [ ] **Step 3: `inbox_history_provider.dart`**

Crear `lib/modules/inbox/providers/inbox_history_provider.dart`:

```dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kHistoryUuidsKey = 'inbox.history.uuids.v1';

/// Set de UUIDs que ESTE dispositivo escribió.
class HistoryCacheNotifier extends StateNotifier<Set<String>> {
  HistoryCacheNotifier() : super(const <String>{}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHistoryUuidsKey);
    if (raw == null) return;
    state = (jsonDecode(raw) as List).map((e) => e as String).toSet();
  }

  Future<void> add(String id) async {
    state = {...state, id};
    await _persist();
  }

  /// Purga: deja sólo los UUIDs cuyos archivos siguen existiendo en el FS.
  Future<void> reconcile(Iterable<String> aliveIds) async {
    final alive = aliveIds.toSet();
    final next = state.intersection(alive);
    if (next.length == state.length) return;
    state = next;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHistoryUuidsKey, jsonEncode(state.toList()));
  }
}

final inboxHistoryCacheProvider =
    StateNotifierProvider<HistoryCacheNotifier, Set<String>>(
  (_) => HistoryCacheNotifier(),
);

/// Capturas escritas por ESTE dispositivo, con su estado actual en el FS.
/// Ordenadas por `capturedAt` desc. Limitado a los últimos N items.
final inboxHistoryProvider =
    FutureProvider<List<InboxCaptureRecord>>((ref) async {
  ref.watch(inboxRefreshTickProvider);
  final storage = ref.watch(inboxStorageProvider);
  final cache = ref.watch(inboxHistoryCacheProvider);
  if (storage == null) return const [];
  final all = await storage.readAll();
  final aliveIds = all.map((r) => r.capture?.id).whereType<String>().toSet();
  // Purga del cache de UUIDs que ya no existen en el FS.
  ref.read(inboxHistoryCacheProvider.notifier).reconcile(aliveIds);
  final mine = all.where((r) {
    final id = r.capture?.id;
    return id != null && cache.contains(id);
  }).toList();
  mine.sort((a, b) =>
      b.capture!.capturedAt.compareTo(a.capture!.capturedAt));
  return mine;
});
```

- [ ] **Step 4: Verificar análisis**

```bash
flutter analyze lib/modules/inbox/
```
Expected: `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/modules/inbox/providers/
git commit -m "feat(inbox): providers Riverpod (folder, captures, history)"
```

---

## Task 9: Hook en `NarrativeWorkspaceNotifier` — `addNoteFromInbox`

**Files:**
- Modify: `lib/modules/books/providers/workspace_providers.dart`

- [ ] **Step 1: Lectura del archivo**

```bash
grep -n "Future<void> createNote" lib/modules/books/providers/workspace_providers.dart
```
Expected: línea 512.

- [ ] **Step 2: Añadir método `addNoteFromInbox`**

En `lib/modules/books/providers/workspace_providers.dart`, justo después del método `createNote` (línea ~541), añadir:

```dart
  /// Crea una `Note` cuyo origen es una captura del inbox.
  ///
  /// La nota llega a la bandeja del libro activo con `kind = NoteKind.loose`
  /// y `status = NoteStatus.inbox`. El `body` es lo que el usuario aceptó
  /// (texto, o texto + URL si era kind=link). El `title` se infiere de la
  /// primera línea no vacía si existe.
  Future<Note?> addNoteFromInbox({
    required String body,
    required String? url,
    required DateTime capturedAt,
    required String deviceLabel,
  }) async {
    final workspace = state.value;
    final activeBook = workspace?.activeBook;
    if (workspace == null || activeBook == null) return null;

    final fullContent = url == null || url.isEmpty
        ? body
        : (body.isEmpty ? url : '$body\n\n$url');

    final inferredTitle = fullContent
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '')
        .let((s) => s.length > 80 ? '${s.substring(0, 77)}…' : s);

    final now = DateTime.now();
    final newNote = Note(
      id: generateEntityId('note'),
      bookId: activeBook.id,
      title: inferredTitle.isEmpty ? null : inferredTitle,
      content: fullContent,
      kind: NoteKind.loose,
      status: NoteStatus.inbox,
      createdAt: capturedAt,
      updatedAt: now,
    );

    await _persist(
      workspace.copyWith(
        notes: [...workspace.notes, newNote],
        books: _touchActiveBook(workspace.books, activeBook.id, now),
      ),
    );
    return newNote;
  }
```

- [ ] **Step 3: Helper `let` extension (si no existe)**

Si `flutter analyze` da error sobre `.let` (es probable que no exista), añadir esta extension al final del archivo o reescribir sin ella. Cambio mínimo: NO añadir extension, reemplazar el bloque `inferredTitle` por:

```dart
    String inferredTitle = '';
    for (final raw in fullContent.split('\n')) {
      final line = raw.trim();
      if (line.isNotEmpty) {
        inferredTitle = line.length > 80 ? '${line.substring(0, 77)}…' : line;
        break;
      }
    }
```

- [ ] **Step 4: Verificar análisis**

```bash
flutter analyze lib/modules/books/providers/workspace_providers.dart
```
Expected: `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/modules/books/providers/workspace_providers.dart
git commit -m "feat(notes): NarrativeWorkspaceNotifier.addNoteFromInbox para integrar capturas"
```

---

## Task 10: iPhone — `CaptureScreen`

**Files:**
- Create: `lib/ui/inbox/iphone/capture_screen.dart`

- [ ] **Step 1: Implementar el widget**

Crear `lib/ui/inbox/iphone/capture_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/models/inbox_capture.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_history_provider.dart';
import 'package:musa/modules/inbox/services/kind_detector_service.dart';
import 'package:musa/shared/utils/id_generator.dart' show generateEntityId;
import 'package:uuid/uuid.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _detector = const KindDetectorService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text;
    if (text.trim().isEmpty || _saving) return;
    final storage = ref.read(inboxStorageProvider);
    if (storage == null) {
      _showSnack('Sin carpeta configurada');
      return;
    }
    setState(() => _saving = true);
    try {
      final det = _detector.detect(text);
      final capture = InboxCapture(
        schemaVersion: 1,
        id: const Uuid().v4(),
        capturedAt: DateTime.now().toUtc(),
        deviceLabel: 'iPhone', // refinable desde Settings (Task 13)
        kind: det.kind,
        body: det.body,
        url: det.url,
      );
      await storage.write(capture);
      await ref.read(inboxHistoryCacheProvider.notifier).add(capture.id);
      bumpInboxRefreshTick(ref);
      if (!mounted) return;
      _controller.clear();
      _showSnack('✓ Guardado a la bandeja');
      _focus.requestFocus();
    } catch (e) {
      _showSnack('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final folder = ref.watch(inboxFolderProvider);
    final detection = _detector.detect(_controller.text);
    final canSave = _controller.text.trim().isNotEmpty &&
        folder.health == InboxFolderHealth.healthy &&
        !_saving;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(folderHealth: folder.health),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    TextField(
                      controller: _controller,
                      focusNode: _focus,
                      maxLines: null,
                      expands: true,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Una idea, un link, una frase…',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 17, height: 1.5),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _KindChip(
                          kind: _controller.text.isEmpty ? null : detection.kind),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton(
                onPressed: canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar a la bandeja'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.folderHealth});
  final InboxFolderHealth folderHealth;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (folderHealth) {
      InboxFolderHealth.healthy => (Colors.green, 'Sincronizado'),
      InboxFolderHealth.unreachable => (Colors.red, 'Sin carpeta'),
      InboxFolderHealth.unconfigured => (Colors.orange, 'Configurar'),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          const Text('Capturar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({this.kind});
  final InboxCaptureKind? kind;

  @override
  Widget build(BuildContext context) {
    if (kind == null) return const SizedBox.shrink();
    final (icon, label) = switch (kind!) {
      InboxCaptureKind.text => ('📝', 'texto'),
      InboxCaptureKind.link => ('🔗', 'link'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text('$icon $label',
          style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
    );
  }
}
```

- [ ] **Step 2: Verificar análisis**

```bash
flutter analyze lib/ui/inbox/iphone/capture_screen.dart
```
Expected: `No issues found!`.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/inbox/iphone/capture_screen.dart
git commit -m "feat(inbox): iPhone CaptureScreen con auto-focus y detección de kind"
```

---

## Task 11: iPhone — `HistoryScreen`

**Files:**
- Create: `lib/ui/inbox/iphone/history_screen.dart`

- [ ] **Step 1: Implementar widget**

Crear `lib/ui/inbox/iphone/history_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/models/inbox_capture.dart';
import 'package:musa/modules/inbox/models/inbox_capture_status.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_history_provider.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(inboxHistoryProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Historial',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  bumpInboxRefreshTick(ref);
                  // Esperar a que el FutureProvider re-resuelva.
                  await ref.read(inboxHistoryProvider.future);
                },
                child: asyncHistory.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _Error(error: e.toString()),
                  data: (records) => records.isEmpty
                      ? _Empty()
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: records.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _HistoryItem(record: records[i]),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.record});
  final InboxCaptureRecord record;

  @override
  Widget build(BuildContext context) {
    final c = record.capture;
    if (c == null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('⚠️ Captura ilegible',
            style: TextStyle(color: Colors.red)),
      );
    }
    final (statusColor, statusText) = switch (record.status) {
      InboxCaptureStatus.pending => (Colors.orange, 'Pendiente'),
      InboxCaptureStatus.processed => (Colors.green, 'Procesada'),
      InboxCaptureStatus.discarded => (Colors.grey, 'Descartada'),
      InboxCaptureStatus.unreadable => (Colors.red, 'Ilegible'),
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _formatLocal(c.capturedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 8),
              _KindLabel(kind: c.kind),
              const Spacer(),
              Text(statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            c.body.isEmpty && c.url != null ? c.url! : c.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatLocal(DateTime utc) {
    final l = utc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}

class _KindLabel extends StatelessWidget {
  const _KindLabel({required this.kind});
  final InboxCaptureKind kind;

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (kind) {
      InboxCaptureKind.text => ('📝', 'texto'),
      InboxCaptureKind.link => ('🔗', 'link'),
    };
    return Text('$icon $text',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600));
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      // necesario para RefreshIndicator
      children: const [
        SizedBox(height: 96),
        Center(child: Text('Aún no hay capturas en este dispositivo.')),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('No se pudo cargar el historial:\n$error',
            textAlign: TextAlign.center),
      ),
    );
  }
}
```

- [ ] **Step 2: Análisis y commit**

```bash
flutter analyze lib/ui/inbox/iphone/history_screen.dart
```
Expected: `No issues found!`.

```bash
git add lib/ui/inbox/iphone/history_screen.dart
git commit -m "feat(inbox): iPhone HistoryScreen con pull-to-refresh y estados visuales"
```

---

## Task 12: iPhone — `OnboardingScreen`

**Files:**
- Create: `lib/ui/inbox/iphone/onboarding_screen.dart`

- [ ] **Step 1: Implementar onboarding**

Crear `lib/ui/inbox/iphone/onboarding_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';

class InboxOnboardingScreen extends ConsumerStatefulWidget {
  const InboxOnboardingScreen({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  ConsumerState<InboxOnboardingScreen> createState() =>
      _InboxOnboardingScreenState();
}

class _InboxOnboardingScreenState
    extends ConsumerState<InboxOnboardingScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _choose() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await ref.read(inboxFolderProvider.notifier).chooseNewFolder();
      if (ok && mounted) widget.onCompleted?.call();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text('MUSA Capturar',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text(
                'Guarda tus ideas en una carpeta que tú elijas — puede '
                'estar en iCloud, Drive, OneDrive, Dropbox… cualquier '
                'servicio de sync que ya uses.\n\n'
                'Tus capturas son archivos .json que tú controlas. MUSA '
                'no habla con ningún servicio en la nube.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              const Spacer(),
              if (_error != null) ...[
                Text(_error!,
                    style: TextStyle(color: Colors.red.shade700)),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _choose,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Elegir carpeta'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Análisis y commit**

```bash
flutter analyze lib/ui/inbox/iphone/onboarding_screen.dart
```

```bash
git add lib/ui/inbox/iphone/onboarding_screen.dart
git commit -m "feat(inbox): iPhone OnboardingScreen para elegir carpeta sincronizada"
```

---

## Task 13: iPhone — Settings de Bandeja

**Files:**
- Create: `lib/ui/inbox/iphone/inbox_settings_screen.dart`

- [ ] **Step 1: Implementar settings**

Crear `lib/ui/inbox/iphone/inbox_settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kInboxDeviceLabelKey = 'inbox.deviceLabel.v1';
const String kInboxHistoryLimitKey = 'inbox.historyLimit.v1';

final inboxDeviceLabelProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(kInboxDeviceLabelKey) ?? 'iPhone';
});

final inboxHistoryLimitProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(kInboxHistoryLimitKey) ?? 20;
});

class InboxSettingsScreen extends ConsumerStatefulWidget {
  const InboxSettingsScreen({super.key});

  @override
  ConsumerState<InboxSettingsScreen> createState() =>
      _InboxSettingsScreenState();
}

class _InboxSettingsScreenState extends ConsumerState<InboxSettingsScreen> {
  late TextEditingController _label;
  int _limit = 20;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _label.text = prefs.getString(kInboxDeviceLabelKey) ?? 'iPhone';
      _limit = prefs.getInt(kInboxHistoryLimitKey) ?? 20;
      _ready = true;
    });
  }

  Future<void> _saveLabel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kInboxDeviceLabelKey, _label.text.trim());
    ref.invalidate(inboxDeviceLabelProvider);
  }

  Future<void> _saveLimit(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kInboxHistoryLimitKey, v);
    setState(() => _limit = v);
    ref.invalidate(inboxHistoryLimitProvider);
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folder = ref.watch(inboxFolderProvider);
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Bandeja')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Carpeta sincronizada',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(folder.path ?? 'Sin configurar',
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                ref.read(inboxFolderProvider.notifier).chooseNewFolder(),
            child: const Text('Cambiar carpeta…'),
          ),
          const Divider(height: 32),
          const Text('Etiqueta de este dispositivo',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          TextField(
            controller: _label,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onEditingComplete: _saveLabel,
            onTapOutside: (_) => _saveLabel(),
          ),
          const Divider(height: 32),
          const Text('Capturas en historial',
              style: TextStyle(fontWeight: FontWeight.w700)),
          Slider(
            value: _limit.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            label: _limit.toString(),
            onChanged: (v) => setState(() => _limit = v.toInt()),
            onChangeEnd: (v) => _saveLimit(v.toInt()),
          ),
          Text('Mostrar las $_limit capturas más recientes.'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Reflejar `deviceLabel` en `CaptureScreen`**

Volver a `lib/ui/inbox/iphone/capture_screen.dart` y reemplazar la línea:
```dart
deviceLabel: 'iPhone', // refinable desde Settings (Task 13)
```
por:
```dart
deviceLabel: ref.read(inboxDeviceLabelProvider).valueOrNull ?? 'iPhone',
```
y añadir el import:
```dart
import 'package:musa/ui/inbox/iphone/inbox_settings_screen.dart';
```

- [ ] **Step 3: Análisis y commit**

```bash
flutter analyze lib/ui/inbox/iphone/
```

```bash
git add lib/ui/inbox/iphone/
git commit -m "feat(inbox): Settings de Bandeja en iPhone (carpeta, etiqueta, límite historial)"
```

---

## Task 14: Modificación de `CaptureToolShell`

**Files:**
- Modify: `lib/app/shells/iphone/capture_tool_shell.dart`

- [ ] **Step 1: Reemplazar el archivo**

Sobreescribir `lib/app/shells/iphone/capture_tool_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/ui/inbox/iphone/capture_screen.dart';
import 'package:musa/ui/inbox/iphone/history_screen.dart';
import 'package:musa/ui/inbox/iphone/onboarding_screen.dart';
import 'package:musa/ui/inbox/iphone/inbox_settings_screen.dart';

/// Shell del iPhone para Ola 1 — "MUSA Capturar".
///
/// Los tabs históricos (Biblioteca, Documento) están ocultos en Ola 1; sólo
/// se exponen Capturar e Historial. La pantalla de onboarding aparece si no
/// hay carpeta configurada.
class CaptureToolShell extends ConsumerStatefulWidget {
  const CaptureToolShell({super.key});

  @override
  ConsumerState<CaptureToolShell> createState() => _CaptureToolShellState();
}

class _CaptureToolShellState extends ConsumerState<CaptureToolShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final folder = ref.watch(inboxFolderProvider);
    if (folder.health == InboxFolderHealth.unconfigured) {
      return InboxOnboardingScreen(onCompleted: () => setState(() {}));
    }
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          CaptureScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Capturar',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'inbox-settings',
        tooltip: 'Ajustes de la bandeja',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const InboxSettingsScreen()),
        ),
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}
```

- [ ] **Step 2: Tests existentes deben seguir pasando**

```bash
flutter test 2>&1 | tail -5
```
Expected: `All tests passed!` o el mismo número de fallos pre-existentes (si los hay), pero SIN nuevos fallos. Si aparece un fallo nuevo en `widget_test.dart` revisar.

- [ ] **Step 3: Commit**

```bash
git add lib/app/shells/iphone/capture_tool_shell.dart
git commit -m "refactor(shell): CaptureToolShell pasa a 2 tabs (Capturar, Historial) para Ola 1"
```

---

## Task 15: Mac — `InboxToolbarButton`

**Files:**
- Create: `lib/ui/inbox/popover/inbox_toolbar_button.dart`
- Modify: `lib/ui/layout/main_screen.dart` (1 línea + 1 import)

- [ ] **Step 1: Crear el botón con badge**

Crear `lib/ui/inbox/popover/inbox_toolbar_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/ui/inbox/popover/inbox_popover.dart';

/// Botón de la bandeja en la toolbar del Studio Shell. Abre el popover.
class InboxToolbarButton extends ConsumerWidget {
  const InboxToolbarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folder = ref.watch(inboxFolderProvider);
    final asyncCaps = ref.watch(inboxPendingCapturesProvider);
    final unreachable = folder.health == InboxFolderHealth.unreachable;
    final unconfigured = folder.health == InboxFolderHealth.unconfigured;

    return MenuAnchor(
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 18,
                      color: unreachable
                          ? Colors.red.shade700
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    if (unreachable)
                      const Positioned(
                        right: -4, top: -2,
                        child: Icon(Icons.error, size: 12, color: Colors.red),
                      )
                    else
                      asyncCaps.maybeWhen(
                        orElse: () => const SizedBox.shrink(),
                        data: (caps) => caps.isEmpty
                            ? const SizedBox.shrink()
                            : Positioned(
                                right: -6, top: -4,
                                child: _Badge(text: caps.length.toString()),
                              ),
                      ),
                  ],
                ),
                if (unconfigured) ...[
                  const SizedBox(width: 6),
                  const Text('Configurar bandeja',
                      style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
        );
      },
      menuChildren: [
        SizedBox(
          width: 320,
          child: InboxPopover(),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}
```

- [ ] **Step 2: Insertar el botón en `main_screen.dart`**

Editar `lib/ui/layout/main_screen.dart`. Buscar el `Row(...)` derecho del `_buildTopBar` (línea ~381):

```dart
          Row(
            children: [
              _WorkspaceSaveIndicator(status: persistenceStatus),
```

Reemplazarlo por (añade el botón ANTES del save indicator):

```dart
          Row(
            children: [
              const InboxToolbarButton(),
              const SizedBox(width: 8),
              _WorkspaceSaveIndicator(status: persistenceStatus),
```

Añadir el import al inicio del archivo (junto a otros imports `lib/ui/...`):

```dart
import '../inbox/popover/inbox_toolbar_button.dart';
```

- [ ] **Step 3: Análisis**

```bash
flutter analyze lib/ui/layout/main_screen.dart lib/ui/inbox/popover/
```
Expected: `No issues found!`.

- [ ] **Step 4: Commit (sin popover aún funcional)**

```bash
git add lib/ui/inbox/popover/inbox_toolbar_button.dart lib/ui/layout/main_screen.dart
git commit -m "feat(inbox): botón de bandeja en toolbar del Mac (placeholder hasta popover)"
```

---

## Task 16: Mac — `InboxPopover`

**Files:**
- Create: `lib/ui/inbox/popover/inbox_popover.dart`

- [ ] **Step 1: Implementar el popover**

Crear `lib/ui/inbox/popover/inbox_popover.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';
import 'package:musa/ui/inbox/window/inbox_management_screen.dart';
import 'package:musa/ui/inbox/window/widgets/capture_actions.dart';

class InboxPopover extends ConsumerWidget {
  const InboxPopover({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folder = ref.watch(inboxFolderProvider);
    final asyncCaps = ref.watch(inboxPendingCapturesProvider);

    if (folder.health == InboxFolderHealth.unconfigured) {
      return _ConfigurePrompt(ref: ref);
    }
    if (folder.health == InboxFolderHealth.unreachable) {
      return _UnreachablePrompt(ref: ref, lastPath: folder.path);
    }

    return asyncCaps.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Error: $e'),
      ),
      data: (caps) {
        if (caps.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('No hay capturas pendientes.')),
          );
        }
        final visible = caps.take(5).toList();
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Text('Capturas pendientes (${caps.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              for (final r in visible)
                _CapturePopoverRow(record: r),
              const Divider(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => const InboxManagementScreen(),
                    ),
                  );
                },
                child: Text('Ver todas (${caps.length}) →'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CapturePopoverRow extends ConsumerWidget {
  const _CapturePopoverRow({required this.record});
  final InboxCaptureRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = record.capture;
    if (c == null) {
      return const ListTile(title: Text('⚠️ Captura ilegible'));
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_kindEmoji(c.kind)} ${_short(c.body, c.url, 80)}',
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => CaptureActions.accept(ref, record),
                style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28), padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: const Text('Aceptar', style: TextStyle(fontSize: 11)),
              ),
              TextButton(
                onPressed: () => CaptureActions.discard(ref, record),
                style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28), padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: const Text('Descartar', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _kindEmoji(k) => k.toString().endsWith('link') ? '🔗' : '📝';
  String _short(String body, String? url, int max) {
    final s = body.isEmpty && url != null ? url : body;
    return s.length <= max ? s : '${s.substring(0, max - 1)}…';
  }
}

class _ConfigurePrompt extends StatelessWidget {
  const _ConfigurePrompt({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Configura la carpeta de la bandeja para empezar.',
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                ref.read(inboxFolderProvider.notifier).chooseNewFolder(),
            child: const Text('Elegir carpeta…'),
          ),
        ],
      ),
    );
  }
}

class _UnreachablePrompt extends StatelessWidget {
  const _UnreachablePrompt({required this.ref, this.lastPath});
  final WidgetRef ref;
  final String? lastPath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 28),
          const SizedBox(height: 8),
          const Text('Bandeja desconectada',
              style: TextStyle(fontWeight: FontWeight.w700)),
          if (lastPath != null) ...[
            const SizedBox(height: 4),
            Text(lastPath!,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ref.read(inboxFolderProvider.notifier).recheck(),
            child: const Text('Reintentar'),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () =>
                ref.read(inboxFolderProvider.notifier).chooseNewFolder(),
            child: const Text('Reconfigurar carpeta…'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Análisis (faltarán imports a Task 17/18)**

```bash
flutter analyze lib/ui/inbox/popover/inbox_popover.dart 2>&1 | head -10
```
Expected: warnings sobre imports a `inbox_management_screen.dart` y `capture_actions.dart` (que aún no existen — se crean en Task 17/18). **No commitear todavía**.

---

## Task 17: Mac — `InboxManagementScreen`

**Files:**
- Create: `lib/ui/inbox/window/inbox_management_screen.dart`
- Create: `lib/ui/inbox/window/widgets/capture_list_item.dart`
- Create: `lib/ui/inbox/window/widgets/capture_detail_panel.dart`

- [ ] **Step 1: `InboxManagementScreen`**

Crear `lib/ui/inbox/window/inbox_management_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';
import 'package:musa/ui/inbox/window/widgets/capture_list_item.dart';
import 'package:musa/ui/inbox/window/widgets/capture_detail_panel.dart';

final inboxSelectedRecordIndexProvider = StateProvider<int?>((_) => null);

class InboxManagementScreen extends ConsumerWidget {
  const InboxManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCaps = ref.watch(inboxPendingCapturesProvider);
    final selectedIdx = ref.watch(inboxSelectedRecordIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandeja de capturas'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: asyncCaps.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (caps) {
          if (caps.isEmpty) {
            return const Center(child: Text('No hay capturas pendientes.'));
          }
          final selected = (selectedIdx != null && selectedIdx < caps.length)
              ? caps[selectedIdx]
              : null;
          return Row(
            children: [
              SizedBox(
                width: 320,
                child: ListView.separated(
                  itemCount: caps.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => CaptureListItem(
                    record: caps[i],
                    selected: selectedIdx == i,
                    onTap: () => ref
                        .read(inboxSelectedRecordIndexProvider.notifier)
                        .state = i,
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: selected == null
                    ? const Center(child: Text('Selecciona una captura'))
                    : CaptureDetailPanel(record: selected),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: `CaptureListItem`**

Crear `lib/ui/inbox/window/widgets/capture_list_item.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:musa/modules/inbox/models/inbox_capture.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';

class CaptureListItem extends StatelessWidget {
  const CaptureListItem({
    super.key,
    required this.record,
    required this.selected,
    required this.onTap,
  });
  final InboxCaptureRecord record;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = record.capture;
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primary.withOpacity(0.08) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: c == null
              ? const Text('⚠️ Captura ilegible')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(_kindLabel(c.kind),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(_when(c.capturedAt),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700)),
                    ]),
                    const SizedBox(height: 6),
                    Text(_preview(c),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(c.deviceLabel,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600)),
                  ],
                ),
        ),
      ),
    );
  }

  String _kindLabel(InboxCaptureKind k) =>
      k == InboxCaptureKind.link ? '🔗 link' : '📝 texto';

  String _preview(InboxCapture c) =>
      c.body.isEmpty && c.url != null ? c.url! : c.body;

  String _when(DateTime utc) {
    final l = utc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}
```

- [ ] **Step 3: `CaptureDetailPanel` (sin acciones aún — Task 18 las añade)**

Crear `lib/ui/inbox/window/widgets/capture_detail_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';

class CaptureDetailPanel extends ConsumerStatefulWidget {
  const CaptureDetailPanel({super.key, required this.record});
  final InboxCaptureRecord record;

  @override
  ConsumerState<CaptureDetailPanel> createState() =>
      _CaptureDetailPanelState();
}

class _CaptureDetailPanelState extends ConsumerState<CaptureDetailPanel> {
  late TextEditingController _editController;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _editController =
        TextEditingController(text: widget.record.capture?.body ?? '');
  }

  @override
  void didUpdateWidget(CaptureDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.path != widget.record.path) {
      _editController.text = widget.record.capture?.body ?? '';
      _editing = false;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.record.capture;
    if (c == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ Captura ilegible',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.red)),
            const SizedBox(height: 12),
            if (widget.record.parseError != null)
              Text(widget.record.parseError!,
                  style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            if (widget.record.rawContent != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade100,
                child: SelectableText(widget.record.rawContent!,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ),
            // Las acciones (Descartar) se conectan en Task 18.
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(c.deviceLabel,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(width: 8),
            Text('· ${c.capturedAt.toLocal()}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          if (c.url != null) ...[
            SelectableText(c.url!,
                style: TextStyle(color: Colors.blue.shade800)),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: _editing
                ? TextField(
                    controller: _editController,
                    maxLines: null,
                    expands: true,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  )
                : SelectableText(
                    c.body.isEmpty ? '(sin texto adicional)' : c.body,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
          ),
          const SizedBox(height: 12),
          // Las acciones se conectan en Task 18 desde un widget aparte.
          _DetailActionsHook(
            record: widget.record,
            editing: _editing,
            editedBody: _editController.text,
            onToggleEdit: () =>
                setState(() => _editing = !_editing),
            onCancelEdit: () => setState(() {
              _editController.text = c.body;
              _editing = false;
            }),
          ),
        ],
      ),
    );
  }
}

class _DetailActionsHook extends StatelessWidget {
  const _DetailActionsHook({
    required this.record,
    required this.editing,
    required this.editedBody,
    required this.onToggleEdit,
    required this.onCancelEdit,
  });
  final InboxCaptureRecord record;
  final bool editing;
  final String editedBody;
  final VoidCallback onToggleEdit;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    // Implementación real se conecta en Task 18 (CaptureActions).
    return Wrap(
      spacing: 8,
      children: [
        FilledButton(onPressed: null, child: const Text('Aceptar como nota')),
        if (!editing)
          OutlinedButton(onPressed: onToggleEdit, child: const Text('Expandir y editar'))
        else ...[
          OutlinedButton(onPressed: onCancelEdit, child: const Text('Cancelar')),
          FilledButton(onPressed: null, child: const Text('Guardar y aceptar')),
        ],
        TextButton(onPressed: null, child: const Text('Descartar')),
      ],
    );
  }
}
```

- [ ] **Step 4: Análisis intermedio**

```bash
flutter analyze lib/ui/inbox/window/
```
Expected: warnings sobre `capture_actions.dart` no existe aún. OK por ahora.

---

## Task 18: Mac — Acciones del detalle (`CaptureActions`)

**Files:**
- Create: `lib/ui/inbox/window/widgets/capture_actions.dart`
- Modify: `lib/ui/inbox/window/widgets/capture_detail_panel.dart`

- [ ] **Step 1: Crear el helper de acciones**

Crear `lib/ui/inbox/window/widgets/capture_actions.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/books/providers/workspace_providers.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';

class CaptureActions {
  static Future<void> accept(WidgetRef ref, InboxCaptureRecord record,
      {String? editedBody}) async {
    final c = record.capture;
    if (c == null) return;
    final storage = ref.read(inboxStorageProvider);
    if (storage == null) return;

    final body = (editedBody ?? c.body);
    await ref
        .read(narrativeWorkspaceProvider.notifier)
        .addNoteFromInbox(
          body: body,
          url: c.url,
          capturedAt: c.capturedAt,
          deviceLabel: c.deviceLabel,
        );
    await storage.markProcessed(File(record.path));
    bumpInboxRefreshTick(ref);
  }

  static Future<void> discard(WidgetRef ref, InboxCaptureRecord record) async {
    final storage = ref.read(inboxStorageProvider);
    if (storage == null) return;
    await storage.markDiscarded(File(record.path));
    bumpInboxRefreshTick(ref);
  }
}
```

- [ ] **Step 2: Conectar los botones en `CaptureDetailPanel`**

Editar `lib/ui/inbox/window/widgets/capture_detail_panel.dart`. Reemplazar la clase `_DetailActionsHook` por:

```dart
class _DetailActionsHook extends ConsumerWidget {
  const _DetailActionsHook({
    required this.record,
    required this.editing,
    required this.editedBody,
    required this.onToggleEdit,
    required this.onCancelEdit,
  });
  final InboxCaptureRecord record;
  final bool editing;
  final String editedBody;
  final VoidCallback onToggleEdit;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      children: [
        if (!editing) ...[
          FilledButton(
            onPressed: () => CaptureActions.accept(ref, record),
            child: const Text('Aceptar como nota'),
          ),
          OutlinedButton(
            onPressed: onToggleEdit,
            child: const Text('Expandir y editar'),
          ),
          TextButton(
            onPressed: () async {
              await CaptureActions.discard(ref, record);
            },
            child: const Text('Descartar'),
          ),
        ] else ...[
          OutlinedButton(
            onPressed: onCancelEdit,
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await CaptureActions.accept(ref, record, editedBody: editedBody);
              onCancelEdit();
            },
            child: const Text('Guardar y aceptar'),
          ),
        ],
      ],
    );
  }
}
```

Y cambiar el import de `package:flutter/material.dart` por:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/ui/inbox/window/widgets/capture_actions.dart';
```

- [ ] **Step 3: Análisis y commit completo de UI Mac**

```bash
flutter analyze lib/ui/inbox/
```
Expected: `No issues found!`.

```bash
git add lib/ui/inbox/popover/inbox_popover.dart lib/ui/inbox/window/
git commit -m "feat(inbox): popover + ventana de gestión Mac con acciones aceptar/expandir/descartar"
```

---

## Task 19: Mac — Watcher FSEvents (debounce 250 ms)

Versión simple: usar `Directory.watch()` que internamente usa FSEvents en macOS. Wrap con debouncer.

**Files:**
- Create: `lib/modules/inbox/services/inbox_watcher_service.dart`
- Modify: `lib/modules/inbox/providers/inbox_folder_provider.dart`

- [ ] **Step 1: Implementar watcher**

Crear `lib/modules/inbox/services/inbox_watcher_service.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Vigila la carpeta `MUSA-Inbox/` (recursivamente sólo donde hace falta) y
/// emite ticks de cambio agregados con debounce.
class InboxWatcherService {
  InboxWatcherService({
    required this.rootDirectory,
    Duration debounce = const Duration(milliseconds: 250),
  })  : _debounce = debounce;

  final Directory rootDirectory;
  final Duration _debounce;

  final _controller = StreamController<void>.broadcast();
  Stream<void> get changes => _controller.stream;

  StreamSubscription<FileSystemEvent>? _sub;
  Timer? _flushTimer;

  Future<void> start() async {
    final inbox = Directory(p.join(rootDirectory.path, 'MUSA-Inbox'));
    if (!inbox.existsSync()) inbox.createSync(recursive: true);

    if (!Platform.isMacOS) {
      // En otras plataformas el watcher es mejor no usarlo en Ola 1.
      return;
    }

    _sub = inbox
        .watch(events: FileSystemEvent.all, recursive: true)
        .listen((_) => _bump());
  }

  Future<void> stop() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await _sub?.cancel();
    _sub = null;
  }

  void _bump() {
    _flushTimer?.cancel();
    _flushTimer = Timer(_debounce, () {
      if (!_controller.isClosed) _controller.add(null);
    });
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
```

- [ ] **Step 2: Cablear el watcher al provider**

Editar `lib/modules/inbox/providers/inbox_folder_provider.dart`. Añadir al final:

```dart
import 'package:musa/modules/inbox/services/inbox_watcher_service.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';

final inboxWatcherProvider = Provider.autoDispose<InboxWatcherService?>((ref) {
  final folder = ref.watch(inboxFolderProvider);
  if (folder.health != InboxFolderHealth.healthy || folder.path == null) {
    return null;
  }
  if (!Platform.isMacOS) return null;
  final watcher = InboxWatcherService(rootDirectory: Directory(folder.path!));
  watcher.start();
  final sub = watcher.changes.listen((_) {
    ref.read(inboxRefreshTickProvider.notifier).state++;
  });
  ref.onDispose(() {
    sub.cancel();
    watcher.dispose();
  });
  return watcher;
});
```

Asegurar que `inboxWatcherProvider` se "instancia" cuando se monta la UI Mac. Para forzar eso, en `main_screen.dart` (en `_MusaMainScreenState.build()`):

```dart
ref.watch(inboxWatcherProvider);
```

(añadir esa línea junto a otros `ref.watch(...)` al principio del `build`).

- [ ] **Step 3: Análisis y commit**

```bash
flutter analyze lib/modules/inbox/ lib/ui/layout/main_screen.dart
git add lib/modules/inbox/services/inbox_watcher_service.dart lib/modules/inbox/providers/inbox_folder_provider.dart lib/ui/layout/main_screen.dart
git commit -m "feat(inbox): watcher FSEvents con debounce 250ms y refresh reactivo del Mac"
```

---

## Task 20: Mac — Atajo `⌘⇧B` + entrada de menú "Ver"

**Files:**
- Modify: `lib/ui/layout/main_screen.dart`

- [ ] **Step 1: Añadir Shortcut + Action**

En `lib/ui/layout/main_screen.dart`, dentro del método `build` del `_MusaMainScreenState`, envolver el `Scaffold` raíz con un `Shortcuts` + `Actions`:

```dart
class _OpenInboxIntent extends Intent {
  const _OpenInboxIntent();
}

// dentro de build:
final scaffold = Scaffold(...); // el ya existente

return Shortcuts(
  shortcuts: <ShortcutActivator, Intent>{
    const SingleActivator(LogicalKeyboardKey.keyB, meta: true, shift: true):
        const _OpenInboxIntent(),
  },
  child: Actions(
    actions: <Type, Action<Intent>>{
      _OpenInboxIntent: CallbackAction<_OpenInboxIntent>(
        onInvoke: (_) {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => const InboxManagementScreen(),
            ),
          );
          return null;
        },
      ),
    },
    child: scaffold,
  ),
);
```

Añadir imports:

```dart
import 'package:flutter/services.dart';
import '../inbox/window/inbox_management_screen.dart';
```

- [ ] **Step 2: (Opcional) Entrada de menú nativo**

Si el Mac tiene menú nativo (típicamente en `macos/Runner/Base.lproj/MainMenu.xib`), añadir un item "Bandeja de capturas" bajo "Ver" que invoque el canal `musa/app_menu` con un nuevo método `showInbox`. En `AppDelegate.swift`:

```swift
@IBAction func showInbox(_ sender: Any?) {
  appMenuChannel?.invokeMethod("showInbox", arguments: nil)
}
```

Y en Dart, en el handler del canal `musa/app_menu` (buscar por `app_menu` en lib/), añadir el case `showInbox` que hace el mismo `Navigator.push` que el shortcut.

> **Nota:** si el setup del menú nativo es complejo, puede aplazarse a Ola 1.5. El atajo `⌘⇧B` y el botón de toolbar son suficientes para Ola 1.

- [ ] **Step 3: Verificación rápida del shortcut**

```bash
flutter run -d macos
```
Comprobar manualmente que `⌘⇧B` abre la ventana de gestión.

- [ ] **Step 4: Commit**

```bash
git add lib/ui/layout/main_screen.dart
git commit -m "feat(inbox): atajo ⌘⇧B abre ventana de gestión de la bandeja"
```

---

## Task 21: Mac — Settings + Onboarding integrados

**Files:**
- Modify: el panel de Settings existente (encontrar dónde está) para añadir una sección "Bandeja"; o crear una entrada accesible desde la toolbar/menu.

- [ ] **Step 1: Localizar el panel de settings**

```bash
grep -rln "showSettings\|SettingsScreen\|AppSettings" lib/ui/ | head -5
```

Identificar el archivo que define la pantalla de settings. Añadir una sección "Bandeja" con:
- Path actual de la carpeta (read-only).
- Botón `Cambiar carpeta…` que llama `inboxFolderProvider.notifier.chooseNewFolder()`.
- Campo para editar la `deviceLabel` de Mac (mismo patrón que el iPhone, almacenado en `SharedPreferences` con key `inbox.deviceLabel.v1`).

> Si no hay panel de settings hoy en Mac (improbable, pero comprobable), aplazar y exponer "Cambiar carpeta…" sólo desde el popover (Task 16 ya lo expone vía `_UnreachablePrompt` y `_ConfigurePrompt`). Marcar como TODO menor en notas, **no como feature crítica**.

- [ ] **Step 2: Onboarding inline**

El popover ya muestra `_ConfigurePrompt` cuando `health == unconfigured`. No hace falta pantalla de onboarding aparte en Mac — basta con ese prompt + el primer click en `Elegir carpeta`.

- [ ] **Step 3: Commit**

```bash
git add <archivos modificados>
git commit -m "feat(inbox): integración settings Mac (sección Bandeja)"
```

---

## Task 22: Verificación final + smoke manual

- [ ] **Step 1: Suite completa**

```bash
flutter test 2>&1 | tail -10
```
Expected: no aumenta el número de tests fallidos respecto al baseline pre-Ola 1. Idealmente el delta es +N (los tests nuevos pasan) sin regresiones.

- [ ] **Step 2: Build macOS**

```bash
flutter build macos --debug
```
Expected: build OK.

- [ ] **Step 3: Build iOS simulator**

```bash
flutter build ios --simulator --no-codesign
```
Expected: build OK.

- [ ] **Step 4: Smoke manual end-to-end**

Escribir un breve checklist y ejecutarlo a mano:

1. Abrir MUSA en Mac (debug). Toolbar muestra botón de bandeja sin badge.
2. Click en bandeja → popover dice "Configura la carpeta…". Click en "Elegir carpeta…".
3. Se abre `NSOpenPanel`. Elegir `~/Documents/MUSA-Test-Inbox/`. Validación OK.
4. Pill de toolbar pasa a verde sin badge (no hay capturas).
5. Lanzar el simulador iOS. Onboarding pide carpeta. Elegir el mismo path (vía Files.app — si está en iCloud Drive, mejor; si es local, el simulador no la sincroniza, así que para el smoke usar la misma ruta absoluta vía "On My iPhone").
6. En iPhone: tab Capturar. Escribir `Diane mira la pizarra. Lo importante es lo que NO está escrito.`. Pill verde. Botón habilitado. Guardar.
7. Toast `✓ Guardado a la bandeja`. Input vaciado. Auto-focus.
8. En Mac: badge debería actualizarse (FSEvents). Click en botón de bandeja.
9. Popover muestra 1 captura. Pulsar `Aceptar`.
10. Verificar que aparece una nota nueva en la bandeja del módulo `notes` del libro activo.
11. Verificar que el archivo se movió a `MUSA-Inbox/processed/`.
12. En iPhone: tab Historial → pull-to-refresh → la captura aparece como `Procesada`.
13. Probar `kind=link`: en iPhone, capturar `https://example.com/foo`. Chip 🔗 visible. Guardar.
14. En Mac: la captura aparece. Click → detalle muestra `https://example.com/foo` como link.
15. Probar `Descartar`: el archivo debe ir a `discarded/`. La captura desaparece de la bandeja del Mac. Historial del iPhone la marca `Descartada`.
16. Probar `Expandir y editar`: capturar texto largo. En Mac → seleccionar → "Expandir y editar" → modificar → "Guardar y aceptar". La nota creada debe contener el texto editado.
17. Probar carpeta inaccesible: cerrar el simulador, mover la carpeta del Mac a otro sitio. Reabrir MUSA → pill rojo, popover dice "Bandeja desconectada", botón "Reconfigurar carpeta…" funciona.

Documentar cualquier fallo en `docs/superpowers/plans/2026-04-25-iphone-captura-bandeja-mac-NOTES.md`.

- [ ] **Step 5: Commit final con notas si las hay**

```bash
git add -A
git commit -m "test(inbox): smoke manual end-to-end Ola 1 — todos los criterios de éxito verificados"
```

---

## Self-Review (hecho por el plan author antes de devolver el plan)

**1. Spec coverage:**
- ✅ Slice A captura iPhone → bandeja Mac: tasks 1-22.
- ✅ Camino 1 (filesystem agnóstico): Task 4 (`InboxStorageService` no depende de provider).
- ✅ Kinds text + link: Tasks 2-3.
- ✅ Bandeja Mac = popover + ventana de gestión: Tasks 16-17.
- ✅ iPhone 2 tabs (Capturar + Historial): Tasks 10-11, 14.
- ✅ Onboarding iPhone: Task 12. Onboarding Mac via popover prompt: Task 21.
- ✅ Detección automática de kind: Task 3.
- ✅ Aceptar como nota / Expandir y editar / Descartar: Task 18.
- ✅ Estados pending/processed/discarded/unreadable: Tasks 2 (enum), 4 (cálculo).
- ✅ Watcher FSEvents Mac con debounce: Task 19.
- ✅ Settings (carpeta, deviceLabel, historyLimit): Task 13 (iPhone) + Task 21 (Mac).
- ✅ NO entra: Voz/Foto/Share Extension/projectHint UI/pickers/multi-select/borrador → no hay tasks para ellos.
- ✅ Acoplamiento mínimo a `.musa` vía `addNoteFromInbox`: Task 9.
- ✅ Ocultar tabs Biblioteca/Documento: Task 14.
- ✅ Ningún refactor en `main_screen.dart`: Task 15 añade UNA línea (`InboxToolbarButton`) y Task 19/20 una más cada uno (`ref.watch(inboxWatcherProvider)`, `Shortcuts`).

**2. Placeholder scan:** No hay TBD/TODO sin sustanciar. Cada paso tiene código real.

**3. Type consistency:**
- `InboxCapture`, `InboxCaptureKind`, `InboxCaptureStatus`, `InboxCaptureRecord` — usados consistentemente.
- `InboxStorageService.markProcessed/markDiscarded/readPending/readAll` — firmas estables a través de tasks.
- `addNoteFromInbox(body, url, capturedAt, deviceLabel)` — signature en Task 9, llamada en Task 18 con los mismos nombres.
- `inboxRefreshTickProvider` y `bumpInboxRefreshTick` — definidos en Task 8, usados en Tasks 10, 18, 19.
- `inboxFolderProvider`, `inboxStorageProvider`, `inboxPendingCapturesProvider`, `inboxHistoryProvider`, `inboxHistoryCacheProvider`, `inboxBookmarkServiceProvider`, `inboxWatcherProvider` — todos definidos antes de su primer uso.

**4. Ambiguities:** Ninguna detectada que afecte a la implementación. Las áreas con cierto margen están explícitamente marcadas como aceptables (entrada de menú nativo opcional, panel de settings Mac dependiente del estado actual del codebase).

Plan listo.
