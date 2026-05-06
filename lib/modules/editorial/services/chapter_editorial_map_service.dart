import '../../../editor/services/text_normalizer.dart';
import '../../../muses/editorial_signals.dart';
import '../../../muses/professional_corpus_calibration.dart';
import '../../books/models/book.dart';
import '../../books/models/narrative_copilot.dart';
import '../../books/services/narrative_document_classifier.dart';
import '../../manuscript/models/document.dart';
import '../models/chapter_editorial_map.dart';

class ChapterEditorialMapService {
  const ChapterEditorialMapService({
    this.documentClassifier = const NarrativeDocumentClassifier(),
    this.professionalCalibration = const ProfessionalCorpusCalibration(),
  });

  final NarrativeDocumentClassifier documentClassifier;
  final ProfessionalCorpusCalibration professionalCalibration;

  ChapterEditorialMapReport build({
    required Book book,
    required List<Document> documents,
    required NarrativeMemory? memory,
    required StoryState? storyState,
    required DateTime now,
  }) {
    final narrativeDocuments = documents
        .where((document) =>
            document.bookId == book.id &&
            documentClassifier.classify(document).kind ==
                NarrativeDocumentKind.scene)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final profile = professionalCalibration.profileForGenre(
      book.narrativeProfile.primaryGenre.name,
    );
    final chapters = <ChapterEditorialMapItem>[];
    for (var index = 0; index < narrativeDocuments.length; index++) {
      chapters.add(_chapterItem(
        document: narrativeDocuments[index],
        index: index,
        total: narrativeDocuments.length,
        memory: memory,
        storyState: storyState,
        profile: profile,
      ));
    }

    return ChapterEditorialMapReport(
      bookId: book.id,
      chapters: chapters,
      summaryActions: _summaryActions(chapters),
      updatedAt: now,
    );
  }

  ChapterEditorialMapItem _chapterItem({
    required Document document,
    required int index,
    required int total,
    required NarrativeMemory? memory,
    required StoryState? storyState,
    required ProfessionalCalibrationProfile profile,
  }) {
    final signals = buildEditorialSignals(document.content);
    final stage = _stageFor(index, total);
    final tensionScore = _tensionScore(signals, storyState);
    final rhythmScore = _rhythmScore(signals, profile);
    final promiseScore = _promiseScore(document.content, memory, stage);
    final need = _primaryNeed(
      stage: stage,
      tensionScore: tensionScore,
      rhythmScore: rhythmScore,
      promiseScore: promiseScore,
      memory: memory,
    );

    return ChapterEditorialMapItem(
      documentId: document.id,
      title: document.title,
      orderIndex: document.orderIndex,
      stage: stage,
      primaryNeed: need,
      tensionScore: tensionScore,
      rhythmScore: rhythmScore,
      promiseScore: promiseScore,
      professionalRhythmLabel: _professionalRhythmLabel(signals, profile),
      evidence: _evidence(signals, memory),
      nextAction: _nextAction(need),
    );
  }

  ChapterEditorialStage _stageFor(int index, int total) {
    if (total <= 1) return ChapterEditorialStage.opening;
    final progress = index / (total - 1);
    if (progress <= 0.33) return ChapterEditorialStage.opening;
    if (progress >= 0.67) return ChapterEditorialStage.closing;
    return ChapterEditorialStage.middle;
  }

  int _tensionScore(EditorialSignals signals, StoryState? storyState) {
    final dialogueHeavy = signals.dialogueMarksCount >= 4;
    final action = signals.contextualActionStrength(dialogueHeavy);
    final localScore =
        36 + (action * 36).round() + (signals.questionCount * 6).clamp(0, 18);
    final globalBias =
        storyState == null ? 0 : ((storyState.globalTension - 50) / 6).round();
    return (localScore + globalBias).clamp(0, 100);
  }

  int _rhythmScore(
    EditorialSignals signals,
    ProfessionalCalibrationProfile profile,
  ) {
    if (profile.metrics == ProfessionalCorpusMetrics.neutral) return 72;
    final delta =
        (signals.avgSentenceLength - profile.metrics.avgSentenceLength).abs();
    return (100 - (delta * 5).round()).clamp(35, 100);
  }

  int _promiseScore(
    String content,
    NarrativeMemory? memory,
    ChapterEditorialStage stage,
  ) {
    final unresolved = memory?.unresolvedPromises ?? const [];
    if (unresolved.isEmpty) return 78;
    final lowered = content.toLowerCase();
    final mentioned = unresolved.where((promise) {
      final token = _compactPromiseToken(promise);
      return token.isNotEmpty && lowered.contains(token);
    }).length;
    var score = 70 - unresolved.length * 8 + mentioned * 12;
    if (stage == ChapterEditorialStage.closing && unresolved.isNotEmpty) {
      score -= 16;
    }
    return score.clamp(0, 100);
  }

  ChapterEditorialNeed _primaryNeed({
    required ChapterEditorialStage stage,
    required int tensionScore,
    required int rhythmScore,
    required int promiseScore,
    required NarrativeMemory? memory,
  }) {
    if (memory?.scenePatternWarnings.isNotEmpty == true) {
      return ChapterEditorialNeed.consequence;
    }
    if (stage == ChapterEditorialStage.closing && promiseScore < 62) {
      return ChapterEditorialNeed.promise;
    }
    if (tensionScore < 48) return ChapterEditorialNeed.tension;
    if (rhythmScore < 62) return ChapterEditorialNeed.rhythm;
    if (promiseScore < 58) return ChapterEditorialNeed.promise;
    return ChapterEditorialNeed.stable;
  }

  String _professionalRhythmLabel(
    EditorialSignals signals,
    ProfessionalCalibrationProfile profile,
  ) {
    if (profile.metrics == ProfessionalCorpusMetrics.neutral) {
      return 'sin perfil';
    }
    final delta = signals.avgSentenceLength - profile.metrics.avgSentenceLength;
    if (delta.abs() <= 2.5) return 'alineado con corpus profesional';
    return delta > 0
        ? 'más lento que corpus profesional'
        : 'más cortado que corpus profesional';
  }

  String _evidence(EditorialSignals signals, NarrativeMemory? memory) {
    final items = <String>[
      '${signals.avgSentenceLength.toStringAsFixed(1)} palabras/frase',
      '${signals.questionCount} preguntas',
      if (memory?.unresolvedPromises.isNotEmpty == true)
        '${memory!.unresolvedPromises.length} promesas abiertas',
    ];
    return items.join(' · ');
  }

  String _nextAction(ChapterEditorialNeed need) {
    return switch (need) {
      ChapterEditorialNeed.consequence =>
        'Añade una consecuencia visible antes de repetir investigación.',
      ChapterEditorialNeed.promise =>
        'Paga, transforma o jerarquiza una promesa abierta en este tramo.',
      ChapterEditorialNeed.tension =>
        'Sube tensión con coste, amenaza o decisión irreversible.',
      ChapterEditorialNeed.rhythm =>
        'Ajusta respiración: corta exposición o rompe frases demasiado largas.',
      ChapterEditorialNeed.stable =>
        'Mantén avance y recalcula tras el siguiente capítulo clave.',
    };
  }

  List<String> _summaryActions(List<ChapterEditorialMapItem> chapters) {
    final actions = <String>[];
    for (final need in ChapterEditorialNeed.values) {
      final match = chapters.where((chapter) => chapter.primaryNeed == need);
      if (match.isEmpty || need == ChapterEditorialNeed.stable) continue;
      actions.add(match.first.nextAction);
    }
    return _dedupe(actions).take(4).toList();
  }

  String _compactPromiseToken(String promise) {
    final words = TextNormalizer.wordPattern
        .allMatches(promise.toLowerCase())
        .map((match) => match.group(0)!)
        .where((word) => word.length > 3)
        .toList();
    if (words.isEmpty) return '';
    return words.length == 1 ? words.first : words.take(2).join(' ');
  }

  List<String> _dedupe(List<String> values) {
    final results = <String>[];
    for (final value in values) {
      if (value.trim().isEmpty || results.contains(value)) continue;
      results.add(value);
    }
    return results;
  }
}
