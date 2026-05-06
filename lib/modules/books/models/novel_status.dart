enum NovelStatusHealth { critical, watch, stable, strong }

enum NovelStatusArea { tension, rhythm, promise, memory, professional }

enum NovelStatusSignalLevel { positive, info, warning, critical }

class NovelStatusReport {
  const NovelStatusReport({
    required this.bookId,
    required this.overallScore,
    required this.healthLevel,
    required this.tensionScore,
    required this.rhythmScore,
    required this.promiseScore,
    required this.memoryScore,
    required this.signals,
    required this.professionalComparisons,
    required this.nextActions,
    required this.updatedAt,
  });

  final String bookId;
  final int overallScore;
  final NovelStatusHealth healthLevel;
  final int tensionScore;
  final int rhythmScore;
  final int promiseScore;
  final int memoryScore;
  final List<NovelStatusSignal> signals;
  final List<ProfessionalMetricComparison> professionalComparisons;
  final List<String> nextActions;
  final DateTime updatedAt;
}

class NovelStatusSignal {
  const NovelStatusSignal({
    required this.area,
    required this.level,
    required this.title,
    required this.detail,
    this.evidence = '',
    this.action = '',
  });

  final NovelStatusArea area;
  final NovelStatusSignalLevel level;
  final String title;
  final String detail;
  final String evidence;
  final String action;
}

class ProfessionalMetricComparison {
  const ProfessionalMetricComparison({
    required this.metric,
    required this.manuscriptValue,
    required this.professionalValue,
    required this.differenceLabel,
  });

  final String metric;
  final double manuscriptValue;
  final double professionalValue;
  final String differenceLabel;
}
