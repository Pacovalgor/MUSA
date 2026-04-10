/// Legacy aggregate of manuscript progress and immediate narrative direction.
class NarrativeState {
  final int currentChapterIndex;
  final int totalWordCount;
  final String currentTensionLevel;
  final String nextGoal;

  NarrativeState({
    required this.currentChapterIndex,
    required this.totalWordCount,
    required this.currentTensionLevel,
    required this.nextGoal,
  });

  Map<String, dynamic> toJson() => {
        'currentChapterIndex': currentChapterIndex,
        'totalWordCount': totalWordCount,
        'currentTensionLevel': currentTensionLevel,
        'nextGoal': nextGoal,
      };

  factory NarrativeState.fromJson(Map<String, dynamic> json) => NarrativeState(
        currentChapterIndex: json['currentChapterIndex'],
        totalWordCount: json['totalWordCount'],
        currentTensionLevel: json['currentTensionLevel'],
        nextGoal: json['nextGoal'],
      );
}
