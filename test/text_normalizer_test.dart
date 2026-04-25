import 'package:flutter_test/flutter_test.dart';
import 'package:musa/editor/services/text_normalizer.dart';

void main() {
  group('stripAccents', () {
    test('removes acute accents on vowels', () {
      expect(TextNormalizer.stripAccents('amenazó'), 'amenazo');
      expect(TextNormalizer.stripAccents('decidió'), 'decidio');
      expect(TextNormalizer.stripAccents('música'), 'musica');
    });

    test('keeps eñe; strips diéresis (ü→u)', () {
      expect(TextNormalizer.stripAccents('niño'), 'niño');
      expect(TextNormalizer.stripAccents('vergüenza'), 'verguenza');
    });

    test('handles empty input', () {
      expect(TextNormalizer.stripAccents(''), '');
    });
  });

  group('stem', () {
    test('verbs converge across present/preterit/imperfect/participle', () {
      // amenaza
      const expectedAmenaza = 'amenaz';
      expect(TextNormalizer.stem('amenaza'), expectedAmenaza);
      expect(TextNormalizer.stem('amenazó'), expectedAmenaza);
      expect(TextNormalizer.stem('amenazaron'), expectedAmenaza);
      expect(TextNormalizer.stem('amenazaba'), expectedAmenaza);
      expect(TextNormalizer.stem('amenazado'), expectedAmenaza);
      expect(TextNormalizer.stem('amenazante'), expectedAmenaza);

      // decide
      const expectedDecide = 'decid';
      expect(TextNormalizer.stem('decide'), expectedDecide);
      expect(TextNormalizer.stem('decidió'), expectedDecide);
      expect(TextNormalizer.stem('decidieron'), expectedDecide);

      // obliga
      const expectedObliga = 'oblig';
      expect(TextNormalizer.stem('obliga'), expectedObliga);
      expect(TextNormalizer.stem('obligó'), expectedObliga);
      expect(TextNormalizer.stem('obligaron'), expectedObliga);
      expect(TextNormalizer.stem('obligaba'), expectedObliga);
    });

    test('plurals collapse with singular', () {
      expect(TextNormalizer.stem('pista'), TextNormalizer.stem('pistas'));
      expect(TextNormalizer.stem('huella'), TextNormalizer.stem('huellas'));
    });

    test('protects very short words from over-stripping', () {
      expect(TextNormalizer.stem('si'), 'si');
      expect(TextNormalizer.stem('no'), 'no');
      expect(TextNormalizer.stem('y'), 'y');
    });

    test('does not collapse irregular root-changing verbs', () {
      // perder→pierde (e→ie diphthong) is a known limitation: distintos stems
      expect(TextNormalizer.stem('pierde'), isNot(TextNormalizer.stem('perdió')));
    });
  });

  group('stemmedContains', () {
    test('matches verb across conjugations', () {
      const text = 'La amenaza inicial pesaba sobre todos.';
      expect(TextNormalizer.stemmedContains(text, 'amenaza'), isTrue);
      const text2 = 'El asesino amenazó a la testigo aquella noche.';
      expect(TextNormalizer.stemmedContains(text2, 'amenaza'), isTrue);
      const text3 = 'Sus palabras amenazaban con romper el silencio.';
      expect(TextNormalizer.stemmedContains(text3, 'amenaza'), isTrue);
    });

    test('falls back to accent-insensitive contains for multi-word', () {
      const text = 'No quiero cambiar el sistema, sólo entenderlo.';
      expect(
        TextNormalizer.stemmedContains(text, 'no quiero cambiar el sistema'),
        isTrue,
      );
    });

    test('returns false on empty inputs', () {
      expect(TextNormalizer.stemmedContains('', 'amenaza'), isFalse);
      expect(TextNormalizer.stemmedContains('texto', ''), isFalse);
    });

    test('does not falsely match unrelated words', () {
      const text = 'La cafetería estaba tranquila.';
      expect(TextNormalizer.stemmedContains(text, 'amenaza'), isFalse);
    });
  });

  group('stemmedAnyContains', () {
    test('returns true if any needle matches', () {
      const text = 'Decidieron por unanimidad esa misma tarde.';
      expect(
        TextNormalizer.stemmedAnyContains(text, ['amenaza', 'decide', 'pista']),
        isTrue,
      );
    });

    test('returns false if no needle matches', () {
      const text = 'El día transcurrió en calma.';
      expect(
        TextNormalizer.stemmedAnyContains(text, ['amenaza', 'decide']),
        isFalse,
      );
    });
  });

  group('stemmedAnyContainsWithSynonyms', () {
    const synonymMap = <String, List<String>>{
      'miedo': <String>['temor', 'pavor'],
      'decide': <String>['elige', 'opta'],
    };

    test('matches the original needle', () {
      expect(
        TextNormalizer.stemmedAnyContainsWithSynonyms(
          'Sentí un miedo lento subir desde el suelo.',
          ['miedo'],
          synonymMap,
        ),
        isTrue,
      );
    });

    test('matches via synonym, with morphology', () {
      expect(
        TextNormalizer.stemmedAnyContainsWithSynonyms(
          'Optaron por marcharse antes del amanecer.',
          ['decide'],
          synonymMap,
        ),
        isTrue,
      );
      expect(
        TextNormalizer.stemmedAnyContainsWithSynonyms(
          'Un pavor antiguo le cerró la garganta.',
          ['miedo'],
          synonymMap,
        ),
        isTrue,
      );
    });

    test('returns false when neither needle nor synonyms appear', () {
      expect(
        TextNormalizer.stemmedAnyContainsWithSynonyms(
          'La tarde se cerró sin sobresaltos.',
          ['miedo', 'decide'],
          synonymMap,
        ),
        isFalse,
      );
    });

    test('handles empty needles or empty synonym map', () {
      expect(
        TextNormalizer.stemmedAnyContainsWithSynonyms(
          'cualquier texto',
          [],
          synonymMap,
        ),
        isFalse,
      );
      expect(
        TextNormalizer.stemmedAnyContainsWithSynonyms(
          'opta sin pensarlo',
          ['miedo'],
          const {},
        ),
        isFalse,
      );
    });
  });
}
