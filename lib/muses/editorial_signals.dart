class EditorialSignals {
  final int dialogueMarksCount;
  final bool hasDialogue;

  final int questionCount;

  final int actionVerbCount;
  final bool hasAction;

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
    required this.sentenceCount,
    required this.avgSentenceLength,
    required this.shortSentenceStreak,
    required this.longSentenceCount,
    required this.lexicalDiversity,
  });
}

EditorialSignals buildEditorialSignals(String text) {
  final normalized = text.trim();
  final lowered = normalized.toLowerCase();

  // Dialogue marks
  final dialogueMarksCount = RegExp(r'[—"“”]').allMatches(normalized).length;

  // Questions
  final questionCount = RegExp(r'\?').allMatches(normalized).length;

  // Action verbs (stems from TensionMusa)
  const actionTokens = [
    // raíces / verbos físicos
    'abr', 'corri', 'corr', 'grit', 'golp', 'salt', 'empuj', 'sac',
    'lanz', 'mir', 'camin', 'entr', 'sal', 'levant', 'sub', 'baj',
    'reaccion', 'decid', 'detuv', 'tom', 'agarr', 'asinti', 'neg',
    // verbos operativos / de consecuencia
    'obliga', 'requiere', 'impide', 'limita', 'prohíbe', 'cuesta', 'depende',
  ];

  int actionVerbCount = 0;
  for (final token in actionTokens) {
    if (lowered.contains(token)) actionVerbCount++;
  }

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
    actionVerbCount: actionVerbCount,
    hasAction: actionVerbCount > 0,
    sentenceCount: sentenceCount,
    avgSentenceLength: avgSentenceLength,
    shortSentenceStreak: maxConsecutiveShorts,
    longSentenceCount: longSentenceCount,
    lexicalDiversity: lexicalDiversity,
  );
}
