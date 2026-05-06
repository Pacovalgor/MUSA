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
  });
}
