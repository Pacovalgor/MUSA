import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../musa_autopilot.dart';
import '../musa.dart';
import '../musa_effectiveness_tracker.dart';

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
  return MusaAutopilot(
    scoreMultipliers: {
      'style': tracker.getThresholdMultiplier('style'),
      'tension': tracker.getThresholdMultiplier('tension'),
      'rhythm': tracker.getThresholdMultiplier('rhythm'),
      'clarity': tracker.getThresholdMultiplier('clarity'),
    },
  );
});

final musaEffectivenessTrackerProvider =
    Provider<MusaEffectivenessTracker>((ref) {
  final tracker = MusaEffectivenessTracker();
  unawaited(tracker.initialize());
  return tracker;
});
