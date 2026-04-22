import '../domain/musa/musa_objects.dart';
import 'editorial_recommendation.dart';
import 'musa.dart';

class MusaAutopilot {
  const MusaAutopilot();

  EditorialRecommendation recommend({
    required String selection,
    required NarrativeContext context,
  }) {
    final analysis = _analyze(selection, context);

    // PRIORITY: Dominance check
    // If one Musa is clearly superior, we favor it directly.
    // For Tension, we allow a lower threshold (>= 2) and ignore Clarity score.
    // We also allow tie-breaking over Rhythm (>=).
    if (analysis.tensionScore >= 2 &&
        analysis.tensionScore >= analysis.rhythmScore &&
        analysis.tensionScore > analysis.styleScore) {
      return EditorialRecommendation(
        type: EditorialRecommendationType.singleMusa,
        musas: const [TensionMusa()],
        reason: 'La tensión narrativa es el factor claramente dominante en este fragmento.',
        confidence: analysis.tensionScore / 5,
      );
    }

    if (analysis.rhythmScore >= 3 &&
        analysis.rhythmScore > analysis.tensionScore &&
        analysis.rhythmScore > analysis.styleScore &&
        analysis.rhythmScore > analysis.clarityScore) {
      return EditorialRecommendation(
        type: EditorialRecommendationType.singleMusa,
        musas: const [RhythmMusa()],
        reason: 'El pulso y el flujo rítmico son los factores claramente dominantes en este fragmento.',
        confidence: analysis.rhythmScore / 5,
      );
    }

    if (analysis.styleScore >= 3 &&
        analysis.styleScore > analysis.tensionScore &&
        analysis.styleScore > analysis.rhythmScore &&
        analysis.styleScore > analysis.clarityScore) {
      return EditorialRecommendation(
        type: EditorialRecommendationType.singleMusa,
        musas: const [StyleMusa()],
        reason: 'El refinamiento de estilo es el factor claramente dominante en este fragmento.',
        confidence: analysis.styleScore / 4,
      );
    }

    if (analysis.clarityScore >= 4 &&
        analysis.rhythmScore >= 3 &&
        analysis.styleScore >= 2) {
      return const EditorialRecommendation(
        type: EditorialRecommendationType.pipeline,
        musas: [ClarityMusa(), RhythmMusa(), StyleMusa()],
        reason:
            'El fragmento necesita despeje estructural, mejor respiración y un cierre más expresivo.',
        confidence: 0.86,
      );
    }

    if (analysis.clarityScore >= 4 && analysis.styleScore >= 3) {
      return const EditorialRecommendation(
        type: EditorialRecommendationType.pipeline,
        musas: [ClarityMusa(), StyleMusa()],
        reason:
            'La base es algo confusa y, una vez limpia, ganará más con un refinamiento de estilo.',
        confidence: 0.81,
      );
    }

    if (analysis.clarityScore >= 4 && analysis.rhythmScore >= 3) {
      return const EditorialRecommendation(
        type: EditorialRecommendationType.pipeline,
        musas: [ClarityMusa(), RhythmMusa()],
        reason:
            'La prioridad es aclarar el pasaje y después ajustar su respiración.',
        confidence: 0.79,
      );
    }

    if (analysis.rhythmScore >= 4 && analysis.styleScore >= 3) {
      return const EditorialRecommendation(
        type: EditorialRecommendationType.pipeline,
        musas: [RhythmMusa(), StyleMusa()],
        reason:
            'El fragmento pide primero un pulso más limpio y después una capa de refinamiento literario.',
        confidence: 0.76,
      );
    }

    if (analysis.rhythmScore >= 4 && analysis.tensionScore >= 3) {
      return const EditorialRecommendation(
        type: EditorialRecommendationType.pipeline,
        musas: [RhythmMusa(), TensionMusa()],
        reason:
            'La escena necesita más tracción interna antes de cargarla de tensión.',
        confidence: 0.74,
      );
    }

    if (analysis.clarityScore >= 4 && analysis.tensionScore >= 3) {
      return const EditorialRecommendation(
        type: EditorialRecommendationType.pipeline,
        musas: [ClarityMusa(), TensionMusa()],
        reason:
            'Conviene despejar el pasaje antes de intensificar su amenaza implícita.',
        confidence: 0.73,
      );
    }

    final best = analysis.bestMusa;
    final reason = switch (best.id) {
      'clarity' =>
        'El fragmento necesita una intervención de nitidez antes que cualquier otra mejora.',
      'rhythm' =>
        'El problema dominante es de flujo: la prosa respira mal o avanza con rigidez.',
      'tension' =>
        'La escena tiene potencial dramático, pero le falta fricción narrativa perceptible.',
      _ =>
        'El pasaje ya es legible; lo que más ganará ahora es una mejora de estilo controlada.',
    };

    return EditorialRecommendation(
      type: EditorialRecommendationType.singleMusa,
      musas: <Musa>[best],
      reason: reason,
      confidence: analysis.bestScore,
    );
  }

  _AutopilotAnalysis _analyze(String selection, NarrativeContext context) {
    final normalized = selection.trim();
    final sentenceParts = normalized
        .split(RegExp(r'(?<=[\.\!\?\…])\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    final wordMatches = RegExp(r"[A-Za-zÁÉÍÓÚáéíóúÑñÜü']+")
        .allMatches(normalized)
        .map((match) => match.group(0)!.toLowerCase())
        .toList();

    final sentenceLengths = sentenceParts
        .map((sentence) =>
            RegExp(r"[A-Za-zÁÉÍÓÚáéíóúÑñÜü']+").allMatches(sentence).length)
        .where((count) => count > 0)
        .toList();

    final averageSentenceLength = sentenceLengths.isEmpty
        ? wordMatches.length.toDouble()
        : sentenceLengths.reduce((a, b) => a + b) / sentenceLengths.length;
    final maxSentenceLength = sentenceLengths.isEmpty
        ? wordMatches.length
        : sentenceLengths.reduce((a, b) => a > b ? a : b);
    final minSentenceLength = sentenceLengths.isEmpty
        ? wordMatches.length
        : sentenceLengths.reduce((a, b) => a < b ? a : b);
    final commaCount = ',;:'.split('').fold<int>(
          0,
          (acc, char) => acc + char.allMatches(normalized).length,
        );
    final subordinateMatches = RegExp(
      r'\b(que|porque|aunque|mientras|cuando|donde|which|that|because|although|while)\b',
      caseSensitive: false,
    ).allMatches(normalized).length;
    final repeatedWords = <String, int>{};
    for (final word in wordMatches) {
      repeatedWords[word] = (repeatedWords[word] ?? 0) + 1;
    }
    final repeatedPenalty =
        repeatedWords.values.where((count) => count >= 3).length;
    final uniqueRatio =
        wordMatches.isEmpty ? 1.0 : repeatedWords.length / wordMatches.length;
    final dramaticLexicon = RegExp(
      r'\b(sangre|sombr|oscur|miedo|amenaza|polic|grit|cadáver|arma|ruido|viento|sombra|blood|fear|threat|shadow|weapon|sirens?)\b',
      caseSensitive: false,
    ).allMatches('${context.tensionLevel} $normalized').length;

    var clarityScore = 0;
    if (averageSentenceLength >= 22) clarityScore += 2;
    if (maxSentenceLength >= 30) clarityScore += 2;
    if (commaCount >= 3) clarityScore += 1;
    if (subordinateMatches >= 2) clarityScore += 1;
    if (repeatedPenalty >= 1) clarityScore += 1;

    var rhythmScore = 0;
    if (sentenceLengths.length >= 2 &&
        (maxSentenceLength - minSentenceLength) <= 3) {
      rhythmScore += 2;
    }
    if (sentenceLengths.length == 1 && averageSentenceLength >= 16) {
      rhythmScore += 2;
    }
    if (RegExp(r'[,:;]').allMatches(normalized).isEmpty &&
        wordMatches.length >= 18) {
      rhythmScore += 1;
    }
    if (sentenceLengths.length >= 3) {
      rhythmScore += 1;
    }

    var styleScore = 0;
    if (uniqueRatio < 0.68) styleScore += 2;
    if (wordMatches.length >= 6 && dramaticLexicon == 0) styleScore += 1;
    if (sentenceParts.length <= 2 && averageSentenceLength < 14) {
      styleScore += 1;
    }

    var tensionScore = 0;
    if (dramaticLexicon >= 1) tensionScore += 2;
    if (context.tensionLevel.toLowerCase() != 'neutral') tensionScore += 1;
    if (sentenceParts.length <= 2 &&
        wordMatches.length <= 10 &&
        dramaticLexicon >= 1) {
      tensionScore += 1;
    }
    if (normalized.contains('?') || normalized.contains('—')) {
      tensionScore += 1;
    }

    final musaScores = <Musa, double>{
      const ClarityMusa(): clarityScore / 6,
      const RhythmMusa(): rhythmScore / 5,
      const StyleMusa(): styleScore / 4,
      const TensionMusa(): tensionScore / 5,
    };

    final bestEntry = musaScores.entries.reduce(
      (current, next) => current.value >= next.value ? current : next,
    );

    return _AutopilotAnalysis(
      clarityScore: clarityScore,
      rhythmScore: rhythmScore,
      styleScore: styleScore,
      tensionScore: tensionScore,
      bestMusa: bestEntry.key,
      bestScore: bestEntry.value.clamp(0, 1).toDouble(),
    );
  }
}

class _AutopilotAnalysis {
  final int clarityScore;
  final int rhythmScore;
  final int styleScore;
  final int tensionScore;
  final Musa bestMusa;
  final double bestScore;

  const _AutopilotAnalysis({
    required this.clarityScore,
    required this.rhythmScore,
    required this.styleScore,
    required this.tensionScore,
    required this.bestMusa,
    required this.bestScore,
  });
}
