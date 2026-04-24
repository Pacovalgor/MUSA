import 'package:collection/collection.dart';

/// Analyzes semantic patterns in narrative text: atmosphere, pacing, thematic echoes.
/// Complements editorial_signals by providing deeper narrative understanding.
class SemanticPatternAnalyzer {
  SemanticPatternAnalyzer();

  /// Detects atmospheric tone in the text.
  /// Returns score 0.0-1.0 for each atmosphere type.
  AtmosphereAnalysis analyzeAtmosphere(String content) {
    final lowerText = content.toLowerCase();
    final tokens = _tokenize(lowerText);

    final tensionScore = _detectTension(lowerText, tokens);
    final mysteryScore = _detectMystery(lowerText, tokens);
    final warmthScore = _detectWarmth(lowerText, tokens);
    final dreadScore = _detectDread(lowerText, tokens);

    return AtmosphereAnalysis(
      tension: tensionScore,
      mystery: mysteryScore,
      warmth: warmthScore,
      dread: dreadScore,
      dominantMood: _getDominantMood(
        tension: tensionScore,
        mystery: mysteryScore,
        warmth: warmthScore,
        dread: dreadScore,
      ),
    );
  }

  /// Analyzes pacing by examining sentence length variation and rhythm.
  /// Returns metrics about narrative speed and acceleration.
  PacingAnalysis analyzePacing(String content) {
    final sentences = _splitSentences(content);
    if (sentences.isEmpty) {
      return PacingAnalysis(
        averageLength: 0.0,
        variance: 0.0,
        shortPercentage: 0.0,
        longPercentage: 0.0,
        accelerating: false,
        pacePattern: 'unknown',
      );
    }

    final lengths = sentences.map((s) => s.split(' ').length).toList();
    final average = lengths.fold<double>(0, (a, b) => a + b) / lengths.length;
    final variance =
        lengths.fold<double>(0, (a, b) => a + (b - average).abs()) / lengths.length;

    final shortCount = lengths.where((l) => l < 5).length;
    final longCount = lengths.where((l) => l > 20).length;

    final isAccelerating = _detectAcceleration(lengths);
    final pattern = _identifyPacePattern(lengths);

    return PacingAnalysis(
      averageLength: average,
      variance: variance,
      shortPercentage: (shortCount / lengths.length) * 100,
      longPercentage: (longCount / lengths.length) * 100,
      accelerating: isAccelerating,
      pacePattern: pattern,
    );
  }

  /// Detects thematic echoes: keywords that repeat throughout the text.
  /// Identifies potential narrative themes and motifs.
  ThematicEchoAnalysis analyzeThematicEchoes(String content) {
    final lowerText = content.toLowerCase();
    final words = _tokenize(lowerText);

    // Filter to meaningful words (not stopwords, min length 4)
    final meaningfulWords = words
        .where((w) => !_isStopword(w) && w.length > 3)
        .toList();

    if (meaningfulWords.isEmpty) {
      return ThematicEchoAnalysis(
        keywordFrequency: {},
        dominantThemes: [],
        themeStrength: 0.0,
      );
    }

    // Count word frequencies
    final frequency = <String, int>{};
    for (final word in meaningfulWords) {
      frequency[word] = (frequency[word] ?? 0) + 1;
    }

    // Filter to words appearing 3+ times (themes)
    final themes = frequency.entries
        .where((e) => e.value >= 3)
        .sortedBy<num>((e) => -e.value)
        .take(10)
        .map((e) => e.key)
        .toList();

    final themeStrength = themes.isEmpty
        ? 0.0
        : (frequency[themes.first]! / meaningfulWords.length).clamp(0.0, 1.0);

    return ThematicEchoAnalysis(
      keywordFrequency: frequency,
      dominantThemes: themes,
      themeStrength: themeStrength,
    );
  }

  // === Private Helpers ===

  double _detectTension(String text, List<String> tokens) {
    final tensionWords = const [
      'nervio',
      'ansia',
      'miedo',
      'pánico',
      'alarma',
      'estrés',
      'urgencia',
      'prisa',
      'rápido',
      'precipitado',
      'apresura',
      'persecución',
      'huida',
      'peligro',
      'amenaza',
      'advertencia',
      'grito',
      'golpe',
      'choque',
      'conflicto',
    ];

    int matches = 0;
    for (final word in tensionWords) {
      if (text.contains(word)) matches++;
    }

    return (matches / tensionWords.length).clamp(0.0, 1.0);
  }

  double _detectMystery(String text, List<String> tokens) {
    final mysteryWords = const [
      'misterio',
      'secreto',
      'incógnita',
      'enigma',
      'desconocido',
      'oculto',
      'escondido',
      'susurro',
      'incierto',
      'dudoso',
      'sospechoso',
      'extraño',
      'anómalo',
      'raro',
      'curiosidad',
      'pregunta',
      'interrogante',
      'pista',
      'indicio',
      'revelación',
    ];

    int matches = 0;
    for (final word in mysteryWords) {
      if (text.contains(word)) matches++;
    }

    return (matches / mysteryWords.length).clamp(0.0, 1.0);
  }

  double _detectWarmth(String text, List<String> tokens) {
    final warmthWords = const [
      'amor',
      'cariño',
      'abrazo',
      'calor',
      'sonrisa',
      'risa',
      'dicha',
      'alegría',
      'felicidad',
      'paz',
      'tranquilidad',
      'serenidad',
      'confort',
      'seguridad',
      'hogar',
      'familia',
      'amigo',
      'compañía',
      'bondad',
      'ternura',
    ];

    int matches = 0;
    for (final word in warmthWords) {
      if (text.contains(word)) matches++;
    }

    return (matches / warmthWords.length).clamp(0.0, 1.0);
  }

  double _detectDread(String text, List<String> tokens) {
    final dreadWords = const [
      'muerte',
      'cadáver',
      'sangre',
      'dolor',
      'sufrimiento',
      'agonía',
      'tortura',
      'abismo',
      'oscuridad',
      'sombra',
      'horror',
      'espanto',
      'terror',
      'maldición',
      'desgracia',
      'ruina',
      'fin',
      'pérdida',
      'desolación',
      'vacío',
    ];

    int matches = 0;
    for (final word in dreadWords) {
      if (text.contains(word)) matches++;
    }

    return (matches / dreadWords.length).clamp(0.0, 1.0);
  }

  String _getDominantMood({
    required double tension,
    required double mystery,
    required double warmth,
    required double dread,
  }) {
    final moods = {
      'tension': tension,
      'mystery': mystery,
      'warmth': warmth,
      'dread': dread,
    };

    final dominant = moods.entries.reduce((a, b) => a.value > b.value ? a : b);
    return dominant.key;
  }

  bool _detectAcceleration(List<int> sentenceLengths) {
    if (sentenceLengths.length < 4) return false;

    final firstHalf = sentenceLengths.sublist(0, sentenceLengths.length ~/ 2);
    final secondHalf = sentenceLengths.sublist(sentenceLengths.length ~/ 2);

    final firstAvg =
        firstHalf.fold<double>(0, (a, b) => a + b) / firstHalf.length;
    final secondAvg =
        secondHalf.fold<double>(0, (a, b) => a + b) / secondHalf.length;

    return secondAvg < firstAvg; // Shorter sentences = acceleration
  }

  String _identifyPacePattern(List<int> sentenceLengths) {
    if (sentenceLengths.length < 3) return 'unknown';

    final avgLength = sentenceLengths.fold<double>(0, (a, b) => a + b) /
        sentenceLengths.length;

    final shortStreak = sentenceLengths.where((l) => l < avgLength * 0.6).length;
    final longStreak = sentenceLengths.where((l) => l > avgLength * 1.5).length;

    if (shortStreak > sentenceLengths.length * 0.4) return 'staccato';
    if (longStreak > sentenceLengths.length * 0.4) return 'flowing';
    return 'balanced';
  }

  List<String> _tokenize(String text) {
    return text
        .split(RegExp(r'[\s\W]+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  List<String> _splitSentences(String text) {
    return text.split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  bool _isStopword(String word) {
    const stopwords = {
      'el', 'la', 'de', 'que', 'y', 'a', 'en', 'un', 'ser', 'se',
      'no', 'haber', 'por', 'con', 'su', 'para', 'es', 'lo', 'como',
      'más', 'o', 'pero', 'sus', 'le', 'ya', 'o', 'fue', 'este', 'ha',
      'sí', 'porque', 'esta', 'son', 'entre', 'está', 'cuando', 'muy',
      'sin', 'sobre', 'ser', 'tiene', 'también', 'me', 'hasta', 'hay',
      'donde', 'han', 'quien', 'están', 'estado', 'desde', 'todo', 'nos',
      'durante', 'estados', 'todos', 'uno', 'les', 'ni', 'contra', 'otros',
      'fueron', 'ese', 'eso', 'había', 'ante', 'ellos', 'era', 'esas',
      'esto', 'nosotros', 'mio', 'algunas', 'algo', 'nosotras', 'mi',
      'mis', 'tú', 'te', 'ti', 'tu', 'tus', 'ellas', 'nosotros', 'vosotras',
      'vosotros', 'os', 'mío', 'mía', 'míos', 'mías', 'tuyo', 'tuya',
      'tuyos', 'tuyas', 'suyo', 'suya', 'suyos', 'suyas', 'nuestro',
      'nuestra', 'nuestros', 'nuestras', 'vuestro', 'vuestra', 'vuestros',
      'vuestras', 'esos', 'esa', 'estamos', 'estará', 'estaría', 'estaban',
    };
    return stopwords.contains(word);
  }
}

/// Results from atmosphere analysis
class AtmosphereAnalysis {
  final double tension;
  final double mystery;
  final double warmth;
  final double dread;
  final String dominantMood;

  AtmosphereAnalysis({
    required this.tension,
    required this.mystery,
    required this.warmth,
    required this.dread,
    required this.dominantMood,
  });

  double get intensity => [tension, mystery, warmth, dread]
      .fold<double>(0, (a, b) => a + b) / 4;
}

/// Results from pacing analysis
class PacingAnalysis {
  final double averageLength;
  final double variance;
  final double shortPercentage;
  final double longPercentage;
  final bool accelerating;
  final String pacePattern;

  PacingAnalysis({
    required this.averageLength,
    required this.variance,
    required this.shortPercentage,
    required this.longPercentage,
    required this.accelerating,
    required this.pacePattern,
  });
}

/// Results from thematic echo analysis
class ThematicEchoAnalysis {
  final Map<String, int> keywordFrequency;
  final List<String> dominantThemes;
  final double themeStrength;

  ThematicEchoAnalysis({
    required this.keywordFrequency,
    required this.dominantThemes,
    required this.themeStrength,
  });
}
