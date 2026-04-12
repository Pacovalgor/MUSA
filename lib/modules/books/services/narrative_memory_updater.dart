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
        const ['pista', 'indicio', 'rastro', 'señal', 'huella', 'clave'],
      ),
      activeThreats: _collectByKeywords(
        recentText,
        const [
          'amenaza',
          'peligro',
          'miedo',
          'riesgo',
          'persecución',
          'muerte'
        ],
      ),
      importantFacts: _collectByKeywords(
        recentText,
        const ['descubre', 'revela', 'sabe que', 'comprende', 'recuerda'],
      ),
      recentCharacterShifts: _collectByKeywords(
        recentText,
        const ['decide', 'duda', 'cambia', 'renuncia', 'confiesa', 'teme'],
      ),
      worldRules: contextualMemory.worldRules,
      systemConstraints: contextualMemory.systemConstraints,
      researchFindings: contextualMemory.researchFindings,
      persistentConcepts: contextualMemory.persistentConcepts,
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

  List<String> _collectByKeywords(String text, List<String> keywords) {
    final loweredKeywords = keywords.map((item) => item.toLowerCase()).toList();
    final results = <String>[];
    for (final sentence in _sentences(text)) {
      final lowered = sentence.toLowerCase();
      if (!loweredKeywords.any(lowered.contains)) continue;
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
