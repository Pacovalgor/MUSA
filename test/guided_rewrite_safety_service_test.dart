import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/musa/models/guided_rewrite.dart';
import 'package:musa/modules/musa/services/guided_rewrite_safety_service.dart';

void main() {
  group('GuidedRewriteSafetyService', () {
    test('flags new capitalized names introduced by a rewrite', () {
      const service = GuidedRewriteSafetyService();
      final audit = service.audit(
        originalText: 'Diane abrió la puerta. La carta estaba sobre la mesa.',
        suggestedText:
            'Diane abrió la puerta. Clara esperaba junto a la carta.',
      );

      expect(audit.level, GuidedRewriteSafetyLevel.warning);
      expect(audit.warnings, contains(GuidedRewriteSafetyWarning.newNames));
      expect(audit.evidence, contains('Clara'));
    });

    test('flags excessive expansion as unsafe for controlled rewrites', () {
      const service = GuidedRewriteSafetyService();
      final audit = service.audit(
        originalText: 'Diane abrió la puerta.',
        suggestedText:
            'Diane abrió la puerta. La habitación parecía distinta. La carta estaba abierta. El pasillo respiraba al otro lado. Algo había cambiado para siempre.',
      );

      expect(audit.level, GuidedRewriteSafetyLevel.warning);
      expect(audit.warnings, contains(GuidedRewriteSafetyWarning.overExpanded));
    });

    test('flags dropped key nouns from the original fragment', () {
      const service = GuidedRewriteSafetyService();
      final audit = service.audit(
        originalText: 'Diane guardó la carta bajo la llave oxidada.',
        suggestedText: 'Diane guardó el papel y siguió caminando.',
      );

      expect(audit.level, GuidedRewriteSafetyLevel.warning);
      expect(audit.warnings, contains(GuidedRewriteSafetyWarning.droppedTerms));
      expect(audit.evidence, contains('carta'));
      expect(audit.evidence, contains('llave'));
    });

    test('keeps safe level for compact rewrites preserving facts', () {
      const service = GuidedRewriteSafetyService();
      final audit = service.audit(
        originalText: 'Diane abrió la puerta. La carta estaba sobre la mesa.',
        suggestedText:
            'Diane abrió la puerta. La carta seguía sobre la mesa, demasiado quieta.',
      );

      expect(audit.level, GuidedRewriteSafetyLevel.safe);
      expect(audit.warnings, isEmpty);
    });
  });
}
