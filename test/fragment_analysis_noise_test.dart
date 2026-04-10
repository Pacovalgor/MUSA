import 'package:flutter_test/flutter_test.dart';
import 'package:musa/editor/services/fragment_analysis_service.dart';

void main() {
  test('capitalized interface noise is not surfaced as a character', () {
    final analysis = const FragmentAnalysisService().analyze(
      selection:
          'Entendido. Busco el símbolo otra vez. Luego abro Reddit y comparo el mapa, pero nadie responde.',
      characters: const [],
      scenarios: const [],
      linkedCharacterIds: const [],
      linkedScenarioIds: const [],
    );

    final names = analysis.characters.map((item) => item.name).toList();
    expect(names, isNot(contains('Entendido')));
    expect(names, isNot(contains('Busco')));
  });
}
