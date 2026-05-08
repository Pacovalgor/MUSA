# iPhone Capture To Creative Card Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let iPhone captures carry a creative-card intent and let Mac turn inbox captures into rich `CreativeCard`s without marking failed captures as processed.

**Architecture:** Keep the existing inbox folder as the device boundary. Extend `InboxCapture` with optional creative-card metadata, pass that metadata through iPhone capture UI and Mac inbox actions, and reuse `NarrativeWorkspaceNotifier.addCreativeCardFromInbox` as the only workspace mutation path. No workspace sync, media manager, audio playback, or transcription is introduced.

**Tech Stack:** Flutter, Riverpod, immutable Dart models, local JSON inbox storage, existing MUSA workspace providers, `flutter_test`.

---

## File Structure

Create:

- `test/inbox/window/capture_actions_test.dart`: focused tests for processing behavior when creating cards succeeds or fails.

Modify:

- `lib/modules/inbox/models/inbox_capture.dart`: optional creative-card metadata on captures.
- `test/inbox/models/inbox_capture_test.dart`: JSON compatibility tests for new optional fields.
- `test/inbox/services/inbox_storage_service_test.dart`: storage round-trip for new optional fields.
- `lib/modules/books/providers/workspace_providers.dart`: explicit creative type and optional attachment parameters for `addCreativeCardFromInbox`.
- `test/creative_conversion_test.dart`: provider tests for explicit type, invalid/missing type fallback, and image attachment reference.
- `lib/ui/inbox/iphone/capture_screen.dart`: creative type selector and writing hint into capture JSON.
- `test/inbox/iphone/capture_screen_test.dart`: widget tests for iPhone capture metadata.
- `lib/ui/inbox/window/widgets/capture_actions.dart`: pass capture metadata to card creation and return success/failure.
- `lib/ui/inbox/window/widgets/capture_detail_panel.dart`: type correction in full inbox window and primary “Crear tarjeta” action.
- `test/inbox/window/capture_detail_panel_test.dart`: widget tests for type correction and successful card creation.
- `lib/ui/inbox/popover/inbox_popover.dart`: quick “Crear tarjeta” action in popover.
- `test/inbox/popover/inbox_popover_test.dart`: widget tests for quick action.
- `ai/memory/PROJECT_MEMORY.md`: record V3.4 stable behavior after implementation.
- `ai/memory/CHANGE_LOG.md`: record V3.4 after implementation.

Do not modify:

- Workspace sync/storage architecture beyond existing local inbox.
- iOS/macOS Swift bookmark channels.
- Media copy/import infrastructure.
- Audio transcription/playback.
- Creative board/editor detail beyond what tests reveal as required by new card metadata.

---

## Task 1: Inbox Capture Metadata

**Files:**
- Modify: `lib/modules/inbox/models/inbox_capture.dart`
- Test: `test/inbox/models/inbox_capture_test.dart`
- Test: `test/inbox/services/inbox_storage_service_test.dart`

- [ ] **Step 1: Write failing model tests**

Append to `test/inbox/models/inbox_capture_test.dart` inside `group('InboxCapture.fromJson / toJson', () { ... })`:

```dart
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
      final back = InboxCapture.fromJson({
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
```

Append to `test/inbox/services/inbox_storage_service_test.dart` inside `group('write', () { ... })`:

```dart
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
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
flutter test test/inbox/models/inbox_capture_test.dart test/inbox/services/inbox_storage_service_test.dart --reporter expanded
```

Expected: FAIL because `InboxCapture` has no `creativeTypeHint`, `attachmentUri`, or `attachmentKind`.

- [ ] **Step 3: Extend `InboxCapture`**

In `lib/modules/inbox/models/inbox_capture.dart`, update the constructor and fields:

```dart
    this.title,
    this.projectHint,
    this.creativeTypeHint,
    this.attachmentUri,
    this.attachmentKind,
  });
```

Add fields:

```dart
  final String? creativeTypeHint;
  final String? attachmentUri;
  final String? attachmentKind;
```

Extend `toJson`:

```dart
        'creativeTypeHint': creativeTypeHint,
        'attachmentUri': attachmentUri,
        'attachmentKind': attachmentKind,
```

Extend `fromJson` return:

```dart
      creativeTypeHint: json['creativeTypeHint'] as String?,
      attachmentUri: json['attachmentUri'] as String?,
      attachmentKind: json['attachmentKind'] as String?,
```

Extend `copyWith` signature:

```dart
    String? creativeTypeHint,
    String? attachmentUri,
    String? attachmentKind,
```

And return:

```dart
      creativeTypeHint: creativeTypeHint ?? this.creativeTypeHint,
      attachmentUri: attachmentUri ?? this.attachmentUri,
      attachmentKind: attachmentKind ?? this.attachmentKind,
```

- [ ] **Step 4: Run tests and commit**

Run:

```bash
dart format lib/modules/inbox/models/inbox_capture.dart test/inbox/models/inbox_capture_test.dart test/inbox/services/inbox_storage_service_test.dart
flutter test test/inbox/models/inbox_capture_test.dart test/inbox/services/inbox_storage_service_test.dart --reporter expanded
flutter analyze lib/modules/inbox/models/inbox_capture.dart test/inbox/models/inbox_capture_test.dart test/inbox/services/inbox_storage_service_test.dart
```

Expected: all pass.

Commit:

```bash
git add lib/modules/inbox/models/inbox_capture.dart test/inbox/models/inbox_capture_test.dart test/inbox/services/inbox_storage_service_test.dart
git commit -m "feat: add creative metadata to inbox captures"
```

---

## Task 2: Workspace Creative Card Creation From Metadata

**Files:**
- Modify: `lib/modules/books/providers/workspace_providers.dart`
- Test: `test/creative_conversion_test.dart`

- [ ] **Step 1: Write failing provider tests**

Append inside `group('Inbox creative cards', () { ... })` in `test/creative_conversion_test.dart`:

```dart
    test('uses explicit creative type when creating card from inbox', () async {
      final capturedAt = DateTime.utc(2026, 5, 8, 10, 15);
      final container = await _containerWithWorkspace(NarrativeWorkspace(
        appSettings: const AppSettings(activeBookId: 'book-1'),
        books: [
          Book(
            id: 'book-1',
            title: 'Libro',
            createdAt: capturedAt,
            updatedAt: capturedAt,
          ),
        ],
      ));
      addTearDown(container.dispose);

      final card = await container
          .read(narrativeWorkspaceProvider.notifier)
          .addCreativeCardFromInbox(
            body: '¿Y si Diane no abrió la puerta?',
            url: null,
            capturedAt: capturedAt,
            deviceLabel: 'iPhone de Paco',
            creativeTypeHint: 'question',
          );

      expect(card, isNotNull);
      expect(card!.type, CreativeCardType.question);
      expect(container.read(activeCreativeCardsProvider).single.type,
          CreativeCardType.question);
    });

    test('ignores invalid creative type hint and keeps inference', () async {
      final capturedAt = DateTime.utc(2026, 5, 8, 10, 15);
      final container = await _containerWithWorkspace(NarrativeWorkspace(
        appSettings: const AppSettings(activeBookId: 'book-1'),
        books: [
          Book(
            id: 'book-1',
            title: 'Libro',
            createdAt: capturedAt,
            updatedAt: capturedAt,
          ),
        ],
      ));
      addTearDown(container.dispose);

      final card = await container
          .read(narrativeWorkspaceProvider.notifier)
          .addCreativeCardFromInbox(
            body: 'https://example.com/door',
            url: 'https://example.com/door',
            capturedAt: capturedAt,
            deviceLabel: 'iPhone de Paco',
            creativeTypeHint: 'unknown-kind',
          );

      expect(card, isNotNull);
      expect(card!.type, CreativeCardType.research);
    });

    test('creates image attachment reference from inbox metadata', () async {
      final capturedAt = DateTime.utc(2026, 5, 8, 10, 15);
      final container = await _containerWithWorkspace(NarrativeWorkspace(
        appSettings: const AppSettings(activeBookId: 'book-1'),
        books: [
          Book(
            id: 'book-1',
            title: 'Libro',
            createdAt: capturedAt,
            updatedAt: capturedAt,
          ),
        ],
      ));
      addTearDown(container.dispose);

      final card = await container
          .read(narrativeWorkspaceProvider.notifier)
          .addCreativeCardFromInbox(
            body: 'Foto del callejón',
            url: null,
            capturedAt: capturedAt,
            deviceLabel: 'iPhone de Paco',
            creativeTypeHint: 'image',
            attachmentUri: 'file:///tmp/alley.png',
            attachmentKind: 'image',
          );

      expect(card, isNotNull);
      expect(card!.type, CreativeCardType.image);
      expect(card.attachments, hasLength(1));
      expect(card.attachments.single.kind, CreativeCardAttachmentKind.image);
      expect(card.attachments.single.uri, 'file:///tmp/alley.png');
      expect(card.attachments.single.title, 'iPhone de Paco');
    });
```

- [ ] **Step 2: Run test and verify failure**

Run:

```bash
flutter test test/creative_conversion_test.dart --reporter expanded
```

Expected: FAIL because `addCreativeCardFromInbox` does not accept the new optional parameters.

- [ ] **Step 3: Extend provider method**

In `lib/modules/books/providers/workspace_providers.dart`, update `addCreativeCardFromInbox` signature:

```dart
  Future<CreativeCard?> addCreativeCardFromInbox({
    required String body,
    required String? url,
    required DateTime capturedAt,
    required String deviceLabel,
    String? creativeTypeHint,
    String? attachmentUri,
    String? attachmentKind,
  }) async {
```

In the method, derive type:

```dart
    final explicitType = _creativeCardTypeFromName(creativeTypeHint);
    final inferredType = _inferCreativeCardType(
      body: trimmedBody,
      url: hasUrl ? trimmedUrl : null,
    );
```

Use:

```dart
      type: explicitType ?? inferredType,
```

Replace current inline attachment creation with:

```dart
      attachments: _creativeInboxAttachments(
        url: hasUrl ? trimmedUrl : null,
        attachmentUri: attachmentUri,
        attachmentKind: attachmentKind,
        deviceLabel: deviceLabel,
        capturedAt: capturedAt,
      ),
```

Add helpers near existing creative inbox helpers:

```dart
CreativeCardType? _creativeCardTypeFromName(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  for (final type in CreativeCardType.values) {
    if (type.name == value) return type;
  }
  return null;
}

CreativeCardAttachmentKind? _creativeAttachmentKindFromName(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  for (final kind in CreativeCardAttachmentKind.values) {
    if (kind.name == value) return kind;
  }
  return null;
}

List<CreativeCardAttachment> _creativeInboxAttachments({
  required String? url,
  required String? attachmentUri,
  required String? attachmentKind,
  required String deviceLabel,
  required DateTime capturedAt,
}) {
  final attachments = <CreativeCardAttachment>[];
  final label = deviceLabel.trim();
  final trimmedUrl = url?.trim() ?? '';
  if (trimmedUrl.isNotEmpty) {
    attachments.add(CreativeCardAttachment(
      id: generateEntityId('creative_attachment'),
      kind: CreativeCardAttachmentKind.link,
      uri: trimmedUrl,
      title: label,
      createdAt: capturedAt,
    ));
  }

  final uri = attachmentUri?.trim() ?? '';
  final kind = _creativeAttachmentKindFromName(attachmentKind);
  if (uri.isNotEmpty && kind != null) {
    final alreadyAdded = attachments.any(
      (attachment) => attachment.uri == uri && attachment.kind == kind,
    );
    if (!alreadyAdded) {
      attachments.add(CreativeCardAttachment(
        id: generateEntityId('creative_attachment'),
        kind: kind,
        uri: uri,
        title: label,
        createdAt: capturedAt,
      ));
    }
  }

  return attachments;
}
```

- [ ] **Step 4: Run tests and commit**

Run:

```bash
dart format lib/modules/books/providers/workspace_providers.dart test/creative_conversion_test.dart
flutter test test/creative_conversion_test.dart --reporter expanded
flutter analyze lib/modules/books/providers/workspace_providers.dart test/creative_conversion_test.dart
```

Expected: all pass.

Commit:

```bash
git add lib/modules/books/providers/workspace_providers.dart test/creative_conversion_test.dart
git commit -m "feat: create creative cards from inbox metadata"
```

---

## Task 3: iPhone Capture Type Selector

**Files:**
- Modify: `lib/ui/inbox/iphone/capture_screen.dart`
- Test: `test/inbox/iphone/capture_screen_test.dart`

- [ ] **Step 1: Create failing widget test**

Create `test/inbox/iphone/capture_screen_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/inbox/models/inbox_capture.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/services/inbox_bookmark_service.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';
import 'package:musa/ui/inbox/iphone/capture_screen.dart';
import 'package:musa/ui/inbox/iphone/inbox_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('capture screen writes selected creative type hint',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      kInboxDeviceLabelKey: 'iPhone de Paco',
    });
    final tempRoot = Directory.systemTemp.createTempSync('musa_capture_ui_');
    addTearDown(() {
      if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
    });
    final storage = InboxStorageService(rootDirectory: tempRoot);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        inboxFolderProvider.overrideWith(
          (ref) => _HealthyInboxFolderNotifier(tempRoot.path),
        ),
        inboxStorageProvider.overrideWithValue(storage),
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
    await tester.pumpAndSettle();

    final captures = await storage.readAll();
    expect(captures, hasLength(1));
    expect(captures.single.capture!.creativeTypeHint, 'question');
    expect(captures.single.capture!.deviceLabel, 'iPhone de Paco');
  });
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
```

- [ ] **Step 2: Run test and verify failure**

Run:

```bash
flutter test test/inbox/iphone/capture_screen_test.dart --reporter expanded
```

Expected: FAIL because selector keys and `creativeTypeHint` write path do not exist.

- [ ] **Step 3: Implement selector**

In `lib/ui/inbox/iphone/capture_screen.dart`, add import:

```dart
import 'package:musa/modules/creative/models/creative_card.dart';
```

Add state:

```dart
  CreativeCardType _creativeType = CreativeCardType.idea;
```

When creating `InboxCapture`, pass:

```dart
        creativeTypeHint: _creativeType.name,
```

Key the save button:

```dart
              key: const Key('iphone-capture-save-button'),
```

Add selector above the save button:

```dart
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CreativeTypeChoice(
                    key: const Key('iphone-capture-type-idea'),
                    label: 'Idea',
                    selected: _creativeType == CreativeCardType.idea,
                    onTap: () => setState(() => _creativeType = CreativeCardType.idea),
                  ),
                  _CreativeTypeChoice(
                    key: const Key('iphone-capture-type-sketch'),
                    label: 'Boceto',
                    selected: _creativeType == CreativeCardType.sketch,
                    onTap: () => setState(() => _creativeType = CreativeCardType.sketch),
                  ),
                  _CreativeTypeChoice(
                    key: const Key('iphone-capture-type-question'),
                    label: 'Pregunta',
                    selected: _creativeType == CreativeCardType.question,
                    onTap: () => setState(() => _creativeType = CreativeCardType.question),
                  ),
                  _CreativeTypeChoice(
                    key: const Key('iphone-capture-type-research'),
                    label: 'Research',
                    selected: _creativeType == CreativeCardType.research,
                    onTap: () => setState(() => _creativeType = CreativeCardType.research),
                  ),
                ],
              ),
            ),
```

Add widget:

```dart
class _CreativeTypeChoice extends StatelessWidget {
  const _CreativeTypeChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
```

- [ ] **Step 4: Run tests and commit**

Run:

```bash
dart format lib/ui/inbox/iphone/capture_screen.dart test/inbox/iphone/capture_screen_test.dart
flutter test test/inbox/iphone/capture_screen_test.dart --reporter expanded
flutter analyze lib/ui/inbox/iphone/capture_screen.dart test/inbox/iphone/capture_screen_test.dart
```

Expected: all pass.

Commit:

```bash
git add lib/ui/inbox/iphone/capture_screen.dart test/inbox/iphone/capture_screen_test.dart
git commit -m "feat: tag iphone captures for creative cards"
```

---

## Task 4: Capture Actions Processing Safety

**Files:**
- Modify: `lib/ui/inbox/window/widgets/capture_actions.dart`
- Test: `test/inbox/window/capture_actions_test.dart`

- [ ] **Step 1: Create failing action tests**

Create `test/inbox/window/capture_actions_test.dart`:

```dart
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
```

If `CaptureActions.acceptAsCreativeCard` cannot accept `container.read`, refactor `CaptureActions` to use `Reader`-style dependency:

```dart
typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);
```

And add overloads/adapters so existing `WidgetRef` callers continue to work.

- [ ] **Step 2: Run test and verify failure**

Run:

```bash
flutter test test/inbox/window/capture_actions_test.dart --reporter expanded
```

Expected: FAIL because `acceptAsCreativeCard` currently returns `Future<void>` and only accepts `WidgetRef`.

- [ ] **Step 3: Refactor actions minimally**

In `lib/ui/inbox/window/widgets/capture_actions.dart`, add:

```dart
typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);
```

Change methods to accept `ProviderReader read` instead of `WidgetRef ref`:

```dart
  static Future<bool> accept(
    ProviderReader read,
    InboxCaptureRecord record, {
    String? editedBody,
  }) async {
```

```dart
  static Future<bool> acceptAsCreativeCard(
    ProviderReader read,
    InboxCaptureRecord record, {
    String? editedBody,
    String? creativeTypeHint,
  }) async {
```

Update reads:

```dart
    final storage = read(inboxStorageProvider);
```

In `accept`, after `addNoteFromInbox`, mark processed and refresh with:

```dart
    await storage.markProcessed(File(record.path));
    read(inboxRefreshTickProvider.notifier).state++;
    return true;
```

Call provider:

```dart
    final card = await read(narrativeWorkspaceProvider.notifier)
        .addCreativeCardFromInbox(
          body: body,
          url: c.url,
          capturedAt: c.capturedAt,
          deviceLabel: c.deviceLabel,
          creativeTypeHint: creativeTypeHint ?? c.creativeTypeHint,
          attachmentUri: c.attachmentUri,
          attachmentKind: c.attachmentKind,
        );
    if (card == null) return false;
    await storage.markProcessed(File(record.path));
    read(inboxRefreshTickProvider.notifier).state++;
    return true;
```

Change `discard` to:

```dart
  static Future<bool> discard(
    ProviderReader read,
    InboxCaptureRecord record,
  ) async {
    final storage = read(inboxStorageProvider);
    if (storage == null) return false;
    await storage.markDiscarded(File(record.path));
    read(inboxRefreshTickProvider.notifier).state++;
    return true;
  }
```

Update every call site in `capture_detail_panel.dart` and `inbox_popover.dart` to pass `ref.read`:

```dart
CaptureActions.accept(ref.read, record)
CaptureActions.acceptAsCreativeCard(ref.read, record)
CaptureActions.discard(ref.read, record)
```

- [ ] **Step 4: Run tests and commit**

Run:

```bash
dart format lib/ui/inbox/window/widgets/capture_actions.dart test/inbox/window/capture_actions_test.dart
flutter test test/inbox/window/capture_actions_test.dart --reporter expanded
flutter analyze lib/ui/inbox/window/widgets/capture_actions.dart test/inbox/window/capture_actions_test.dart
```

Expected: all pass.

Commit:

```bash
git add lib/ui/inbox/window/widgets/capture_actions.dart test/inbox/window/capture_actions_test.dart
git commit -m "fix: preserve failed creative inbox captures"
```

---

## Task 5: Mac Inbox Detail Type Correction

**Files:**
- Modify: `lib/ui/inbox/window/widgets/capture_detail_panel.dart`
- Test: `test/inbox/window/capture_detail_panel_test.dart`

- [ ] **Step 1: Create failing widget test**

Create `test/inbox/window/capture_detail_panel_test.dart`:

```dart
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
    final storage = InboxStorageService(rootDirectory: tempRoot);
    final capture = InboxCapture(
      schemaVersion: 1,
      id: 'capture-1',
      capturedAt: now,
      deviceLabel: 'iPhone de Paco',
      kind: InboxCaptureKind.text,
      body: '¿Y si Diane no abrió la puerta?',
      creativeTypeHint: 'idea',
    );
    final file = await storage.write(capture);
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
              path: file.path,
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
    await tester.pumpAndSettle();

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
```

- [ ] **Step 2: Run test and verify failure**

Run:

```bash
flutter test test/inbox/window/capture_detail_panel_test.dart --reporter expanded
```

Expected: FAIL because type correction controls and `capture-detail-create-card` do not exist.

- [ ] **Step 3: Add type correction UI**

In `capture_detail_panel.dart`, import:

```dart
import 'package:musa/modules/creative/models/creative_card.dart';
```

Add state:

```dart
  CreativeCardType _creativeType = CreativeCardType.idea;
```

Sync in `initState` and `didUpdateWidget` using helper:

```dart
  CreativeCardType _typeFromCapture() {
    final raw = widget.record.capture?.creativeTypeHint;
    for (final type in CreativeCardType.values) {
      if (type.name == raw) return type;
    }
    return CreativeCardType.idea;
  }
```

Set `_creativeType = _typeFromCapture();`.

Render a compact selector above actions:

```dart
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TypeChip(
                key: const Key('capture-detail-type-idea'),
                label: 'Idea',
                selected: _creativeType == CreativeCardType.idea,
                onTap: () => setState(() => _creativeType = CreativeCardType.idea),
              ),
              _TypeChip(
                key: const Key('capture-detail-type-sketch'),
                label: 'Boceto',
                selected: _creativeType == CreativeCardType.sketch,
                onTap: () => setState(() => _creativeType = CreativeCardType.sketch),
              ),
              _TypeChip(
                key: const Key('capture-detail-type-question'),
                label: 'Pregunta',
                selected: _creativeType == CreativeCardType.question,
                onTap: () => setState(() => _creativeType = CreativeCardType.question),
              ),
              _TypeChip(
                key: const Key('capture-detail-type-research'),
                label: 'Research',
                selected: _creativeType == CreativeCardType.research,
                onTap: () => setState(() => _creativeType = CreativeCardType.research),
              ),
            ],
          ),
```

Pass selected type into `_DetailActionsHook`, add field:

```dart
  final CreativeCardType creativeType;
```

Update create-card buttons:

```dart
            key: const Key('capture-detail-create-card'),
            onPressed: () => CaptureActions.acceptAsCreativeCard(
              ref.read,
              record,
              creativeTypeHint: creativeType.name,
            ),
```

And edited version:

```dart
              await CaptureActions.acceptAsCreativeCard(
                ref.read,
                record,
                editedBody: editController.text,
                creativeTypeHint: creativeType.name,
              );
```

- [ ] **Step 4: Run tests and commit**

Run:

```bash
dart format lib/ui/inbox/window/widgets/capture_detail_panel.dart test/inbox/window/capture_detail_panel_test.dart
flutter test test/inbox/window/capture_detail_panel_test.dart --reporter expanded
flutter analyze lib/ui/inbox/window/widgets/capture_detail_panel.dart test/inbox/window/capture_detail_panel_test.dart
```

Expected: all pass.

Commit:

```bash
git add lib/ui/inbox/window/widgets/capture_detail_panel.dart test/inbox/window/capture_detail_panel_test.dart
git commit -m "feat: choose creative type in inbox detail"
```

---

## Task 6: Mac Popover Quick Create Card

**Files:**
- Modify: `lib/ui/inbox/popover/inbox_popover.dart`
- Test: `test/inbox/popover/inbox_popover_test.dart`

- [ ] **Step 1: Create failing widget test**

Create `test/inbox/popover/inbox_popover_test.dart`:

```dart
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
    final storage = InboxStorageService(rootDirectory: tempRoot);
    await storage.write(InboxCapture(
      schemaVersion: 1,
      id: 'capture-1',
      capturedAt: now,
      deviceLabel: 'iPhone de Paco',
      kind: InboxCaptureKind.text,
      body: 'Pregunta capturada',
      creativeTypeHint: 'question',
    ));
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
      ],
      child: const MaterialApp(home: Scaffold(body: InboxPopover())),
    ));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(InboxPopover)),
    );
    await container.read(narrativeWorkspaceProvider.notifier).bootstrap();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inbox-popover-create-card-capture-1')));
    await tester.pumpAndSettle();

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
```

- [ ] **Step 2: Run test and verify failure**

Run:

```bash
flutter test test/inbox/popover/inbox_popover_test.dart --reporter expanded
```

Expected: FAIL because quick create-card button is missing.

- [ ] **Step 3: Add popover action**

In `lib/ui/inbox/popover/inbox_popover.dart`, update row buttons:

```dart
              TextButton(
                key: Key('inbox-popover-create-card-${c.id}'),
                onPressed: () => CaptureActions.acceptAsCreativeCard(
                  ref.read,
                  record,
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Crear tarjeta',
                    style: TextStyle(fontSize: 11)),
              ),
```

Keep note accept as secondary:

```dart
              TextButton(
                onPressed: () => CaptureActions.accept(ref.read, record),
                ...
                child: const Text('Nota', style: TextStyle(fontSize: 11)),
              ),
```

Update `_kindEmoji` for current values:

```dart
  String _kindEmoji(InboxCaptureKind kind) => switch (kind) {
        InboxCaptureKind.link => '🔗',
        InboxCaptureKind.text => '📝',
      };
```

- [ ] **Step 4: Run tests and commit**

Run:

```bash
dart format lib/ui/inbox/popover/inbox_popover.dart test/inbox/popover/inbox_popover_test.dart
flutter test test/inbox/popover/inbox_popover_test.dart --reporter expanded
flutter analyze lib/ui/inbox/popover/inbox_popover.dart test/inbox/popover/inbox_popover_test.dart
```

Expected: all pass.

Commit:

```bash
git add lib/ui/inbox/popover/inbox_popover.dart test/inbox/popover/inbox_popover_test.dart
git commit -m "feat: create creative cards from inbox popover"
```

---

## Task 7: Verification And Project Memory

**Files:**
- Modify: `ai/memory/PROJECT_MEMORY.md`
- Modify: `ai/memory/CHANGE_LOG.md`

- [ ] **Step 1: Update project memory**

Add under V3.3 in `ai/memory/PROJECT_MEMORY.md`:

```markdown
- **V3.4 (2026-05-08)**:
  - ✅ **Captura iPhone orientada a Mesa creativa**: `InboxCapture` puede transportar intención editorial para crear tarjetas con tipo explícito.
  - ✅ **Bandeja Mac prioriza tarjetas**: las capturas pendientes pueden crear `CreativeCard` del libro activo sin pasar por nota, conservando “Aceptar como nota” como alternativa.
  - ✅ **Fallo recuperable**: si no hay libro activo o la tarjeta no se crea, la captura permanece pendiente.
```

Add under recurring restrictions:

```markdown
- V3.4 mantiene la bandeja como frontera local-first entre iPhone y Mac; no sincronizar `.musa` directamente ni copiar media al proyecto.
```

- [ ] **Step 2: Update changelog**

Add under `## 2026-05-08` in `ai/memory/CHANGE_LOG.md`:

```markdown
- Se registra V3.4 en memoria estable: captura iPhone con intención editorial y creación de tarjetas creativas desde la bandeja Mac.
```

- [ ] **Step 3: Run focused tests**

Run:

```bash
flutter test test/inbox/models/inbox_capture_test.dart --reporter expanded
flutter test test/inbox/services/inbox_storage_service_test.dart --reporter expanded
flutter test test/inbox/services/kind_detector_service_test.dart --reporter expanded
flutter test test/creative_conversion_test.dart --reporter expanded
flutter test test/inbox/iphone/capture_screen_test.dart --reporter expanded
flutter test test/inbox/window/capture_actions_test.dart --reporter expanded
flutter test test/inbox/window/capture_detail_panel_test.dart --reporter expanded
flutter test test/inbox/popover/inbox_popover_test.dart --reporter expanded
```

Expected: all pass.

- [ ] **Step 4: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Step 5: Run full suite excluding real model smoke**

Run:

```bash
flutter test $(find test -name '*.dart' ! -name 'llama_processor_real_smoke_test.dart' -print | sort)
```

Expected: all tests pass; diagnostic EPUB tests may remain skipped unless `MUSA_RUN_EPUB_DIAGNOSTIC=true`.

- [ ] **Step 6: Check status**

Run:

```bash
git diff --check
git status -sb
```

Expected: no whitespace errors and only intended files modified before the final docs commit.

- [ ] **Step 7: Commit and push**

Commit:

```bash
git add ai/memory/PROJECT_MEMORY.md ai/memory/CHANGE_LOG.md
git commit -m "docs: record iphone creative capture"
git push origin main
```

Expected: push succeeds.

---

## Self-Review Checklist

- Spec coverage: model metadata, iPhone selector, Mac full-window correction, popover quick action, processing safety, docs, tests.
- No media manager, direct workspace sync, conflict handling, audio playback, or transcription are included.
- New optional `InboxCapture` fields are backward-compatible.
- `CreativeCard` model is not changed.
- Captures are only marked processed after successful card creation.
