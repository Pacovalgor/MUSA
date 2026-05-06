import '../models/guided_rewrite.dart';

class GuidedRewriteSafetyService {
  const GuidedRewriteSafetyService();

  GuidedRewriteSafetyAudit audit({
    required String originalText,
    required String suggestedText,
  }) {
    final warnings = <GuidedRewriteSafetyWarning>[];
    final evidence = <String>[];

    final newNames = _newCapitalizedNames(originalText, suggestedText);
    if (newNames.isNotEmpty) {
      warnings.add(GuidedRewriteSafetyWarning.newNames);
      evidence.add('Nombres nuevos: ${newNames.join(', ')}');
    }

    if (_isOverExpanded(originalText, suggestedText)) {
      warnings.add(GuidedRewriteSafetyWarning.overExpanded);
      evidence.add('Expansión excesiva');
    }

    final droppedTerms = _droppedKeyTerms(originalText, suggestedText);
    if (droppedTerms.isNotEmpty) {
      warnings.add(GuidedRewriteSafetyWarning.droppedTerms);
      evidence.add('Términos perdidos: ${droppedTerms.join(', ')}');
    }

    return GuidedRewriteSafetyAudit(
      level: warnings.isEmpty
          ? GuidedRewriteSafetyLevel.safe
          : GuidedRewriteSafetyLevel.warning,
      warnings: warnings,
      evidence: evidence.join(' · '),
    );
  }

  List<String> _newCapitalizedNames(String originalText, String suggestedText) {
    final original = _capitalizedTerms(originalText)
        .map((term) => term.toLowerCase())
        .toSet();
    final results = <String>[];
    for (final term in _capitalizedTerms(suggestedText)) {
      if (_ignoredCapitalizedTerms.contains(term)) continue;
      if (original.contains(term.toLowerCase())) continue;
      if (results.contains(term)) continue;
      results.add(term);
    }
    return results;
  }

  bool _isOverExpanded(String originalText, String suggestedText) {
    final originalWords = _words(originalText).length;
    final suggestedWords = _words(suggestedText).length;
    if (originalWords == 0) return suggestedWords > 0;
    return suggestedWords > originalWords * 2.2 && suggestedWords > 18;
  }

  List<String> _droppedKeyTerms(String originalText, String suggestedText) {
    final suggested = suggestedText.toLowerCase();
    final results = <String>[];
    for (final term in _keyTerms(originalText)) {
      if (suggested.contains(term.toLowerCase())) continue;
      if (results.contains(term)) continue;
      results.add(term);
      if (results.length == 4) break;
    }
    return results;
  }

  List<String> _capitalizedTerms(String text) {
    return RegExp(r'\b[A-ZÁÉÍÓÚÑ][a-záéíóúñ]{2,}\b')
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  List<String> _keyTerms(String text) {
    final terms = <String>[];
    for (final word in _words(text)) {
      final lower = word.toLowerCase();
      if (lower.length < 5) continue;
      if (_stopWords.contains(lower)) continue;
      if (terms.contains(lower)) continue;
      terms.add(lower);
    }
    return terms;
  }

  List<String> _words(String text) {
    return RegExp(r"[A-Za-zÁÉÍÓÚáéíóúÑñ]+")
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  static const _ignoredCapitalizedTerms = <String>{
    'Capítulo',
    'Recomendado',
  };

  static const _stopWords = <String>{
    'había',
    'sobre',
    'desde',
    'donde',
    'cuando',
    'porque',
    'entre',
    'nadie',
    'estaba',
    'seguía',
    'abrió',
    'guardó',
  };
}
