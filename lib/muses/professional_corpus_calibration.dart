class ProfessionalCorpusCalibration {
  static const _neutralProfile = ProfessionalCalibrationProfile(
    genre: 'literary',
    referenceTitle: 'Base editorial neutral',
    sourceReportPath: '',
    metrics: ProfessionalCorpusMetrics.neutral,
    references: [],
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
      metrics: ProfessionalCorpusMetrics(
        avgSentenceLength: 13.428,
        dialogueMarksPerK: 28.548,
        questionsPerK: 4.598,
        dramaticTermsPerK: 5.67,
        lexicalDiversity: 0.267,
      ),
      references: [
        ProfessionalCorpusReference(
          title: 'Mithas y Karthay',
          author: 'Tina Daniell',
          filename: 'Mithas_y_Karthay_Tina_Daniell.epub',
        ),
        ProfessionalCorpusReference(
          title: 'Kitiara Uth Matar',
          author: 'Tina Daniell',
          filename: 'Kitiara_Uth_Matar_Tina_Daniell.epub',
        ),
        ProfessionalCorpusReference(
          title: 'El orbe de los dragones',
          author: 'Margaret Weis',
          filename: 'El_orbe_de_los_dragones_Margaret_Weis.epub',
        ),
        ProfessionalCorpusReference(
          title: 'El mazo de Kharas',
          author: 'Margaret Weis',
          filename: 'El_mazo_de_Kharas_Margaret_Weis.epub',
        ),
        ProfessionalCorpusReference(
          title: 'La torre de Wayreth',
          author: 'Margaret Weis',
          filename: 'La_torre_de_Wayreth_Margaret_Weis.epub',
        ),
      ],
      scoreMultipliers: {
        'clarity': 1.0,
        'rhythm': 1.06,
        'style': 1.08,
        'tension': 1.1,
      },
    ),
    'thriller': ProfessionalCalibrationProfile(
      genre: 'thriller',
      referenceTitle: 'Tras la puerta',
      sourceReportPath: 'test/fixtures/report-libro2.md',
      metrics: ProfessionalCorpusMetrics(
        avgSentenceLength: 10.206,
        dialogueMarksPerK: 37.136,
        questionsPerK: 8.734,
        dramaticTermsPerK: 1.246,
        lexicalDiversity: 0.294,
      ),
      references: [
        ProfessionalCorpusReference(
          title: 'Tras la puerta',
          author: 'Freida McFadden',
          filename: 'Tras_la_puerta_Freida_McFadden.epub',
        ),
        ProfessionalCorpusReference(
          title: 'La asistenta',
          author: 'Freida McFadden',
          filename: 'La_asistenta_Freida_McFadden.epub',
        ),
        ProfessionalCorpusReference(
          title: 'Nunca mientas',
          author: 'Freida McFadden',
          filename: 'Nunca_mientas_Freida_McFadden.epub',
        ),
        ProfessionalCorpusReference(
          title: 'El recluso',
          author: 'Freida McFadden',
          filename: 'El_recluso_Freida_McFadden.epub',
        ),
        ProfessionalCorpusReference(
          title: 'El problema final',
          author: 'Arturo Perez-Reverte',
          filename: 'El_problema_final_Arturo_PerezReverte.epub',
        ),
      ],
      scoreMultipliers: {
        'clarity': 1.0,
        'rhythm': 1.08,
        'style': 1.0,
        'tension': 1.14,
      },
    ),
    'historical': ProfessionalCalibrationProfile(
      genre: 'historical',
      referenceTitle: 'Un lugar llamado libertad',
      sourceReportPath: 'test/fixtures/report-libro3.md',
      metrics: ProfessionalCorpusMetrics(
        avgSentenceLength: 13.07,
        dialogueMarksPerK: 28.16,
        questionsPerK: 4.054,
        dramaticTermsPerK: 1.78,
        lexicalDiversity: 0.246,
      ),
      references: [
        ProfessionalCorpusReference(
          title: 'Un lugar llamado libertad',
          author: 'Ken Follett',
          filename: 'Un_lugar_llamado_libertad_Ken_Follett.epub',
        ),
        ProfessionalCorpusReference(
          title: 'Los pilares de la Tierra',
          author: 'Ken Follett',
          filename: 'Los_pilares_de_la_Tierra_Edicion_ilustrada_Ken_Follett.epub',
        ),
        ProfessionalCorpusReference(
          title: 'La caida de los gigantes',
          author: 'Ken Follett',
          filename: 'La_caida_de_los_gigantes_Ken_Follett.epub',
        ),
        ProfessionalCorpusReference(
          title: 'Una columna de fuego',
          author: 'Ken Follett',
          filename: 'Una_columna_de_fuego_Ken_Follett.epub',
        ),
        ProfessionalCorpusReference(
          title: 'Circo Maximo',
          author: 'Santiago Posteguillo',
          filename: 'Circo_Maximo_Santiago_Posteguillo.epub',
        ),
      ],
      scoreMultipliers: {
        'clarity': 1.1,
        'rhythm': 1.07,
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
    required this.metrics,
    required this.references,
    required this.scoreMultipliers,
  });

  final String genre;
  final String referenceTitle;
  final String sourceReportPath;
  final ProfessionalCorpusMetrics metrics;
  final List<ProfessionalCorpusReference> references;
  final Map<String, double> scoreMultipliers;
}

class ProfessionalCorpusMetrics {
  static const neutral = ProfessionalCorpusMetrics(
    avgSentenceLength: 0,
    dialogueMarksPerK: 0,
    questionsPerK: 0,
    dramaticTermsPerK: 0,
    lexicalDiversity: 0,
  );

  const ProfessionalCorpusMetrics({
    required this.avgSentenceLength,
    required this.dialogueMarksPerK,
    required this.questionsPerK,
    required this.dramaticTermsPerK,
    required this.lexicalDiversity,
  });

  final double avgSentenceLength;
  final double dialogueMarksPerK;
  final double questionsPerK;
  final double dramaticTermsPerK;
  final double lexicalDiversity;
}

class ProfessionalCorpusReference {
  const ProfessionalCorpusReference({
    required this.title,
    required this.author,
    required this.filename,
    this.sampleText,
  });

  final String title;
  final String author;
  final String filename;
  final String? sampleText;
}
