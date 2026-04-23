import '../domain/musa/musa_objects.dart';
import 'editorial_recommendation.dart';
import 'editorial_signals.dart';
import 'musa.dart';

class MusaAutopilot {
  const MusaAutopilot();

  EditorialRecommendation recommend({
    required String selection,
    required NarrativeContext context,
  }) {
    final analysis = _analyze(selection, context);

    // Calculate secondary candidates for all paths
    final allMusas = [
      const TensionMusa(),
      const RhythmMusa(),
      const StyleMusa(),
      const ClarityMusa(),
    ];

    List<Musa> getSecondaryMusas(List<Musa> primaryMusas) {
      final scores = <Musa, double>{
        const ClarityMusa(): analysis.clarityScore / 6,
        const RhythmMusa(): analysis.rhythmScore / 5,
        const StyleMusa(): analysis.styleScore / 4,
        const TensionMusa(): analysis.tensionScore / 5,
      };

      return allMusas
          .where((musa) => !primaryMusas.any((p) => p.id == musa.id))
          .where((musa) => (scores[musa] ?? 0) >= 0.2) // Significant enough
          .toList()
        ..sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));
    }

    // PRIORITY: Dominance check
    if (analysis.tensionScore >= 2 &&
        analysis.tensionScore >= analysis.rhythmScore &&
        analysis.tensionScore > analysis.styleScore) {
      const primary = TensionMusa();
      final triggers = analysis.triggers[primary.id] ?? [];
      return EditorialRecommendation(
        type: EditorialRecommendationType.singleMusa,
        musas: const [primary],
        secondaryMusas: getSecondaryMusas(const [primary]).take(2).toList(),
        reason: _buildReason(primary, triggers),
        confidence: analysis.tensionScore / 5,
      );
    }

    if (analysis.rhythmScore >= 3 &&
        analysis.rhythmScore > analysis.tensionScore &&
        analysis.rhythmScore > analysis.styleScore &&
        analysis.rhythmScore > analysis.clarityScore) {
      const primary = RhythmMusa();
      final triggers = analysis.triggers[primary.id] ?? [];
      return EditorialRecommendation(
        type: EditorialRecommendationType.singleMusa,
        musas: const [primary],
        secondaryMusas: getSecondaryMusas(const [primary]).take(2).toList(),
        reason: _buildReason(primary, triggers),
        confidence: analysis.rhythmScore / 5,
      );
    }

    if (analysis.styleScore >= 3 &&
        analysis.styleScore > analysis.tensionScore &&
        analysis.styleScore > analysis.rhythmScore &&
        analysis.styleScore > analysis.clarityScore) {
      const primary = StyleMusa();
      final triggers = analysis.triggers[primary.id] ?? [];
      return EditorialRecommendation(
        type: EditorialRecommendationType.singleMusa,
        musas: const [primary],
        secondaryMusas: getSecondaryMusas(const [primary]).take(2).toList(),
        reason: _buildReason(primary, triggers),
        confidence: analysis.styleScore / 4,
      );
    }

    if (analysis.clarityScore >= 4 &&
        analysis.rhythmScore >= 3 &&
        analysis.styleScore >= 2) {
      const primaryMusas = [ClarityMusa(), RhythmMusa(), StyleMusa()];
      return EditorialRecommendation(
        type: EditorialRecommendationType.pipeline,
        musas: primaryMusas,
        secondaryMusas: getSecondaryMusas(primaryMusas).take(1).toList(),
        reason:
            'El fragmento necesita despeje estructural, mejor respiración y un cierre más expresivo.',
        confidence: 0.86,
      );
    }

    if (analysis.clarityScore >= 4 && analysis.styleScore >= 3) {
      const primaryMusas = [ClarityMusa(), StyleMusa()];
      return EditorialRecommendation(
        type: EditorialRecommendationType.pipeline,
        musas: primaryMusas,
        secondaryMusas: getSecondaryMusas(primaryMusas).take(2).toList(),
        reason:
            'La base es algo confusa y, una vez limpia, ganará más con un refinamiento de estilo.',
        confidence: 0.81,
      );
    }

    if (analysis.clarityScore >= 4 && analysis.rhythmScore >= 3) {
      const primaryMusas = [ClarityMusa(), RhythmMusa()];
      return EditorialRecommendation(
        type: EditorialRecommendationType.pipeline,
        musas: primaryMusas,
        secondaryMusas: getSecondaryMusas(primaryMusas).take(2).toList(),
        reason:
            'La prioridad es aclarar el pasaje y después ajustar su respiración.',
        confidence: 0.79,
      );
    }

    if (analysis.rhythmScore >= 4 && analysis.styleScore >= 3) {
      const primaryMusas = [RhythmMusa(), StyleMusa()];
      return EditorialRecommendation(
        type: EditorialRecommendationType.pipeline,
        musas: primaryMusas,
        secondaryMusas: getSecondaryMusas(primaryMusas).take(2).toList(),
        reason:
            'El fragmento pide primero un pulso más limpio y después una capa de refinamiento literario.',
        confidence: 0.76,
      );
    }

    if (analysis.rhythmScore >= 4 && analysis.tensionScore >= 3) {
      const primaryMusas = [RhythmMusa(), TensionMusa()];
      return EditorialRecommendation(
        type: EditorialRecommendationType.pipeline,
        musas: primaryMusas,
        secondaryMusas: getSecondaryMusas(primaryMusas).take(2).toList(),
        reason:
            'La escena necesita más tracción interna antes de cargarla de tensión.',
        confidence: 0.74,
      );
    }

    if (analysis.clarityScore >= 4 && analysis.tensionScore >= 3) {
      const primaryMusas = [ClarityMusa(), TensionMusa()];
      return EditorialRecommendation(
        type: EditorialRecommendationType.pipeline,
        musas: primaryMusas,
        secondaryMusas: getSecondaryMusas(primaryMusas).take(2).toList(),
        reason:
            'Conviene despejar el pasaje antes de intensificar su amenaza implícita.',
        confidence: 0.73,
      );
    }

    final best = analysis.bestMusa;
    final bestTriggers = analysis.triggers[best.id] ?? [];
    final reason = _buildReason(best, bestTriggers);

    return EditorialRecommendation(
      type: EditorialRecommendationType.singleMusa,
      musas: <Musa>[best],
      secondaryMusas: getSecondaryMusas([best]).take(2).toList(),
      reason: reason,
      confidence: analysis.bestScore,
    );
  }

  String _buildReason(Musa musa, List<String> triggers) {
    if (triggers.isEmpty) {
      return switch (musa.id) {
        'clarity' => 'El fragmento necesita una intervención de nitidez antes que cualquier otra mejora.',
        'rhythm' => 'El problema dominante es de flujo: la prosa respira mal o avanza con rigidez.',
        'tension' => 'La escena tiene potencial dramático, pero le falta fricción narrativa perceptible.',
        _ => 'El pasaje ya es legible; lo que más ganará ahora es una mejora de estilo controlada.',
      };
    }

    final triggerText = triggers.join(' y ');
    return switch (musa.id) {
      'tension' => 'He elegido Tensión porque detecto $triggerText.',
      'rhythm' => 'He elegido Ritmo porque el flujo rítmico presenta $triggerText.',
      'style' => 'He elegido Estilo por $triggerText.',
      'clarity' => 'He elegido Claridad porque el pasaje presenta $triggerText.',
      _ => 'He elegido ${musa.name} por $triggerText.',
    };
  }

  _AutopilotAnalysis _analyze(String selection, NarrativeContext context) {
    final normalized = selection.trim();
    final signals = buildEditorialSignals(normalized);

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

    final dramaticLexicon = RegExp(
      r'\b(sangre|sombr|oscur|miedo|amenaza|polic|grit|cadáver|arma|ruido|viento|sombra|blood|fear|threat|shadow|weapon|sirens?)\b',
      caseSensitive: false,
    ).allMatches('${context.tensionLevel} $normalized').length;

    final triggers = <String, List<String>>{
      'clarity': [],
      'rhythm': [],
      'style': [],
      'tension': [],
    };

    var clarityScore = 0;
    if (signals.avgSentenceLength >= 22) {
      clarityScore += 2;
      triggers['clarity']!.add('frases largas');
    }
    if (maxSentenceLength >= 30) {
      clarityScore += 2;
      triggers['clarity']!.add('complejidad estructural');
    }
    if (commaCount >= 3 || subordinateMatches >= 2) {
      clarityScore += 1;
      triggers['clarity']!.add('estructura confusa');
    }
    if (repeatedPenalty >= 1) {
      clarityScore += 1;
    }

    var rhythmScore = 0;
    if (signals.shortSentenceStreak >= 3) {
      rhythmScore += 2;
      triggers['rhythm']!.add('frases cortas repetidas');
    }

    if (sentenceLengths.length >= 2 &&
        (maxSentenceLength - minSentenceLength) <= 3) {
      rhythmScore += 2;
      triggers['rhythm']!.add('fragmentación alta');
    }
    if (sentenceLengths.length == 1 && signals.avgSentenceLength >= 16) {
      rhythmScore += 2;
    }
    if (RegExp(r'[,:;]').allMatches(normalized).isEmpty &&
        wordMatches.length >= 18) {
      rhythmScore += 1;
    }

    var styleScore = 0;
    if (signals.lexicalDiversity < 0.68) {
      styleScore += 2;
      triggers['style']!.add('repetición de términos');
    }
    if (repeatedPenalty >= 1) {
      styleScore += 1;
      triggers['style']!.add('baja variación léxica');
    }
    if (wordMatches.length >= 6 && dramaticLexicon == 0) styleScore += 1;

    var tensionScore = 0;

    // Detect stagnant dialogue
    if (signals.dialogueMarksCount >= 2 && !signals.hasAction) {
      tensionScore += 2;
      triggers['tension']!.add('diálogo sin acción y ausencia de avance físico');
    }

    if (dramaticLexicon >= 1) {
      tensionScore += 2;
      triggers['tension']!.add('léxico dramático');
    }
    if (context.tensionLevel.toLowerCase() != 'neutral') {
      tensionScore += 1;
      triggers['tension']!.add('contexto de tensión');
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
      triggers: triggers,
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
  final Map<String, List<String>> triggers;

  const _AutopilotAnalysis({
    required this.clarityScore,
    required this.rhythmScore,
    required this.styleScore,
    required this.tensionScore,
    required this.bestMusa,
    required this.bestScore,
    required this.triggers,
  });
}
