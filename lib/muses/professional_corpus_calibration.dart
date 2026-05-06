class ProfessionalCorpusCalibration {
  static const _neutralProfile = ProfessionalCalibrationProfile(
    genre: 'literary',
    referenceTitle: 'Base editorial neutral',
    sourceReportPath: '',
    scoreMultipliers: {
      'clarity': 1.0,
      'rhythm': 1.0,
      'style': 1.0,
      'tension': 1.0,
    },
  );

  static const _profiles = <String, ProfessionalCalibrationProfile>{
    'fantasy': ProfessionalCalibrationProfile(
      genre: 'fantasy',
      referenceTitle: 'Mithas y Karthay',
      sourceReportPath: 'test/fixtures/report-libro1.md',
      scoreMultipliers: {
        'clarity': 1.0,
        'rhythm': 1.04,
        'style': 1.08,
        'tension': 1.06,
      },
    ),
    'thriller': ProfessionalCalibrationProfile(
      genre: 'thriller',
      referenceTitle: 'Tras la puerta',
      sourceReportPath: 'test/fixtures/report-libro2.md',
      scoreMultipliers: {
        'clarity': 1.0,
        'rhythm': 1.05,
        'style': 1.0,
        'tension': 1.12,
      },
    ),
    'historical': ProfessionalCalibrationProfile(
      genre: 'historical',
      referenceTitle: 'Un lugar llamado libertad',
      sourceReportPath: 'test/fixtures/report-libro3.md',
      scoreMultipliers: {
        'clarity': 1.08,
        'rhythm': 1.06,
        'style': 1.04,
        'tension': 1.0,
      },
    ),
  };

  const ProfessionalCorpusCalibration();

  ProfessionalCalibrationProfile profileForGenre(String? genre) {
    final normalized = _normalizeGenre(genre);
    return _profiles[normalized] ?? _neutralProfile;
  }

  Map<String, double> scoreMultipliersForGenre(String? genre) {
    return profileForGenre(genre).scoreMultipliers;
  }

  Map<String, double> combineWithPersonal({
    required String? genre,
    required Map<String, double> personalMultipliers,
  }) {
    final professional = scoreMultipliersForGenre(genre);
    final musaIds = <String>{
      ...professional.keys,
      ...personalMultipliers.keys,
    };

    return {
      for (final musaId in musaIds)
        musaId: ((professional[musaId] ?? 1.0) *
                (personalMultipliers[musaId] ?? 1.0))
            .clamp(0.75, 1.35)
            .toDouble(),
    };
  }

  String _normalizeGenre(String? genre) {
    return (genre ?? '').trim().toLowerCase();
  }
}

class ProfessionalCalibrationProfile {
  const ProfessionalCalibrationProfile({
    required this.genre,
    required this.referenceTitle,
    required this.sourceReportPath,
    required this.scoreMultipliers,
  });

  final String genre;
  final String referenceTitle;
  final String sourceReportPath;
  final Map<String, double> scoreMultipliers;
}
