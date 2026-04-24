class EditorialSignals {
  final int dialogueMarksCount;
  final bool hasDialogue;

  final int questionCount;

  final int actionVerbCount;
  final bool hasAction;

  // Weighted action scores (0.0-1.0 range for easier comparison)
  final double physicalActionScore;      // corrió, saltó, entró (concrete movement)
  final double operationalScore;         // obliga, requiere, impide (consequence)
  final double dialogueActionScore;      // dijo, respondió, preguntó (speech context)

  final int sentenceCount;
  final double avgSentenceLength;

  final int shortSentenceStreak;
  final int longSentenceCount;

  final double lexicalDiversity;

  const EditorialSignals({
    required this.dialogueMarksCount,
    required this.hasDialogue,
    required this.questionCount,
    required this.actionVerbCount,
    required this.hasAction,
    required this.physicalActionScore,
    required this.operationalScore,
    required this.dialogueActionScore,
    required this.sentenceCount,
    required this.avgSentenceLength,
    required this.shortSentenceStreak,
    required this.longSentenceCount,
    required this.lexicalDiversity,
  });

  /// Combined action strength considering context
  /// In dialogue context, dialogue actions are more valuable than physical actions
  /// In narrative context, physical actions are most valuable
  double contextualActionStrength(bool isDialogueHeavy) {
    if (isDialogueHeavy) {
      // Dialogue context: prioritize dialogue verbs + operational flow
      return (dialogueActionScore * 0.5 + operationalScore * 0.4 + physicalActionScore * 0.1).clamp(0.0, 1.0);
    } else {
      // Narrative context: prioritize physical actions + operational consequences
      return (physicalActionScore * 0.6 + operationalScore * 0.3 + dialogueActionScore * 0.1).clamp(0.0, 1.0);
    }
  }
}

EditorialSignals buildEditorialSignals(String text) {
  final normalized = text.trim();
  final lowered = normalized.toLowerCase();

  // Dialogue marks
  final dialogueMarksCount = RegExp(r'[—“””]').allMatches(normalized).length;
  final isDialogueHeavy = dialogueMarksCount >= 4;

  // Questions
  final questionCount = RegExp(r'\?').allMatches(normalized).length;

  // Action verbs by type with weighted scoring
  const physicalActionTokens = [
    // Verbos de movimiento físico / acción concreta
    'corr', 'grit', 'golp', 'salt', 'empuj', 'sac',
    'lanz', 'mir', 'camin', 'entr', 'sal', 'levant', 'sub', 'baj',
    'reaccion', 'detuv', 'tom', 'agarr', 'asinti', 'neg',
  ];

  const operationalTokens = [
    // Verbos que generan consecuencias / obligaciones
    'oblig', 'requiere', 'impide', 'limita', 'prohib', 'cuesta', 'depend',
    'fuerz', 'orden', 'exig', 'permite', 'niega',
  ];

  const dialogueTokens = [
    // Verbos dicendi y de comunicación
    'dij', 'respondio', 'pregunt', 'grit', 'susurr', 'mentin', 'jur',
    'prom', 'confes', 'ment', 'asum', 'insist', 'demand',
  ];

  int physicalActionCount = 0;
  for (final token in physicalActionTokens) {
    if (lowered.contains(token)) physicalActionCount++;
  }

  int operationalCount = 0;
  for (final token in operationalTokens) {
    if (lowered.contains(token)) operationalCount++;
  }

  int dialogueCount = 0;
  for (final token in dialogueTokens) {
    if (lowered.contains(token)) dialogueCount++;
  }

  final totalActionCount = physicalActionCount + operationalCount + dialogueCount;

  // Normalize scores to 0.0-1.0 range
  // Clamp at arbitrary max (5 instances = 1.0) to prevent over-weighting
  final physicalActionScore = (physicalActionCount / 5.0).clamp(0.0, 1.0);
  final operationalScore = (operationalCount / 5.0).clamp(0.0, 1.0);
  final dialogueActionScore = isDialogueHeavy
      ? (dialogueCount / 5.0).clamp(0.0, 1.0)
      : (dialogueCount / 5.0).clamp(0.0, 0.7); // Reduce weight in non-dialogue contexts

  // Sentences and length
  final sentenceParts = normalized
      .split(RegExp(r'(?<=[\.\!\?\…])\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();

  final sentenceLengths = sentenceParts
      .map((sentence) =>
          RegExp(r"[A-Za-zÁÉÍÓÚáéíóúÑñÜü']+").allMatches(sentence).length)
      .where((count) => count > 0)
      .toList();

  final wordMatches = RegExp(r"[A-Za-zÁÉÍÓÚáéíóúÑñÜü']+")
      .allMatches(normalized)
      .map((match) => match.group(0)!.toLowerCase())
      .toList();

  final sentenceCount = sentenceParts.length;
  final avgSentenceLength = sentenceLengths.isEmpty
      ? wordMatches.length.toDouble()
      : sentenceLengths.reduce((a, b) => a + b) / sentenceLengths.length;

  // Short sentence streak
  int maxConsecutiveShorts = 0;
  int currentConsecutiveShorts = 0;
  for (final length in sentenceLengths) {
    if (length < 6) {
      currentConsecutiveShorts++;
      if (currentConsecutiveShorts > maxConsecutiveShorts) {
        maxConsecutiveShorts = currentConsecutiveShorts;
      }
    } else {
      currentConsecutiveShorts = 0;
    }
  }

  // Long sentence count (Clarity threshold is >= 22)
  final longSentenceCount = sentenceLengths.where((l) => l >= 22).length;

  // Lexical diversity
  final repeatedWords = <String, int>{};
  for (final word in wordMatches) {
    repeatedWords[word] = (repeatedWords[word] ?? 0) + 1;
  }
  final lexicalDiversity =
      wordMatches.isEmpty ? 1.0 : repeatedWords.length / wordMatches.length;

  return EditorialSignals(
    dialogueMarksCount: dialogueMarksCount,
    hasDialogue: dialogueMarksCount > 0,
    questionCount: questionCount,
    actionVerbCount: totalActionCount,
    hasAction: totalActionCount > 0,
    physicalActionScore: physicalActionScore,
    operationalScore: operationalScore,
    dialogueActionScore: dialogueActionScore,
    sentenceCount: sentenceCount,
    avgSentenceLength: avgSentenceLength,
    shortSentenceStreak: maxConsecutiveShorts,
    longSentenceCount: longSentenceCount,
    lexicalDiversity: lexicalDiversity,
  );
}
