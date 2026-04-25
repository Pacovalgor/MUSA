import '../../../editor/services/text_analysis_lexicons.dart';
import '../../manuscript/models/document.dart';

enum NarrativeDocumentKind {
  scene,
  research,
  worldbuilding,
  technical,
  unknown,
}

class NarrativeDocumentClassification {
  final NarrativeDocumentKind kind;
  final String reason;
  final double confidence;

  const NarrativeDocumentClassification({
    required this.kind,
    required this.reason,
    this.confidence = 1.0,
  });

  bool get updatesStoryState => kind == NarrativeDocumentKind.scene;
  bool get isAmbiguous => confidence < 0.6;
  bool get isConfident => confidence >= 0.85;
}

class NarrativeDocumentClassifier {
  const NarrativeDocumentClassifier();

  NarrativeDocumentClassification classify(Document document) {
    return _classify(document.title, document.content, _isManuscriptDocument(document));
  }

  NarrativeDocumentClassification classifyRaw(String content, {String title = ''}) {
    return _classify(title, content, false);
  }

  NarrativeDocumentClassification _classify(String title, String content, bool isManuscript) {
    final lowerTitle = title.toLowerCase();
    final lowerText = content.toLowerCase();
    final sample =
        '$lowerTitle\n${lowerText.length > 2400 ? lowerText.substring(0, 2400) : lowerText}';

    // Chapters/scenes are assumed narrative — skip technical/research detection
    // unless there are very strong signals (≥2 matches) to avoid false positives
    // from short tokens like 'api' matching as substrings in Spanish words.
    final technicalThreshold = isManuscript ? 2 : 1;
    final technicalMatches =
        _countMatches(sample, TextAnalysisLexicons.documentTechnicalTokens);
    if (technicalMatches >= technicalThreshold) {
      final confidence = (technicalMatches /
              TextAnalysisLexicons.documentTechnicalTokens.length)
          .clamp(0.5, 1.0);
      return NarrativeDocumentClassification(
        kind: NarrativeDocumentKind.technical,
        reason:
            'Parece material técnico o de preparación, no una escena narrativa.',
        confidence: confidence,
      );
    }

    final researchThreshold = isManuscript ? 2 : 1;
    final researchMatches =
        _countMatches(sample, TextAnalysisLexicons.documentResearchTokens);
    if (researchMatches >= researchThreshold) {
      final confidence = (researchMatches /
              TextAnalysisLexicons.documentResearchTokens.length)
          .clamp(0.5, 1.0);
      return NarrativeDocumentClassification(
        kind: NarrativeDocumentKind.research,
        reason: 'Parece material de investigación o apoyo documental.',
        confidence: confidence,
      );
    }

    final magicMatches = _countMatches(
        sample, TextAnalysisLexicons.documentWorldbuildingMagicTokens);
    final buildMatches = _countMatches(
        sample, TextAnalysisLexicons.documentWorldbuildingBuildTokens);
    if (magicMatches > 0 && buildMatches > 0) {
      final confidence = ((magicMatches + buildMatches) /
              (TextAnalysisLexicons.documentWorldbuildingMagicTokens.length +
                  TextAnalysisLexicons.documentWorldbuildingBuildTokens.length))
          .clamp(0.5, 1.0);
      return NarrativeDocumentClassification(
        kind: NarrativeDocumentKind.worldbuilding,
        reason: 'Parece construcción de mundo o material de diseño narrativo.',
        confidence: confidence,
      );
    }

    final (sceneSignals, actionPresent, contextPresent) = _countSceneSignals(sample);
    final manuscriptBonus = isManuscript && content.length > 40 ? 0.3 : 0.0;

    // Require action/context signals alongside introspection to avoid false positives
    final hasSceneContext = actionPresent || contextPresent;

    if (sceneSignals > 0 && hasSceneContext || manuscriptBonus > 0) {
      final baseConfidence = (sceneSignals * 0.25).clamp(0.0, 1.0) + manuscriptBonus;
      return NarrativeDocumentClassification(
        kind: NarrativeDocumentKind.scene,
        reason:
            'Contiene señales de escena narrativa o un capítulo manuscrito sustancial.',
        confidence: baseConfidence.clamp(0.4, 1.0),
      );
    }

    return const NarrativeDocumentClassification(
      kind: NarrativeDocumentKind.unknown,
      reason: 'No hay suficientes señales para tratarlo como escena narrativa.',
      confidence: 0.0,
    );
  }

  int _countMatches(String value, List<String> tokens) {
    int count = 0;
    for (final token in tokens) {
      if (value.contains(token)) count++;
    }
    return count;
  }

  bool _isManuscriptDocument(Document document) {
    return document.kind == DocumentKind.chapter ||
        document.kind == DocumentKind.scene;
  }

  (int, bool, bool) _countSceneSignals(String sample) {
    int signals = 0;
    bool actionPresent = false;
    bool contextPresent = false;

    if (_hasAny(sample, TextAnalysisLexicons.documentSceneFirstPersonTokens)) {
      signals++;
    }

    if (_hasAny(sample, TextAnalysisLexicons.documentSceneActionTokens)) {
      signals++;
      actionPresent = true;
    }

    final timeMatchClock = RegExp(r'\b\d{1,2}:\s?\d{2}\b').hasMatch(sample);
    final timeMatchAMPM = RegExp(r'\b\d{1,2}\s*(?:am|pm)\b').hasMatch(sample);
    final timeMatch = timeMatchClock || timeMatchAMPM;

    final hasPlace =
        _hasAny(sample, TextAnalysisLexicons.documentScenePlaceTokens);

    if (timeMatch || hasPlace) {
      signals++;
      contextPresent = true;
    }

    return (signals, actionPresent, contextPresent);
  }

  bool _hasAny(String value, List<String> tokens) {
    for (final token in tokens) {
      if (value.contains(token)) return true;
    }
    return false;
  }
}
