import 'package:flutter_test/flutter_test.dart';
import 'package:musa/muses/musa.dart';
import 'package:musa/muses/musa_autopilot.dart';
import 'package:musa/domain/musa/musa_objects.dart';

void main() {
  group('MusaAutopilot: Minimum Priority Orchestration', () {
    const autopilot = MusaAutopilot();
    final emptyContext = NarrativeContext(
      bookTitle: 'Test',
      documentTitle: 'Chapter 1',
      projectSummary: '',
      knownFacts: [],
      tensionLevel: 'neutral',
    );

    test('prefers TensionMusa over others when multiple signals present', () {
      // Content with heavy dramatic lexicon to ensure TensionScore >= 4
      const text = 'Había sangre, un cadáver y una amenaza de muerte en las sombras de la habitación, mientras el viento gritaba como un ruido de armas.';
      final recommendation = autopilot.recommend(
        selection: text,
        context: emptyContext,
      );

      expect(recommendation.primaryMusa, isA<TensionMusa>());
      expect(recommendation.musas.length, 1);
      expect(recommendation.reason.toLowerCase(), contains('tensión'));
    });

    test('prefers RhythmMusa over Style/Clarity when rhythm is the main issue', () {
      // Content with many short sentences to ensure RhythmScore >= 4
      const text = 'Él caminó. Él miró. Él saltó. Ella rio. Todo cayó. Nada quedó. El fin llegó.';
      final recommendation = autopilot.recommend(
        selection: text,
        context: emptyContext,
      );

      expect(recommendation.primaryMusa, isA<RhythmMusa>());
      expect(recommendation.musas.length, 1);
      expect(recommendation.reason.toLowerCase(), contains('rítmico'));
    });

    test('falls back to ClarityMusa for generic messy text', () {
      const text = 'Una frase que es muy larga y que tiene muchas comas, y que además repite que, porque es confusa de leer de forma directa y rápida.';
      final recommendation = autopilot.recommend(
        selection: text,
        context: emptyContext,
      );

      expect(recommendation.primaryMusa, isA<ClarityMusa>());
      expect(recommendation.musas.length, 1);
    });
  });
}
