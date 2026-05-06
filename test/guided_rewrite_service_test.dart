import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/musa/models/guided_rewrite.dart';
import 'package:musa/modules/musa/services/guided_rewrite_service.dart';

void main() {
  group('GuidedRewriteService', () {
    test('raises tension without changing named facts or adding characters',
        () {
      const service = GuidedRewriteService();
      final result = service.rewrite(
        selection: 'Diane abrió la puerta. La carta estaba sobre la mesa.',
        action: GuidedRewriteAction.raiseTension,
      );

      expect(result.originalText, contains('Diane'));
      expect(result.suggestedText, contains('Diane'));
      expect(result.suggestedText, contains('carta'));
      expect(result.suggestedText, isNot(contains('Clara')));
      expect(
          result.safetyNotes, contains(GuidedRewriteSafetyNote.preserveFacts));
      expect(result.action, GuidedRewriteAction.raiseTension);
    });

    test('clarifies long sentence by splitting it without inventing plot', () {
      const service = GuidedRewriteService();
      final result = service.rewrite(
        selection:
            'Diane abrió la puerta porque había oído el ruido que venía del pasillo mientras la carta seguía sobre la mesa y la lámpara temblaba.',
        action: GuidedRewriteAction.clarify,
      );

      expect(result.suggestedText, contains('Diane abrió la puerta'));
      expect(
          result.suggestedText
              .split('.')
              .where((part) => part.trim().isNotEmpty),
          hasLength(greaterThan(1)));
      expect(
          result.safetyNotes, contains(GuidedRewriteSafetyNote.preserveVoice));
    });

    test('reduces exposition by keeping the concrete sentence', () {
      const service = GuidedRewriteService();
      final result = service.rewrite(
        selection:
            'Diane sabía que la investigación era importante porque desde hacía años había aprendido que toda pista podía cambiarlo todo. La llave seguía bajo la alfombra.',
        action: GuidedRewriteAction.reduceExposition,
      );

      expect(
          result.suggestedText, contains('La llave seguía bajo la alfombra'));
      expect(result.suggestedText, isNot(contains('desde hacía años')));
    });

    test('makes dialogue more physical without changing spoken lines', () {
      const service = GuidedRewriteService();
      final result = service.rewrite(
        selection: '—¿Lo viste? —No. —Entonces alguien miente.',
        action: GuidedRewriteAction.naturalizeDialogue,
      );

      expect(result.suggestedText, contains('—¿Lo viste?'));
      expect(result.suggestedText, contains('—No.'));
      expect(result.suggestedText, contains('alguien miente'));
      expect(result.suggestedText, contains('silencio'));
    });

    test('returns unchanged result for empty selection', () {
      const service = GuidedRewriteService();
      final result = service.rewrite(
        selection: '   ',
        action: GuidedRewriteAction.raiseTension,
      );

      expect(result.suggestedText, '');
      expect(result.safetyNotes, contains(GuidedRewriteSafetyNote.noExpansion));
    });
  });
}
