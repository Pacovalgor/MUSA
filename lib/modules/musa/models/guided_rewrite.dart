enum GuidedRewriteAction {
  raiseTension,
  clarify,
  reduceExposition,
  naturalizeDialogue,
}

extension GuidedRewriteActionAttribution on GuidedRewriteAction {
  String get feedbackSlug {
    return switch (this) {
      GuidedRewriteAction.raiseTension => 'guided-rewrite.raise-tension',
      GuidedRewriteAction.clarify => 'guided-rewrite.clarify',
      GuidedRewriteAction.reduceExposition =>
        'guided-rewrite.reduce-exposition',
      GuidedRewriteAction.naturalizeDialogue =>
        'guided-rewrite.naturalize-dialogue',
    };
  }
}

enum GuidedRewriteSafetyNote {
  preserveFacts,
  preserveVoice,
  noNewCharacters,
  noPlotResolution,
  noExpansion,
}

enum GuidedRewriteSource { deterministic, localModel }

enum GuidedRewriteSafetyLevel { safe, warning }

enum GuidedRewriteSafetyWarning {
  newNames,
  overExpanded,
  droppedTerms,
}

class GuidedRewriteSafetyAudit {
  const GuidedRewriteSafetyAudit({
    required this.level,
    required this.warnings,
    this.evidence = '',
  });

  final GuidedRewriteSafetyLevel level;
  final List<GuidedRewriteSafetyWarning> warnings;
  final String evidence;
}

class GuidedRewriteResult {
  const GuidedRewriteResult({
    required this.action,
    required this.originalText,
    required this.suggestedText,
    required this.safetyNotes,
    required this.editorComment,
    this.source = GuidedRewriteSource.deterministic,
    this.safetyAudit = const GuidedRewriteSafetyAudit(
      level: GuidedRewriteSafetyLevel.safe,
      warnings: [],
    ),
  });

  final GuidedRewriteAction action;
  final String originalText;
  final String suggestedText;
  final List<GuidedRewriteSafetyNote> safetyNotes;
  final String editorComment;
  final GuidedRewriteSource source;
  final GuidedRewriteSafetyAudit safetyAudit;
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
