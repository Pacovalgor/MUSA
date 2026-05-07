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
    final card = _card(
      'card-1',
      'Puerta convertida',
      CreativeCardStatus.converted,
    );
    final repository = _MemoryWorkspaceRepository(_workspaceWithCards([card]));

    await tester
        .pumpWidget(_app(repository, CreativeCardDetailPanel(card: card)));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('creative-card-detail-status-field')),
      findsNothing,
    );
    expect(find.text('Convertida'), findsOneWidget);
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

CreativeCard _card(
  String id,
  String title,
  CreativeCardStatus status,
) {
  final now = DateTime.utc(2026, 5, 7);
  return CreativeCard(
    id: id,
    bookId: 'book-1',
    title: title,
    body: 'Detalle inicial',
    type: CreativeCardType.idea,
    status: status,
    tags: const ['inicial'],
    createdAt: now,
    updatedAt: now,
  );
}
