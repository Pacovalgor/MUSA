import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_copilot.dart';
import 'package:musa/modules/books/models/novel_status.dart';
import 'package:musa/modules/continuity/models/continuity_audit.dart';
import 'package:musa/modules/musa/models/guided_rewrite.dart';
import 'package:musa/modules/musa/services/guided_rewrite_planner.dart';

void main() {
  group('GuidedRewritePlanner', () {
    test('recommends raising tension for a low-tension thriller', () {
      const planner = GuidedRewritePlanner();
      final recommendation = planner.recommend(
        selection: 'Diane abrió la puerta. La carta estaba sobre la mesa.',
        book: _book(genre: BookPrimaryGenre.thriller),
        novelStatus: _status(tensionScore: 28),
        continuityFindings: const [],
        memory: _memory(),
        storyState: _storyState(globalTension: 24),
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.action, GuidedRewriteAction.raiseTension);
      expect(recommendation.title, contains('tensión'));
      expect(recommendation.reason, contains('thriller'));
    });

    test('recommends reducing exposition for explanatory selected text', () {
      const planner = GuidedRewritePlanner();
      final recommendation = planner.recommend(
        selection:
            'Diane sabía que la investigación era importante porque desde hacía años había aprendido a no confiar en nadie. La llave seguía bajo la alfombra.',
        book: _book(),
        novelStatus: _status(),
        continuityFindings: const [],
        memory: _memory(),
        storyState: _storyState(),
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.action, GuidedRewriteAction.reduceExposition);
      expect(recommendation.reason, contains('explicación'));
    });

    test('recommends naturalizing dialogue when dialogue lacks physical beats',
        () {
      const planner = GuidedRewritePlanner();
      final recommendation = planner.recommend(
        selection: '—¿Lo viste? —No. —Entonces alguien miente.',
        book: _book(),
        novelStatus: _status(),
        continuityFindings: const [],
        memory: _memory(),
        storyState: _storyState(),
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.action, GuidedRewriteAction.naturalizeDialogue);
      expect(recommendation.reason, contains('diálogo'));
    });

    test('uses continuity risk to recommend clarifying the selected promise',
        () {
      const planner = GuidedRewritePlanner();
      final recommendation = planner.recommend(
        selection: 'La señal volvió a aparecer en la pantalla.',
        book: _book(),
        novelStatus: _status(),
        continuityFindings: const [
          ContinuityFinding(
            type: ContinuityFindingType.unresolvedPromise,
            severity: ContinuityFindingSeverity.warning,
            title: 'Promesas abiertas sin pago',
            detail: 'La novela acumula promesas abiertas.',
            evidence: 'la señal · la llamada · la carta',
          ),
        ],
        memory: _memory(unresolvedPromises: ['la señal', 'la llamada']),
        storyState: _storyState(),
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.action, GuidedRewriteAction.clarify);
      expect(recommendation.evidence, contains('la señal'));
    });

    test('does not force a recommendation without a clear signal', () {
      const planner = GuidedRewritePlanner();
      final recommendation = planner.recommend(
        selection: 'Diane miró la ciudad desde la ventana.',
        book: _book(),
        novelStatus: _status(),
        continuityFindings: const [],
        memory: _memory(),
        storyState: _storyState(),
      );

      expect(recommendation, isNull);
    });

    test('uses learned action multipliers to break competing signals', () {
      const planner = GuidedRewritePlanner();
      final recommendation = planner.recommend(
        selection:
            '—¿Lo viste? —No. Diane sabía que la investigación era importante porque desde hacía años había aprendido a no confiar.',
        book: _book(),
        novelStatus: _status(),
        continuityFindings: const [],
        memory: _memory(),
        storyState: _storyState(),
        actionMultipliers: const {
          'guided-rewrite.reduce-exposition': 0.7,
          'guided-rewrite.naturalize-dialogue': 1.25,
        },
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.action, GuidedRewriteAction.naturalizeDialogue);
    });
  });
}

Book _book({BookPrimaryGenre genre = BookPrimaryGenre.literary}) {
  final now = DateTime(2026, 5, 6);
  return Book(
    id: 'book-1',
    title: 'Libro',
    createdAt: now,
    updatedAt: now,
    narrativeProfile: BookNarrativeProfile(
      primaryGenre: genre,
      readerPromise: 'Una investigación íntima con coste emocional.',
    ),
  );
}

NovelStatusReport _status({int tensionScore = 72}) {
  final now = DateTime(2026, 5, 6);
  return NovelStatusReport(
    bookId: 'book-1',
    overallScore: 74,
    healthLevel: NovelStatusHealth.stable,
    tensionScore: tensionScore,
    rhythmScore: 72,
    promiseScore: 78,
    memoryScore: 74,
    signals: const [],
    professionalComparisons: const [],
    nextActions: const [],
    updatedAt: now,
  );
}

NarrativeMemory _memory({List<String> unresolvedPromises = const []}) {
  return NarrativeMemory(
    bookId: 'book-1',
    unresolvedPromises: unresolvedPromises,
    updatedAt: DateTime(2026, 5, 6),
  );
}

StoryState _storyState({int globalTension = 72}) {
  return StoryState(
    bookId: 'book-1',
    globalTension: globalTension,
    updatedAt: DateTime(2026, 5, 6),
  );
}
