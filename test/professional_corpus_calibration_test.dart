import 'package:flutter_test/flutter_test.dart';
import 'package:musa/muses/professional_corpus_calibration.dart';

void main() {
  group('ProfessionalCorpusCalibration', () {
    const calibration = ProfessionalCorpusCalibration();

    test('keeps professional calibration separate from personal feedback', () {
      final professional = calibration.scoreMultipliersForGenre('thriller');

      expect(professional['tension'], greaterThan(1.0));
      expect(professional['rhythm'], greaterThan(1.0));
      expect(professional.containsKey('timesAccepted'), isFalse);
      expect(professional.containsKey('timesRejected'), isFalse);
    });

    test('anchors thriller calibration to Tras la puerta', () {
      final profile = calibration.profileForGenre('thriller');

      expect(profile.referenceTitle, 'Tras la puerta');
      expect(profile.genre, 'thriller');
      expect(profile.scoreMultipliers['tension'], greaterThan(1.0));
    });

    test('anchors fantasy and historical calibration to the audited books', () {
      final fantasy = calibration.profileForGenre('fantasy');
      final historical = calibration.profileForGenre('historical');

      expect(fantasy.referenceTitle, 'Mithas y Karthay');
      expect(historical.referenceTitle, 'Un lugar llamado libertad');
    });

    test('combines professional and personal multipliers conservatively', () {
      final combined = calibration.combineWithPersonal(
        genre: 'thriller',
        personalMultipliers: const {
          'tension': 1.2,
          'style': 0.8,
        },
      );

      expect(combined['tension'], greaterThan(1.2));
      expect(combined['tension'], lessThanOrEqualTo(1.35));
      expect(combined['style'], 0.8);
    });
  });
}
