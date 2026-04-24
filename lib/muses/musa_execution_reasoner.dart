import 'musa.dart';

/// Tracks and explains why each musa in a pipeline was executed or skipped.
/// Provides transparency into the editorial decision-making process.
class MusaExecutionReasoner {
  final List<MusaExecutionDecision> decisions = [];

  void recordExecution(
    Musa musa,
    String reason, {
    double scoreValue = 0.0,
    double thresholdValue = 0.0,
    Map<String, String>? contextDetails,
  }) {
    decisions.add(MusaExecutionDecision(
      musaId: musa.id,
      musaName: musa.name,
      executed: true,
      reason: reason,
      scoreValue: scoreValue,
      thresholdValue: thresholdValue,
      contextDetails: contextDetails ?? {},
      timestamp: DateTime.now(),
    ));
  }

  void recordSkip(
    Musa musa,
    String reason, {
    double scoreValue = 0.0,
    double thresholdValue = 0.0,
    Map<String, String>? contextDetails,
  }) {
    decisions.add(MusaExecutionDecision(
      musaId: musa.id,
      musaName: musa.name,
      executed: false,
      reason: reason,
      scoreValue: scoreValue,
      thresholdValue: thresholdValue,
      contextDetails: contextDetails ?? {},
      timestamp: DateTime.now(),
    ));
  }

  String generateExecutionSummary() {
    if (decisions.isEmpty) return 'Sin decisiones registradas.';

    final executed = decisions.where((d) => d.executed).toList();
    final skipped = decisions.where((d) => !d.executed).toList();

    final buffer = StringBuffer();
    buffer.writeln('📋 Explicación del Pipeline Editorial');
    buffer.writeln('═' * 40);

    if (executed.isNotEmpty) {
      buffer.writeln('\n✅ Musas Ejecutadas:');
      for (final decision in executed) {
        buffer.writeln('  • ${decision.musaName}');
        buffer.writeln('    └─ ${decision.reason}');
        if (decision.scoreValue > 0) {
          buffer.writeln(
              '    └─ Score: ${decision.scoreValue.toStringAsFixed(2)} (umbral: ${decision.thresholdValue.toStringAsFixed(2)})');
        }
      }
    }

    if (skipped.isNotEmpty) {
      buffer.writeln('\n⏭️ Musas Omitidas:');
      for (final decision in skipped) {
        buffer.writeln('  • ${decision.musaName}');
        buffer.writeln('    └─ ${decision.reason}');
        if (decision.scoreValue > 0) {
          buffer.writeln(
              '    └─ Score: ${decision.scoreValue.toStringAsFixed(2)} (umbral: ${decision.thresholdValue.toStringAsFixed(2)})');
        }
      }
    }

    return buffer.toString();
  }

  String getReasonForMusa(String musaId) {
    final decision = decisions.firstWhere(
      (d) => d.musaId == musaId,
      orElse: () => MusaExecutionDecision(
        musaId: musaId,
        musaName: 'Desconocida',
        executed: false,
        reason: 'Sin información disponible',
        scoreValue: 0.0,
        thresholdValue: 0.0,
        contextDetails: {},
        timestamp: DateTime.now(),
      ),
    );

    return decision.executed
        ? '✅ Ejecutada: ${decision.reason}'
        : '⏭️ Omitida: ${decision.reason}';
  }

  List<MusaExecutionDecision> get executedMusas =>
      decisions.where((d) => d.executed).toList();

  List<MusaExecutionDecision> get skippedMusas =>
      decisions.where((d) => !d.executed).toList();

  int get totalDecisions => decisions.length;

  void clear() => decisions.clear();
}

/// Detailed record of a musa execution/skip decision
class MusaExecutionDecision {
  final String musaId;
  final String musaName;
  final bool executed;
  final String reason;
  final double scoreValue;
  final double thresholdValue;
  final Map<String, String> contextDetails;
  final DateTime timestamp;

  MusaExecutionDecision({
    required this.musaId,
    required this.musaName,
    required this.executed,
    required this.reason,
    required this.scoreValue,
    required this.thresholdValue,
    required this.contextDetails,
    required this.timestamp,
  });

  String get executionStatus => executed ? 'EXECUTED' : 'SKIPPED';

  String get scoreDisplay => scoreValue == 0
      ? 'N/A'
      : '${scoreValue.toStringAsFixed(2)}/${thresholdValue.toStringAsFixed(2)}';
}

/// Suggestion explanation provider
/// Shows what each musa did to the text
class SuggestionExplainer {
  static String explainClarityChange(
    String original,
    String suggestion,
  ) {
    final originalWords = original.split(RegExp(r'\s+'));
    final suggestionWords = suggestion.split(RegExp(r'\s+'));

    final wordsRemoved = originalWords.length - suggestionWords.length;
    final wordsAdded = suggestionWords.length - originalWords.length;

    final buffer = StringBuffer();
    buffer.write('Clarity realizó: ');

    if (wordsRemoved > 0) {
      buffer.write('eliminó $wordsRemoved palabras');
      if (wordsAdded > 0) buffer.write(' y agregó $wordsAdded');
    } else if (wordsAdded > 0) {
      buffer.write('agregó $wordsAdded palabras');
    } else {
      buffer.write('reestructuró la oración');
    }

    return buffer.toString();
  }

  static String explainRhythmChange(
    String original,
    String suggestion,
  ) {
    final originalSentences =
        original.split(RegExp(r'[.!?]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    final suggestionSentences =
        suggestion.split(RegExp(r'[.!?]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    final sentencesAdded = suggestionSentences.length - originalSentences.length;
    final sentencesRemoved = originalSentences.length - suggestionSentences.length;

    if (sentencesAdded > 0) {
      return 'Rhythm dividió párrafos complejos en $sentencesAdded oraciones más cortas';
    } else if (sentencesRemoved > 0) {
      return 'Rhythm consolidó $sentencesRemoved oraciones en estructuras más fluidas';
    } else {
      return 'Rhythm ajustó la cadencia sin cambiar el número de oraciones';
    }
  }

  static String explainStyleChange(
    String original,
    String suggestion,
  ) {
    final originalLength = original.length;
    final suggestionLength = suggestion.length;

    if (suggestionLength > originalLength * 1.1) {
      return 'Style enriqueció el lenguaje con descripciones más vívidas';
    } else if (suggestionLength < originalLength * 0.9) {
      return 'Style condensó prosa redundante sin perder significado';
    } else {
      return 'Style refinó vocabulario y precisión léxica';
    }
  }

  static String explainTensionChange(
    String original,
    String suggestion,
  ) {
    final originalHasQuestion = original.contains('?');
    final suggestionHasQuestion = suggestion.contains('?');

    if (!originalHasQuestion && suggestionHasQuestion) {
      return 'Tension agregó preguntas retóricas para crear intriga';
    }

    if (original.length < suggestion.length) {
      return 'Tension intensificó la escena con detalles sensoriales';
    }

    return 'Tension restructuró para máxima carga dramática';
  }

  static String explainMusaChange(
    String musaId,
    String original,
    String suggestion,
  ) {
    return switch (musaId) {
      'clarity' => explainClarityChange(original, suggestion),
      'rhythm' => explainRhythmChange(original, suggestion),
      'style' => explainStyleChange(original, suggestion),
      'tension' => explainTensionChange(original, suggestion),
      _ => 'La musa realizó cambios editoriales en el fragmento',
    };
  }
}
