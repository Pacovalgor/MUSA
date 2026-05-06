enum EditorialAuditSeverity { info, warning, critical }

enum EditorialAuditFindingType {
  unpaidPromise,
  paidPromise,
  forgottenPromise,
  contradiction,
  repeatedPattern,
}

class EditorialPromiseLedger {
  const EditorialPromiseLedger({
    required this.readerPromises,
    required this.paidPromises,
    required this.unresolvedPromises,
    required this.forgottenPromises,
  });

  final List<String> readerPromises;
  final List<String> paidPromises;
  final List<String> unresolvedPromises;
  final List<String> forgottenPromises;
}

class EditorialAuditFinding {
  const EditorialAuditFinding({
    required this.type,
    required this.severity,
    required this.title,
    required this.detail,
    this.evidence = '',
    this.action = '',
  });

  final EditorialAuditFindingType type;
  final EditorialAuditSeverity severity;
  final String title;
  final String detail;
  final String evidence;
  final String action;
}

class EditorialAuditReport {
  const EditorialAuditReport({
    required this.bookId,
    required this.promiseLedger,
    required this.findings,
    required this.nextActions,
    required this.updatedAt,
  });

  final String bookId;
  final EditorialPromiseLedger promiseLedger;
  final List<EditorialAuditFinding> findings;
  final List<String> nextActions;
  final DateTime updatedAt;
}
