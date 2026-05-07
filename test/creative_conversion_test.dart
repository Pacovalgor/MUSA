import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/app_settings.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_workspace.dart';
import 'package:musa/modules/books/providers/workspace_providers.dart';
import 'package:musa/modules/books/services/narrative_workspace_repository.dart';
import 'package:musa/modules/characters/models/character.dart';
import 'package:musa/modules/creative/models/creative_card.dart';
import 'package:musa/modules/creative/providers/creative_providers.dart';
import 'package:musa/modules/manuscript/models/document.dart';
import 'package:musa/modules/notes/models/note.dart';
import 'package:musa/modules/scenarios/models/scenario.dart';

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
  group('Creative card conversions', () {
    test('converts a card to a note and marks the card converted', () async {
      final container = await _containerWithCard();
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
      final container = await _containerWithCard(
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
      expect(
          container.read(activeCreativeCardsProvider).single.linkedCharacterIds,
          contains(character.id));
    });

    test('converts a card to a scenario and marks the card converted',
        () async {
      final container = await _containerWithCard(
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
      expect(
          container.read(activeCreativeCardsProvider).single.linkedScenarioIds,
          contains(scenario.id));
    });

    test('converts a card to a scratch document and marks the card converted',
        () async {
      final container = await _containerWithCard(type: CreativeCardType.sketch);
      addTearDown(container.dispose);

      final document = await container
          .read(narrativeWorkspaceProvider.notifier)
          .convertCreativeCardToDocument('creative-1');

      expect(document, isNotNull);
      expect(document!.title, 'La puerta azul');
      expect(document.kind, DocumentKind.scratch);
      expect(document.content, contains('Clara'));
      expect(
          container.read(activeCreativeCardsProvider).single.linkedDocumentIds,
          contains(document.id));
    });

    test('returns null and does not persist when card id is unknown', () async {
      final container = await _containerWithCard();
      addTearDown(container.dispose);

      final notifier = container.read(narrativeWorkspaceProvider.notifier);
      final note = await notifier.convertCreativeCardToNote('missing');
      final character =
          await notifier.convertCreativeCardToCharacter('missing');
      final scenario = await notifier.convertCreativeCardToScenario('missing');
      final document = await notifier.convertCreativeCardToDocument('missing');

      final workspace = notifier.state.value!;
      expect(note, isNull);
      expect(character, isNull);
      expect(scenario, isNull);
      expect(document, isNull);
      expect(workspace.notes, isEmpty);
      expect(workspace.characters, isEmpty);
      expect(workspace.scenarios, isEmpty);
      expect(workspace.documents, isEmpty);
      expect(workspace.creativeCards.single.status, CreativeCardStatus.inbox);
    });

    test('does not duplicate note conversion for an already converted card',
        () async {
      final now = DateTime.utc(2026, 5, 7);
      final note = Note(
        id: 'note-1',
        bookId: 'book-1',
        title: 'La puerta azul',
        content: 'Aparece cuando Clara miente.',
        kind: NoteKind.idea,
        createdAt: now,
        updatedAt: now,
      );
      final container = await _containerWithCard(
        existingNotes: [note],
        card: CreativeCard(
          id: 'creative-1',
          bookId: 'book-1',
          title: 'La puerta azul',
          body: 'Aparece cuando Clara miente.',
          status: CreativeCardStatus.converted,
          linkedNoteIds: const ['note-1'],
          convertedTo: const CreativeCardConversion(
            kind: CreativeCardConversionKind.note,
            targetId: 'note-1',
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );
      addTearDown(container.dispose);

      final first = await container
          .read(narrativeWorkspaceProvider.notifier)
          .convertCreativeCardToNote('creative-1');
      final second = await container
          .read(narrativeWorkspaceProvider.notifier)
          .convertCreativeCardToNote('creative-1');

      final workspace = container.read(narrativeWorkspaceProvider).value!;
      expect(first?.id, 'note-1');
      expect(second?.id, 'note-1');
      expect(workspace.notes, hasLength(1));
      expect(workspace.creativeCards.single.linkedNoteIds, ['note-1']);
    });

    test(
        'does not convert an already converted card to a different target type',
        () async {
      final now = DateTime.utc(2026, 5, 7);
      final note = Note(
        id: 'note-1',
        bookId: 'book-1',
        title: 'La puerta azul',
        content: 'Aparece cuando Clara miente.',
        kind: NoteKind.idea,
        createdAt: now,
        updatedAt: now,
      );
      final container = await _containerWithCard(
        existingNotes: [note],
        card: CreativeCard(
          id: 'creative-1',
          bookId: 'book-1',
          title: 'Diane',
          body: 'Aparece cuando Clara miente.',
          status: CreativeCardStatus.converted,
          linkedNoteIds: const ['note-1'],
          convertedTo: const CreativeCardConversion(
            kind: CreativeCardConversionKind.note,
            targetId: 'note-1',
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );
      addTearDown(container.dispose);

      final character = await container
          .read(narrativeWorkspaceProvider.notifier)
          .convertCreativeCardToCharacter('creative-1');

      final workspace = container.read(narrativeWorkspaceProvider).value!;
      expect(character, isNull);
      expect(workspace.characters, isEmpty);
      expect(workspace.notes, hasLength(1));
      expect(workspace.creativeCards.single.convertedTo?.targetId, 'note-1');
    });

    test('conversion uses card book even when another book is active',
        () async {
      final now = DateTime.utc(2026, 5, 7);
      final container = await _containerWithCard(
        activeBookId: 'book-2',
        extraBooks: [
          Book(id: 'book-2', title: 'Dos', createdAt: now, updatedAt: now),
        ],
      );
      addTearDown(container.dispose);

      final note = await container
          .read(narrativeWorkspaceProvider.notifier)
          .convertCreativeCardToNote('creative-1');

      final workspace = container.read(narrativeWorkspaceProvider).value!;
      expect(note?.bookId, 'book-1');
      expect(workspace.books.first.updatedAt, isNot(now));
      expect(workspace.books.last.updatedAt, now);
    });

    test('document conversion uses next order index for the card book only',
        () async {
      final now = DateTime.utc(2026, 5, 7);
      final container = await _containerWithCard(
        existingDocuments: [
          Document(
            id: 'doc-1',
            bookId: 'book-1',
            title: 'Capítulo',
            orderIndex: 4,
            createdAt: now,
            updatedAt: now,
          ),
          Document(
            id: 'doc-2',
            bookId: 'book-2',
            title: 'Otro libro',
            orderIndex: 99,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      addTearDown(container.dispose);

      final document = await container
          .read(narrativeWorkspaceProvider.notifier)
          .convertCreativeCardToDocument('creative-1');

      expect(document?.orderIndex, 5);
    });
  });
}

Future<ProviderContainer> _containerWithCard({
  CreativeCardType type = CreativeCardType.idea,
  String title = 'La puerta azul',
  String activeBookId = 'book-1',
  List<Book> extraBooks = const [],
  CreativeCard? card,
  List<Note> existingNotes = const [],
  List<Character> existingCharacters = const [],
  List<Scenario> existingScenarios = const [],
  List<Document> existingDocuments = const [],
}) async {
  final now = DateTime.utc(2026, 5, 7);
  final repository = _MemoryWorkspaceRepository(NarrativeWorkspace(
    appSettings: AppSettings(activeBookId: activeBookId),
    books: [
      Book(id: 'book-1', title: 'Libro', createdAt: now, updatedAt: now),
      ...extraBooks,
    ],
    notes: existingNotes,
    characters: existingCharacters,
    scenarios: existingScenarios,
    documents: existingDocuments,
    creativeCards: [
      card ??
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
  final container = ProviderContainer(
    overrides: [
      narrativeWorkspaceRepositoryProvider.overrideWithValue(repository),
    ],
  );
  await container.read(narrativeWorkspaceProvider.notifier).bootstrap();
  return container;
}
