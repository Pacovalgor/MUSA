import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_copilot.dart';
import 'package:musa/modules/books/models/novel_status.dart';
import 'package:musa/modules/editorial/models/chapter_editorial_map.dart';
import 'package:musa/modules/editorial/models/editorial_audit.dart';
import 'package:musa/modules/editorial/models/editorial_director.dart';
import 'package:musa/modules/editorial/services/editorial_director_service.dart';
import 'package:musa/modules/manuscript/models/document.dart';

void main() {
  group('EditorialDirectorService', () {
    test('asks for narrative material before producing editorial missions', () {
      final report = const EditorialDirectorService().build(
        book: _book(readerPromise: ''),
        documents: const [],
        memory: null,
        novelStatus: null,
        editorialAudit: null,
        chapterMap: null,
        storyState: null,
        now: _now,
      );

      expect(report.readiness, EditorialDirectorReadiness.setup);
      expect(
          report.missions.single.source, EditorialDirectorMissionSource.setup);
      expect(report.missions.single.action, contains('ADN narrativo'));
    });

    test('prioritizes critical contradictions above local chapter rhythm', () {
      final report = const EditorialDirectorService().build(
        book: _book(),
        documents: [_doc()],
        memory: NarrativeMemory.empty('book', _now),
        novelStatus: _status(rhythmScore: 42),
        editorialAudit: _audit(
          findings: const [
            EditorialAuditFinding(
              type: EditorialAuditFindingType.contradiction,
              severity: EditorialAuditSeverity.critical,
              title: 'Contradicción de continuidad',
              detail: 'Clara sabe y no sabe quién abrió la puerta.',
              action: 'Decide una versión canónica antes de reescribir.',
            ),
          ],
        ),
        chapterMap: _chapterMap(ChapterEditorialNeed.rhythm),
        storyState: null,
        now: _now,
      );

      expect(report.readiness, EditorialDirectorReadiness.intervention);
      expect(report.missions.first.source,
          EditorialDirectorMissionSource.editorialAudit);
      expect(
          report.missions.first.priority, EditorialDirectorPriority.critical);
    });

    test('turns forgotten promises and closing chapter needs into one mission',
        () {
      final report = const EditorialDirectorService().build(
        book: _book(),
        documents: [_doc()],
        memory: NarrativeMemory(
          bookId: 'book',
          unresolvedPromises: ['encontrar la llave'],
          updatedAt: _now,
        ),
        novelStatus: _status(promiseScore: 48),
        editorialAudit: _audit(
          promiseLedger: const EditorialPromiseLedger(
            readerPromises: ['encontrar la llave'],
            paidPromises: [],
            unresolvedPromises: ['encontrar la llave'],
            forgottenPromises: ['encontrar la llave'],
          ),
        ),
        chapterMap: _chapterMap(ChapterEditorialNeed.promise),
        storyState: null,
        now: _now,
      );

      expect(report.missions.first.source,
          EditorialDirectorMissionSource.promiseLedger);
      expect(report.missions.first.detail, contains('encontrar la llave'));
      expect(report.missions.first.action, contains('promesa'));
    });

    test('keeps a stable direction when all reports are healthy', () {
      final report = const EditorialDirectorService().build(
        book: _book(),
        documents: [_doc()],
        memory: NarrativeMemory.empty('book', _now),
        novelStatus: _status(overallScore: 88),
        editorialAudit: _audit(),
        chapterMap: _chapterMap(ChapterEditorialNeed.stable),
        storyState: StoryState(
          bookId: 'book',
          nextBestMove: 'Avanza al siguiente capítulo clave.',
          updatedAt: _now,
        ),
        now: _now,
      );

      expect(report.readiness, EditorialDirectorReadiness.advance);
      expect(report.missions.first.priority, EditorialDirectorPriority.normal);
      expect(report.missions.first.action, contains('siguiente capítulo'));
    });
  });
}

final _now = DateTime(2026, 5, 6);

Book _book({String readerPromise = 'Una investigación con coste.'}) {
  return Book(
    id: 'book',
    title: 'Libro',
    createdAt: _now,
    updatedAt: _now,
    narrativeProfile: BookNarrativeProfile(readerPromise: readerPromise),
  );
}

Document _doc() {
  return Document(
    id: 'c1',
    bookId: 'book',
    title: 'Capítulo 1',
    orderIndex: 1,
    content: 'Clara entró en la casa.',
    createdAt: _now,
    updatedAt: _now,
  );
}

NovelStatusReport _status({
  int overallScore = 76,
  int rhythmScore = 76,
  int promiseScore = 76,
}) {
  return NovelStatusReport(
    bookId: 'book',
    overallScore: overallScore,
    healthLevel: NovelStatusHealth.stable,
    tensionScore: 76,
    rhythmScore: rhythmScore,
    promiseScore: promiseScore,
    memoryScore: 76,
    signals: const [],
    professionalComparisons: const [],
    nextActions: const [],
    updatedAt: _now,
  );
}

EditorialAuditReport _audit({
  EditorialPromiseLedger promiseLedger = const EditorialPromiseLedger(
    readerPromises: [],
    paidPromises: [],
    unresolvedPromises: [],
    forgottenPromises: [],
  ),
  List<EditorialAuditFinding> findings = const [],
}) {
  return EditorialAuditReport(
    bookId: 'book',
    promiseLedger: promiseLedger,
    findings: findings,
    nextActions: const [],
    updatedAt: _now,
  );
}

ChapterEditorialMapReport _chapterMap(ChapterEditorialNeed need) {
  return ChapterEditorialMapReport(
    bookId: 'book',
    chapters: [
      ChapterEditorialMapItem(
        documentId: 'c1',
        title: 'Capítulo 1',
        orderIndex: 1,
        stage: ChapterEditorialStage.closing,
        primaryNeed: need,
        tensionScore: 70,
        rhythmScore: need == ChapterEditorialNeed.rhythm ? 42 : 80,
        promiseScore: need == ChapterEditorialNeed.promise ? 42 : 80,
        professionalRhythmLabel: 'alineado con corpus profesional',
        evidence: '1 promesas abiertas',
        nextAction: need == ChapterEditorialNeed.promise
            ? 'Paga, transforma o jerarquiza una promesa abierta.'
            : 'Mantén avance y recalcula.',
      ),
    ],
    summaryActions: const [],
    updatedAt: _now,
  );
}
