import 'package:flutter_test/flutter_test.dart';
import 'package:musa/muses/musa_effectiveness_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MusaEffectivenessTracker', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('keeps threshold neutral until minimum sample size is reached',
        () async {
      final tracker = MusaEffectivenessTracker();
      await tracker.initialize();

      for (var i = 0; i < MusaEffectivenessTracker.minimumSamples - 1; i++) {
        await tracker.recordSuggestionShown('style');
        await tracker.recordAcceptance('style');
      }

      expect(tracker.getThresholdMultiplier('style'), 1.0);
    });

    test('raises threshold multiplier after enough accepted suggestions',
        () async {
      final tracker = MusaEffectivenessTracker();
      await tracker.initialize();

      for (var i = 0; i < MusaEffectivenessTracker.minimumSamples; i++) {
        await tracker.recordSuggestionShown('clarity');
        await tracker.recordAcceptance('clarity');
      }

      expect(tracker.getThresholdMultiplier('clarity'), 1.2);
    });

    test('lowers threshold multiplier after enough rejected suggestions',
        () async {
      final tracker = MusaEffectivenessTracker();
      await tracker.initialize();

      for (var i = 0; i < MusaEffectivenessTracker.minimumSamples; i++) {
        await tracker.recordSuggestionShown('rhythm');
        await tracker.recordRejection('rhythm');
      }

      expect(tracker.getThresholdMultiplier('rhythm'), 0.8);
    });
  });
}
