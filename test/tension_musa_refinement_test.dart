import 'package:flutter_test/flutter_test.dart';
import 'package:musa/muses/musa.dart';

void main() {
  group('TensionMusa: Local Context Refinement', () {
    const musa = TensionMusa();

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

    test('does not add local context for short neutral text', () {
      const text = 'Había una vez un pequeño pueblo.';
      final contract = musa.refinedContract(text);

      expect(contract, isNot(contains('[LOCAL CONTEXT]')));
      expect(contract, equals(musa.promptContract));
    });
  });
}
