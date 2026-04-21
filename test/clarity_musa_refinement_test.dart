import 'package:flutter_test/flutter_test.dart';
import 'package:musa/muses/musa.dart';

void main() {
  group('ClarityMusa: Local Context Refinement', () {
    const musa = ClarityMusa();

    test('adds local rule when multiple questions are detected', () {
      const text = '¿Quién era él? ¿Por qué volvió?';
      final contract = musa.refinedContract(text);

      expect(contract, contains('[LOCAL CONTEXT]'));
      expect(contract, contains('múltiples preguntas'));
      expect(contract, contains('prioriza la nitidez'));
    });

    test('adds local rule when short dialogue is detected', () {
      const text = '—No lo sé —dijo ella.';
      final contract = musa.refinedContract(text);

      expect(contract, contains('[LOCAL CONTEXT]'));
      expect(contract, contains('Diálogo breve detectado'));
      expect(contract, contains('réplica sea nítida y directa'));
    });

    test('does not add local context for neutral text', () {
      const text = 'Esta es una frase normal y descriptiva sin señales especiales.';
      final contract = musa.refinedContract(text);

      expect(contract, isNot(contains('[LOCAL CONTEXT]')));
      expect(contract, equals(musa.promptContract));
    });

    test('handles null or empty selection gracefully', () {
      expect(musa.refinedContract(null), equals(musa.promptContract));
      expect(musa.refinedContract(''), equals(musa.promptContract));
      expect(musa.refinedContract('   '), equals(musa.promptContract));
    });
  });
}
