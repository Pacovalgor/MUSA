import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/app_settings.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_workspace.dart';
import 'package:musa/modules/books/providers/workspace_providers.dart';
import 'package:musa/modules/books/services/narrative_workspace_repository.dart';
import 'package:musa/modules/creative/models/creative_card.dart';
import 'package:musa/modules/creative/providers/creative_providers.dart';
import 'package:musa/modules/manuscript/models/document.dart';
import 'package:musa/modules/notes/models/note.dart';

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
  });
}

Future<ProviderContainer> _containerWithCard({
  CreativeCardType type = CreativeCardType.idea,
  String title = 'La puerta azul',
}) async {
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
