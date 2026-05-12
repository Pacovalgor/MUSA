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
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.detail,
    this.evidence = '',
    this.action = '',
  });

  /// Identificador estable derivado de tipo + evidencia.
  /// Permite descartar hallazgos entre sesiones sin persistir la lista completa.
  final String id;
  final ContinuityFindingType type;
  final ContinuityFindingSeverity severity;
  final String title;
  final String detail;
  final String evidence;
  final String action;
}
