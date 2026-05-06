import '../../muses/musa.dart';
import '../../modules/books/models/musa_settings.dart';

/// Clean, compact representation of the project for AI consumption.
/// Decouples the IA engine from the full project model.
class NarrativeContext {
  final String bookTitle;
  final String documentTitle;
  final String projectSummary;
  final List<String> knownFacts;
  final List<String> openQuestions;
  final List<String> motifs;
  final String tensionLevel;
  final Map<String, dynamic> metadata;

  NarrativeContext({
    required this.bookTitle,
    required this.documentTitle,
    required this.projectSummary,
    required this.knownFacts,
    this.openQuestions = const [],
    this.motifs = const [],
    required this.tensionLevel,
    this.metadata = const {},
  });
}

/// Request DTO for any Musa intervention.
class MusaRequest {
  final String selection;
  final String documentTitle;
  final String documentContext;
  final NarrativeContext narrativeContext;
  final Musa musa;
  final MusaSettings settings;
  final DateTime timestamp;

  MusaRequest({
    required this.selection,
    required this.documentTitle,
    required this.documentContext,
    required this.narrativeContext,
    required this.musa,
    required this.settings,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Sealed class to separate streaming chunks from final editorial suggestions.
sealed class MusaResponse {}

class MusaChunk extends MusaResponse {
  final String delta;
  MusaChunk(this.delta);
}

class MusaSuggestion extends MusaResponse {
  final String id;
  final String originalText;
  final String suggestedText;
  final String? editorComment;
  final String? sourceMusaId;
  final DateTime timestamp;

  MusaSuggestion({
    required this.id,
    required this.originalText,
    required this.suggestedText,
    this.editorComment,
    this.sourceMusaId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
