import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_copilot.dart';
import 'package:musa/modules/characters/models/character.dart';
import 'package:musa/modules/continuity/models/continuity_audit.dart';
import 'package:musa/modules/continuity/models/continuity_state.dart';
import 'package:musa/modules/continuity/services/continuity_audit_service.dart';
import 'package:musa/modules/manuscript/models/document.dart';
import 'package:musa/modules/scenarios/models/scenario.dart';

void main() {
  final now = DateTime(2026, 5, 6, 12);

  group('ContinuityAuditService', () {
    test('flags unresolved promises as continuity risks', () {
      final findings = const ContinuityAuditService().audit(
        book: _book(now),
        documents: [
          _chapter(now, 0, 'Diane encontró una llave. ¿Quién abrió la puerta?'),
        ],
        memory: NarrativeMemory(
          bookId: 'book-1',
          readerPromises: const ['Diane descubrirá quién abrió la puerta.'],
          unresolvedPromises: const [
            '¿Quién abrió la puerta?',
            '¿Por qué la llave estaba escondida?',
            '¿Qué vio el testigo?',
          ],
          updatedAt: now,
        ),
        storyState: StoryState(bookId: 'book-1', updatedAt: now),
        continuityState: ContinuityState(bookId: 'book-1', lastUpdatedAt: now),
        characters: const [],
        scenarios: const [],
        now: now,
      );

      final promise = findings.firstWhere(
        (finding) => finding.type == ContinuityFindingType.unresolvedPromise,
      );
      expect(promise.severity, ContinuityFindingSeverity.warning);
      expect(promise.title, contains('Promesas'));
      expect(promise.action, contains('Cierra'));
    });

    test('flags explicit forbidden contradictions found in manuscript text',
        () {
      final findings = const ContinuityAuditService().audit(
        book: _book(now),
        documents: [
          _chapter(
            now,
            0,
            'Diane habló con Clara. Clara no tiene hermana y nunca salió de Madrid.',
          ),
        ],
        memory: NarrativeMemory.empty('book-1', now),
        storyState: StoryState(bookId: 'book-1', updatedAt: now),
        continuityState: ContinuityState(
          bookId: 'book-1',
          forbiddenContradictions: const ['Clara no tiene hermana'],
          lastUpdatedAt: now,
        ),
        characters: const [],
        scenarios: const [],
        now: now,
      );

      final contradiction = findings.firstWhere(
        (finding) => finding.type == ContinuityFindingType.contradiction,
      );
      expect(contradiction.severity, ContinuityFindingSeverity.critical);
      expect(contradiction.evidence, contains('Clara no tiene hermana'));
    });

    test('flags named characters and scenarios used before they have a sheet',
        () {
      final findings = const ContinuityAuditService().audit(
        book: _book(now),
        documents: [
          _chapter(
            now,
            0,
            'Clara entró en el Observatorio Norte. Diane la esperaba junto a la puerta.',
          ),
        ],
        memory: NarrativeMemory.empty('book-1', now),
        storyState: StoryState(bookId: 'book-1', updatedAt: now),
        continuityState: ContinuityState(bookId: 'book-1', lastUpdatedAt: now),
        characters: [
          _character(now, 'Diane'),
        ],
        scenarios: [
          _scenario(now, 'Callejón de Tenderloin'),
        ],
        now: now,
      );

      expect(
        findings.any(
          (finding) =>
              finding.type == ContinuityFindingType.untrackedCharacter &&
              finding.evidence.contains('Clara'),
        ),
        isTrue,
      );
      expect(
        findings.any(
          (finding) =>
              finding.type == ContinuityFindingType.untrackedScenario &&
              finding.evidence.contains('Observatorio Norte'),
        ),
        isTrue,
      );
    });

    test('returns an empty audit when continuity is coherent', () {
      final findings = const ContinuityAuditService().audit(
        book: _book(now),
        documents: [
          _chapter(now, 0, 'Diane entró en el callejón y cerró la puerta.'),
        ],
        memory: NarrativeMemory(
          bookId: 'book-1',
          readerPromises: const ['Diane resolverá el caso.'],
          updatedAt: now,
        ),
        storyState: StoryState(bookId: 'book-1', updatedAt: now),
        continuityState: ContinuityState(
          bookId: 'book-1',
          knownFacts: const ['Diane investiga el caso.'],
          lastUpdatedAt: now,
        ),
        characters: [
          _character(now, 'Diane'),
        ],
        scenarios: [
          _scenario(now, 'callejón'),
        ],
        now: now,
      );

      expect(findings, isEmpty);
    });
  });
}

Book _book(DateTime now) {
  return Book(
    id: 'book-1',
    title: 'Fixture',
    createdAt: now,
    updatedAt: now,
    narrativeProfile: const BookNarrativeProfile(
      primaryGenre: BookPrimaryGenre.thriller,
      readerPromise: 'Una investigación con promesas claras y pagos visibles.',
    ),
  );
}

Document _chapter(DateTime now, int index, String content) {
  return Document(
    id: 'chapter-$index',
    bookId: 'book-1',
    title: 'Capítulo ${index + 1}',
    orderIndex: index,
    content: content,
    wordCount: content.split(RegExp(r'\s+')).length,
    createdAt: now,
    updatedAt: now,
  );
}

Character _character(DateTime now, String name) {
  return Character(
    id: 'character-$name',
    bookId: 'book-1',
    name: name,
    createdAt: now,
    updatedAt: now,
  );
}

Scenario _scenario(DateTime now, String name) {
  return Scenario(
    id: 'scenario-$name',
    bookId: 'book-1',
    name: name,
    createdAt: now,
    updatedAt: now,
  );
}
