enum EditorialDirectorReadiness { setup, intervention, revision, advance }

enum EditorialDirectorPriority { critical, high, normal }

enum EditorialDirectorMissionSource {
  setup,
  editorialAudit,
  promiseLedger,
  novelStatus,
  chapterMap,
  storyState,
}

class EditorialDirectorReport {
  const EditorialDirectorReport({
    required this.bookId,
    required this.readiness,
    required this.summary,
    required this.missions,
    required this.updatedAt,
  });

  final String bookId;
  final EditorialDirectorReadiness readiness;
  final String summary;
  final List<EditorialDirectorMission> missions;
  final DateTime updatedAt;
}

class EditorialDirectorMission {
  const EditorialDirectorMission({
    required this.priority,
    required this.source,
    required this.title,
    required this.detail,
    required this.action,
    this.evidence = '',
  });

  final EditorialDirectorPriority priority;
  final EditorialDirectorMissionSource source;
  final String title;
  final String detail;
  final String action;
  final String evidence;
}
