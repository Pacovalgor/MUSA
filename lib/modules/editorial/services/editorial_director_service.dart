import '../../books/models/book.dart';
import '../../books/models/narrative_copilot.dart';
import '../../books/models/novel_status.dart';
import '../../manuscript/models/document.dart';
import '../models/chapter_editorial_map.dart';
import '../models/editorial_audit.dart';
import '../models/editorial_director.dart';

class EditorialDirectorService {
  const EditorialDirectorService();

  EditorialDirectorReport build({
    required Book book,
    required List<Document> documents,
    required NarrativeMemory? memory,
    required NovelStatusReport? novelStatus,
    required EditorialAuditReport? editorialAudit,
    required ChapterEditorialMapReport? chapterMap,
    required StoryState? storyState,
    required DateTime now,
  }) {
    final missions = <EditorialDirectorMission>[];
    final hasNarrativeMaterial =
        documents.any((document) => document.content.trim().isNotEmpty);
    final hasReaderPromise =
        book.narrativeProfile.readerPromise?.trim().isNotEmpty == true;

    if (!hasReaderPromise || !hasNarrativeMaterial || memory == null) {
      missions.add(EditorialDirectorMission(
        priority: EditorialDirectorPriority.high,
        source: EditorialDirectorMissionSource.setup,
        title: 'Preparar base narrativa',
        detail: 'MUSA necesita ADN narrativo, material y memoria para dirigir.',
        action: !hasReaderPromise
            ? 'Define el ADN narrativo y la promesa de lectura del libro.'
            : 'Añade o analiza capítulos narrativos para construir memoria.',
      ));
      return EditorialDirectorReport(
        bookId: book.id,
        readiness: EditorialDirectorReadiness.setup,
        summary: 'Primero hay que completar la base de dirección editorial.',
        missions: missions,
        updatedAt: now,
      );
    }

    missions.addAll(_criticalAuditMissions(editorialAudit));
    final promiseMission = _promiseMission(editorialAudit, chapterMap, memory);
    if (promiseMission != null) missions.add(promiseMission);
    final statusMission = _novelStatusMission(novelStatus);
    if (statusMission != null) missions.add(statusMission);
    final chapterMission = _chapterMission(chapterMap);
    if (chapterMission != null) missions.add(chapterMission);

    if (missions.isEmpty) {
      missions.add(EditorialDirectorMission(
        priority: EditorialDirectorPriority.normal,
        source: EditorialDirectorMissionSource.storyState,
        title: 'Avanzar con control',
        detail:
            'No hay bloqueos editoriales críticos en los reportes actuales.',
        action: storyState?.nextBestMove.trim().isNotEmpty == true
            ? storyState!.nextBestMove
            : 'Avanza al siguiente capítulo clave y vuelve a recalcular.',
      ));
    }

    final ordered = _ordered(missions).take(5).toList();
    return EditorialDirectorReport(
      bookId: book.id,
      readiness: _readiness(ordered, novelStatus),
      summary: _summary(ordered),
      missions: ordered,
      updatedAt: now,
    );
  }

  List<EditorialDirectorMission> _criticalAuditMissions(
    EditorialAuditReport? audit,
  ) {
    if (audit == null) return const [];
    return audit.findings
        .where((finding) =>
            finding.severity == EditorialAuditSeverity.critical &&
            finding.type == EditorialAuditFindingType.contradiction)
        .map(
          (finding) => EditorialDirectorMission(
            priority: EditorialDirectorPriority.critical,
            source: EditorialDirectorMissionSource.editorialAudit,
            title: finding.title,
            detail: finding.detail,
            action: finding.action.trim().isEmpty
                ? 'Decide la versión canónica antes de seguir reescribiendo.'
                : finding.action,
            evidence: finding.evidence,
          ),
        )
        .toList();
  }

  EditorialDirectorMission? _promiseMission(
    EditorialAuditReport? audit,
    ChapterEditorialMapReport? chapterMap,
    NarrativeMemory memory,
  ) {
    final forgotten = audit?.promiseLedger.forgottenPromises ?? const [];
    final unresolved =
        audit?.promiseLedger.unresolvedPromises.isNotEmpty == true
            ? audit!.promiseLedger.unresolvedPromises
            : memory.unresolvedPromises;
    final closingNeedsPromise = chapterMap?.chapters.any((chapter) =>
            chapter.stage == ChapterEditorialStage.closing &&
            chapter.primaryNeed == ChapterEditorialNeed.promise) ==
        true;
    if (forgotten.isEmpty && !closingNeedsPromise && unresolved.length < 3) {
      return null;
    }
    final promise = forgotten.isNotEmpty
        ? forgotten.first
        : (unresolved.isNotEmpty ? unresolved.first : 'promesa principal');
    return EditorialDirectorMission(
      priority: EditorialDirectorPriority.high,
      source: EditorialDirectorMissionSource.promiseLedger,
      title: 'Resolver promesa abierta',
      detail: 'La promesa "$promise" sigue sin pago narrativo claro.',
      action: 'Paga, transforma o jerarquiza esa promesa antes de abrir otra.',
      evidence: '${unresolved.length} promesas abiertas',
    );
  }

  EditorialDirectorMission? _novelStatusMission(NovelStatusReport? status) {
    if (status == null) return null;
    final weakScores = <String, int>{
      'tensión': status.tensionScore,
      'ritmo': status.rhythmScore,
      'promesa': status.promiseScore,
      'memoria': status.memoryScore,
    }.entries.where((entry) => entry.value < 60).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (weakScores.isEmpty) return null;
    final weakest = weakScores.first;
    return EditorialDirectorMission(
      priority: EditorialDirectorPriority.high,
      source: EditorialDirectorMissionSource.novelStatus,
      title: 'Reforzar ${weakest.key}',
      detail: 'El estado global marca ${weakest.value}/100 en ${weakest.key}.',
      action: status.nextActions.isNotEmpty
          ? status.nextActions.first
          : 'Corrige primero el área más débil del estado de novela.',
    );
  }

  EditorialDirectorMission? _chapterMission(
    ChapterEditorialMapReport? chapterMap,
  ) {
    if (chapterMap == null) return null;
    final chapter =
        chapterMap.chapters.cast<ChapterEditorialMapItem?>().firstWhere(
              (item) => item?.primaryNeed != ChapterEditorialNeed.stable,
              orElse: () => null,
            );
    if (chapter == null) return null;
    return EditorialDirectorMission(
      priority: EditorialDirectorPriority.normal,
      source: EditorialDirectorMissionSource.chapterMap,
      title: 'Ajustar ${chapter.title}',
      detail: 'El capítulo pide ${_needLabel(chapter.primaryNeed)}.',
      action: chapter.nextAction,
      evidence: chapter.evidence,
    );
  }

  List<EditorialDirectorMission> _ordered(
    List<EditorialDirectorMission> missions,
  ) {
    final result = [...missions];
    result
        .sort((a, b) => _priorityRank(b.priority) - _priorityRank(a.priority));
    return _dedupe(result);
  }

  List<EditorialDirectorMission> _dedupe(
    List<EditorialDirectorMission> missions,
  ) {
    final keys = <String>{};
    final result = <EditorialDirectorMission>[];
    for (final mission in missions) {
      final key = '${mission.source.name}:${mission.title}:${mission.action}';
      if (keys.add(key)) result.add(mission);
    }
    return result;
  }

  int _priorityRank(EditorialDirectorPriority priority) {
    return switch (priority) {
      EditorialDirectorPriority.critical => 3,
      EditorialDirectorPriority.high => 2,
      EditorialDirectorPriority.normal => 1,
    };
  }

  EditorialDirectorReadiness _readiness(
    List<EditorialDirectorMission> missions,
    NovelStatusReport? status,
  ) {
    if (missions.any(
        (mission) => mission.priority == EditorialDirectorPriority.critical)) {
      return EditorialDirectorReadiness.intervention;
    }
    if (missions
        .any((mission) => mission.priority == EditorialDirectorPriority.high)) {
      return EditorialDirectorReadiness.revision;
    }
    if ((status?.overallScore ?? 75) >= 80) {
      return EditorialDirectorReadiness.advance;
    }
    return EditorialDirectorReadiness.revision;
  }

  String _summary(List<EditorialDirectorMission> missions) {
    final first = missions.first;
    return switch (first.priority) {
      EditorialDirectorPriority.critical =>
        'Hay un bloqueo crítico antes de avanzar.',
      EditorialDirectorPriority.high =>
        'La novela pide una intervención editorial concreta.',
      EditorialDirectorPriority.normal =>
        'La novela puede avanzar con seguimiento normal.',
    };
  }

  String _needLabel(ChapterEditorialNeed need) {
    return switch (need) {
      ChapterEditorialNeed.tension => 'tensión',
      ChapterEditorialNeed.rhythm => 'ritmo',
      ChapterEditorialNeed.promise => 'promesa',
      ChapterEditorialNeed.consequence => 'consecuencia',
      ChapterEditorialNeed.stable => 'estabilidad',
    };
  }
}
