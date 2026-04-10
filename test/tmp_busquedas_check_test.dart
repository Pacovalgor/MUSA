import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musa/editor/services/chapter_analysis_service.dart';
import 'package:musa/modules/characters/models/character.dart';
import 'package:musa/modules/scenarios/models/scenario.dart';

void main() {
  test('busquedas next step', () {
    final workspaceFile = File('/Users/paco/Library/Containers/com.example.musa/Data/Library/Application Support/com.example.musa/musa/musa_workspace.json');
    final data = jsonDecode(workspaceFile.readAsStringSync()) as Map<String, dynamic>;
    final characters = (data['characters'] as List).cast<Map<String, dynamic>>().map(Character.fromJson).toList();
    final scenarios = (data['scenarios'] as List).cast<Map<String, dynamic>>().map(Scenario.fromJson).toList();
    final doc = (data['documents'] as List).cast<Map<String, dynamic>>().firstWhere((d) => d['title'] == 'Busquedas sin voz');
    final analysis = const ChapterAnalysisService().analyze(
      chapterText: doc['content'] as String,
      characters: characters,
      scenarios: scenarios,
      linkedCharacterIds: (doc['characterIds'] as List? ?? const []).cast<String>(),
      linkedScenarioIds: (doc['scenarioIds'] as List? ?? const []).cast<String>(),
    );
    print('moment=' + analysis.dominantNarrativeMoment.title);
    print('function=' + analysis.chapterFunction.toString());
    print('next=' + (analysis.nextStep?.type.toString() ?? 'null'));
    print('label=' + (analysis.nextStep?.label ?? 'null'));
    print('recommendation=' + (analysis.recommendation?.message ?? 'null'));
  });
}
