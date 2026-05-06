import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_copilot.dart';
import 'package:musa/modules/continuity/models/continuity_audit.dart';
import 'package:musa/modules/editorial/models/editorial_audit.dart';
import 'package:musa/modules/editorial/services/editorial_audit_service.dart';
import 'package:musa/modules/manuscript/models/document.dart';

void main() {
  group('EditorialAuditService', () {
    test('builds a promise ledger with paid and unresolved promises', () {
      final report = const EditorialAuditService().audit(
        book: _book(),
        documents: [
          _doc(0, 'La carta prometía revelar quién llamó a Diane.'),
          _doc(1, 'Diane descubrió quién llamó y guardó la carta.'),
        ],
        memory: _memory(
          readerPromises: ['quién llamó'],
          unresolvedPromises: ['la carta'],
        ),
        continuityFindings: const [],
        now: DateTime(2026, 5, 6),
      );

      expect(report.promiseLedger.paidPromises, contains('quién llamó'));
      expect(report.promiseLedger.unresolvedPromises, contains('la carta'));
      expect(
        report.findings.map((finding) => finding.type),
        contains(EditorialAuditFindingType.unpaidPromise),
      );
    });

    test('flags forgotten promises absent from the last third of manuscript',
        () {
      final report = const EditorialAuditService().audit(
        book: _book(),
        documents: [
          _doc(0, 'El símbolo apareció en la pared.'),
          _doc(1, 'Diane interrogó al testigo.'),
          _doc(2, 'La ciudad amaneció bajo la lluvia.'),
        ],
        memory: _memory(unresolvedPromises: ['símbolo']),
        continuityFindings: const [],
        now: DateTime(2026, 5, 6),
      );

      expect(
        report.findings.map((finding) => finding.type),
        contains(EditorialAuditFindingType.forgottenPromise),
      );
    });

    test('carries critical continuity contradictions into editorial audit', () {
      final report = const EditorialAuditService().audit(
        book: _book(),
        documents: [_doc(0, 'Diane cruzó el callejón.')],
        memory: _memory(),
        continuityFindings: const [
          ContinuityFinding(
            type: ContinuityFindingType.contradiction,
            severity: ContinuityFindingSeverity.critical,
            title: 'Contradicción prohibida detectada',
            detail: 'El manuscrito contradice una regla fijada.',
            evidence: 'Diane no puede salir de Madrid',
          ),
        ],
        now: DateTime(2026, 5, 6),
      );

      final contradiction = report.findings.singleWhere(
        (finding) => finding.type == EditorialAuditFindingType.contradiction,
      );

      expect(contradiction.severity, EditorialAuditSeverity.critical);
      expect(contradiction.evidence, contains('Madrid'));
    });

    test('returns stable next actions ordered by severity', () {
      final report = const EditorialAuditService().audit(
        book: _book(),
        documents: [_doc(0, 'El símbolo apareció.')],
        memory: _memory(
          unresolvedPromises: ['símbolo', 'llamada', 'carta'],
          scenePatternWarnings: ['Se repite investigar sin consecuencia.'],
        ),
        continuityFindings: const [],
        now: DateTime(2026, 5, 6),
      );

      expect(report.nextActions.length, lessThanOrEqualTo(4));
      expect(report.nextActions.first, contains('promesa'));
    });
  });
}

Book _book() {
  final now = DateTime(2026, 5, 6);
  return Book(
    id: 'book-1',
    title: 'Libro',
    createdAt: now,
    updatedAt: now,
  );
}

Document _doc(int order, String content) {
  final now = DateTime(2026, 5, 6);
  return Document(
    id: 'doc-$order',
    bookId: 'book-1',
    title: 'Capítulo $order',
    content: content,
    orderIndex: order,
    createdAt: now,
    updatedAt: now,
  );
}

NarrativeMemory _memory({
  List<String> readerPromises = const [],
  List<String> unresolvedPromises = const [],
  List<String> scenePatternWarnings = const [],
}) {
  return NarrativeMemory(
    bookId: 'book-1',
    readerPromises: readerPromises,
    unresolvedPromises: unresolvedPromises,
    scenePatternWarnings: scenePatternWarnings,
    updatedAt: DateTime(2026, 5, 6),
  );
}
