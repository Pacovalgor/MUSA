import 'package:flutter_test/flutter_test.dart';
import 'package:musa/muses/musa.dart';

void main() {
  group('RhythmMusa: Local Context Refinement', () {
    const musa = RhythmMusa();

    test('adds local rule when multiple long sentences are detected', () {
      const text = 'Esta es una frase extremadamente larga que se extiende sin piedad a través de múltiples comas y conjunciones sin dar un respiro al lector porque el autor decidió que todo tenía que decirse de una vez en este mismo aliento. Y aquí viene otra frase igual de extensa que tampoco parece tener la intención de detenerse en ningún momento cercano, forzando la vista y la memoria de quien intenta descifrar qué diablos estaba pensando el personaje principal cuando cruzó la puerta de la vieja taberna en ruinas.';
      final contract = musa.refinedContract(text);

      expect(contract, contains('[LOCAL CONTEXT]'));
      expect(contract, contains('frases muy largas y complejas'));
      expect(contract, contains('alternar su longitud'));
    });

    test('adds local rule when consecutive short sentences are detected', () {
      const text = 'El viento sopló. La puerta crujió. Él se giró. Todo estaba oscuro.';
      final contract = musa.refinedContract(text);

      expect(contract, contains('[LOCAL CONTEXT]'));
      expect(contract, contains('frases muy cortas consecutivas'));
      expect(contract, contains('ritmo demasiado fragmentado o monótono'));
    });

    test('does not add local context for balanced text', () {
      const text = 'La puerta se abrió lentamente y una figura apareció en el umbral. No dijo nada. Solo la miró con esos ojos grises que ella recordaba tan bien.';
      final contract = musa.refinedContract(text);

      expect(contract, isNot(contains('[LOCAL CONTEXT]')));
      expect(contract, equals(musa.promptContract));
    });
  });
}
