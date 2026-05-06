import '../../../editor/services/text_analysis_lexicons.dart';
import '../../../editor/services/text_normalizer.dart';
import '../../manuscript/models/document.dart';
import '../models/narrative_copilot.dart';
import 'contextual_memory_updater.dart';
import 'narrative_document_classifier.dart';

class NarrativeMemoryUpdater {
  const NarrativeMemoryUpdater({
    this.documentClassifier = const NarrativeDocumentClassifier(),
    this.contextualMemoryUpdater = const ContextualMemoryUpdater(),
  });

  final NarrativeDocumentClassifier documentClassifier;
  final ContextualMemoryUpdater contextualMemoryUpdater;

  NarrativeMemory update({
    required String bookId,
    required List<Document> documents,
    required NarrativeMemory? previous,
    required DateTime now,
  }) {
    final narrativeDocuments = documents
        .where((document) =>
            documentClassifier.classify(document).kind ==
            NarrativeDocumentKind.scene)
        .toList();
    final recentText = _recentManuscriptText(narrativeDocuments);
    final contextualMemory = contextualMemoryUpdater.update(
      documents: documents,
      documentClassifier: documentClassifier,
    );
    return NarrativeMemory(
      bookId: bookId,
      openQuestions: _collectQuestions(recentText),
      plantedClues: _collectByKeywords(
        recentText,
        TextAnalysisLexicons.memoryClueKeywords,
      ),
      activeThreats: _collectByKeywords(
        recentText,
        TextAnalysisLexicons.memoryThreatKeywords,
      ),
      importantFacts: _collectByKeywords(
        recentText,
        TextAnalysisLexicons.memoryFactKeywords,
      ),
      recentCharacterShifts: _collectByKeywords(
        recentText,
        TextAnalysisLexicons.memoryCharacterShiftKeywords,
      ),
      worldRules: contextualMemory.worldRules,
      systemConstraints: contextualMemory.systemConstraints,
      researchFindings: contextualMemory.researchFindings,
      persistentConcepts: contextualMemory.persistentConcepts,
      readerPromises: _collectReaderPromises(recentText),
      unresolvedPromises: _collectUnresolvedPromises(recentText),
      toneSignals: _collectToneSignals(recentText),
      scenePatternWarnings: _collectScenePatternWarnings(recentText),
      updatedAt: now,
    );
  }

  String _recentManuscriptText(List<Document> documents) {
    final ordered = documents.toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return ordered
        .where((document) => document.content.trim().isNotEmpty)
        .toList()
        .reversed
        .take(4)
        .map((document) => document.content)
        .join('\n\n');
  }

  List<String> _collectQuestions(String text) {
    final results = <String>[];
    for (final sentence in _sentences(text)) {
      if (sentence.contains('?') || sentence.contains('¿')) {
        results.add(_compact(sentence));
      }
      if (results.length == 5) break;
    }
    return results;
  }

  List<String> _collectReaderPromises(String text) {
    final results = <String>[];
    for (final sentence in _sentences(text)) {
      final lowered = sentence.toLowerCase();
      final hasExplicitPromise =
          lowered.contains('promesa') || lowered.contains('promete');
      final hasPromiseShape = (lowered.contains('descubrir') ||
              lowered.contains('resolver') ||
              lowered.contains('revelar') ||
              lowered.contains('encontrar')) &&
          (lowered.contains('quién') ||
              lowered.contains('quien') ||
              lowered.contains('antes') ||
              lowered.contains('verdad'));
      if (!hasExplicitPromise && !hasPromiseShape) continue;
      final compacted = _compact(sentence);
      if (!results.contains(compacted)) results.add(compacted);
      if (results.length == 5) break;
    }
    return results;
  }

  List<String> _collectUnresolvedPromises(String text) {
    final results = <String>[];
    for (final sentence in _sentences(text)) {
      final lowered = sentence.toLowerCase();
      final isQuestion = sentence.contains('?') || sentence.contains('¿');
      final isOpenPromise = lowered.contains('seguía abierta') ||
          lowered.contains('sigue abierta') ||
          lowered.contains('sin resolver') ||
          lowered.contains('pendiente');
      if (!isQuestion && !isOpenPromise) continue;
      final compacted = _compact(sentence);
      if (!results.contains(compacted)) results.add(compacted);
      if (results.length == 5) break;
    }
    return results;
  }

  List<String> _collectToneSignals(String text) {
    const toneTokens = <String>[
      'sombrío',
      'sombria',
      'oscuro',
      'miedo',
      'amenaza',
      'sombra',
      'melancólico',
      'íntimo',
      'épico',
      'urgente',
      'irónico',
    ];
    final lowered = text.toLowerCase();
    final results = <String>[];
    for (final token in toneTokens) {
      if (!lowered.contains(token)) continue;
      final normalized = token == 'sombria' ? 'sombrío' : token;
      if (!results.contains(normalized)) results.add(normalized);
      if (results.length == 5) break;
    }
    return results;
  }

  List<String> _collectScenePatternWarnings(String text) {
    final lowered = text.toLowerCase();
    final investigationMatches =
        RegExp(r'\b(investig|pista|busca|búsqueda|buscar)\w*')
            .allMatches(lowered)
            .length;
    final hasConsequence = TextNormalizer.stemmedAnyContainsWithSynonyms(
      lowered,
      TextAnalysisLexicons.progressDefaultTokens,
      TextAnalysisLexicons.synonymMap,
    );
    if (investigationMatches >= 3 &&
        (!hasConsequence || lowered.contains('sin consecuencia'))) {
      return const ['investigación sin consecuencia'];
    }
    return const [];
  }

  List<String> _collectByKeywords(String text, List<String> keywords) {
    final results = <String>[];
    for (final sentence in _sentences(text)) {
      if (!TextNormalizer.stemmedAnyContainsWithSynonyms(
        sentence,
        keywords,
        TextAnalysisLexicons.synonymMap,
      )) {
        continue;
      }
      final compacted = _compact(sentence);
      if (!results.contains(compacted)) results.add(compacted);
      if (results.length == 5) break;
    }
    return results;
  }

  List<String> _sentences(String text) {
    return text
        .replaceAll('\n', ' ')
        .split(RegExp(r'(?<=[.!?¿])\s+'))
        .map((item) => item.trim())
        .where((item) => item.length > 18)
        .toList();
  }

  String _compact(String value) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 160) return clean;
    return '${clean.substring(0, 157).trimRight()}...';
  }
}
