import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/app_settings.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_workspace.dart';
import 'package:musa/modules/books/providers/workspace_providers.dart';
import 'package:musa/modules/books/services/narrative_workspace_repository.dart';
import 'package:musa/modules/creative/models/creative_card.dart';
import 'package:musa/modules/creative/providers/creative_providers.dart';

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

    test('activeBookCreativeCards filters and sorts by updatedAt descending',
        () {
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

    test('activeCreativeCardsProvider returns active book cards only',
        () async {
      final now = DateTime.utc(2026, 5, 7);
      final repository = _MemoryWorkspaceRepository(NarrativeWorkspace(
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
      final container = ProviderContainer(
        overrides: [
          narrativeWorkspaceRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(narrativeWorkspaceProvider.notifier).bootstrap();

      expect(
        container.read(activeCreativeCardsProvider).map((card) => card.id),
        ['active'],
      );
    });

    test(
        'workspace notifier can create, update, move and archive creative cards',
        () async {
      final now = DateTime.utc(2026, 5, 7);
      final repository = _MemoryWorkspaceRepository(NarrativeWorkspace(
        appSettings: const AppSettings(activeBookId: 'book-1'),
        books: [
          Book(id: 'book-1', title: 'Libro', createdAt: now, updatedAt: now),
        ],
      ));
      final container = ProviderContainer(
        overrides: [
          narrativeWorkspaceRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(narrativeWorkspaceProvider.notifier);
      await notifier.bootstrap();
      final created = await notifier.createCreativeCard(
        title: 'Puerta azul',
        body: 'Aparece cuando Clara miente.',
        type: CreativeCardType.idea,
        tags: const ['clara'],
      );

      expect(created, isNotNull);
      expect(
        container.read(activeCreativeCardsProvider).single.title,
        'Puerta azul',
      );

      await notifier.updateCreativeCard(
        created!.copyWith(title: 'Puerta roja', body: 'Otra version.'),
      );
      expect(
        container.read(activeCreativeCardsProvider).single.title,
        'Puerta roja',
      );

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

      final notifier = container.read(narrativeWorkspaceProvider.notifier);
      await notifier.bootstrap();
      await notifier.linkCreativeCard(
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

    test('workspace notifier ignores unknown creative card ids', () async {
      final now = DateTime.utc(2026, 5, 7);
      final card = CreativeCard(
        id: 'creative-1',
        bookId: 'book-1',
        title: 'Idea',
        createdAt: now,
        updatedAt: now,
      );
      final repository = _MemoryWorkspaceRepository(NarrativeWorkspace(
        appSettings: const AppSettings(activeBookId: 'book-1'),
        books: [
          Book(id: 'book-1', title: 'Libro', createdAt: now, updatedAt: now),
        ],
        creativeCards: [card],
      ));
      final container = ProviderContainer(
        overrides: [
          narrativeWorkspaceRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(narrativeWorkspaceProvider.notifier);
      await notifier.bootstrap();
      await notifier.updateCreativeCard(CreativeCard(
        id: 'missing',
        bookId: 'book-1',
        title: 'No existe',
        createdAt: now,
        updatedAt: now,
      ));
      await notifier.moveCreativeCard(
        cardId: 'missing',
        status: CreativeCardStatus.archived,
      );
      await notifier.linkCreativeCard(
        cardId: 'missing',
        characterIds: const ['char-1'],
      );

      expect(repository.workspace.creativeCards.single.toJson(), card.toJson());
      expect(repository.workspace.books.single.updatedAt, now);
    });

    test('workspace notifier ignores no-op creative card updates', () async {
      final now = DateTime.utc(2026, 5, 7);
      final card = CreativeCard(
        id: 'creative-1',
        bookId: 'book-1',
        title: 'Idea',
        body: 'Sin cambios',
        tags: const ['clara'],
        createdAt: now,
        updatedAt: now,
      );
      final repository = _MemoryWorkspaceRepository(NarrativeWorkspace(
        appSettings: const AppSettings(activeBookId: 'book-1'),
        books: [
          Book(id: 'book-1', title: 'Libro', createdAt: now, updatedAt: now),
        ],
        creativeCards: [card],
      ));
      final container = ProviderContainer(
        overrides: [
          narrativeWorkspaceRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(narrativeWorkspaceProvider.notifier);
      await notifier.bootstrap();
      await notifier.updateCreativeCard(card);

      expect(repository.workspace.creativeCards.single.toJson(), card.toJson());
      expect(repository.workspace.books.single.updatedAt, now);
    });

    test('workspace notifier preserves creative card book ownership on update',
        () async {
      final now = DateTime.utc(2026, 5, 7);
      final repository = _MemoryWorkspaceRepository(NarrativeWorkspace(
        appSettings: const AppSettings(activeBookId: 'book-1'),
        books: [
          Book(id: 'book-1', title: 'Uno', createdAt: now, updatedAt: now),
          Book(id: 'book-2', title: 'Dos', createdAt: now, updatedAt: now),
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
      final container = ProviderContainer(
        overrides: [
          narrativeWorkspaceRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(narrativeWorkspaceProvider.notifier);
      await notifier.bootstrap();
      await notifier.updateCreativeCard(CreativeCard(
        id: 'creative-1',
        bookId: 'book-2',
        title: 'Idea revisada',
        createdAt: now,
        updatedAt: now,
      ));

      final updated = repository.workspace.creativeCards.single;
      expect(updated.bookId, 'book-1');
      expect(updated.title, 'Idea revisada');
      expect(repository.workspace.books.first.updatedAt, isNot(now));
      expect(repository.workspace.books.last.updatedAt, now);
    });
  });
}
