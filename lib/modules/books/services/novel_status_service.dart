import '../../../editor/services/text_analysis_lexicons.dart';
import '../../../editor/services/text_normalizer.dart';
import '../../../muses/editorial_signals.dart';
import '../../../muses/professional_corpus_calibration.dart';
import '../../manuscript/models/document.dart';
import '../models/book.dart';
import '../models/narrative_copilot.dart';
import '../models/novel_status.dart';
import 'narrative_document_classifier.dart';

class NovelStatusService {
  const NovelStatusService({
    this.professionalCalibration = const ProfessionalCorpusCalibration(),
    this.documentClassifier = const NarrativeDocumentClassifier(),
  });

  final ProfessionalCorpusCalibration professionalCalibration;
  final NarrativeDocumentClassifier documentClassifier;

  NovelStatusReport build({
    required Book book,
    required List<Document> documents,
    required NarrativeMemory? memory,
    required StoryState? storyState,
    required DateTime now,
  }) {
    final narrativeDocuments = documents
        .where((document) =>
            documentClassifier.classify(document).kind ==
            NarrativeDocumentKind.scene)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final manuscriptText = narrativeDocuments
        .map((document) => document.content)
        .where((content) => content.trim().isNotEmpty)
        .join('\n\n');
    final signals = manuscriptText.trim().isEmpty
        ? buildEditorialSignals('')
        : buildEditorialSignals(manuscriptText);
    final totalWords = _wordCount(manuscriptText);
    final profile = professionalCalibration.profileForGenre(
      book.narrativeProfile.primaryGenre.name,
    );
    final comparisons = _professionalComparisons(
      signals: signals,
      manuscriptText: manuscriptText,
      totalWords: totalWords,
      profile: profile,
    );

    final tensionScore = _tensionScore(
      book: book,
      storyState: storyState,
      memory: memory,
      comparisons: comparisons,
    );
    final rhythmScore = _rhythmScore(comparisons);
    final promiseScore = _promiseScore(book, memory);
    final memoryScore = _memoryScore(memory);
    final statusSignals = _statusSignals(
      book: book,
      memory: memory,
      storyState: storyState,
      tensionScore: tensionScore,
      rhythmScore: rhythmScore,
      promiseScore: promiseScore,
      memoryScore: memoryScore,
      comparisons: comparisons,
      hasNarrativeText: manuscriptText.trim().isNotEmpty,
    );
    final overallScore =
        ((tensionScore + rhythmScore + promiseScore + memoryScore) / 4)
            .round()
            .clamp(0, 100);

    return NovelStatusReport(
      bookId: book.id,
      overallScore: overallScore,
      healthLevel: _healthLevel(overallScore),
      tensionScore: tensionScore,
      rhythmScore: rhythmScore,
      promiseScore: promiseScore,
      memoryScore: memoryScore,
      signals: statusSignals,
      professionalComparisons: comparisons,
      nextActions: _nextActions(statusSignals, storyState).take(3).toList(),
      updatedAt: now,
    );
  }

  int _tensionScore({
    required Book book,
    required StoryState? storyState,
    required NarrativeMemory? memory,
    required List<ProfessionalMetricComparison> comparisons,
  }) {
    var score = storyState?.globalTension ?? 50;
    if (memory?.activeThreats.isNotEmpty == true) score += 8;
    if (book.narrativeProfile.primaryGenre == BookPrimaryGenre.thriller &&
        score < 30) {
      score -= 8;
    }
    return score.clamp(0, 100);
  }

  int _rhythmScore(List<ProfessionalMetricComparison> comparisons) {
    final sentenceLength =
        comparisons.cast<ProfessionalMetricComparison?>().firstWhere(
              (item) => item?.metric == 'Longitud media de frase',
              orElse: () => null,
            );
    if (sentenceLength == null) return 72;
    final delta =
        (sentenceLength.manuscriptValue - sentenceLength.professionalValue)
            .abs();
    return (100 - (delta * 4).round()).clamp(35, 100);
  }

  int _promiseScore(Book book, NarrativeMemory? memory) {
    final hasBookPromise =
        book.narrativeProfile.readerPromise?.trim().isNotEmpty == true;
    final readerPromises = memory?.readerPromises.length ?? 0;
    final unresolved = memory?.unresolvedPromises.length ?? 0;
    var score = hasBookPromise ? 78 : 48;
    score += (readerPromises * 4).clamp(0, 12);
    score -= (unresolved * 8).clamp(0, 48);
    return score.clamp(0, 100);
  }

  int _memoryScore(NarrativeMemory? memory) {
    if (memory == null) return 35;
    final usefulSignals = memory.openQuestions.length +
        memory.plantedClues.length +
        memory.activeThreats.length +
        memory.importantFacts.length +
        memory.readerPromises.length +
        memory.toneSignals.length;
    final warnings = memory.scenePatternWarnings.length +
        (memory.unresolvedPromises.length > 4 ? 1 : 0);
    return (48 + usefulSignals * 6 - warnings * 10).clamp(0, 100);
  }

  List<NovelStatusSignal> _statusSignals({
    required Book book,
    required NarrativeMemory? memory,
    required StoryState? storyState,
    required int tensionScore,
    required int rhythmScore,
    required int promiseScore,
    required int memoryScore,
    required List<ProfessionalMetricComparison> comparisons,
    required bool hasNarrativeText,
  }) {
    final results = <NovelStatusSignal>[];
    if (!hasNarrativeText) {
      results.add(const NovelStatusSignal(
        area: NovelStatusArea.memory,
        level: NovelStatusSignalLevel.info,
        title: 'Sin material narrativo suficiente',
        detail: 'Aún no hay escenas o capítulos con texto para evaluar.',
        action: 'Escribe o importa capítulos y vuelve a analizar el libro.',
      ));
    }
    if (book.narrativeProfile.readerPromise?.trim().isEmpty ?? true) {
      results.add(const NovelStatusSignal(
        area: NovelStatusArea.promise,
        level: NovelStatusSignalLevel.warning,
        title: 'Promesa de lectura sin definir',
        detail:
            'El ADN narrativo todavía no fija qué experiencia debe sostener la novela.',
        action: 'Define una promesa concreta en el perfil narrativo del libro.',
      ));
    }
    if (tensionScore < 35) {
      results.add(NovelStatusSignal(
        area: NovelStatusArea.tension,
        level: NovelStatusSignalLevel.warning,
        title: 'Tensión por debajo de la promesa',
        detail: book.narrativeProfile.primaryGenre == BookPrimaryGenre.thriller
            ? 'Para thriller, la tensión actual queda baja frente al patrón profesional del género.'
            : 'La tensión actual todavía no empuja con claridad la lectura.',
        evidence: storyState == null ? '' : '${storyState.globalTension}/100',
        action:
            'Sube tensión con amenaza, reloj, coste o una decisión irreversible.',
      ));
    }
    if (promiseScore < 60) {
      results.add(NovelStatusSignal(
        area: NovelStatusArea.promise,
        level: NovelStatusSignalLevel.warning,
        title: 'Demasiadas promesas abiertas',
        detail:
            'Hay promesas abiertas compitiendo por atención sin pago narrativo suficiente.',
        evidence: '${memory?.unresolvedPromises.length ?? 0} abiertas',
        action:
            'Cierra, transforma o jerarquiza una promesa antes de abrir otra.',
      ));
    }
    if (memory?.scenePatternWarnings.isNotEmpty == true) {
      results.add(NovelStatusSignal(
        area: NovelStatusArea.memory,
        level: NovelStatusSignalLevel.warning,
        title: 'Patrón de escena repetido',
        detail: memory!.scenePatternWarnings.first,
        action: 'Convierte la repetición en consecuencia visible o decisión.',
      ));
    }
    if (rhythmScore < 65) {
      final comparison =
          comparisons.cast<ProfessionalMetricComparison?>().firstWhere(
                (item) => item?.metric == 'Longitud media de frase',
                orElse: () => null,
              );
      results.add(NovelStatusSignal(
        area: NovelStatusArea.rhythm,
        level: NovelStatusSignalLevel.info,
        title: 'Ritmo alejado del perfil profesional',
        detail: comparison == null
            ? 'El ritmo se aleja del objetivo del libro.'
            : 'La longitud media de frase está ${comparison.differenceLabel} del corpus profesional.',
        action: 'Ajusta respiración de frase según la intensidad buscada.',
      ));
    }
    if (results.isEmpty) {
      results.add(const NovelStatusSignal(
        area: NovelStatusArea.memory,
        level: NovelStatusSignalLevel.positive,
        title: 'Estado narrativo estable',
        detail:
            'La novela conserva una relación sana entre memoria, promesa, ritmo y tensión.',
        action: 'Sigue avanzando y recalcula tras el próximo capítulo clave.',
      ));
    }
    return results.take(6).toList();
  }

  List<String> _nextActions(
    List<NovelStatusSignal> signals,
    StoryState? storyState,
  ) {
    final actions = <String>[
      for (final signal in signals)
        if (signal.action.trim().isNotEmpty) signal.action,
      if (storyState?.nextBestMove.trim().isNotEmpty == true)
        storyState!.nextBestMove,
    ];
    return _dedupe(actions);
  }

  List<ProfessionalMetricComparison> _professionalComparisons({
    required EditorialSignals signals,
    required String manuscriptText,
    required int totalWords,
    required ProfessionalCalibrationProfile profile,
  }) {
    if (profile.metrics == ProfessionalCorpusMetrics.neutral) return const [];
    final perKBase = totalWords == 0 ? 0 : totalWords / 1000;
    return [
      ProfessionalMetricComparison(
        metric: 'Longitud media de frase',
        manuscriptValue: signals.avgSentenceLength,
        professionalValue: profile.metrics.avgSentenceLength,
        differenceLabel: _differenceLabel(
          signals.avgSentenceLength,
          profile.metrics.avgSentenceLength,
          tolerance: 2.5,
        ),
      ),
      ProfessionalMetricComparison(
        metric: 'Diálogo por mil palabras',
        manuscriptValue:
            perKBase == 0 ? 0 : signals.dialogueMarksCount / perKBase,
        professionalValue: profile.metrics.dialogueMarksPerK,
        differenceLabel: _differenceLabel(
          perKBase == 0 ? 0 : signals.dialogueMarksCount / perKBase,
          profile.metrics.dialogueMarksPerK,
          tolerance: 8,
        ),
      ),
      ProfessionalMetricComparison(
        metric: 'Preguntas por mil palabras',
        manuscriptValue: perKBase == 0 ? 0 : signals.questionCount / perKBase,
        professionalValue: profile.metrics.questionsPerK,
        differenceLabel: _differenceLabel(
          perKBase == 0 ? 0 : signals.questionCount / perKBase,
          profile.metrics.questionsPerK,
          tolerance: 4,
        ),
      ),
      ProfessionalMetricComparison(
        metric: 'Términos dramáticos por mil palabras',
        manuscriptValue:
            perKBase == 0 ? 0 : _dramaticTerms(manuscriptText) / perKBase,
        professionalValue: profile.metrics.dramaticTermsPerK,
        differenceLabel: _differenceLabel(
          perKBase == 0 ? 0 : _dramaticTerms(manuscriptText) / perKBase,
          profile.metrics.dramaticTermsPerK,
          tolerance: 3,
        ),
      ),
    ];
  }

  String _differenceLabel(
    double manuscriptValue,
    double professionalValue, {
    required double tolerance,
  }) {
    if (professionalValue == 0) return 'sin baseline';
    final delta = manuscriptValue - professionalValue;
    if (delta.abs() <= tolerance) return 'alineado';
    return delta > 0 ? 'por encima' : 'por debajo';
  }

  NovelStatusHealth _healthLevel(int score) {
    if (score < 35) return NovelStatusHealth.critical;
    if (score < 70) return NovelStatusHealth.watch;
    if (score < 85) return NovelStatusHealth.stable;
    return NovelStatusHealth.strong;
  }

  int _wordCount(String text) {
    return TextNormalizer.wordPattern.allMatches(text).length;
  }

  int _dramaticTerms(String text) {
    final lowered = text.toLowerCase();
    var count = 0;
    for (final token in TextAnalysisLexicons.tensionTokens) {
      if (lowered.contains(token)) count++;
    }
    return count;
  }

  List<String> _dedupe(List<String> values) {
    final results = <String>[];
    for (final value in values) {
      final compacted = value.trim();
      if (compacted.isEmpty || results.contains(compacted)) continue;
      results.add(compacted);
    }
    return results;
  }
}
