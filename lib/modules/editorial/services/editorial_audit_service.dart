import '../../books/models/book.dart';
import '../../books/models/narrative_copilot.dart';
import '../../continuity/models/continuity_audit.dart';
import '../../manuscript/models/document.dart';
import '../models/editorial_audit.dart';

class EditorialAuditService {
  const EditorialAuditService();

  EditorialAuditReport audit({
    required Book book,
    required List<Document> documents,
    required NarrativeMemory? memory,
    required List<ContinuityFinding> continuityFindings,
    required DateTime now,
  }) {
    final orderedDocuments = documents
        .where((document) => document.bookId == book.id)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final manuscriptText = orderedDocuments
        .map((document) => document.content)
        .join('\n\n')
        .toLowerCase();
    final lastThirdText = _lastThirdText(orderedDocuments).toLowerCase();
    final readerPromises = _compact(memory?.readerPromises ?? const []);
    final unresolvedRaw = _compact(memory?.unresolvedPromises ?? const []);
    final paid = readerPromises
        .where((promise) => _looksPaid(promise, manuscriptText))
        .toList();
    final unresolved =
        unresolvedRaw.where((promise) => !paid.contains(promise)).toList();
    final forgotten = unresolved
        .where((promise) => !_mentionsPromise(promise, lastThirdText))
        .toList();

    final findings = <EditorialAuditFinding>[
      ..._contradictionFindings(continuityFindings),
      ..._unpaidPromiseFindings(unresolved),
      ..._forgottenPromiseFindings(forgotten),
      ..._repeatedPatternFindings(memory),
      ..._paidPromiseFindings(paid),
    ];
    findings.sort((a, b) => _severityRank(b.severity).compareTo(
          _severityRank(a.severity),
        ));

    return EditorialAuditReport(
      bookId: book.id,
      promiseLedger: EditorialPromiseLedger(
        readerPromises: readerPromises,
        paidPromises: paid,
        unresolvedPromises: unresolved,
        forgottenPromises: forgotten,
      ),
      findings: findings.take(10).toList(),
      nextActions: _nextActions(findings).take(4).toList(),
      updatedAt: now,
    );
  }

  List<EditorialAuditFinding> _contradictionFindings(
    List<ContinuityFinding> continuityFindings,
  ) {
    return [
      for (final finding in continuityFindings)
        if (finding.type == ContinuityFindingType.contradiction)
          EditorialAuditFinding(
            type: EditorialAuditFindingType.contradiction,
            severity: finding.severity == ContinuityFindingSeverity.critical
                ? EditorialAuditSeverity.critical
                : EditorialAuditSeverity.warning,
            title: finding.title,
            detail: finding.detail,
            evidence: finding.evidence,
            action: finding.action,
          ),
    ];
  }

  List<EditorialAuditFinding> _unpaidPromiseFindings(
    List<String> unresolved,
  ) {
    if (unresolved.isEmpty) return const [];
    return [
      EditorialAuditFinding(
        type: EditorialAuditFindingType.unpaidPromise,
        severity: unresolved.length >= 3
            ? EditorialAuditSeverity.critical
            : EditorialAuditSeverity.warning,
        title: 'Promesas sin pago narrativo',
        detail:
            'Hay preguntas o promesas activas que todavía no reciben respuesta suficiente.',
        evidence: unresolved.take(4).join(' · '),
        action:
            'Cierra, transforma o jerarquiza una promesa antes de abrir otra.',
      ),
    ];
  }

  List<EditorialAuditFinding> _forgottenPromiseFindings(
    List<String> forgotten,
  ) {
    if (forgotten.isEmpty) return const [];
    return [
      EditorialAuditFinding(
        type: EditorialAuditFindingType.forgottenPromise,
        severity: EditorialAuditSeverity.warning,
        title: 'Promesa ausente del tramo reciente',
        detail:
            'Una promesa abierta ya no aparece en el último tramo del manuscrito.',
        evidence: forgotten.take(4).join(' · '),
        action:
            'Recupera esta promesa en una consecuencia, pista, decisión o cierre.',
      ),
    ];
  }

  List<EditorialAuditFinding> _repeatedPatternFindings(
    NarrativeMemory? memory,
  ) {
    final warnings = memory?.scenePatternWarnings ?? const [];
    if (warnings.isEmpty) return const [];
    return [
      EditorialAuditFinding(
        type: EditorialAuditFindingType.repeatedPattern,
        severity: EditorialAuditSeverity.warning,
        title: 'Patrón narrativo repetido',
        detail: warnings.first,
        evidence: warnings.take(2).join(' · '),
        action: 'Convierte la repetición en una consecuencia visible.',
      ),
    ];
  }

  List<EditorialAuditFinding> _paidPromiseFindings(List<String> paid) {
    if (paid.isEmpty) return const [];
    return [
      EditorialAuditFinding(
        type: EditorialAuditFindingType.paidPromise,
        severity: EditorialAuditSeverity.info,
        title: 'Promesa pagada',
        detail: 'El manuscrito contiene señales de respuesta o cierre.',
        evidence: paid.take(4).join(' · '),
        action: 'Comprueba que el pago sea proporcional a la promesa abierta.',
      ),
    ];
  }

  List<String> _nextActions(List<EditorialAuditFinding> findings) {
    final actions = <String>[];
    for (final finding in findings) {
      final action = finding.action.trim();
      if (action.isEmpty) continue;
      if (actions.contains(action)) continue;
      actions.add(action);
    }
    return actions;
  }

  bool _looksPaid(String promise, String manuscriptText) {
    final normalized = promise.toLowerCase();
    if (!_mentionsPromise(promise, manuscriptText)) return false;
    final paymentMarkers = <String>[
      'descubrió $normalized',
      'reveló $normalized',
      'resolvió $normalized',
      'entendió $normalized',
      '$normalized quedó claro',
      '$normalized se aclaró',
    ];
    return paymentMarkers.any(manuscriptText.contains);
  }

  bool _mentionsPromise(String promise, String text) {
    final normalized = promise.toLowerCase().trim();
    if (normalized.isEmpty) return false;
    return text.contains(normalized);
  }

  String _lastThirdText(List<Document> documents) {
    if (documents.isEmpty) return '';
    final start = (documents.length * 2 / 3).floor();
    return documents.skip(start).map((document) => document.content).join('\n');
  }

  int _severityRank(EditorialAuditSeverity severity) {
    return switch (severity) {
      EditorialAuditSeverity.critical => 3,
      EditorialAuditSeverity.warning => 2,
      EditorialAuditSeverity.info => 1,
    };
  }

  List<String> _compact(List<String> values) {
    final results = <String>[];
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty) continue;
      if (results.contains(normalized)) continue;
      results.add(normalized);
    }
    return results;
  }
}
