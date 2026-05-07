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
    final card = _card('card-1', 'Puerta azul', CreativeCardStatus.inbox);
    final repository = _MemoryWorkspaceRepository(_workspaceWithCards([card]));

    await tester
        .pumpWidget(_app(repository, CreativeCardDetailPanel(card: card)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('creative-card-detail-title-field')),
      '  Puerta roja  ',
    );
    await tester.enterText(
      find.byKey(const Key('creative-card-detail-body-field')),
      '  Clara la encuentra en el sotano.  ',
    );
    await tester.enterText(
      find.byKey(const Key('creative-card-detail-tags-field')),
      ' clara, misterio, , sotano ',
    );
    await tester.tap(find.byKey(const Key('creative-card-detail-save-button')));
    await tester.pumpAndSettle();

    final stored = repository.workspace.creativeCards.single;
    expect(stored.title, 'Puerta roja');
    expect(stored.body, 'Clara la encuentra en el sotano.');
    expect(stored.tags, ['clara', 'misterio', 'sotano']);
  });

  testWidgets('converted card cannot be moved to editable statuses',
      (tester) async {
    const conversion = CreativeCardConversion(
      kind: CreativeCardConversionKind.note,
      targetId: 'note-1',
    );
    final card = _card(
      'card-1',
      'Puerta convertida',
      CreativeCardStatus.converted,
      type: CreativeCardType.character,
      convertedTo: conversion,
    );
    final repository = _MemoryWorkspaceRepository(_workspaceWithCards([card]));

    await tester
        .pumpWidget(_app(repository, CreativeCardDetailPanel(card: card)));
    await tester.pumpAndSettle();

    final typeDropdown = tester.widget<DropdownButton<CreativeCardType>>(
      find.byType(DropdownButton<CreativeCardType>),
    );
    expect(typeDropdown.onChanged, isNull);
    expect(
      find.byKey(const Key('creative-card-detail-status-field')),
      findsNothing,
    );
    expect(find.text('Convertida'), findsOneWidget);

    await tester.tap(find.byKey(const Key('creative-card-detail-save-button')));
    await tester.pumpAndSettle();

    final stored = repository.workspace.creativeCards.single;
    expect(stored.type, CreativeCardType.character);
    expect(stored.status, CreativeCardStatus.converted);
    expect(stored.convertedTo?.kind, CreativeCardConversionKind.note);
    expect(stored.convertedTo?.targetId, 'note-1');
  });

  testWidgets('same-card external status move is preserved when saving title',
      (tester) async {
    final card = _card('card-1', 'Puerta azul', CreativeCardStatus.inbox);
    final repository = _MemoryWorkspaceRepository(_workspaceWithCards([card]));

    await tester.pumpWidget(
      _app(
        repository,
        Consumer(
          builder: (context, ref, _) {
            final workspace = ref.watch(narrativeWorkspaceProvider).value;
            final selectedCard = workspace?.creativeCards
                .where((item) => item.id == 'card-1')
                .firstOrNull;
            return CreativeCardDetailPanel(card: selectedCard);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CreativeCardDetailPanel)),
    );
    await container.read(narrativeWorkspaceProvider.notifier).moveCreativeCard(
          cardId: 'card-1',
          status: CreativeCardStatus.readyToUse,
        );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('creative-card-detail-title-field')),
      'Puerta roja',
    );
    await tester.tap(find.byKey(const Key('creative-card-detail-save-button')));
    await tester.pumpAndSettle();

    final stored = repository.workspace.creativeCards.single;
    expect(stored.title, 'Puerta roja');
    expect(stored.status, CreativeCardStatus.readyToUse);
  });

  testWidgets('detail panel adds and removes link attachments', (tester) async {
    final repository = _MemoryWorkspaceRepository(_workspaceWithCard());
    final card = repository.workspace.creativeCards.single;

    await tester
        .pumpWidget(_app(repository, CreativeCardDetailPanel(card: card)));
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

    await tester.tap(
      find.byKey(
        Key('creative-card-remove-attachment-${stored.attachments.single.id}'),
      ),
    );
    await tester.pumpAndSettle();

    stored = repository.workspace.creativeCards.single;
    expect(stored.attachments, isEmpty);
  });

  testWidgets('detail panel shows image attachment as reference text',
      (tester) async {
    final now = DateTime.utc(2026, 5, 7);
    final repository = _MemoryWorkspaceRepository(
      _workspaceWithCard(
        attachments: [
          CreativeCardAttachment(
            id: 'image-1',
            kind: CreativeCardAttachmentKind.image,
            uri: '/tmp/reference.png',
            title: 'Foto de referencia',
            createdAt: now,
          ),
        ],
      ),
    );
    final card = repository.workspace.creativeCards.single;

    await tester
        .pumpWidget(_app(repository, CreativeCardDetailPanel(card: card)));
    await tester.pumpAndSettle();

    expect(find.text('Foto de referencia'), findsOneWidget);
    expect(find.text('/tmp/reference.png'), findsOneWidget);
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

NarrativeWorkspace _workspaceWithCards(List<CreativeCard> cards) {
  final now = DateTime.utc(2026, 5, 7);
  return NarrativeWorkspace(
    appSettings: const AppSettings(activeBookId: 'book-1'),
    books: [
      Book(
        id: 'book-1',
        title: 'El ojo invisible',
        createdAt: now,
        updatedAt: now,
      ),
    ],
    creativeCards: cards,
  );
}

NarrativeWorkspace _workspaceWithCard({
  CreativeCardStatus status = CreativeCardStatus.inbox,
  CreativeCardConversion? convertedTo,
  List<CreativeCardAttachment> attachments = const [],
}) {
  return _workspaceWithCards([
    _card(
      'card-1',
      'Puerta azul',
      status,
      convertedTo: convertedTo,
      attachments: attachments,
    ),
  ]);
}

CreativeCard _card(
  String id,
  String title,
  CreativeCardStatus status, {
  CreativeCardType type = CreativeCardType.idea,
  CreativeCardConversion? convertedTo,
  List<CreativeCardAttachment> attachments = const [],
}) {
  final now = DateTime.utc(2026, 5, 7);
  return CreativeCard(
    id: id,
    bookId: 'book-1',
    title: title,
    body: 'Detalle inicial',
    type: type,
    status: status,
    tags: const ['inicial'],
    attachments: attachments,
    convertedTo: convertedTo,
    createdAt: now,
    updatedAt: now,
  );
}
