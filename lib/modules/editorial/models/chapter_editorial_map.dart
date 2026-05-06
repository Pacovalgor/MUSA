enum ChapterEditorialStage { opening, middle, closing }

enum ChapterEditorialNeed { tension, rhythm, promise, consequence, stable }

class ChapterEditorialMapReport {
  const ChapterEditorialMapReport({
    required this.bookId,
    required this.chapters,
    required this.summaryActions,
    required this.updatedAt,
  });

  final String bookId;
  final List<ChapterEditorialMapItem> chapters;
  final List<String> summaryActions;
  final DateTime updatedAt;
}

class ChapterEditorialMapItem {
  const ChapterEditorialMapItem({
    required this.documentId,
    required this.title,
    required this.orderIndex,
    required this.stage,
    required this.primaryNeed,
    required this.tensionScore,
    required this.rhythmScore,
    required this.promiseScore,
    required this.professionalRhythmLabel,
    required this.evidence,
    required this.nextAction,
  });

  final String documentId;
  final String title;
  final int orderIndex;
  final ChapterEditorialStage stage;
  final ChapterEditorialNeed primaryNeed;
  final int tensionScore;
  final int rhythmScore;
  final int promiseScore;
  final String professionalRhythmLabel;
  final String evidence;
  final String nextAction;
}
