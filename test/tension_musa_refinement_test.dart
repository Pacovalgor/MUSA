import 'package:flutter_test/flutter_test.dart';
import 'package:musa/muses/musa.dart';

void main() {
  group('TensionMusa: Local Context Refinement', () {
    const musa = TensionMusa();

    // ===== NUEVA HEURÍSTICA: DIÁLOGO SIN ACCIÓN =====

    test('adds local rule when stagnant dialogue is detected (no action)', () {
      const text = '—¿Qué haces aquí?\n—Nada que te importe.';
      final contract = musa.refinedContract(text);

      expect(contract, contains('[LOCAL CONTEXT]'));
      expect(contract, contains('intercambio de diálogo sin acción ni consecuencias'));
    });

    test('adds local rule when stagnant dialogue is detected (quotes, no action)', () {
      const text = '"No deberías haber venido", dijo ella. "Lo sé", respondió él.';
      final contract = musa.refinedContract(text);

      expect(contract, contains('[LOCAL CONTEXT]'));
      expect(contract, contains('intercambio de diálogo sin acción ni consecuencias'));
    });

    test('does not add local rule when dialogue includes action verbs', () {
      const text = '—¿Qué haces aquí? —preguntó ella mientras abrió la puerta.';
      final contract = musa.refinedContract(text);

      expect(contract, isNot(contains('[LOCAL CONTEXT]')));
      expect(contract, equals(musa.promptContract));
    });

    test('does not add local rule when dialogue includes operational verbs', () {
      const text = '—Esto nos obliga a elegir —murmuró él.';
      final contract = musa.refinedContract(text);

      expect(contract, isNot(contains('[LOCAL CONTEXT]')));
      expect(contract, equals(musa.promptContract));
    });

    test('does not add local rule for single line dialogue', () {
      const text = '—Hola.';
      final contract = musa.refinedContract(text);

      expect(contract, isNot(contains('[LOCAL CONTEXT]')));
      expect(contract, equals(musa.promptContract));
    });
    
    test('does not add question-based rule when questions include action', () {
      const text = '¿Quién está ahí? ¿Qué haces? Él abrió la puerta y corrió hacia la escalera.';
      final contract = musa.refinedContract(text);

      expect(contract, isNot(contains('múltiples interrogantes')));
    });

    // ===== HEURÍSTICAS ANTIGUAS (SE MANTIENEN) =====

    test('adds rule for many questions without action', () {
      const text = '¿Quién está ahí? ¿Por qué no responde? ¿Qué es esa sombra?';
      final contract = musa.refinedContract(text);

      expect(contract, contains('[LOCAL CONTEXT]'));
      expect(contract, contains('múltiples interrogantes'));
      expect(contract, contains('consecuencias'));
    });

    test('adds rule for static passage with low action verb density', () {
      const text = 'La habitación estaba en un silencio absoluto. El aire era pesado, denso, casi irrespirable, pero no había movimiento alguno en los rincones.';
      final contract = musa.refinedContract(text);

      expect(contract, contains('[LOCAL CONTEXT]'));
      expect(contract, contains('estático'));
      expect(contract, contains('verbos de acción física'));
    });

    test('does not add local context for balanced passage with action', () {
      const text = 'Él abrió la puerta de un golpe y corrió por el pasillo gritando su nombre.';
      final contract = musa.refinedContract(text);

      expect(contract, isNot(contains('[LOCAL CONTEXT]')));
      expect(contract, equals(musa.promptContract));
    });

    test('does not add local context for descriptive text without dialogue', () {
      const text = 'La habitación estaba oscura y el aire era pesado.';
      final contract = musa.refinedContract(text);

      expect(contract, isNot(contains('[LOCAL CONTEXT]')));
      expect(contract, equals(musa.promptContract));
    });
  });
}