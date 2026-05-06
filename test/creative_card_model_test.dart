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
