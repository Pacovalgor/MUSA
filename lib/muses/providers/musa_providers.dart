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
  return const MusaAutopilot();
});

final musaEffectivenessTrackerProvider =
    Provider<MusaEffectivenessTracker>((ref) {
  return MusaEffectivenessTracker();
});
