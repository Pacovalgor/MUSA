import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modules/books/providers/workspace_providers.dart';
import '../musa_autopilot.dart';
import '../musa.dart';
import '../musa_effectiveness_tracker.dart';
import '../professional_corpus_calibration.dart';

final availableMusesProvider = Provider<List<Musa>>((ref) {
  return const [
    StyleMusa(),
    TensionMusa(),
    RhythmMusa(),
    ClarityMusa(),
  ];
});

final musaAutopilotProvider = Provider<MusaAutopilot>((ref) {
  final tracker = ref.watch(musaEffectivenessTrackerProvider);
  final calibration = ref.watch(professionalCorpusCalibrationProvider);
  final activeBook = ref.watch(activeBookProvider);
  final personalMultipliers = {
    'style': tracker.getThresholdMultiplier('style'),
    'tension': tracker.getThresholdMultiplier('tension'),
    'rhythm': tracker.getThresholdMultiplier('rhythm'),
    'clarity': tracker.getThresholdMultiplier('clarity'),
  };

  return MusaAutopilot(
    scoreMultipliers: calibration.combineWithPersonal(
      genre: activeBook?.narrativeProfile.primaryGenre.name,
      personalMultipliers: personalMultipliers,
    ),
  );
});

final professionalCorpusCalibrationProvider =
    Provider<ProfessionalCorpusCalibration>((ref) {
  return const ProfessionalCorpusCalibration();
});

final musaEffectivenessTrackerProvider =
    Provider<MusaEffectivenessTracker>((ref) {
  final tracker = MusaEffectivenessTracker();
  unawaited(tracker.initialize());
  return tracker;
});
