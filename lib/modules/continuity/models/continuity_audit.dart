enum ContinuityFindingType {
  unresolvedPromise,
  contradiction,
  untrackedCharacter,
  untrackedScenario,
  repeatedPattern,
}

enum ContinuityFindingSeverity { info, warning, critical }

class ContinuityFinding {
  const ContinuityFinding({
    required this.type,
    required this.severity,
    required this.title,
    required this.detail,
    this.evidence = '',
    this.action = '',
  });

  final ContinuityFindingType type;
  final ContinuityFindingSeverity severity;
  final String title;
  final String detail;
  final String evidence;
  final String action;
}
