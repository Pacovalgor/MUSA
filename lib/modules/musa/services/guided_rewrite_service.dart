import '../models/guided_rewrite.dart';

class GuidedRewriteService {
  const GuidedRewriteService();

  GuidedRewriteResult rewrite({
    required String selection,
    required GuidedRewriteAction action,
  }) {
    final trimmed = selection.trim();
    if (trimmed.isEmpty) {
      return GuidedRewriteResult(
        action: action,
        originalText: selection,
        suggestedText: '',
        safetyNotes: const [
          GuidedRewriteSafetyNote.preserveFacts,
          GuidedRewriteSafetyNote.noExpansion,
        ],
        editorComment:
            'No hay texto suficiente para proponer una reescritura controlada.',
      );
    }

    final suggestedText = switch (action) {
      GuidedRewriteAction.raiseTension => _raiseTension(trimmed),
      GuidedRewriteAction.clarify => _clarify(trimmed),
      GuidedRewriteAction.reduceExposition => _reduceExposition(trimmed),
      GuidedRewriteAction.naturalizeDialogue => _naturalizeDialogue(trimmed),
    };

    return GuidedRewriteResult(
      action: action,
      originalText: selection,
      suggestedText: suggestedText,
      safetyNotes: const [
        GuidedRewriteSafetyNote.preserveFacts,
        GuidedRewriteSafetyNote.preserveVoice,
        GuidedRewriteSafetyNote.noNewCharacters,
        GuidedRewriteSafetyNote.noPlotResolution,
      ],
      editorComment: _editorComment(action),
    );
  }

  String _raiseTension(String text) {
    final sentences = _splitSentences(text);
    if (sentences.isEmpty) return text;

    var touched = false;
    final rewritten = <String>[];
    for (final sentence in sentences) {
      if (!touched &&
          _containsAny(sentence.toLowerCase(), const [
            'carta',
            'puerta',
            'llave',
            'sombra',
            'silencio',
            'pasillo',
          ])) {
        rewritten.add(_appendBeforeEnd(sentence, ', demasiado quieta'));
        touched = true;
      } else {
        rewritten.add(sentence);
      }
    }

    if (touched) return rewritten.join(' ');
    return _appendBeforeEnd(text, ', con una tensión seca en el aire');
  }

  String _clarify(String text) {
    var clarified = text
        .replaceFirst(RegExp(r'\s+porque\s+'), '. ')
        .replaceFirst(RegExp(r'\s+mientras\s+'), '. ')
        .replaceFirst(RegExp(r'\s+y\s+la\s+'), '. La ')
        .replaceFirst(RegExp(r'\s+y\s+el\s+'), '. El ');

    clarified = clarified
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .join(' ');

    return _normalizeSentenceStarts(clarified);
  }

  String _reduceExposition(String text) {
    final sentences = _splitSentences(text);
    final concrete = sentences.where((sentence) {
      final lower = sentence.toLowerCase();
      return !_containsAny(lower, const [
        'sabía que',
        'desde hacía',
        'había aprendido',
        'era importante porque',
        'recordaba que',
      ]);
    }).toList();

    if (concrete.isEmpty) return text;
    return concrete.join(' ');
  }

  String _naturalizeDialogue(String text) {
    final firstQuestionIndex = text.indexOf('?');
    if (firstQuestionIndex >= 0) {
      return text.replaceRange(
        firstQuestionIndex + 1,
        firstQuestionIndex + 1,
        ' El silencio pesó entre una respuesta y la siguiente.',
      );
    }

    final firstPeriodIndex = text.indexOf('.');
    if (firstPeriodIndex >= 0) {
      return text.replaceRange(
        firstPeriodIndex + 1,
        firstPeriodIndex + 1,
        ' El silencio dejó el gesto suspendido.',
      );
    }

    return '$text El silencio hizo más visible el gesto.';
  }

  String _editorComment(GuidedRewriteAction action) {
    return switch (action) {
      GuidedRewriteAction.raiseTension =>
        'Sube la tensión del fragmento sin resolver la escena ni añadir datos nuevos.',
      GuidedRewriteAction.clarify =>
        'Aclara la lectura separando impulsos narrativos que estaban comprimidos.',
      GuidedRewriteAction.reduceExposition =>
        'Reduce explicación abstracta y deja en primer plano la acción concreta.',
      GuidedRewriteAction.naturalizeDialogue =>
        'Añade respiración física al diálogo manteniendo las frases dichas.',
    };
  }

  List<String> _splitSentences(String text) {
    return RegExp(r'[^.!?]+[.!?]?')
        .allMatches(text)
        .map((match) => match.group(0)?.trim() ?? '')
        .where((sentence) => sentence.isNotEmpty)
        .toList();
  }

  String _appendBeforeEnd(String sentence, String addition) {
    final trimmed = sentence.trimRight();
    if (trimmed.isEmpty) return sentence;

    final last = trimmed[trimmed.length - 1];
    if (last == '.' || last == '!' || last == '?') {
      return '${trimmed.substring(0, trimmed.length - 1)}$addition$last';
    }

    return '$trimmed$addition.';
  }

  String _normalizeSentenceStarts(String text) {
    return text
        .split('. ')
        .map((sentence) {
          final trimmed = sentence.trim();
          if (trimmed.isEmpty) return trimmed;
          return trimmed[0].toUpperCase() + trimmed.substring(1);
        })
        .where((sentence) => sentence.isNotEmpty)
        .join('. ');
  }

  bool _containsAny(String text, List<String> needles) {
    return needles.any(text.contains);
  }
}
