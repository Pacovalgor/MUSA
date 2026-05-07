# Creative Card Detail Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn each creative card into a rich editable unit inside the Mesa creativa before mobile-direct capture or mind-map canvas work.

**Architecture:** Keep `CreativeCard` as the persisted model and evolve the existing board into a board-plus-detail editor. Add a focused detail widget that edits cards through `NarrativeWorkspaceNotifier.updateCreativeCard`, existing conversion methods, and a new unlink-capable `setCreativeCardLinks` helper. Keep cards out of narrative memory, continuity, editorial audit, and director services.

**Tech Stack:** Flutter, Riverpod, immutable workspace models, local JSON persistence, `flutter_test`.

---

## File Structure

Create:

- `lib/editor/widgets/creative_card_detail_panel.dart`: detail panel for selected creative card, including editing, attachments, linked entities, and actions.
- `test/creative_card_detail_panel_test.dart`: widget tests for detail-panel behavior and persistence.

Modify:

- `lib/editor/widgets/creative_board_editor.dart`: maintain selected card id, render board and detail side by side, pass selection callbacks to tiles, clear selection when the card disappears.
- `lib/modules/books/providers/workspace_providers.dart`: add `setCreativeCardLinks` so UI can both link and unlink entities explicitly.
- `test/creative_board_editor_test.dart`: update board tests for selection, detail rendering, and selection cleanup.
- `ai/memory/PROJECT_MEMORY.md`: record V3.2 after implementation.
- `ai/memory/CHANGE_LOG.md`: add V3.2 entry after implementation.

Do not modify:

- Narrative memory updater, story state updater, continuity audit, editorial audit, editorial director, guided rewrite, or model runtime.
- Mobile shells in this version.

---

## Task 1: Board Selection And Detail Layout

**Files:**
- Modify: `lib/editor/widgets/creative_board_editor.dart`
- Test: `test/creative_board_editor_test.dart`

- [ ] **Step 1: Write failing board-selection tests**

Append these tests to `test/creative_board_editor_test.dart`:

```dart
testWidgets('selecting a card opens its detail panel', (tester) async {
  final repository = _MemoryWorkspaceRepository(
    _workspaceWithCards([
      _card('card-1', 'Puerta azul', CreativeCardStatus.inbox),
    ]),
  );

  await tester.pumpWidget(_app(repository, const CreativeBoardEditor()));
  await tester.pumpAndSettle();

  expect(find.text('Selecciona una tarjeta'), findsOneWidget);

  await tester.tap(find.byKey(const Key('creative-card-tile-card-1')));
  await tester.pumpAndSettle();

  expect(find.text('Detalle de tarjeta'), findsOneWidget);
  expect(find.byKey(const Key('creative-card-detail-title-field')),
      findsOneWidget);
});

testWidgets('selected card is cleared when it is archived', (tester) async {
  final repository = _MemoryWorkspaceRepository(
    _workspaceWithCards([
      _card('card-1', 'Idea para archivar', CreativeCardStatus.inbox),
    ]),
  );

  await tester.pumpWidget(_app(repository, const CreativeBoardEditor()));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('creative-card-tile-card-1')));
  await tester.pumpAndSettle();

  final container = ProviderScope.containerOf(
    tester.element(find.byType(CreativeBoardEditor)),
  );
  await container
      .read(narrativeWorkspaceProvider.notifier)
      .archiveCreativeCard('card-1');
  await tester.pumpAndSettle();

  expect(find.text('Selecciona una tarjeta'), findsOneWidget);
});
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
flutter test test/creative_board_editor_test.dart --reporter expanded
```

Expected: FAIL because tile keys, selection state, empty-detail text, and detail panel do not exist.

- [ ] **Step 3: Add selection state and side-by-side layout**

In `lib/editor/widgets/creative_board_editor.dart`, add selected card state:

```dart
class _CreativeBoardEditorState extends ConsumerState<CreativeBoardEditor> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  CreativeCardType _type = CreativeCardType.idea;
  String? _selectedCardId;
  bool _isCreating = false;
```

In `build`, derive the selected card from visible cards:

```dart
final selectedCard = cards.cast<CreativeCard?>().firstWhere(
  (card) => card?.id == _selectedCardId,
  orElse: () => null,
);
if (_selectedCardId != null && selectedCard == null) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) setState(() => _selectedCardId = null);
  });
}
```

Replace the board-only `Expanded` branch with board + detail:

```dart
Expanded(
  child: activeBook == null
      ? const _BoardMessage(
          icon: Icons.menu_book_outlined,
          title: 'No hay libro activo',
          body: 'Selecciona o crea un libro para usar la mesa creativa.',
        )
      : cards.isEmpty
          ? const _BoardMessage(
              icon: Icons.dashboard_customize_outlined,
              title: 'No hay tarjetas visibles',
              body:
                  'Crea una tarjeta para capturar ideas, bocetos o preguntas sin llevarlas a memoria narrativa.',
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _BoardColumns(
                    cards: cards,
                    selectedCardId: _selectedCardId,
                    onSelectCard: (card) {
                      setState(() => _selectedCardId = card.id);
                    },
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 380,
                  child: CreativeCardDetailPanel(card: selectedCard),
                ),
              ],
            ),
),
```

Add import:

```dart
import 'creative_card_detail_panel.dart';
```

Update `_BoardColumns`, `_BoardColumn`, and `_CreativeCardTile` constructors:

```dart
class _BoardColumns extends StatelessWidget {
  const _BoardColumns({
    required this.cards,
    required this.selectedCardId,
    required this.onSelectCard,
  });

  final List<CreativeCard> cards;
  final String? selectedCardId;
  final ValueChanged<CreativeCard> onSelectCard;
```

Pass fields through `_BoardColumn`:

```dart
_BoardColumn(
  status: status,
  cards: cards.where((card) => card.status == status).toList(growable: false),
  selectedCardId: selectedCardId,
  onSelectCard: onSelectCard,
)
```

And into `_CreativeCardTile`:

```dart
_CreativeCardTile(
  card: cards[index],
  isSelected: cards[index].id == selectedCardId,
  onTap: () => onSelectCard(cards[index]),
)
```

Wrap the tile with a tappable surface:

```dart
return InkWell(
  key: Key('creative-card-tile-${card.id}'),
  borderRadius: BorderRadius.circular(tokens.radiusSm),
  onTap: onTap,
  child: DecoratedBox(
    decoration: BoxDecoration(
      color: tokens.canvasBackground,
      border: Border.all(
        color: isSelected ? tokens.borderStrong : _statusColor(card.status, tokens),
        width: isSelected ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(tokens.radiusSm),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.title.trim().isEmpty ? 'Idea sin título' : card.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (card.body.trim().isNotEmpty) Text(card.body, maxLines: 3),
        ],
      ),
    ),
  ),
);
```

- [ ] **Step 4: Add first-pass detail panel**

Create `lib/editor/widgets/creative_card_detail_panel.dart` with a minimal first-pass panel:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../modules/creative/models/creative_card.dart';

class CreativeCardDetailPanel extends ConsumerWidget {
  const CreativeCardDetailPanel({super.key, required this.card});

  final CreativeCard? card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = MusaTheme.tokensOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.panelBackground,
        border: Border.all(color: tokens.borderSoft),
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: card == null
            ? Center(
                child: Text(
                  'Selecciona una tarjeta',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textMuted,
                      ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalle de tarjeta',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('creative-card-detail-title-field'),
                    controller: TextEditingController(text: card!.title),
                  ),
                ],
              ),
      ),
    );
  }
}
```

This first-pass panel intentionally creates a controller in build only for Task 1. Task 2 replaces it with a proper stateful panel.

- [ ] **Step 5: Run tests and commit**

Run:

```bash
dart format lib/editor/widgets/creative_board_editor.dart lib/editor/widgets/creative_card_detail_panel.dart test/creative_board_editor_test.dart
flutter test test/creative_board_editor_test.dart --reporter expanded
flutter analyze lib/editor/widgets/creative_board_editor.dart lib/editor/widgets/creative_card_detail_panel.dart test/creative_board_editor_test.dart
```

Expected: all pass.

Commit:

```bash
git add lib/editor/widgets/creative_board_editor.dart lib/editor/widgets/creative_card_detail_panel.dart test/creative_board_editor_test.dart
git commit -m "feat: select creative cards on board"
```

---

## Task 2: Editable Card Fields

**Files:**
- Modify: `lib/editor/widgets/creative_card_detail_panel.dart`
- Test: `test/creative_card_detail_panel_test.dart`

- [ ] **Step 1: Create failing detail edit tests**

Create `test/creative_card_detail_panel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musa/core/theme.dart';
import 'package:musa/editor/widgets/creative_card_detail_panel.dart';
import 'package:musa/modules/books/models/app_settings.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_workspace.dart';
import 'package:musa/modules/books/providers/workspace_providers.dart';
import 'package:musa/modules/books/services/narrative_workspace_repository.dart';
import 'package:musa/modules/creative/models/creative_card.dart';

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

void main() {
  testWidgets('detail panel edits title body and tags', (tester) async {
    final repository = _MemoryWorkspaceRepository(_workspaceWithCard());
    final card = repository.workspace.creativeCards.single;

    await tester.pumpWidget(_app(repository, CreativeCardDetailPanel(card: card)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('creative-card-detail-title-field')),
      'Puerta roja',
    );
    await tester.enterText(
      find.byKey(const Key('creative-card-detail-body-field')),
      'Aparece cuando Clara deja de mentir.',
    );
    await tester.enterText(
      find.byKey(const Key('creative-card-detail-tags-field')),
      'clara, puerta, giro',
    );
    await tester.tap(find.byKey(const Key('creative-card-detail-save-button')));
    await tester.pumpAndSettle();

    final stored = repository.workspace.creativeCards.single;
    expect(stored.title, 'Puerta roja');
    expect(stored.body, 'Aparece cuando Clara deja de mentir.');
    expect(stored.tags, ['clara', 'puerta', 'giro']);
  });

  testWidgets('converted card cannot be moved to editable statuses',
      (tester) async {
    final repository = _MemoryWorkspaceRepository(_workspaceWithCard(
      status: CreativeCardStatus.converted,
      convertedTo: const CreativeCardConversion(
        kind: CreativeCardConversionKind.note,
        targetId: 'note-1',
      ),
    ));
    final card = repository.workspace.creativeCards.single;

    await tester.pumpWidget(_app(repository, CreativeCardDetailPanel(card: card)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('creative-card-detail-status-field')),
        findsNothing);
    expect(find.text('Convertida'), findsWidgets);
  });
}

Widget _app(_MemoryWorkspaceRepository repository, Widget child) {
  return ProviderScope(
    overrides: [
      narrativeWorkspaceRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: MusaTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

NarrativeWorkspace _workspaceWithCard({
  CreativeCardStatus status = CreativeCardStatus.inbox,
  CreativeCardConversion? convertedTo,
}) {
  final now = DateTime.utc(2026, 5, 7);
  return NarrativeWorkspace(
    appSettings: const AppSettings(activeBookId: 'book-1'),
    books: [
      Book(id: 'book-1', title: 'Libro', createdAt: now, updatedAt: now),
    ],
    creativeCards: [
      CreativeCard(
        id: 'creative-1',
        bookId: 'book-1',
        title: 'Puerta azul',
        body: 'Aparece cuando Clara miente.',
        status: status,
        convertedTo: convertedTo,
        tags: const ['clara'],
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
flutter test test/creative_card_detail_panel_test.dart --reporter expanded
```

Expected: FAIL because fields and save behavior are not implemented.

- [ ] **Step 3: Replace first-pass panel with stateful editor**

Convert `CreativeCardDetailPanel` to `ConsumerStatefulWidget`:

```dart
class CreativeCardDetailPanel extends ConsumerStatefulWidget {
  const CreativeCardDetailPanel({super.key, required this.card});

  final CreativeCard? card;

  @override
  ConsumerState<CreativeCardDetailPanel> createState() =>
      _CreativeCardDetailPanelState();
}
```

Add controllers and sync:

```dart
class _CreativeCardDetailPanelState extends ConsumerState<CreativeCardDetailPanel> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagsController = TextEditingController();
  CreativeCardType _type = CreativeCardType.idea;
  CreativeCardStatus _status = CreativeCardStatus.inbox;
  String? _syncedCardId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _syncCard(CreativeCard? card) {
    if (card == null) {
      _syncedCardId = null;
      return;
    }
    if (_syncedCardId == card.id) return;
    _syncedCardId = card.id;
    _titleController.text = card.title;
    _bodyController.text = card.body;
    _tagsController.text = card.tags.join(', ');
    _type = card.type;
    _status = card.status;
  }
```

Implement save:

```dart
Future<void> _save(CreativeCard card) async {
  final tags = _tagsController.text
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList();
  final nextStatus = card.status == CreativeCardStatus.converted
      ? CreativeCardStatus.converted
      : _status;
  await ref.read(narrativeWorkspaceProvider.notifier).updateCreativeCard(
        card.copyWith(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          type: _type,
          status: nextStatus,
          tags: tags,
        ),
      );
}
```

Build fields:

```dart
TextField(
  key: const Key('creative-card-detail-title-field'),
  controller: _titleController,
  decoration: const InputDecoration(labelText: 'Título'),
),
TextField(
  key: const Key('creative-card-detail-body-field'),
  controller: _bodyController,
  minLines: 4,
  maxLines: 8,
  decoration: const InputDecoration(labelText: 'Cuerpo'),
),
TextField(
  key: const Key('creative-card-detail-tags-field'),
  controller: _tagsController,
  decoration: const InputDecoration(labelText: 'Tags separados por coma'),
),
DropdownButtonFormField<CreativeCardType>(
  key: const Key('creative-card-detail-type-field'),
  initialValue: _type,
  onChanged: card.status == CreativeCardStatus.converted
      ? null
      : (value) => setState(() => _type = value ?? _type),
  items: CreativeCardType.values
      .map((value) => DropdownMenuItem(value: value, child: Text(_typeLabel(value))))
      .toList(),
),
if (card.status != CreativeCardStatus.converted)
  DropdownButtonFormField<CreativeCardStatus>(
    key: const Key('creative-card-detail-status-field'),
    initialValue: _status,
    onChanged: (value) => setState(() => _status = value ?? _status),
    items: _editableStatuses
        .map((value) => DropdownMenuItem(value: value, child: Text(_statusLabel(value))))
        .toList(),
  )
else
  const Text('Convertida'),
FilledButton(
  key: const Key('creative-card-detail-save-button'),
  onPressed: () => _save(card),
  child: const Text('Guardar'),
),
```

Define local labels in `creative_card_detail_panel.dart`:

```dart
const _editableStatuses = [
  CreativeCardStatus.inbox,
  CreativeCardStatus.exploring,
  CreativeCardStatus.promising,
  CreativeCardStatus.readyToUse,
];
```

- [ ] **Step 4: Run tests and commit**

Run:

```bash
dart format lib/editor/widgets/creative_card_detail_panel.dart test/creative_card_detail_panel_test.dart
flutter test test/creative_card_detail_panel_test.dart --reporter expanded
flutter test test/creative_board_editor_test.dart --reporter expanded
flutter analyze lib/editor/widgets/creative_card_detail_panel.dart test/creative_card_detail_panel_test.dart
```

Expected: all pass.

Commit:

```bash
git add lib/editor/widgets/creative_card_detail_panel.dart test/creative_card_detail_panel_test.dart
git commit -m "feat: edit creative card details"
```

---

## Task 3: Attachment Editing

**Files:**
- Modify: `lib/editor/widgets/creative_card_detail_panel.dart`
- Test: `test/creative_card_detail_panel_test.dart`

- [ ] **Step 1: Add failing attachment tests**

Append to `test/creative_card_detail_panel_test.dart`:

```dart
testWidgets('detail panel adds and removes link attachments', (tester) async {
  final repository = _MemoryWorkspaceRepository(_workspaceWithCard());
  final card = repository.workspace.creativeCards.single;

  await tester.pumpWidget(_app(repository, CreativeCardDetailPanel(card: card)));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('creative-card-attachment-title-field')),
    'Referencia',
  );
  await tester.enterText(
    find.byKey(const Key('creative-card-attachment-uri-field')),
    'https://example.com/door',
  );
  await tester.tap(find.byKey(const Key('creative-card-add-link-button')));
  await tester.pumpAndSettle();

  var stored = repository.workspace.creativeCards.single;
  expect(stored.attachments, hasLength(1));
  expect(stored.attachments.single.kind, CreativeCardAttachmentKind.link);
  expect(stored.attachments.single.title, 'Referencia');
  expect(stored.attachments.single.uri, 'https://example.com/door');

  await tester.tap(find.byKey(Key('creative-card-remove-attachment-${stored.attachments.single.id}')));
  await tester.pumpAndSettle();

  stored = repository.workspace.creativeCards.single;
  expect(stored.attachments, isEmpty);
});

testWidgets('detail panel shows image attachment as reference text',
    (tester) async {
  final now = DateTime.utc(2026, 5, 7);
  final repository = _MemoryWorkspaceRepository(_workspaceWithCard(
    attachments: [
      CreativeCardAttachment(
        id: 'image-1',
        kind: CreativeCardAttachmentKind.image,
        uri: '/tmp/reference.png',
        title: 'Foto de referencia',
        createdAt: now,
      ),
    ],
  ));
  final card = repository.workspace.creativeCards.single;

  await tester.pumpWidget(_app(repository, CreativeCardDetailPanel(card: card)));
  await tester.pumpAndSettle();

  expect(find.text('Foto de referencia'), findsOneWidget);
  expect(find.text('/tmp/reference.png'), findsOneWidget);
});
```

Update the `_workspaceWithCard` helper signature:

```dart
NarrativeWorkspace _workspaceWithCard({
  CreativeCardStatus status = CreativeCardStatus.inbox,
  CreativeCardConversion? convertedTo,
  List<CreativeCardAttachment> attachments = const [],
}) {
```

Pass `attachments: attachments` into `CreativeCard`.

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
flutter test test/creative_card_detail_panel_test.dart --reporter expanded
```

Expected: FAIL because attachment fields and buttons do not exist.

- [ ] **Step 3: Implement attachment controls**

In `CreativeCardDetailPanel`, add controllers:

```dart
final _attachmentTitleController = TextEditingController();
final _attachmentUriController = TextEditingController();
```

Dispose them.

Add helper methods:

```dart
Future<void> _addLinkAttachment(CreativeCard card) async {
  final uri = _attachmentUriController.text.trim();
  if (uri.isEmpty) return;
  final title = _attachmentTitleController.text.trim();
  final attachment = CreativeCardAttachment(
    id: 'creative_attachment_${DateTime.now().microsecondsSinceEpoch}',
    kind: CreativeCardAttachmentKind.link,
    uri: uri,
    title: title,
    createdAt: DateTime.now(),
  );
  await ref.read(narrativeWorkspaceProvider.notifier).updateCreativeCard(
        card.copyWith(attachments: [...card.attachments, attachment]),
      );
  if (!mounted) return;
  _attachmentTitleController.clear();
  _attachmentUriController.clear();
}

Future<void> _removeAttachment(
  CreativeCard card,
  CreativeCardAttachment attachment,
) async {
  await ref.read(narrativeWorkspaceProvider.notifier).updateCreativeCard(
        card.copyWith(
          attachments: card.attachments
              .where((item) => item.id != attachment.id)
              .toList(),
        ),
      );
}
```

Add attachment UI below tags:

```dart
Text(
  'Adjuntos',
  style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: tokens.textPrimary,
        fontWeight: FontWeight.w700,
      ),
),
const SizedBox(height: 8),
for (final attachment in card.attachments)
  ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(
      attachment.title.isEmpty ? _attachmentKindLabel(attachment.kind) : attachment.title,
    ),
    subtitle: Text(attachment.uri),
    trailing: IconButton(
      key: Key('creative-card-remove-attachment-${attachment.id}'),
      tooltip: 'Quitar adjunto',
      icon: const Icon(Icons.close, size: 16),
      onPressed: () => _removeAttachment(card, attachment),
    ),
  ),
TextField(
  key: const Key('creative-card-attachment-title-field'),
  controller: _attachmentTitleController,
  decoration: const InputDecoration(labelText: 'Título del enlace'),
),
TextField(
  key: const Key('creative-card-attachment-uri-field'),
  controller: _attachmentUriController,
  decoration: const InputDecoration(labelText: 'URL o ruta'),
),
OutlinedButton.icon(
  key: const Key('creative-card-add-link-button'),
  onPressed: () => _addLinkAttachment(card),
  icon: const Icon(Icons.link, size: 16),
  label: const Text('Añadir enlace'),
),
```

Add label:

```dart
String _attachmentKindLabel(CreativeCardAttachmentKind kind) {
  return switch (kind) {
    CreativeCardAttachmentKind.link => 'Enlace',
    CreativeCardAttachmentKind.image => 'Imagen',
  };
}
```

- [ ] **Step 4: Run tests and commit**

Run:

```bash
dart format lib/editor/widgets/creative_card_detail_panel.dart test/creative_card_detail_panel_test.dart
flutter test test/creative_card_detail_panel_test.dart --reporter expanded
flutter analyze lib/editor/widgets/creative_card_detail_panel.dart test/creative_card_detail_panel_test.dart
```

Expected: all pass.

Commit:

```bash
git add lib/editor/widgets/creative_card_detail_panel.dart test/creative_card_detail_panel_test.dart
git commit -m "feat: edit creative card attachments"
```

---

## Task 4: Explicit Entity Links

**Files:**
- Modify: `lib/modules/books/providers/workspace_providers.dart`
- Modify: `lib/editor/widgets/creative_card_detail_panel.dart`
- Test: `test/creative_workspace_test.dart`
- Test: `test/creative_card_detail_panel_test.dart`

- [ ] **Step 1: Write failing unlink-capable workspace test**

Append to `test/creative_workspace_test.dart`:

```dart
test('workspace notifier can replace creative card links with empty lists',
    () async {
  final now = DateTime.utc(2026, 5, 7);
  final repository = _MemoryWorkspaceRepository(NarrativeWorkspace(
    appSettings: const AppSettings(activeBookId: 'book-1'),
    books: [
      Book(id: 'book-1', title: 'Libro', createdAt: now, updatedAt: now),
    ],
    creativeCards: [
      CreativeCard(
        id: 'creative-1',
        bookId: 'book-1',
        title: 'Idea',
        linkedCharacterIds: const ['char-1'],
        linkedScenarioIds: const ['scenario-1'],
        linkedDocumentIds: const ['doc-1'],
        linkedNoteIds: const ['note-1'],
        createdAt: now,
        updatedAt: now,
      ),
    ],
  ));
  final container = ProviderContainer(
    overrides: [
      narrativeWorkspaceRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  await container.read(narrativeWorkspaceProvider.notifier).bootstrap();

  await container.read(narrativeWorkspaceProvider.notifier).setCreativeCardLinks(
        cardId: 'creative-1',
        characterIds: const [],
        scenarioIds: const [],
        documentIds: const [],
        noteIds: const [],
      );

  final card = container.read(activeCreativeCardsProvider).single;
  expect(card.linkedCharacterIds, isEmpty);
  expect(card.linkedScenarioIds, isEmpty);
  expect(card.linkedDocumentIds, isEmpty);
  expect(card.linkedNoteIds, isEmpty);
});
```

- [ ] **Step 2: Run test and verify failure**

Run:

```bash
flutter test test/creative_workspace_test.dart --reporter expanded
```

Expected: FAIL because `setCreativeCardLinks` does not exist.

- [ ] **Step 3: Implement `setCreativeCardLinks`**

Add this method near `linkCreativeCard` in `NarrativeWorkspaceNotifier`:

```dart
Future<void> setCreativeCardLinks({
  required String cardId,
  required List<String> characterIds,
  required List<String> scenarioIds,
  required List<String> documentIds,
  required List<String> noteIds,
}) async {
  final workspace = state.value;
  if (workspace == null) return;

  final now = DateTime.now();
  String? bookId;
  var changed = false;
  final updatedCards = workspace.creativeCards.map((card) {
    if (card.id != cardId) return card;
    bookId = card.bookId;
    if (_stringListsEqual(card.linkedCharacterIds, characterIds) &&
        _stringListsEqual(card.linkedScenarioIds, scenarioIds) &&
        _stringListsEqual(card.linkedDocumentIds, documentIds) &&
        _stringListsEqual(card.linkedNoteIds, noteIds)) {
      return card;
    }
    changed = true;
    return card.copyWith(
      linkedCharacterIds: characterIds,
      linkedScenarioIds: scenarioIds,
      linkedDocumentIds: documentIds,
      linkedNoteIds: noteIds,
      updatedAt: now,
    );
  }).toList();
  if (!changed) return;

  await _persist(
    workspace.copyWith(
      creativeCards: updatedCards,
      books: _touchActiveBook(workspace.books, bookId, now),
    ),
  );
}
```

- [ ] **Step 4: Add failing detail link test**

Append to `test/creative_card_detail_panel_test.dart`:

```dart
testWidgets('detail panel links and unlinks existing entities', (tester) async {
  final now = DateTime.utc(2026, 5, 7);
  final repository = _MemoryWorkspaceRepository(_workspaceWithCard(
    extraCharacters: [
      Character(id: 'char-1', bookId: 'book-1', name: 'Clara', createdAt: now, updatedAt: now),
    ],
    extraScenarios: [
      Scenario(id: 'scenario-1', bookId: 'book-1', name: 'Callejón', createdAt: now, updatedAt: now),
    ],
    extraDocuments: [
      Document(id: 'doc-1', bookId: 'book-1', title: 'Capítulo 1', orderIndex: 0, createdAt: now, updatedAt: now),
    ],
    extraNotes: [
      Note(id: 'note-1', bookId: 'book-1', title: 'Pista', createdAt: now, updatedAt: now),
    ],
  ));
  final card = repository.workspace.creativeCards.single;

  await tester.pumpWidget(_app(repository, CreativeCardDetailPanel(card: card)));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('creative-link-character-char-1')));
  await tester.tap(find.byKey(const Key('creative-link-scenario-scenario-1')));
  await tester.tap(find.byKey(const Key('creative-link-document-doc-1')));
  await tester.tap(find.byKey(const Key('creative-link-note-note-1')));
  await tester.pumpAndSettle();

  var stored = repository.workspace.creativeCards.single;
  expect(stored.linkedCharacterIds, ['char-1']);
  expect(stored.linkedScenarioIds, ['scenario-1']);
  expect(stored.linkedDocumentIds, ['doc-1']);
  expect(stored.linkedNoteIds, ['note-1']);

  await tester.tap(find.byKey(const Key('creative-link-character-char-1')));
  await tester.pumpAndSettle();

  stored = repository.workspace.creativeCards.single;
  expect(stored.linkedCharacterIds, isEmpty);
});
```

Add imports in the test:

```dart
import 'package:musa/modules/characters/models/character.dart';
import 'package:musa/modules/manuscript/models/document.dart';
import 'package:musa/modules/notes/models/note.dart';
import 'package:musa/modules/scenarios/models/scenario.dart';
```

Extend `_workspaceWithCard` helper with lists for those entities.

Use this concrete helper shape:

```dart
NarrativeWorkspace _workspaceWithCard({
  CreativeCardStatus status = CreativeCardStatus.inbox,
  CreativeCardConversion? convertedTo,
  List<CreativeCardAttachment> attachments = const [],
  List<Character> extraCharacters = const [],
  List<Scenario> extraScenarios = const [],
  List<Document> extraDocuments = const [],
  List<Note> extraNotes = const [],
}) {
  final now = DateTime.utc(2026, 5, 7);
  return NarrativeWorkspace(
    appSettings: const AppSettings(activeBookId: 'book-1'),
    books: [
      Book(id: 'book-1', title: 'Libro', createdAt: now, updatedAt: now),
    ],
    characters: extraCharacters,
    scenarios: extraScenarios,
    documents: extraDocuments,
    notes: extraNotes,
    creativeCards: [
      CreativeCard(
        id: 'creative-1',
        bookId: 'book-1',
        title: 'Puerta azul',
        body: 'Aparece cuando Clara miente.',
        status: status,
        convertedTo: convertedTo,
        tags: const ['clara'],
        attachments: attachments,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}
```

- [ ] **Step 5: Implement link sections**

In `CreativeCardDetailPanel`, read active workspace lists:

```dart
final workspace = ref.watch(narrativeWorkspaceProvider).value;
final characters = workspace?.activeBookCharacters ?? const [];
final scenarios = workspace?.activeBookScenarios ?? const [];
final documents = workspace?.activeBookDocuments ?? const [];
final notes = workspace?.activeBookNotes ?? const [];
```

Add a toggle helper:

```dart
Future<void> _toggleLink({
  required CreativeCard card,
  String? characterId,
  String? scenarioId,
  String? documentId,
  String? noteId,
}) async {
  List<String> toggle(List<String> ids, String? id) {
    if (id == null) return ids;
    return ids.contains(id)
        ? ids.where((item) => item != id).toList()
        : [...ids, id];
  }

  await ref.read(narrativeWorkspaceProvider.notifier).setCreativeCardLinks(
        cardId: card.id,
        characterIds: toggle(card.linkedCharacterIds, characterId),
        scenarioIds: toggle(card.linkedScenarioIds, scenarioId),
        documentIds: toggle(card.linkedDocumentIds, documentId),
        noteIds: toggle(card.linkedNoteIds, noteId),
      );
}
```

Render compact link chips:

```dart
Wrap(
  spacing: 6,
  runSpacing: 6,
  children: [
    for (final character in characters)
      FilterChip(
        key: Key('creative-link-character-${character.id}'),
        label: Text(character.displayName),
        selected: card.linkedCharacterIds.contains(character.id),
        onSelected: (_) => _toggleLink(card: card, characterId: character.id),
      ),
  ],
),
```

Repeat for scenarios, documents, and notes with keys:

```dart
creative-link-scenario-${scenario.id}
creative-link-document-${document.id}
creative-link-note-${note.id}
```

- [ ] **Step 6: Run tests and commit**

Run:

```bash
dart format lib/modules/books/providers/workspace_providers.dart lib/editor/widgets/creative_card_detail_panel.dart test/creative_workspace_test.dart test/creative_card_detail_panel_test.dart
flutter test test/creative_workspace_test.dart --reporter expanded
flutter test test/creative_card_detail_panel_test.dart --reporter expanded
flutter analyze lib/modules/books/providers/workspace_providers.dart lib/editor/widgets/creative_card_detail_panel.dart test/creative_workspace_test.dart test/creative_card_detail_panel_test.dart
```

Expected: all pass.

Commit:

```bash
git add lib/modules/books/providers/workspace_providers.dart lib/editor/widgets/creative_card_detail_panel.dart test/creative_workspace_test.dart test/creative_card_detail_panel_test.dart
git commit -m "feat: link creative cards to workspace entities"
```

---

## Task 5: Detail Actions And Board Integration Hardening

**Files:**
- Modify: `lib/editor/widgets/creative_card_detail_panel.dart`
- Modify: `lib/editor/widgets/creative_board_editor.dart`
- Test: `test/creative_card_detail_panel_test.dart`
- Test: `test/creative_board_editor_test.dart`

- [ ] **Step 1: Add failing action tests**

Append to `test/creative_card_detail_panel_test.dart`:

```dart
testWidgets('detail panel converts an unconverted card to a note',
    (tester) async {
  final repository = _MemoryWorkspaceRepository(_workspaceWithCard());
  final card = repository.workspace.creativeCards.single;

  await tester.pumpWidget(_app(repository, CreativeCardDetailPanel(card: card)));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('creative-detail-convert-note')));
  await tester.pumpAndSettle();

  final stored = repository.workspace.creativeCards.single;
  expect(repository.workspace.notes, hasLength(1));
  expect(stored.status, CreativeCardStatus.converted);
  expect(stored.convertedTo?.kind, CreativeCardConversionKind.note);
});

testWidgets('detail panel archives an unconverted card', (tester) async {
  final repository = _MemoryWorkspaceRepository(_workspaceWithCard());
  final card = repository.workspace.creativeCards.single;

  await tester.pumpWidget(_app(repository, CreativeCardDetailPanel(card: card)));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('creative-detail-archive')));
  await tester.pumpAndSettle();

  expect(repository.workspace.creativeCards.single.status,
      CreativeCardStatus.archived);
});
```

Append to `test/creative_board_editor_test.dart`:

```dart
testWidgets('archiving selected card returns board to empty detail state',
    (tester) async {
  final repository = _MemoryWorkspaceRepository(
    _workspaceWithCards([
      _card('card-1', 'Idea archivada', CreativeCardStatus.inbox),
    ]),
  );

  await tester.pumpWidget(_app(repository, const CreativeBoardEditor()));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('creative-card-tile-card-1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('creative-detail-archive')));
  await tester.pumpAndSettle();

  expect(find.text('Selecciona una tarjeta'), findsOneWidget);
  expect(find.text('Idea archivada'), findsNothing);
});
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
flutter test test/creative_card_detail_panel_test.dart test/creative_board_editor_test.dart --reporter expanded
```

Expected: FAIL because action buttons are missing or selection cleanup still keeps a stale selected card.

- [ ] **Step 3: Add detail actions**

In `CreativeCardDetailPanel`, render action buttons only for unconverted cards:

```dart
if (card.status != CreativeCardStatus.converted) ...[
  const SizedBox(height: 14),
  Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      FilledButton.tonal(
        key: const Key('creative-detail-convert-note'),
        onPressed: () => _convertAndReturn(
          () => ref.read(narrativeWorkspaceProvider.notifier)
              .convertCreativeCardToNote(card.id),
        ),
        child: const Text('Convertir en nota'),
      ),
      OutlinedButton(
        key: const Key('creative-detail-convert-character'),
        onPressed: () => _convertAndReturn(
          () => ref.read(narrativeWorkspaceProvider.notifier)
              .convertCreativeCardToCharacter(card.id),
        ),
        child: const Text('Personaje'),
      ),
      OutlinedButton(
        key: const Key('creative-detail-convert-scenario'),
        onPressed: () => _convertAndReturn(
          () => ref.read(narrativeWorkspaceProvider.notifier)
              .convertCreativeCardToScenario(card.id),
        ),
        child: const Text('Escenario'),
      ),
      OutlinedButton(
        key: const Key('creative-detail-convert-document'),
        onPressed: () => _convertAndReturn(
          () => ref.read(narrativeWorkspaceProvider.notifier)
              .convertCreativeCardToDocument(card.id),
        ),
        child: const Text('Documento'),
      ),
      TextButton(
        key: const Key('creative-detail-archive'),
        onPressed: () => ref
            .read(narrativeWorkspaceProvider.notifier)
            .archiveCreativeCard(card.id),
        child: const Text('Archivar'),
      ),
    ],
  ),
]
```

Add helper:

```dart
Future<void> _convertAndReturn(Future<Object?> Function() convert) async {
  await convert();
  await ref.read(narrativeWorkspaceProvider.notifier).openCreativeBoard();
}
```

- [ ] **Step 4: Ensure board selection cleanup works after archive**

Always key the detail panel by selected card id so Flutter does not preserve stale detail state:

```dart
CreativeCardDetailPanel(
  key: ValueKey(selectedCard?.id ?? 'empty-creative-card-detail'),
  card: selectedCard,
)
```

- [ ] **Step 5: Run tests and commit**

Run:

```bash
dart format lib/editor/widgets/creative_card_detail_panel.dart lib/editor/widgets/creative_board_editor.dart test/creative_card_detail_panel_test.dart test/creative_board_editor_test.dart
flutter test test/creative_card_detail_panel_test.dart --reporter expanded
flutter test test/creative_board_editor_test.dart --reporter expanded
flutter analyze lib/editor/widgets/creative_card_detail_panel.dart lib/editor/widgets/creative_board_editor.dart test/creative_card_detail_panel_test.dart test/creative_board_editor_test.dart
```

Expected: all pass.

Commit:

```bash
git add lib/editor/widgets/creative_card_detail_panel.dart lib/editor/widgets/creative_board_editor.dart test/creative_card_detail_panel_test.dart test/creative_board_editor_test.dart
git commit -m "feat: add creative card detail actions"
```

---

## Task 6: Memory, Changelog, Full Verification

**Files:**
- Modify: `ai/memory/PROJECT_MEMORY.md`
- Modify: `ai/memory/CHANGE_LOG.md`

- [ ] **Step 1: Update project memory**

Add under V3.1 in `ai/memory/PROJECT_MEMORY.md`:

```markdown
- **V3.2 (2026-05-07)**:
  - ✅ **Tarjeta creativa enriquecida**: cada `CreativeCard` puede abrirse en un panel de detalle para editar título, cuerpo, tipo, estado y tags.
  - ✅ **Adjuntos y vínculos explícitos**: las tarjetas gestionan enlaces, referencias de imagen y relaciones con personajes, escenarios, documentos y notas del libro activo.
  - ✅ **Antesala no canónica reforzada**: las tarjetas siguen fuera de memoria narrativa, continuidad y auditoría hasta conversión o acción explícita.
```

Add under recurring restrictions:

```markdown
- V3.2 mantiene adjuntos de imagen como referencias URI/ruta; no copiar archivos al `.musa` hasta que exista gestor de media explícito.
```

- [ ] **Step 2: Update changelog**

Create a new `## 2026-05-07` heading in `ai/memory/CHANGE_LOG.md` if it is not already present, then add:

```markdown
- Se registra V3.2 en memoria estable: detalle enriquecido de tarjetas creativas con edición, adjuntos y vínculos explícitos.
```

- [ ] **Step 3: Run focused tests**

Run:

```bash
flutter test test/creative_card_model_test.dart --reporter expanded
flutter test test/creative_workspace_test.dart --reporter expanded
flutter test test/creative_conversion_test.dart --reporter expanded
flutter test test/creative_board_editor_test.dart --reporter expanded
flutter test test/creative_card_detail_panel_test.dart --reporter expanded
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

- [ ] **Step 6: Check diff cleanliness**

Run:

```bash
git diff --check
git status -sb
```

Expected: no whitespace errors and only intended files modified.

- [ ] **Step 7: Commit and push**

Commit:

```bash
git add ai/memory/PROJECT_MEMORY.md ai/memory/CHANGE_LOG.md
git commit -m "docs: record creative card detail"
git push origin main
```

Expected: push succeeds.

---

## Self-Review

Spec coverage:

- Editable fields are covered in Task 2.
- Link and image-reference attachments are covered in Task 3.
- Links to characters, scenarios, documents and notes are covered in Task 4.
- Converted-card restrictions and conversion/archive actions are covered in Task 5.
- Memory/changelog and full verification are covered in Task 6.
- No mobile direct capture or canvas work is included.

Placeholder scan:

- No unfinished tasks or unresolved method names are intentionally left.

Type consistency:

- Core types remain `CreativeCard`, `CreativeCardAttachment`, `CreativeCardType`, `CreativeCardStatus`, `CreativeCardAttachmentKind`.
- New helper is consistently named `setCreativeCardLinks`.
- Detail widget is consistently named `CreativeCardDetailPanel`.
