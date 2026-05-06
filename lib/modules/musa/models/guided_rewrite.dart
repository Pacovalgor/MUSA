enum GuidedRewriteAction {
  raiseTension,
  clarify,
  reduceExposition,
  naturalizeDialogue,
}

enum GuidedRewriteSafetyNote {
  preserveFacts,
  preserveVoice,
  noNewCharacters,
  noPlotResolution,
  noExpansion,
}

class GuidedRewriteResult {
  const GuidedRewriteResult({
    required this.action,
    required this.originalText,
    required this.suggestedText,
    required this.safetyNotes,
    required this.editorComment,
  });

  final GuidedRewriteAction action;
  final String originalText;
  final String suggestedText;
  final List<GuidedRewriteSafetyNote> safetyNotes;
  final String editorComment;
}

class GuidedRewriteRecommendation {
  const GuidedRewriteRecommendation({
    required this.action,
    required this.title,
    required this.reason,
    this.evidence = '',
    this.priority = 0,
  });

  final GuidedRewriteAction action;
  final String title;
  final String reason;
  final String evidence;
  final int priority;
}
