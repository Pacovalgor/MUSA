import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ia/embedded/management/model_manager.dart';
import 'scenarios/embedded_scenario_autofill_service.dart';
import 'scenarios/scenario_autofill_service.dart';
import 'scenarios/unavailable_scenario_autofill_service.dart';

final scenarioAutofillServiceProvider =
    Provider<ScenarioAutofillService>((ref) {
  if (Platform.isMacOS) {
    final activeModelPath = ref.watch(
      modelManagerProvider.select((s) => s.activeModelPath),
    );
    return EmbeddedScenarioAutofillService(activeModelPath: activeModelPath);
  }

  return UnavailableScenarioAutofillService();
});
