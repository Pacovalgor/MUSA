import 'package:flutter_test/flutter_test.dart';
import 'package:musa/muses/musa_autopilot.dart';
import 'package:musa/domain/musa/musa_objects.dart';

void main() {
  group('MusaAutopilot: Explainability', () {
    const autopilot = MusaAutopilot();

    test('recommends Tension with specific reason for stagnant dialogue', () {
      const text = '—¿Qué haces aquí?\n—Nada que te importe.';
      final context = NarrativeContext(
        bookTitle: 'Test Book',
        documentTitle: 'Chapter 1',
        projectSummary: 'A test project',
        knownFacts: [],
        tensionLevel: 'neutral',
      );
      
      final recommendation = autopilot.recommend(selection: text, context: context);
      
      expect(recommendation.primaryMusa.id, equals('tension'));
      expect(recommendation.reason, contains('He elegido Tensión porque detecto diálogo sin acción'));
    });

    test('recommends Rhythm with specific reason for short sentences', () {
      const text = 'Él vino. Ella se fue. Todo acabó.';
      final context = NarrativeContext(
        bookTitle: 'Test Book',
        documentTitle: 'Chapter 1',
        projectSummary: 'A test project',
        knownFacts: [],
        tensionLevel: 'neutral',
      );
      
      final recommendation = autopilot.recommend(selection: text, context: context);
      
      expect(recommendation.primaryMusa.id, equals('rhythm'));
      expect(recommendation.reason, contains('He elegido Ritmo porque hay frases cortas repetidas'));
    });

    test('recommends Style with specific reason for repetition', () {
      const text = 'El horizonte azul se perdía en el mar azul bajo un cielo azul.';
      final context = NarrativeContext(
        bookTitle: 'Test Book',
        documentTitle: 'Chapter 1',
        projectSummary: 'A test project',
        knownFacts: [],
        tensionLevel: 'neutral',
      );
      
      final recommendation = autopilot.recommend(selection: text, context: context);
      
      expect(recommendation.primaryMusa.id, equals('style'));
      expect(recommendation.reason, contains('He elegido Estilo por baja variación léxica'));
    });

    test('recommends Clarity with specific reason for long sentences', () {
      // Added commas to avoid the "Rhythm" penalty for lack of punctuation in long sentences
      const text = 'Esta es una frase extremadamente larga, compleja y densa, que intenta demostrar cómo el sistema detecta la necesidad de claridad, incluso cuando la longitud media supera los umbrales.';
      final context = NarrativeContext(
        bookTitle: 'Test Book',
        documentTitle: 'Chapter 1',
        projectSummary: 'A test project',
        knownFacts: [],
        tensionLevel: 'neutral',
      );
      
      final recommendation = autopilot.recommend(selection: text, context: context);
      
      expect(recommendation.primaryMusa.id, equals('clarity'));
      expect(recommendation.reason, contains('He elegido Claridad porque el pasaje presenta frases largas'));
    });
  });
}
