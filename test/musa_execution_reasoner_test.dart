import 'package:flutter_test/flutter_test.dart';
import 'package:musa/muses/musa_execution_reasoner.dart';
import 'package:musa/muses/musa.dart';

void main() {
  group('Musa Execution Reasoner', () {
    test('Records musa execution with reason', () {
      final reasoner = MusaExecutionReasoner();
      final musa = ClarityMusa();

      reasoner.recordExecution(
        musa,
        'Detectadas 4 preguntas que confunden el pasaje',
        scoreValue: 4.5,
        thresholdValue: 4.0,
      );

      expect(reasoner.executedMusas, hasLength(1));
      expect(reasoner.executedMusas.first.musaId, equals('clarity'));
      expect(reasoner.executedMusas.first.executed, isTrue);
    });

    test('Records musa skip with reason', () {
      final reasoner = MusaExecutionReasoner();
      final musa = RhythmMusa();

      reasoner.recordSkip(
        musa,
        'Ritmo ya fue solucionado por paso anterior',
        scoreValue: 1.5,
        thresholdValue: 3.0,
      );

      expect(reasoner.skippedMusas, hasLength(1));
      expect(reasoner.skippedMusas.first.musaId, equals('rhythm'));
      expect(reasoner.skippedMusas.first.executed, isFalse);
    });

    test('Generates execution summary with executed and skipped musas', () {
      final reasoner = MusaExecutionReasoner();

      reasoner.recordExecution(
        ClarityMusa(),
        'Detectadas preguntas redundantes',
        scoreValue: 4.5,
        thresholdValue: 4.0,
      );

      reasoner.recordSkip(
        RhythmMusa(),
        'Ritmo ya está balanceado',
        scoreValue: 2.0,
        thresholdValue: 3.0,
      );

      final summary = reasoner.generateExecutionSummary();

      expect(summary, contains('✅ Musas Ejecutadas'));
      expect(summary, contains('⏭️ Musas Omitidas'));
      expect(summary, contains('Clarity'));
      expect(summary, contains('Rhythm'));
    });

    test('Gets reason for specific musa', () {
      final reasoner = MusaExecutionReasoner();

      reasoner.recordExecution(
        StyleMusa(),
        'Muchos adverbios en -mente detectados',
      );

      final reason = reasoner.getReasonForMusa('style');

      expect(reason, contains('✅ Ejecutada'));
      expect(reason, contains('Muchos adverbios'));
    });

    test('Tracks execution statistics', () {
      final reasoner = MusaExecutionReasoner();

      reasoner.recordExecution(ClarityMusa(), 'Razón 1');
      reasoner.recordExecution(RhythmMusa(), 'Razón 2');
      reasoner.recordSkip(StyleMusa(), 'Razón 3');
      reasoner.recordSkip(TensionMusa(), 'Razón 4');

      expect(reasoner.totalDecisions, equals(4));
      expect(reasoner.executedMusas, hasLength(2));
      expect(reasoner.skippedMusas, hasLength(2));
    });

    test('Clears all decisions', () {
      final reasoner = MusaExecutionReasoner();

      reasoner.recordExecution(ClarityMusa(), 'Razón');
      expect(reasoner.totalDecisions, equals(1));

      reasoner.clear();
      expect(reasoner.totalDecisions, equals(0));
    });
  });

  group('Suggestion Explainer', () {
    test('Explains clarity changes in word count', () {
      const original = 'Esta es una oración muy larga y confusa que necesita simplificación.';
      const suggestion = 'Esta oración es larga y confusa.';

      final explanation = SuggestionExplainer.explainClarityChange(
        original,
        suggestion,
      );

      expect(explanation, contains('eliminó'));
      expect(explanation, contains('palabras'));
    });

    test('Explains rhythm changes when sentences are split', () {
      const original =
          'Entré al apartamento. Miré alrededor. El lugar estaba desordenado.';
      const suggestion =
          'Entré al apartamento y miré alrededor. El lugar estaba desordenado.';

      final explanation =
          SuggestionExplainer.explainRhythmChange(original, suggestion);

      expect(explanation, contains('Rhythm'));
    });

    test('Explains style changes for enrichment', () {
      const original = 'La puerta estaba abierta.';
      const suggestion =
          'La puerta de roble estaba entreabierta, revelando una sombra indistinta en el interior.';

      final explanation = SuggestionExplainer.explainStyleChange(
        original,
        suggestion,
      );

      expect(explanation, contains('enriqueció'));
    });

    test('Explains style changes for condensation', () {
      const original = 'Era un día muy, muy hermoso con mucho, mucho sol.';
      const suggestion = 'Era un día hermoso y soleado.';

      final explanation = SuggestionExplainer.explainStyleChange(
        original,
        suggestion,
      );

      expect(explanation, contains('condensó'));
    });

    test('Explains tension changes with questions', () {
      const original = 'Escuché un ruido en la oscuridad.';
      const suggestion = '¿Escuché un ruido en la oscuridad o era mi imaginación?';

      final explanation = SuggestionExplainer.explainTensionChange(
        original,
        suggestion,
      );

      expect(explanation, contains('preguntas'));
    });

    test('Routes explanation by musa ID', () {
      const original = 'Original text';
      const suggestion = 'Modified text with changes';

      final clarityExpl = SuggestionExplainer.explainMusaChange(
        'clarity',
        original,
        suggestion,
      );
      final rhythmExpl =
          SuggestionExplainer.explainMusaChange('rhythm', original, suggestion);

      expect(clarityExpl, isNotEmpty);
      expect(rhythmExpl, isNotEmpty);
    });
  });
}
