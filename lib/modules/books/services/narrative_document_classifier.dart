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

  const NarrativeDocumentClassification({
    required this.kind,
    required this.reason,
  });

  bool get updatesStoryState => kind == NarrativeDocumentKind.scene;
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

    if (_hasAny(sample, const [
      'entrevista full stack',
      'manual completo',
      'objetivo transmitir',
      'regla base',
      'frontend',
      'backend',
      'api',
      'pull request',
      'currículum',
    ])) {
      return const NarrativeDocumentClassification(
        kind: NarrativeDocumentKind.technical,
        reason:
            'Parece material técnico o de preparación, no una escena narrativa.',
      );
    }

    if (_hasAny(sample, const [
      'resumen ejecutivo',
      'documento de investigación',
      'objetivo de este documento',
      'cómo hacer que',
      'cómo construir',
      'qué es la',
      'características:',
      'se basa',
      'este documento analiza',
      'este documento explica',
      'osint',
      'apofenia',
    ])) {
      return const NarrativeDocumentClassification(
        kind: NarrativeDocumentKind.research,
        reason: 'Parece material de investigación o apoyo documental.',
      );
    }

    if (_hasAny(sample, const [
          'reino',
          'magia',
          'culto',
          'ritual',
          'símbolos',
          'mitología',
          'reglas del mundo',
        ]) &&
        _hasAny(sample, const [
          'diseñar',
          'construir',
          'uso narrativo',
          'worldbuilding',
          'origen cultural',
        ])) {
      return const NarrativeDocumentClassification(
        kind: NarrativeDocumentKind.worldbuilding,
        reason: 'Parece construcción de mundo o material de diseño narrativo.',
      );
    }

    if (_hasSceneSignals(sample) || (isManuscript && content.length > 40)) {
      return const NarrativeDocumentClassification(
        kind: NarrativeDocumentKind.scene,
        reason:
            'Contiene señales de escena narrativa o un capítulo manuscrito sustancial.',
      );
    }

    return const NarrativeDocumentClassification(
      kind: NarrativeDocumentKind.unknown,
      reason: 'No hay suficientes señales para tratarlo como escena narrativa.',
    );
  }

  bool _isManuscriptDocument(Document document) {
    return document.kind == DocumentKind.chapter ||
        document.kind == DocumentKind.scene;
  }

  bool _hasSceneSignals(String sample) {
    final hasFirstPerson = _hasAny(sample, const [
      ' me ',
      ' mi ',
      ' mis ',
      ' conmigo ',
      ' desperté',
      ' miré',
      ' caminé',
      ' pensé',
      ' sentí',
    ]);
    final hasSceneAction = _hasAny(sample, const [
      'dije',
      'respondió',
      'preguntó',
      'me detuve',
      'entré',
      'salí',
      'levanté',
      'encendí',
      'seguía',
      'estaba',
    ]);
    final hasTimeOrPlace = RegExp(r'\b\d{1,2}:\s?\d{2}\b').hasMatch(sample) ||
        _hasAny(sample, const [
          'san francisco',
          'apartamento',
          'callejón',
          'redacción',
          'cafetería',
          'mission',
          'tenderloin',
        ]);
    return (hasFirstPerson && hasSceneAction) ||
        (hasTimeOrPlace && hasSceneAction);
  }

  bool _hasAny(String value, List<String> tokens) {
    for (final token in tokens) {
      if (value.contains(token)) return true;
    }
    return false;
  }
}
