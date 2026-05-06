# Creative Workbench Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a per-book Mesa creativa where authors can capture, organize, attach, link, and convert creative cards without contaminating narrative memory before conversion.

**Architecture:** Add a focused `lib/modules/creative/` module with immutable models and derived providers, then integrate it into `NarrativeWorkspace` and `NarrativeWorkspaceNotifier`. UI arrives after the domain layer is verified, using a new `CreativeBoardEditor` surfaced as a book-level editor mode.

**Tech Stack:** Flutter, Riverpod, local JSON workspace persistence, existing immutable model/copyWith patterns, `flutter_test`.

---

## File Structure

Create:

- `lib/modules/creative/models/creative_card.dart`: enums and immutable creative card models.
- `lib/modules/creative/providers/creative_providers.dart`: active-book derived providers.
- `lib/editor/widgets/creative_board_editor.dart`: Mac board UI for the active book.
- `test/creative_card_model_test.dart`: model serialization and compatibility tests.
- `test/creative_workspace_test.dart`: workspace persistence and operations tests.
- `test/creative_conversion_test.dart`: conversion tests.

Modify:

- `lib/modules/books/models/narrative_workspace.dart`: store `creativeCards`, expose `activeBookCreativeCards`, serialize/deserialize with defaults.
- `lib/modules/books/providers/workspace_providers.dart`: add methods to create/update/move/archive/link/convert creative cards.
- `lib/modules/notes/models/note.dart`: optionally add `sourceCreativeCardId` only if conversion traceability cannot be represented through `CreativeCard.convertedTo`. Prefer not modifying `Note` unless tests prove it is needed.
- `lib/ui/widgets/sidebar.dart`: add Mesa creativa entry under the active book area.
- `lib/ui/layout/main_screen.dart`: route `WorkspaceEditorMode.creative` to `CreativeBoardEditor`.
- `ai/memory/PROJECT_MEMORY.md`: record V3.1 once implemented.
- `ai/memory/CHANGE_LOG.md`: add one short V3.1 entry.

Important implementation choice:

- Add `WorkspaceEditorMode.creative`.
- Keep cards non-canonical. Do not include them in `NarrativeMemoryUpdater`, `StoryStateUpdater`, continuity, editorial audit, or editorial director inputs.

---

## Task 1: Creative Card Model

**Files:**
- Create: `lib/modules/creative/models/creative_card.dart`
- Test: `test/creative_card_model_test.dart`

- [ ] **Step 1: Write the failing model tests**

Create `test/creative_card_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/creative/models/creative_card.dart';

void main() {
  group('CreativeCard', () {
    test('round-trips all fields through JSON', () {
      final now = DateTime.utc(2026, 5, 7, 10, 30);
      final card = CreativeCard(
        id: 'creative-1',
        bookId: 'book-1',
        title: 'La puerta azul',
        body: 'Una puerta que solo aparece cuando Clara miente.',
        type: CreativeCardType.idea,
        status: CreativeCardStatus.promising,
        tags: const ['misterio', 'clara'],
        attachments: [
          CreativeCardAttachment(
            id: 'att-1',
            kind: CreativeCardAttachmentKind.link,
            uri: 'https://example.com/door',
            title: 'Referencia',
            createdAt: now,
          ),
        ],
        source: CreativeCardSource.iphone,
        linkedCharacterIds: const ['char-1'],
        linkedScenarioIds: const ['scn-1'],
        linkedDocumentIds: const ['doc-1'],
        linkedNoteIds: const ['note-1'],
        convertedTo: const CreativeCardConversion(
          kind: CreativeCardConversionKind.note,
          targetId: 'note-2',
        ),
        createdAt: now,
        updatedAt: now,
      );

      final json = card.toJson();
      final restored = CreativeCard.fromJson(json);

      expect(restored.id, 'creative-1');
      expect(restored.bookId, 'book-1');
      expect(restored.title, 'La puerta azul');
      expect(restored.body, contains('Clara'));
      expect(restored.type, CreativeCardType.idea);
      expect(restored.status, CreativeCardStatus.promising);
      expect(restored.tags, ['misterio', 'clara']);
      expect(restored.attachments.single.kind, CreativeCardAttachmentKind.link);
      expect(restored.attachments.single.uri, 'https://example.com/door');
      expect(restored.source, CreativeCardSource.iphone);
      expect(restored.linkedCharacterIds, ['char-1']);
      expect(restored.linkedScenarioIds, ['scn-1']);
      expect(restored.linkedDocumentIds, ['doc-1']);
      expect(restored.linkedNoteIds, ['note-1']);
      expect(restored.convertedTo?.kind, CreativeCardConversionKind.note);
      expect(restored.convertedTo?.targetId, 'note-2');
      expect(restored.createdAt, now);
      expect(restored.updatedAt, now);
    });

    test('uses safe defaults for older or partial JSON', () {
      final card = CreativeCard.fromJson({
        'id': 'creative-2',
        'bookId': 'book-1',
        'createdAt': '2026-05-07T10:30:00.000Z',
        'updatedAt': '2026-05-07T10:31:00.000Z',
      });

      expect(card.title, '');
      expect(card.body, '');
      expect(card.type, CreativeCardType.idea);
      expect(card.status, CreativeCardStatus.inbox);
      expect(card.tags, isEmpty);
      expect(card.attachments, isEmpty);
      expect(card.source, CreativeCardSource.manual);
      expect(card.convertedTo, isNull);
    });

    test('copyWith can move status and preserve immutable lists', () {
      final now = DateTime.utc(2026, 5, 7);
      final card = CreativeCard(
        id: 'creative-3',
        bookId: 'book-1',
        title: 'Idea',
        createdAt: now,
        updatedAt: now,
      );

      final moved = card.copyWith(
        status: CreativeCardStatus.readyToUse,
        tags: const ['usar'],
        updatedAt: now.add(const Duration(minutes: 1)),
      );

      expect(card.status, CreativeCardStatus.inbox);
      expect(card.tags, isEmpty);
      expect(moved.status, CreativeCardStatus.readyToUse);
      expect(moved.tags, ['usar']);
      expect(moved.updatedAt.isAfter(card.updatedAt), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
flutter test test/creative_card_model_test.dart --reporter expanded
```

Expected: FAIL because `package:musa/modules/creative/models/creative_card.dart` does not exist.

- [ ] **Step 3: Implement the model**

Create `lib/modules/creative/models/creative_card.dart`:

```dart
import '../../../shared/utils/enum_codec.dart';

enum CreativeCardType { idea, sketch, character, scenario, image, research, question }

enum CreativeCardStatus { inbox, exploring, promising, readyToUse, converted, archived }

enum CreativeCardSource { manual, inbox, iphone, ipad, imported }

enum CreativeCardAttachmentKind { link, image }

enum CreativeCardConversionKind { note, character, scenario, document }

class CreativeCardAttachment {
  const CreativeCardAttachment({
    required this.id,
    required this.kind,
    required this.uri,
    this.title = '',
    required this.createdAt,
  });

  final String id;
  final CreativeCardAttachmentKind kind;
  final String uri;
  final String title;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'uri': uri,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CreativeCardAttachment.fromJson(Map<String, dynamic> json) {
    return CreativeCardAttachment(
      id: json['id'] as String,
      kind: enumFromName(
        CreativeCardAttachmentKind.values,
        json['kind'] as String?,
        CreativeCardAttachmentKind.link,
      ),
      uri: json['uri'] as String? ?? '',
      title: json['title'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class CreativeCardConversion {
  const CreativeCardConversion({
    required this.kind,
    required this.targetId,
  });

  final CreativeCardConversionKind kind;
  final String targetId;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'targetId': targetId,
      };

  factory CreativeCardConversion.fromJson(Map<String, dynamic> json) {
    return CreativeCardConversion(
      kind: enumFromName(
        CreativeCardConversionKind.values,
        json['kind'] as String?,
        CreativeCardConversionKind.note,
      ),
      targetId: json['targetId'] as String? ?? '',
    );
  }
}

class CreativeCard {
  const CreativeCard({
    required this.id,
    required this.bookId,
    this.title = '',
    this.body = '',
    this.type = CreativeCardType.idea,
    this.status = CreativeCardStatus.inbox,
    this.tags = const [],
    this.attachments = const [],
    this.source = CreativeCardSource.manual,
    this.linkedCharacterIds = const [],
    this.linkedScenarioIds = const [],
    this.linkedDocumentIds = const [],
    this.linkedNoteIds = const [],
    this.convertedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String bookId;
  final String title;
  final String body;
  final CreativeCardType type;
  final CreativeCardStatus status;
  final List<String> tags;
  final List<CreativeCardAttachment> attachments;
  final CreativeCardSource source;
  final List<String> linkedCharacterIds;
  final List<String> linkedScenarioIds;
  final List<String> linkedDocumentIds;
  final List<String> linkedNoteIds;
  final CreativeCardConversion? convertedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  CreativeCard copyWith({
    String? title,
    String? body,
    CreativeCardType? type,
    CreativeCardStatus? status,
    List<String>? tags,
    List<CreativeCardAttachment>? attachments,
    CreativeCardSource? source,
    List<String>? linkedCharacterIds,
    List<String>? linkedScenarioIds,
    List<String>? linkedDocumentIds,
    List<String>? linkedNoteIds,
    CreativeCardConversion? convertedTo,
    bool clearConvertedTo = false,
    DateTime? updatedAt,
  }) {
    return CreativeCard(
      id: id,
      bookId: bookId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      source: source ?? this.source,
      linkedCharacterIds: linkedCharacterIds ?? this.linkedCharacterIds,
      linkedScenarioIds: linkedScenarioIds ?? this.linkedScenarioIds,
      linkedDocumentIds: linkedDocumentIds ?? this.linkedDocumentIds,
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
      convertedTo: clearConvertedTo ? null : (convertedTo ?? this.convertedTo),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'title': title,
        'body': body,
        'type': type.name,
        'status': status.name,
        'tags': tags,
        'attachments': attachments.map((item) => item.toJson()).toList(),
        'source': source.name,
        'linkedCharacterIds': linkedCharacterIds,
        'linkedScenarioIds': linkedScenarioIds,
        'linkedDocumentIds': linkedDocumentIds,
        'linkedNoteIds': linkedNoteIds,
        'convertedTo': convertedTo?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CreativeCard.fromJson(Map<String, dynamic> json) {
    return CreativeCard(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: enumFromName(
        CreativeCardType.values,
        json['type'] as String?,
        CreativeCardType.idea,
      ),
      status: enumFromName(
        CreativeCardStatus.values,
        json['status'] as String?,
        CreativeCardStatus.inbox,
      ),
      tags: List<String>.from(json['tags'] as List? ?? const []),
      attachments: (json['attachments'] as List? ?? const [])
          .map((item) =>
              CreativeCardAttachment.fromJson(item as Map<String, dynamic>))
          .toList(),
      source: enumFromName(
        CreativeCardSource.values,
        json['source'] as String?,
        CreativeCardSource.manual,
      ),
      linkedCharacterIds:
          List<String>.from(json['linkedCharacterIds'] as List? ?? const []),
      linkedScenarioIds:
          List<String>.from(json['linkedScenarioIds'] as List? ?? const []),
      linkedDocumentIds:
          List<String>.from(json['linkedDocumentIds'] as List? ?? const []),
      linkedNoteIds:
          List<String>.from(json['linkedNoteIds'] as List? ?? const []),
      convertedTo: json['convertedTo'] is Map<String, dynamic>
          ? CreativeCardConversion.fromJson(
              json['convertedTo'] as Map<String, dynamic>,
            )
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
```

- [ ] **Step 4: Format and run the model test**

Run:

```bash
dart format lib/modules/creative/models/creative_card.dart test/creative_card_model_test.dart
flutter test test/creative_card_model_test.dart --reporter expanded
```

Expected: all 3 model tests pass.

- [ ] **Step 5: Commit**

Run:

```bash
git add lib/modules/creative/models/creative_card.dart test/creative_card_model_test.dart
git commit -m "feat: add creative card model"
```

---

## Task 2: Workspace Persistence

**Files:**
- Modify: `lib/modules/books/models/narrative_workspace.dart`
- Test: `test/creative_workspace_test.dart`

- [ ] **Step 1: Write failing workspace persistence tests**

Create `test/creative_workspace_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/app_settings.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_workspace.dart';
import 'package:musa/modules/creative/models/creative_card.dart';

void main() {
  group('NarrativeWorkspace creative cards', () {
    test('loads old workspaces without creativeCards as an empty list', () {
      final now = DateTime.utc(2026, 5, 7);
      final workspace = NarrativeWorkspace.fromJson({
        'appSettings': {'activeBookId': 'book-1'},
        'books': [
          {
            'id': 'book-1',
            'title': 'Libro',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }
        ],
      });

      expect(workspace.creativeCards, isEmpty);
      expect(workspace.activeBookCreativeCards, isEmpty);
    });

    test('round-trips creativeCards through workspace JSON', () {
      final now = DateTime.utc(2026, 5, 7);
      final workspace = NarrativeWorkspace(
        appSettings: const AppSettings(activeBookId: 'book-1'),
        books: [
          Book(
            id: 'book-1',
            title: 'Libro',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        creativeCards: [
          CreativeCard(
            id: 'creative-1',
            bookId: 'book-1',
            title: 'Idea',
            status: CreativeCardStatus.exploring,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final restored = NarrativeWorkspace.fromJson(workspace.toJson());

      expect(restored.creativeCards.single.id, 'creative-1');
      expect(restored.activeBookCreativeCards.single.title, 'Idea');
      expect(
        restored.activeBookCreativeCards.single.status,
        CreativeCardStatus.exploring,
      );
    });

    test('activeBookCreativeCards filters and sorts by updatedAt descending', () {
      final now = DateTime.utc(2026, 5, 7);
      final workspace = NarrativeWorkspace(
        appSettings: const AppSettings(activeBookId: 'book-1'),
        books: [
          Book(id: 'book-1', title: 'Uno', createdAt: now, updatedAt: now),
          Book(id: 'book-2', title: 'Dos', createdAt: now, updatedAt: now),
        ],
        creativeCards: [
          CreativeCard(
            id: 'older',
            bookId: 'book-1',
            title: 'Older',
            createdAt: now,
            updatedAt: now,
          ),
          CreativeCard(
            id: 'other-book',
            bookId: 'book-2',
            title: 'Other',
            createdAt: now,
            updatedAt: now.add(const Duration(hours: 3)),
          ),
          CreativeCard(
            id: 'newer',
            bookId: 'book-1',
            title: 'Newer',
            createdAt: now,
            updatedAt: now.add(const Duration(hours: 1)),
          ),
        ],
      );

      expect(
        workspace.activeBookCreativeCards.map((card) => card.id),
        ['newer', 'older'],
      );
    });
  });
}
```

- [ ] **Step 2: Run the workspace test and verify it fails**

Run:

```bash
flutter test test/creative_workspace_test.dart --reporter expanded
```

Expected: FAIL because `NarrativeWorkspace.creativeCards` and `activeBookCreativeCards` do not exist.

- [ ] **Step 3: Add creativeCards to NarrativeWorkspace**

Modify `lib/modules/books/models/narrative_workspace.dart`:

1. Add import:

```dart
import '../../creative/models/creative_card.dart';
```

2. Add field near other per-book collections:

```dart
final List<CreativeCard> creativeCards;
```

3. Add constructor parameter:

```dart
this.creativeCards = const [],
```

4. Add getter after `activeBookNotes`:

```dart
List<CreativeCard> get activeBookCreativeCards {
  final book = activeBook;
  if (book == null) return const [];
  final results = creativeCards.where((card) => card.bookId == book.id).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return results;
}
```

5. Add `creativeCards` to `copyWith` signature and returned workspace:

```dart
List<CreativeCard>? creativeCards,
```

```dart
creativeCards: creativeCards ?? this.creativeCards,
```

6. Add to `toJson`:

```dart
'creativeCards': creativeCards.map((item) => item.toJson()).toList(),
```

7. Add to `fromJson`:

```dart
creativeCards: (json['creativeCards'] as List? ?? const [])
    .map((item) => CreativeCard.fromJson(item as Map<String, dynamic>))
    .toList(),
```

- [ ] **Step 4: Format and run workspace tests**

Run:

```bash
dart format lib/modules/books/models/narrative_workspace.dart test/creative_workspace_test.dart
flutter test test/creative_workspace_test.dart --reporter expanded
```

Expected: all workspace persistence tests pass.

- [ ] **Step 5: Run model regression test**

Run:

```bash
flutter test test/creative_card_model_test.dart --reporter expanded
```

Expected: all model tests still pass.

- [ ] **Step 6: Commit**

Run:

```bash
git add lib/modules/books/models/narrative_workspace.dart test/creative_workspace_test.dart
git commit -m "feat: persist creative cards in workspace"
```

---

## Task 3: Active Creative Providers

**Files:**
- Create: `lib/modules/creative/providers/creative_providers.dart`
- Test: `test/creative_workspace_test.dart`

- [ ] **Step 1: Add failing provider test**

Append this import to `test/creative_workspace_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/books/providers/workspace_providers.dart';
import 'package:musa/modules/creative/providers/creative_providers.dart';
```

Append this test inside the existing group:

```dart
test('activeCreativeCardsProvider returns active book cards only', () async {
  final now = DateTime.utc(2026, 5, 7);
  final container = ProviderContainer();
  addTearDown(container.dispose);

  container.read(narrativeWorkspaceProvider.notifier).state =
      AsyncData(NarrativeWorkspace(
    appSettings: const AppSettings(activeBookId: 'book-1'),
    books: [
      Book(id: 'book-1', title: 'Uno', createdAt: now, updatedAt: now),
      Book(id: 'book-2', title: 'Dos', createdAt: now, updatedAt: now),
    ],
    creativeCards: [
      CreativeCard(
        id: 'active',
        bookId: 'book-1',
        title: 'Activa',
        createdAt: now,
        updatedAt: now,
      ),
      CreativeCard(
        id: 'inactive',
        bookId: 'book-2',
        title: 'Inactiva',
        createdAt: now,
        updatedAt: now,
      ),
    ],
  ));

  expect(
    container.read(activeCreativeCardsProvider).map((card) => card.id),
    ['active'],
  );
});
```

- [ ] **Step 2: Run provider test and verify it fails**

Run:

```bash
flutter test test/creative_workspace_test.dart --reporter expanded
```

Expected: FAIL because `creative_providers.dart` and `activeCreativeCardsProvider` do not exist.

- [ ] **Step 3: Implement providers**

Create `lib/modules/creative/providers/creative_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/providers/workspace_providers.dart';
import '../models/creative_card.dart';

final activeCreativeCardsProvider = Provider<List<CreativeCard>>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.activeBookCreativeCards ??
      const [];
});

final visibleCreativeCardsProvider = Provider<List<CreativeCard>>((ref) {
  return ref
      .watch(activeCreativeCardsProvider)
      .where((card) => card.status != CreativeCardStatus.archived)
      .toList();
});
```

- [ ] **Step 4: Run provider test**

Run:

```bash
dart format lib/modules/creative/providers/creative_providers.dart test/creative_workspace_test.dart
flutter test test/creative_workspace_test.dart --reporter expanded
```

Expected: all creative workspace tests pass.

- [ ] **Step 5: Commit**

Run:

```bash
git add lib/modules/creative/providers/creative_providers.dart test/creative_workspace_test.dart
git commit -m "feat: add creative card providers"
```

---

## Task 4: Workspace Operations

**Files:**
- Modify: `lib/modules/books/providers/workspace_providers.dart`
- Test: `test/creative_workspace_test.dart`

- [ ] **Step 1: Add failing operation tests**

Append these tests inside the group in `test/creative_workspace_test.dart`:

```dart
test('workspace notifier can create, update, move and archive creative cards',
    () async {
  final now = DateTime.utc(2026, 5, 7);
  final container = ProviderContainer();
  addTearDown(container.dispose);

  container.read(narrativeWorkspaceProvider.notifier).state =
      AsyncData(NarrativeWorkspace(
    appSettings: const AppSettings(activeBookId: 'book-1'),
    books: [
      Book(id: 'book-1', title: 'Libro', createdAt: now, updatedAt: now),
    ],
  ));

  final notifier = container.read(narrativeWorkspaceProvider.notifier);
  final created = await notifier.createCreativeCard(
    title: 'Puerta azul',
    body: 'Aparece cuando Clara miente.',
    type: CreativeCardType.idea,
    tags: const ['clara'],
  );

  expect(created, isNotNull);
  expect(container.read(activeCreativeCardsProvider).single.title, 'Puerta azul');

  await notifier.updateCreativeCard(
    created!.copyWith(title: 'Puerta roja', body: 'Otra version.'),
  );
  expect(container.read(activeCreativeCardsProvider).single.title, 'Puerta roja');

  await notifier.moveCreativeCard(
    cardId: created.id,
    status: CreativeCardStatus.readyToUse,
  );
  expect(
    container.read(activeCreativeCardsProvider).single.status,
    CreativeCardStatus.readyToUse,
  );

  await notifier.archiveCreativeCard(created.id);
  expect(
    container.read(activeCreativeCardsProvider).single.status,
    CreativeCardStatus.archived,
  );
});

test('workspace notifier can link a creative card to existing entities',
    () async {
  final now = DateTime.utc(2026, 5, 7);
  final container = ProviderContainer();
  addTearDown(container.dispose);

  container.read(narrativeWorkspaceProvider.notifier).state =
      AsyncData(NarrativeWorkspace(
    appSettings: const AppSettings(activeBookId: 'book-1'),
    books: [
      Book(id: 'book-1', title: 'Libro', createdAt: now, updatedAt: now),
    ],
    creativeCards: [
      CreativeCard(
        id: 'creative-1',
        bookId: 'book-1',
        title: 'Idea',
        createdAt: now,
        updatedAt: now,
      ),
    ],
  ));

  await container.read(narrativeWorkspaceProvider.notifier).linkCreativeCard(
        cardId: 'creative-1',
        characterIds: const ['char-1'],
        scenarioIds: const ['scn-1'],
        documentIds: const ['doc-1'],
        noteIds: const ['note-1'],
      );

  final card = container.read(activeCreativeCardsProvider).single;
  expect(card.linkedCharacterIds, ['char-1']);
  expect(card.linkedScenarioIds, ['scn-1']);
  expect(card.linkedDocumentIds, ['doc-1']);
  expect(card.linkedNoteIds, ['note-1']);
});
```

- [ ] **Step 2: Run operation tests and verify failure**

Run:

```bash
flutter test test/creative_workspace_test.dart --reporter expanded
```

Expected: FAIL because notifier methods do not exist.

- [ ] **Step 3: Implement notifier methods**

Add methods to `NarrativeWorkspaceNotifier` in `lib/modules/books/providers/workspace_providers.dart` near note/document creation methods:

```dart
Future<CreativeCard?> createCreativeCard({
  String title = '',
  String body = '',
  CreativeCardType type = CreativeCardType.idea,
  CreativeCardStatus status = CreativeCardStatus.inbox,
  List<String> tags = const [],
  List<CreativeCardAttachment> attachments = const [],
  CreativeCardSource source = CreativeCardSource.manual,
}) async {
  final workspace = state.value;
  final activeBook = workspace?.activeBook;
  if (workspace == null || activeBook == null) return null;

  final now = DateTime.now();
  final card = CreativeCard(
    id: generateEntityId('creative'),
    bookId: activeBook.id,
    title: title.trim(),
    body: body.trim(),
    type: type,
    status: status,
    tags: tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(),
    attachments: attachments,
    source: source,
    createdAt: now,
    updatedAt: now,
  );

  await _persist(
    workspace.copyWith(
      creativeCards: [...workspace.creativeCards, card],
      books: _touchActiveBook(workspace.books, activeBook.id, now),
    ),
  );
  return card;
}

Future<void> updateCreativeCard(CreativeCard card) async {
  final workspace = state.value;
  if (workspace == null) return;

  final now = DateTime.now();
  final updatedCards = workspace.creativeCards.map((item) {
    if (item.id != card.id) return item;
    return card.copyWith(updatedAt: now);
  }).toList();

  await _persist(
    workspace.copyWith(
      creativeCards: updatedCards,
      books: _touchActiveBook(workspace.books, card.bookId, now),
    ),
  );
}

Future<void> moveCreativeCard({
  required String cardId,
  required CreativeCardStatus status,
}) async {
  final workspace = state.value;
  if (workspace == null) return;

  final now = DateTime.now();
  String? bookId;
  final updatedCards = workspace.creativeCards.map((card) {
    if (card.id != cardId) return card;
    bookId = card.bookId;
    return card.copyWith(status: status, updatedAt: now);
  }).toList();

  await _persist(
    workspace.copyWith(
      creativeCards: updatedCards,
      books: _touchActiveBook(workspace.books, bookId, now),
    ),
  );
}

Future<void> archiveCreativeCard(String cardId) async {
  await moveCreativeCard(
    cardId: cardId,
    status: CreativeCardStatus.archived,
  );
}

Future<void> linkCreativeCard({
  required String cardId,
  List<String>? characterIds,
  List<String>? scenarioIds,
  List<String>? documentIds,
  List<String>? noteIds,
}) async {
  final workspace = state.value;
  if (workspace == null) return;

  final now = DateTime.now();
  String? bookId;
  final updatedCards = workspace.creativeCards.map((card) {
    if (card.id != cardId) return card;
    bookId = card.bookId;
    return card.copyWith(
      linkedCharacterIds: characterIds ?? card.linkedCharacterIds,
      linkedScenarioIds: scenarioIds ?? card.linkedScenarioIds,
      linkedDocumentIds: documentIds ?? card.linkedDocumentIds,
      linkedNoteIds: noteIds ?? card.linkedNoteIds,
      updatedAt: now,
    );
  }).toList();

  await _persist(
    workspace.copyWith(
      creativeCards: updatedCards,
      books: _touchActiveBook(workspace.books, bookId, now),
    ),
  );
}
```

Also add import:

```dart
import '../../creative/models/creative_card.dart';
```

- [ ] **Step 4: Run operation tests**

Run:

```bash
dart format lib/modules/books/providers/workspace_providers.dart test/creative_workspace_test.dart
flutter test test/creative_workspace_test.dart --reporter expanded
```

Expected: all creative workspace tests pass.

- [ ] **Step 5: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: no issues found.

- [ ] **Step 6: Commit**

Run:

```bash
git add lib/modules/books/providers/workspace_providers.dart test/creative_workspace_test.dart
git commit -m "feat: manage creative cards in workspace"
```

---

## Task 5: Conversion Operations

**Files:**
- Modify: `lib/modules/books/providers/workspace_providers.dart`
- Test: `test/creative_conversion_test.dart`

- [ ] **Step 1: Write failing conversion tests**

Create `test/creative_conversion_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/app_settings.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_workspace.dart';
import 'package:musa/modules/books/providers/workspace_providers.dart';
import 'package:musa/modules/creative/models/creative_card.dart';
import 'package:musa/modules/creative/providers/creative_providers.dart';
import 'package:musa/modules/manuscript/models/document.dart';
import 'package:musa/modules/notes/models/note.dart';

void main() {
  group('Creative card conversions', () {
    test('converts a card to a note and marks the card converted', () async {
      final container = _containerWithCard();
      addTearDown(container.dispose);

      final note = await container
          .read(narrativeWorkspaceProvider.notifier)
          .convertCreativeCardToNote('creative-1');

      expect(note, isNotNull);
      expect(note!.title, 'La puerta azul');
      expect(note.content, contains('Clara'));
      expect(note.kind, NoteKind.idea);

      final card = container.read(activeCreativeCardsProvider).single;
      expect(card.status, CreativeCardStatus.converted);
      expect(card.convertedTo?.kind, CreativeCardConversionKind.note);
      expect(card.convertedTo?.targetId, note.id);
      expect(card.linkedNoteIds, contains(note.id));
    });

    test('converts a card to a character and marks the card converted',
        () async {
      final container = _containerWithCard(
        type: CreativeCardType.character,
        title: 'Diane',
      );
      addTearDown(container.dispose);

      final character = await container
          .read(narrativeWorkspaceProvider.notifier)
          .convertCreativeCardToCharacter('creative-1');

      expect(character, isNotNull);
      expect(character!.name, 'Diane');
      expect(character.notes, contains('Clara'));
      expect(container.read(activeCreativeCardsProvider).single.linkedCharacterIds,
          contains(character.id));
    });

    test('converts a card to a scenario and marks the card converted',
        () async {
      final container = _containerWithCard(
        type: CreativeCardType.scenario,
        title: 'Casa de la puerta azul',
      );
      addTearDown(container.dispose);

      final scenario = await container
          .read(narrativeWorkspaceProvider.notifier)
          .convertCreativeCardToScenario('creative-1');

      expect(scenario, isNotNull);
      expect(scenario!.name, 'Casa de la puerta azul');
      expect(scenario.notes, contains('Clara'));
      expect(container.read(activeCreativeCardsProvider).single.linkedScenarioIds,
          contains(scenario.id));
    });

    test('converts a card to a scratch document and marks the card converted',
        () async {
      final container = _containerWithCard(type: CreativeCardType.sketch);
      addTearDown(container.dispose);

      final document = await container
          .read(narrativeWorkspaceProvider.notifier)
          .convertCreativeCardToDocument('creative-1');

      expect(document, isNotNull);
      expect(document!.title, 'La puerta azul');
      expect(document.kind, DocumentKind.scratch);
      expect(document.content, contains('Clara'));
      expect(container.read(activeCreativeCardsProvider).single.linkedDocumentIds,
          contains(document.id));
    });
  });
}

ProviderContainer _containerWithCard({
  CreativeCardType type = CreativeCardType.idea,
  String title = 'La puerta azul',
}) {
  final now = DateTime.utc(2026, 5, 7);
  final container = ProviderContainer();
  container.read(narrativeWorkspaceProvider.notifier).state =
      AsyncData(NarrativeWorkspace(
    appSettings: const AppSettings(activeBookId: 'book-1'),
    books: [
      Book(id: 'book-1', title: 'Libro', createdAt: now, updatedAt: now),
    ],
    creativeCards: [
      CreativeCard(
        id: 'creative-1',
        bookId: 'book-1',
        title: title,
        body: 'Aparece cuando Clara miente.',
        type: type,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  ));
  return container;
}
```

- [ ] **Step 2: Run conversion tests and verify failure**

Run:

```bash
flutter test test/creative_conversion_test.dart --reporter expanded
```

Expected: FAIL because conversion methods do not exist.

- [ ] **Step 3: Implement conversion methods**

Add methods to `NarrativeWorkspaceNotifier`:

```dart
Future<Note?> convertCreativeCardToNote(String cardId) async {
  final workspace = state.value;
  final card = _creativeCardById(workspace, cardId);
  if (workspace == null || card == null) return null;

  final now = DateTime.now();
  final note = Note(
    id: generateEntityId('note'),
    bookId: card.bookId,
    title: card.title.trim().isEmpty ? null : card.title.trim(),
    content: card.body.trim(),
    kind: _noteKindForCreativeCard(card.type),
    status: NoteStatus.inbox,
    createdAt: now,
    updatedAt: now,
  );
  final updatedCard = card.copyWith(
    status: CreativeCardStatus.converted,
    convertedTo: CreativeCardConversion(
      kind: CreativeCardConversionKind.note,
      targetId: note.id,
    ),
    linkedNoteIds: _appendUnique(card.linkedNoteIds, note.id),
    updatedAt: now,
  );

  await _persist(
    workspace.copyWith(
      notes: [...workspace.notes, note],
      creativeCards: _replaceCreativeCard(workspace.creativeCards, updatedCard),
      books: _touchActiveBook(workspace.books, card.bookId, now),
      selectedNoteId: note.id,
      clearSelectedCharacterId: true,
      clearSelectedScenarioId: true,
      editorMode: WorkspaceEditorMode.note,
    ),
  );
  return note;
}

Future<Character?> convertCreativeCardToCharacter(String cardId) async {
  final workspace = state.value;
  final card = _creativeCardById(workspace, cardId);
  if (workspace == null || card == null) return null;

  final now = DateTime.now();
  final character = Character(
    id: generateEntityId('character'),
    bookId: card.bookId,
    name: card.title.trim().isEmpty ? 'Personaje sin nombre' : card.title.trim(),
    notes: card.body.trim(),
    createdAt: now,
    updatedAt: now,
  );
  final updatedCard = card.copyWith(
    status: CreativeCardStatus.converted,
    convertedTo: CreativeCardConversion(
      kind: CreativeCardConversionKind.character,
      targetId: character.id,
    ),
    linkedCharacterIds: _appendUnique(card.linkedCharacterIds, character.id),
    updatedAt: now,
  );

  await _persist(
    workspace.copyWith(
      characters: [...workspace.characters, character],
      creativeCards: _replaceCreativeCard(workspace.creativeCards, updatedCard),
      books: _touchActiveBook(workspace.books, card.bookId, now),
      selectedCharacterId: character.id,
      clearSelectedScenarioId: true,
      editorMode: WorkspaceEditorMode.character,
    ),
  );
  return character;
}

Future<Scenario?> convertCreativeCardToScenario(String cardId) async {
  final workspace = state.value;
  final card = _creativeCardById(workspace, cardId);
  if (workspace == null || card == null) return null;

  final now = DateTime.now();
  final scenario = Scenario(
    id: generateEntityId('scenario'),
    bookId: card.bookId,
    name: card.title.trim().isEmpty ? 'Escenario sin nombre' : card.title.trim(),
    notes: card.body.trim(),
    createdAt: now,
    updatedAt: now,
  );
  final updatedCard = card.copyWith(
    status: CreativeCardStatus.converted,
    convertedTo: CreativeCardConversion(
      kind: CreativeCardConversionKind.scenario,
      targetId: scenario.id,
    ),
    linkedScenarioIds: _appendUnique(card.linkedScenarioIds, scenario.id),
    updatedAt: now,
  );

  await _persist(
    workspace.copyWith(
      scenarios: [...workspace.scenarios, scenario],
      creativeCards: _replaceCreativeCard(workspace.creativeCards, updatedCard),
      books: _touchActiveBook(workspace.books, card.bookId, now),
      selectedScenarioId: scenario.id,
      clearSelectedCharacterId: true,
      editorMode: WorkspaceEditorMode.scenario,
    ),
  );
  return scenario;
}

Future<Document?> convertCreativeCardToDocument(String cardId) async {
  final workspace = state.value;
  final card = _creativeCardById(workspace, cardId);
  if (workspace == null || card == null) return null;

  final now = DateTime.now();
  final activeBookDocuments =
      workspace.documents.where((document) => document.bookId == card.bookId);
  final nextOrder = activeBookDocuments.isEmpty
      ? 0
      : activeBookDocuments
              .map((document) => document.orderIndex)
              .reduce((a, b) => a > b ? a : b) +
          1;
  final document = Document(
    id: generateEntityId('document'),
    bookId: card.bookId,
    title: card.title.trim().isEmpty ? 'Boceto' : card.title.trim(),
    kind: DocumentKind.scratch,
    orderIndex: nextOrder,
    content: card.body.trim(),
    wordCount: _wordCount(card.body),
    createdAt: now,
    updatedAt: now,
  );
  final updatedCard = card.copyWith(
    status: CreativeCardStatus.converted,
    convertedTo: CreativeCardConversion(
      kind: CreativeCardConversionKind.document,
      targetId: document.id,
    ),
    linkedDocumentIds: _appendUnique(card.linkedDocumentIds, document.id),
    updatedAt: now,
  );

  await _persist(
    workspace.copyWith(
      documents: [...workspace.documents, document],
      creativeCards: _replaceCreativeCard(workspace.creativeCards, updatedCard),
      books: _touchActiveBook(workspace.books, card.bookId, now),
      selectedDocumentId: document.id,
      editorMode: WorkspaceEditorMode.document,
    ),
  );
  return document;
}
```

Add private helpers in the same class:

```dart
CreativeCard? _creativeCardById(NarrativeWorkspace? workspace, String cardId) {
  if (workspace == null) return null;
  for (final card in workspace.creativeCards) {
    if (card.id == cardId) return card;
  }
  return null;
}

List<CreativeCard> _replaceCreativeCard(
  List<CreativeCard> cards,
  CreativeCard updated,
) {
  return cards.map((card) => card.id == updated.id ? updated : card).toList();
}

List<String> _appendUnique(List<String> values, String value) {
  if (values.contains(value)) return values;
  return [...values, value];
}

NoteKind _noteKindForCreativeCard(CreativeCardType type) {
  return switch (type) {
    CreativeCardType.idea => NoteKind.idea,
    CreativeCardType.sketch => NoteKind.structural,
    CreativeCardType.character => NoteKind.character,
    CreativeCardType.scenario => NoteKind.scenario,
    CreativeCardType.image => NoteKind.loose,
    CreativeCardType.research => NoteKind.research,
    CreativeCardType.question => NoteKind.structural,
  };
}
```

- [ ] **Step 4: Run conversion tests**

Run:

```bash
dart format lib/modules/books/providers/workspace_providers.dart test/creative_conversion_test.dart
flutter test test/creative_conversion_test.dart --reporter expanded
```

Expected: all conversion tests pass.

- [ ] **Step 5: Run workspace regression tests**

Run:

```bash
flutter test test/creative_workspace_test.dart --reporter expanded
```

Expected: all creative workspace tests still pass.

- [ ] **Step 6: Commit**

Run:

```bash
git add lib/modules/books/providers/workspace_providers.dart test/creative_conversion_test.dart
git commit -m "feat: convert creative cards"
```

---

## Task 6: Creative Board UI

**Files:**
- Create: `lib/editor/widgets/creative_board_editor.dart`
- Modify: `lib/modules/books/models/narrative_workspace.dart`
- Modify: `lib/ui/widgets/sidebar.dart`
- Modify: `lib/ui/layout/main_screen.dart`
- Test: `test/creative_board_editor_test.dart`

- [ ] **Step 1: Add editor mode testable contract**

Update `WorkspaceEditorMode` in `lib/modules/books/models/narrative_workspace.dart`:

```dart
enum WorkspaceEditorMode { book, document, note, character, scenario, creative }
```

Do not commit yet; this is part of the UI task.

- [ ] **Step 2: Write failing UI smoke test**

Create `test/creative_board_editor_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musa/editor/widgets/creative_board_editor.dart';
import 'package:musa/modules/books/models/app_settings.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_workspace.dart';
import 'package:musa/modules/books/providers/workspace_providers.dart';
import 'package:musa/modules/creative/models/creative_card.dart';

void main() {
  testWidgets('CreativeBoardEditor renders columns and existing cards',
      (tester) async {
    final now = DateTime.utc(2026, 5, 7);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(narrativeWorkspaceProvider.notifier).state =
        AsyncData(NarrativeWorkspace(
      appSettings: const AppSettings(activeBookId: 'book-1'),
      books: [
        Book(id: 'book-1', title: 'Libro', createdAt: now, updatedAt: now),
      ],
      creativeCards: [
        CreativeCard(
          id: 'creative-1',
          bookId: 'book-1',
          title: 'La puerta azul',
          body: 'Aparece cuando Clara miente.',
          status: CreativeCardStatus.promising,
          tags: const ['clara'],
          createdAt: now,
          updatedAt: now,
        ),
      ],
    ));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: CreativeBoardEditor())),
      ),
    );

    expect(find.text('Mesa creativa'), findsOneWidget);
    expect(find.text('Bandeja'), findsOneWidget);
    expect(find.text('Prometedor'), findsOneWidget);
    expect(find.text('La puerta azul'), findsOneWidget);
    expect(find.text('clara'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run UI test and verify failure**

Run:

```bash
flutter test test/creative_board_editor_test.dart --reporter expanded
```

Expected: FAIL because `CreativeBoardEditor` does not exist.

- [ ] **Step 4: Implement `CreativeBoardEditor`**

Create `lib/editor/widgets/creative_board_editor.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/books/providers/workspace_providers.dart';
import '../../modules/creative/models/creative_card.dart';
import '../../modules/creative/providers/creative_providers.dart';

class CreativeBoardEditor extends ConsumerWidget {
  const CreativeBoardEditor({super.key});

  static const _columns = [
    CreativeCardStatus.inbox,
    CreativeCardStatus.exploring,
    CreativeCardStatus.promising,
    CreativeCardStatus.readyToUse,
    CreativeCardStatus.converted,
    CreativeCardStatus.archived,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(activeCreativeCardsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(48, 56, 48, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mesa creativa',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => ref
                    .read(narrativeWorkspaceProvider.notifier)
                    .createCreativeCard(title: 'Nueva idea'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva tarjeta'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${cards.length} tarjetas en este libro',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black45,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 620,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final status = _columns[index];
                final columnCards =
                    cards.where((card) => card.status == status).toList();
                return _CreativeColumn(
                  status: status,
                  cards: columnCards,
                  onMove: (card, nextStatus) => ref
                      .read(narrativeWorkspaceProvider.notifier)
                      .moveCreativeCard(cardId: card.id, status: nextStatus),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemCount: _columns.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreativeColumn extends StatelessWidget {
  const _CreativeColumn({
    required this.status,
    required this.cards,
    required this.onMove,
  });

  final CreativeCardStatus status;
  final List<CreativeCard> cards;
  final void Function(CreativeCard card, CreativeCardStatus status) onMove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _statusLabel(status),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                '${cards.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black38,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: cards.isEmpty
                ? Text(
                    'Sin tarjetas',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black26,
                        ),
                  )
                : ListView.builder(
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CreativeCardTile(
                          card: cards[index],
                          onMove: onMove,
                        ),
                      );
                    },
                    itemCount: cards.length,
                  ),
          ),
        ],
      ),
    );
  }
}

class _CreativeCardTile extends StatelessWidget {
  const _CreativeCardTile({
    required this.card,
    required this.onMove,
  });

  final CreativeCard card;
  final void Function(CreativeCard card, CreativeCardStatus status) onMove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.title.trim().isEmpty ? 'Idea sin titulo' : card.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              PopupMenuButton<CreativeCardStatus>(
                tooltip: 'Mover',
                icon: const Icon(Icons.more_horiz, size: 18),
                onSelected: (status) => onMove(card, status),
                itemBuilder: (context) => CreativeCardStatus.values
                    .map(
                      (status) => PopupMenuItem(
                        value: status,
                        child: Text(_statusLabel(status)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          if (card.body.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              card.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                    height: 1.35,
                  ),
            ),
          ],
          if (card.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: card.tags
                  .map(
                    (tag) => Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

String _statusLabel(CreativeCardStatus status) {
  return switch (status) {
    CreativeCardStatus.inbox => 'Bandeja',
    CreativeCardStatus.exploring => 'Explorando',
    CreativeCardStatus.promising => 'Prometedor',
    CreativeCardStatus.readyToUse => 'Para usar',
    CreativeCardStatus.converted => 'Convertido',
    CreativeCardStatus.archived => 'Archivado',
  };
}
```

- [ ] **Step 5: Wire main screen route**

Modify `lib/ui/layout/main_screen.dart`.

Add import:

```dart
import '../../editor/widgets/creative_board_editor.dart';
```

Find the editor mode switch that renders `BookEditor`, document editor, note editor, character editor, and scenario editor. Add:

```dart
WorkspaceEditorMode.creative => const CreativeBoardEditor(),
```

If the file uses if/else instead of switch, add the equivalent branch for `workspace.editorMode == WorkspaceEditorMode.creative`.

- [ ] **Step 6: Wire sidebar entry**

Modify `lib/ui/widgets/sidebar.dart`.

Find the active book navigation items near `Libro activo`. Add one entry labelled `Mesa creativa` that calls:

```dart
ref.read(narrativeWorkspaceProvider.notifier).setEditorMode(
  WorkspaceEditorMode.creative,
);
```

If there is no public `setEditorMode`, add this small method to `NarrativeWorkspaceNotifier`:

```dart
Future<void> setEditorMode(WorkspaceEditorMode mode) async {
  final workspace = state.value;
  if (workspace == null) return;
  await _persist(workspace.copyWith(editorMode: mode));
}
```

- [ ] **Step 7: Run UI smoke test**

Run:

```bash
dart format lib/editor/widgets/creative_board_editor.dart lib/modules/books/models/narrative_workspace.dart lib/ui/layout/main_screen.dart lib/ui/widgets/sidebar.dart test/creative_board_editor_test.dart
flutter test test/creative_board_editor_test.dart --reporter expanded
```

Expected: UI smoke test passes.

- [ ] **Step 8: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: no issues found.

- [ ] **Step 9: Commit**

Run:

```bash
git add lib/editor/widgets/creative_board_editor.dart lib/modules/books/models/narrative_workspace.dart lib/ui/layout/main_screen.dart lib/ui/widgets/sidebar.dart test/creative_board_editor_test.dart
git commit -m "feat: add creative board editor"
```

---

## Task 7: Inbox To Creative Card

**Files:**
- Modify: `lib/modules/books/providers/workspace_providers.dart`
- Modify: `lib/ui/inbox/window/widgets/capture_actions.dart`
- Test: `test/creative_conversion_test.dart`

- [ ] **Step 1: Add failing inbox conversion test**

Append to `test/creative_conversion_test.dart`:

```dart
test('adds inbox capture as creative card with source and attachment',
    () async {
  final now = DateTime.utc(2026, 5, 7);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(narrativeWorkspaceProvider.notifier).state =
      AsyncData(NarrativeWorkspace(
    appSettings: const AppSettings(activeBookId: 'book-1'),
    books: [
      Book(id: 'book-1', title: 'Libro', createdAt: now, updatedAt: now),
    ],
  ));

  final card = await container
      .read(narrativeWorkspaceProvider.notifier)
      .addCreativeCardFromInbox(
        body: 'Idea capturada desde iPhone',
        url: 'https://example.com/ref',
        capturedAt: now,
        deviceLabel: 'iPhone de Paco',
      );

  expect(card, isNotNull);
  expect(card!.source, CreativeCardSource.inbox);
  expect(card.title, 'Idea capturada desde iPhone');
  expect(card.body, contains('Idea capturada'));
  expect(card.attachments.single.kind, CreativeCardAttachmentKind.link);
  expect(card.attachments.single.uri, 'https://example.com/ref');
});
```

- [ ] **Step 2: Run test and verify failure**

Run:

```bash
flutter test test/creative_conversion_test.dart --reporter expanded
```

Expected: FAIL because `addCreativeCardFromInbox` does not exist.

- [ ] **Step 3: Implement inbox-to-card method**

Add to `NarrativeWorkspaceNotifier`:

```dart
Future<CreativeCard?> addCreativeCardFromInbox({
  required String body,
  required String? url,
  required DateTime capturedAt,
  required String deviceLabel,
}) async {
  final attachments = <CreativeCardAttachment>[
    if (url != null && url.trim().isNotEmpty)
      CreativeCardAttachment(
        id: generateEntityId('creative_attachment'),
        kind: CreativeCardAttachmentKind.link,
        uri: url.trim(),
        title: deviceLabel.trim(),
        createdAt: capturedAt,
      ),
  ];

  return createCreativeCard(
    title: _inferCreativeTitle(body, url),
    body: body.trim(),
    type: url != null && url.trim().isNotEmpty
        ? CreativeCardType.research
        : CreativeCardType.idea,
    attachments: attachments,
    source: CreativeCardSource.inbox,
  );
}

String _inferCreativeTitle(String body, String? url) {
  for (final raw in body.split('\n')) {
    final line = raw.trim();
    if (line.isNotEmpty) {
      return line.length > 80 ? '${line.substring(0, 77)}…' : line;
    }
  }
  final fallback = url?.trim() ?? '';
  if (fallback.isEmpty) return 'Idea capturada';
  return fallback.length > 80 ? '${fallback.substring(0, 77)}…' : fallback;
}
```

- [ ] **Step 4: Add UI action in capture management**

Modify `lib/ui/inbox/window/widgets/capture_actions.dart`.

Add a new action method:

```dart
static Future<void> acceptAsCreativeCard(
  WidgetRef ref,
  InboxCaptureRecord record, {
  String? editedBody,
}) async {
  final capture = record.capture;
  await ref.read(narrativeWorkspaceProvider.notifier).addCreativeCardFromInbox(
        body: editedBody ?? capture.body,
        url: capture.url,
        capturedAt: capture.capturedAt,
        deviceLabel: capture.deviceLabel,
      );
  await ref.read(inboxStorageProvider)?.markProcessed(record);
  refreshInbox(ref);
}
```

Then add a button in `CaptureDetailPanel` labelled `Enviar a mesa` that calls `CaptureActions.acceptAsCreativeCard(ref, record)`. Keep the existing accept-as-note flow intact.

- [ ] **Step 5: Run tests**

Run:

```bash
dart format lib/modules/books/providers/workspace_providers.dart lib/ui/inbox/window/widgets/capture_actions.dart lib/ui/inbox/window/widgets/capture_detail_panel.dart test/creative_conversion_test.dart
flutter test test/creative_conversion_test.dart --reporter expanded
```

Expected: conversion tests pass, including inbox-to-card.

- [ ] **Step 6: Run inbox regression tests**

Run:

```bash
flutter test test/inbox/services/inbox_storage_service_test.dart test/inbox/models/inbox_capture_test.dart --reporter expanded
```

Expected: inbox storage/model tests still pass.

- [ ] **Step 7: Commit**

Run:

```bash
git add lib/modules/books/providers/workspace_providers.dart lib/ui/inbox/window/widgets/capture_actions.dart lib/ui/inbox/window/widgets/capture_detail_panel.dart test/creative_conversion_test.dart
git commit -m "feat: send inbox captures to creative board"
```

---

## Task 8: Memory, Changelog, Full Verification

**Files:**
- Modify: `ai/memory/PROJECT_MEMORY.md`
- Modify: `ai/memory/CHANGE_LOG.md`

- [ ] **Step 1: Update project memory**

Add to `ai/memory/PROJECT_MEMORY.md` under stable decisions:

```markdown
- **V3.1 (2026-05-07)**:
  - ✅ **Mesa creativa por libro**: tarjetas creativas persistidas por libro para ideas, bocetos, personajes incipientes, escenarios, imagenes, investigacion y preguntas.
  - ✅ **Tablero Mac**: `CreativeBoardEditor` organiza tarjetas por Bandeja, Explorando, Prometedor, Para usar, Convertido y Archivado.
  - ✅ **Conversiones revisables**: una tarjeta puede convertirse en nota, personaje, escenario o documento `scratch`, quedando enlazada al destino.
  - ✅ **Entrada desde inbox**: capturas aceptadas pueden entrar como tarjetas creativas sin sustituir el flujo existente de notas.
```

Add under recurring restrictions:

```markdown
- V3.1 mantiene las tarjetas creativas fuera de memoria narrativa, continuidad, auditoria y direccion editorial hasta conversion o accion explicita de uso.
```

- [ ] **Step 2: Update changelog**

Add to `ai/memory/CHANGE_LOG.md`:

```markdown
- Se registra V3.1 en memoria estable: Mesa creativa por libro con tarjetas, tablero, conversiones e inbox hacia tarjetas.
```

- [ ] **Step 3: Run focused tests**

Run:

```bash
flutter test test/creative_card_model_test.dart --reporter expanded
flutter test test/creative_workspace_test.dart --reporter expanded
flutter test test/creative_conversion_test.dart --reporter expanded
flutter test test/creative_board_editor_test.dart --reporter expanded
```

Expected: all focused creative tests pass.

- [ ] **Step 4: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: no issues found.

- [ ] **Step 5: Run full suite excluding real model smoke**

Run:

```bash
flutter test $(find test -name '*.dart' ! -name 'llama_processor_real_smoke_test.dart' -print | sort)
```

Expected: all tests pass; diagnostic EPUB tests may remain skipped unless their env flag is enabled.

- [ ] **Step 6: Check diff cleanliness**

Run:

```bash
git diff --check
git status -sb
```

Expected: no whitespace errors; only intended files changed.

- [ ] **Step 7: Commit**

Run:

```bash
git add ai/memory/PROJECT_MEMORY.md ai/memory/CHANGE_LOG.md
git commit -m "docs: record creative workbench"
```

- [ ] **Step 8: Push**

Run:

```bash
git push origin main
```

Expected: push succeeds.

---

## Self-Review

Spec coverage:

- Per-book creative cards: Tasks 1-4.
- Persistence and old workspace defaults: Task 2.
- Board UI: Task 6.
- Conversion to note/personaje/escenario/document: Task 5.
- Inbox/mobile-ready input: Task 7.
- Attachments/source fields: Tasks 1 and 7.
- Non-canonical rule: Task 8 memory plus implementation boundaries; no updater/audit service is modified.
- Canvas/mapa mental: intentionally reserved beyond V3.1; model has links and attachments, but no canvas UI in this plan.

Placeholder scan:

- No `TBD`, `TODO`, placeholder steps, or unresolved function names are intentionally left in this plan.

Type consistency:

- Core types: `CreativeCard`, `CreativeCardAttachment`, `CreativeCardConversion`.
- Provider: `activeCreativeCardsProvider`.
- Workspace methods: `createCreativeCard`, `updateCreativeCard`, `moveCreativeCard`, `archiveCreativeCard`, `linkCreativeCard`, conversion methods, and `addCreativeCardFromInbox`.
