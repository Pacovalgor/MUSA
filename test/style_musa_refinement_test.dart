import 'package:flutter_test/flutter_test.dart';
import 'package:musa/muses/musa.dart';

void main() {
  group('StyleMusa: Local Context Refinement', () {
    const musa = StyleMusa();

    test('adds local rule when multiple adverbs in -mente are detected', () {
      const text = 'Él caminaba lentamente y ella respondía rápidamente.';
      final contract = musa.refinedContract(text);

      expect(contract, contains('[LOCAL CONTEXT]'));
      expect(contract, contains('adverbios en "-mente"'));
      expect(contract, contains('imágenes concretas'));
    });

    test('adds local rule when substantial words are repeated', () {
      const text = 'El horizonte parecía distante. En aquel horizonte no había nada.';
      final contract = musa.refinedContract(text);

      expect(contract, contains('[LOCAL CONTEXT]'));
      expect(contract, contains('Se repiten términos como "horizonte"'));
      expect(contract, contains('variedad léxica'));
    });

    test('does not add local context for neutral text', () {
      const text = 'Esta es una frase normal y descriptiva sin señales de estilo especiales.';
      final contract = musa.refinedContract(text);

      expect(contract, isNot(contains('[LOCAL CONTEXT]')));
      expect(contract, equals(musa.promptContract));
    });

    test('handles punctuation in repeated words detection', () {
      const text = 'La habitación estaba en silencio; un silencio profundo.';
      final contract = musa.refinedContract(text);

      expect(contract, contains('Se repiten términos como "silencio"'));
    });
  });
}
