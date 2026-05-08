import 'package:flutter_test/flutter_test.dart';
import 'package:musa/editor/models/fragment_analysis.dart';
import 'package:musa/editor/services/chapter_analysis_service.dart';
import 'package:musa/editor/services/chapter_character_validation_service.dart';
import 'package:musa/editor/services/fragment_analysis_service.dart';
import 'package:musa/modules/characters/models/character.dart';

void main() {
  test('capitalized interface noise is not surfaced as a character', () {
    final analysis = const FragmentAnalysisService().analyze(
      selection:
          'Entendido. Busco el símbolo otra vez. Luego abro Reddit y comparo el mapa, pero nadie responde.',
      characters: const [],
      scenarios: const [],
      linkedCharacterIds: const ['char-clara', 'char-diane'],
      linkedScenarioIds: const [],
    );

    final names = analysis.characters.map((item) => item.name).toList();
    expect(names, isNot(contains('Entendido')));
    expect(names, isNot(contains('Busco')));
  });

  test('chapter analysis does not surface verbs as characters', () {
    final analysis = const ChapterAnalysisService().analyze(
      chapterText: '''
San Francisco, 9:03 a. M. Me desperté antes de que sonara el despertador.
No por energía, sino por inquietud. Posible avance abierto.

Me levanté despacio. Me duché sin pensar, me vestí sin elegir.
Escribí una nota y decía que tenía que estar preparada.

Tomé el Muni hasta Civic Center y caminé hacia el distrito Tenderloin.
''',
      characters: const [],
      scenarios: const [],
      linkedCharacterIds: const [],
      linkedScenarioIds: const [],
    );

    final names = analysis.mainCharacters.map((item) => item.name).toList();
    expect(names, isNot(contains('Posible')));
    expect(names, isNot(contains('Escrib')));
    expect(names, isNot(contains('Escribí')));
    expect(names, isNot(contains('Decía')));
  });

  test('async chapter analysis filters characters with local validator',
      () async {
    final now = DateTime.utc(2026, 5, 8);
    const service = ChapterAnalysisService(
      characterValidationService: _FakeCharacterValidationService(
        confirmedNames: {'Clara Torres'},
      ),
    );
    final analysis = await service.analyzeAsync(
      chapterText: '''
Clara Torres, periodista de treinta años, abrió la puerta del apartamento.
Clara Torres llamó a Diane Vale desde el pasillo.
Diane Vale no respondió. Clara Torres volvió a pronunciar su nombre.
''',
      characters: [
        Character(
          id: 'char-clara',
          bookId: 'book-1',
          name: 'Clara Torres',
          createdAt: now,
          updatedAt: now,
        ),
        Character(
          id: 'char-diane',
          bookId: 'book-1',
          name: 'Diane Vale',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      scenarios: const [],
      linkedCharacterIds: const [],
      linkedScenarioIds: const [],
    );

    final names = analysis.mainCharacters.map((item) => item.name).toList();
    expect(names, contains('Clara Torres'));
    expect(names, isNot(contains('Diane Vale')));
    expect(
      analysis.characterDevelopments
          .map((item) => item.characterIdOrName)
          .toSet(),
      everyElement(anyOf('Clara Torres', 'char-clara')),
    );
    expect(analysis.nextStep?.entityName, isNot('Diane Vale'));
    expect(analysis.nextStep?.targetId, isNot('char-diane'));
  });
}

class _FakeCharacterValidationService
    implements ChapterCharacterValidationService {
  const _FakeCharacterValidationService({required this.confirmedNames});

  final Set<String> confirmedNames;

  @override
  bool get isReady => true;

  @override
  Future<Set<String>> confirmPersonNames({
    required String chapterText,
    required List<DetectedCharacter> candidates,
  }) async {
    return confirmedNames;
  }
}
