import '../../manuscript/models/document.dart';
import 'narrative_document_classifier.dart';

class ContextualMemoryDraft {
  final List<String> worldRules;
  final List<String> systemConstraints;
  final List<String> researchFindings;
  final List<String> persistentConcepts;

  const ContextualMemoryDraft({
    this.worldRules = const [],
    this.systemConstraints = const [],
    this.researchFindings = const [],
    this.persistentConcepts = const [],
  });
}

class ContextualMemoryUpdater {
  const ContextualMemoryUpdater();

  ContextualMemoryDraft update({
    required List<Document> documents,
    required NarrativeDocumentClassifier documentClassifier,
  }) {
    final worldRules = <String>[];
    final systemConstraints = <String>[];
    final researchFindings = <String>[];
    final persistentConcepts = <String>[];

    final ordered = documents.toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    for (final document in ordered.reversed.take(8).toList().reversed) {
      final classification = documentClassifier.classify(document);
      if (!_canEnrichContext(classification.kind)) continue;

      for (final sentence in _sentences(document.content)) {
        final lowered = sentence.toLowerCase();
        if (_hasNegatedEvidence(lowered)) continue;

        if (_hasAffirmedAny(lowered, const [
          'regla',
          'ley',
          'juramento',
          'maldición',
          'pacto',
        ])) {
          _addBounded(worldRules, sentence);
        }
        if (_hasAffirmedAny(lowered, const [
          'coste',
          'límite',
          'limite',
          'prohíbe',
          'prohibe',
          'obliga',
          'restricción',
          'restriccion',
          'depende',
          'solo puede',
        ])) {
          _addBounded(systemConstraints, sentence);
        }
        if (classification.kind == NarrativeDocumentKind.research &&
            _hasAffirmedAny(lowered, const [
              'hallazgo',
              'evidencia',
              'investigación',
              'investigacion',
              'indica que',
              'confirma que',
              'demuestra que',
              'señala que',
              'sugiere que',
            ])) {
          _addBounded(researchFindings, sentence);
        }
        if (_hasAffirmedAny(lowered, const [
          'concepto',
          'símbolo',
          'simbolo',
          'sistema',
          'protocolo',
          'culto',
          'orden',
          'tecnología',
          'tecnologia',
        ])) {
          _addBounded(persistentConcepts, sentence);
        }
      }
    }

    return ContextualMemoryDraft(
      worldRules: worldRules,
      systemConstraints: systemConstraints,
      researchFindings: researchFindings,
      persistentConcepts: persistentConcepts,
    );
  }

  bool _canEnrichContext(NarrativeDocumentKind kind) {
    return kind == NarrativeDocumentKind.scene ||
        kind == NarrativeDocumentKind.research ||
        kind == NarrativeDocumentKind.worldbuilding;
  }

  bool _hasNegatedEvidence(String lowered) {
    return _hasAny(lowered, const [
      'sin coste',
      'sin límite',
      'sin limite',
      'sin obligación',
      'sin obligacion',
      'no existe regla',
      'no hay regla',
      'no hay límite',
      'no hay limite',
      'nadie está obligado',
      'nadie esta obligado',
      'no está obligado',
      'no esta obligado',
      'no hay restricción',
      'no hay restriccion',
    ]);
  }

  bool _hasAffirmedAny(String lowered, List<String> tokens) {
    for (final token in tokens) {
      if (_hasAffirmedToken(lowered, token)) return true;
    }
    return false;
  }

  bool _hasAffirmedToken(String lowered, String token) {
    var start = 0;
    while (true) {
      final index = lowered.indexOf(token, start);
      if (index == -1) return false;
      final prefixStart = (index - 24).clamp(0, index);
      final prefix = lowered.substring(prefixStart, index);
      if (!prefix.contains('sin ') &&
          !prefix.contains('no ') &&
          !prefix.contains('nadie ')) {
        return true;
      }
      start = index + token.length;
    }
  }

  List<String> _sentences(String text) {
    return text
        .replaceAll('\n', ' ')
        .split(RegExp(r'(?<=[.!?¿])\s+'))
        .map((item) => item.trim())
        .where((item) => item.length > 22)
        .toList();
  }

  void _addBounded(List<String> values, String value) {
    final compacted = _compact(value);
    if (compacted.isEmpty || values.contains(compacted)) return;
    values.add(compacted);
    if (values.length > 5) values.removeAt(0);
  }

  String _compact(String value) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 160) return clean;
    return '${clean.substring(0, 157).trimRight()}...';
  }

  bool _hasAny(String value, List<String> tokens) {
    for (final token in tokens) {
      if (value.contains(token)) return true;
    }
    return false;
  }
}
