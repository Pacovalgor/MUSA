import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musa/core/theme.dart';
import 'package:musa/editor/widgets/creative_board_editor.dart';
import 'package:musa/modules/books/models/app_settings.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_workspace.dart';
import 'package:musa/modules/books/providers/workspace_providers.dart';
import 'package:musa/modules/books/services/narrative_workspace_repository.dart';
import 'package:musa/modules/creative/models/creative_card.dart';
import 'package:musa/ui/widgets/sidebar.dart';

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
  testWidgets(
    'board renders active book cards by status and hides archived cards',
    (tester) async {
      final repository = _MemoryWorkspaceRepository(
        _workspaceWithCards([
          _card('inbox', 'Semilla inicial', CreativeCardStatus.inbox),
          _card('exploring', 'Mirada lateral', CreativeCardStatus.exploring),
          _card('ready', 'Escena preparada', CreativeCardStatus.readyToUse),
          _card('archived', 'Idea vieja', CreativeCardStatus.archived),
        ]),
      );

      await tester.pumpWidget(_app(repository, const CreativeBoardEditor()));
      await tester.pumpAndSettle();

      expect(find.text('Mesa creativa'), findsOneWidget);
      expect(find.text('Libro: El ojo invisible'), findsOneWidget);
      expect(find.text('Inbox'), findsWidgets);
      expect(find.text('Explorando'), findsWidgets);
      expect(find.text('Prometedoras'), findsOneWidget);
      expect(find.text('Listas'), findsWidgets);
      expect(find.text('Convertidas'), findsOneWidget);
      expect(find.text('Semilla inicial'), findsOneWidget);
      expect(find.text('Mirada lateral'), findsOneWidget);
      expect(find.text('Escena preparada'), findsOneWidget);
      expect(find.text('Idea vieja'), findsNothing);
    },
  );

  testWidgets('sidebar opens creative mode', (tester) async {
    final repository = _MemoryWorkspaceRepository(_workspaceWithCards());

    await tester.pumpWidget(_app(repository, const MusaSidebar()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mesa creativa'));
    await tester.pumpAndSettle();

    expect(repository.workspace.editorMode, WorkspaceEditorMode.creative);
  });

  testWidgets('creating a card persists it to the active book', (tester) async {
    final repository = _MemoryWorkspaceRepository(_workspaceWithCards());

    await tester.pumpWidget(_app(repository, const CreativeBoardEditor()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('creative-card-title-field')),
      'Puerta azul',
    );
    await tester.enterText(
      find.byKey(const Key('creative-card-body-field')),
      'Aparece cuando Clara miente.',
    );
    await tester.tap(find.byKey(const Key('creative-card-create-button')));
    await tester.pumpAndSettle();

    final created = repository.workspace.activeBookCreativeCards.single;
    expect(created.bookId, 'book-1');
    expect(created.title, 'Puerta azul');
    expect(created.body, 'Aparece cuando Clara miente.');
    expect(created.type, CreativeCardType.idea);
    expect(find.text('Puerta azul'), findsOneWidget);
  });

  testWidgets('board can move a card between statuses', (tester) async {
    final repository = _MemoryWorkspaceRepository(
      _workspaceWithCards([
        _card('card-1', 'Mover esta idea', CreativeCardStatus.inbox),
      ]),
    );

    await tester.pumpWidget(_app(repository, const CreativeBoardEditor()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('creative-card-card-1-readyToUse')));
    await tester.pumpAndSettle();

    expect(
      repository.workspace.activeBookCreativeCards.single.status,
      CreativeCardStatus.readyToUse,
    );
    expect(find.text('Mover esta idea'), findsOneWidget);
  });

  testWidgets('creation form resets the visible type after create',
      (tester) async {
    final repository = _MemoryWorkspaceRepository(_workspaceWithCards());

    await tester.pumpWidget(_app(repository, const CreativeBoardEditor()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<CreativeCardType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personaje').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('creative-card-title-field')),
      'Diane',
    );
    await tester.tap(find.byKey(const Key('creative-card-create-button')));
    await tester.pumpAndSettle();

    expect(repository.workspace.activeBookCreativeCards.single.type,
        CreativeCardType.character);
    expect(find.byKey(const ValueKey(CreativeCardType.idea)), findsOneWidget);
    expect(
      find.byKey(const ValueKey(CreativeCardType.character)),
      findsNothing,
    );
  });

  testWidgets('converted cards cannot be moved back from the board',
      (tester) async {
    final repository = _MemoryWorkspaceRepository(
      _workspaceWithCards([
        _card('converted', 'Idea convertida', CreativeCardStatus.converted),
      ]),
    );

    await tester.pumpWidget(_app(repository, const CreativeBoardEditor()));
    await tester.pumpAndSettle();

    expect(find.text('Idea convertida'), findsOneWidget);
    expect(
      find.byKey(const Key('creative-card-converted-inbox')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('creative-card-converted-readyToUse')),
      findsNothing,
    );
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

NarrativeWorkspace _workspaceWithCards([List<CreativeCard> cards = const []]) {
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
  CreativeCardStatus status, {
  CreativeCardType type = CreativeCardType.idea,
}) {
  final now = DateTime.utc(2026, 5, 7);
  return CreativeCard(
    id: id,
    bookId: 'book-1',
    title: title,
    body: 'Detalle de $title',
    type: type,
    status: status,
    tags: const ['clara', 'umbral'],
    createdAt: now,
    updatedAt: now,
  );
}
