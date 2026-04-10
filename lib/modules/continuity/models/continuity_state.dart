class ContinuityState {
  final String bookId;
  final String projectSummary;
  final String currentTensionLevel;
  final List<String> knownFacts;
  final List<String> openQuestions;
  final List<String> motifs;
  final List<String> forbiddenContradictions;
  final DateTime lastUpdatedAt;

  const ContinuityState({
    required this.bookId,
    this.projectSummary = '',
    this.currentTensionLevel = 'neutral',
    this.knownFacts = const [],
    this.openQuestions = const [],
    this.motifs = const [],
    this.forbiddenContradictions = const [],
    required this.lastUpdatedAt,
  });

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'projectSummary': projectSummary,
        'currentTensionLevel': currentTensionLevel,
        'knownFacts': knownFacts,
        'openQuestions': openQuestions,
        'motifs': motifs,
        'forbiddenContradictions': forbiddenContradictions,
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory ContinuityState.fromJson(Map<String, dynamic> json) =>
      ContinuityState(
        bookId: json['bookId'] as String,
        projectSummary: json['projectSummary'] as String? ?? '',
        currentTensionLevel:
            json['currentTensionLevel'] as String? ?? 'neutral',
        knownFacts: List<String>.from(json['knownFacts'] as List? ?? const []),
        openQuestions:
            List<String>.from(json['openQuestions'] as List? ?? const []),
        motifs: List<String>.from(json['motifs'] as List? ?? const []),
        forbiddenContradictions: List<String>.from(
          json['forbiddenContradictions'] as List? ?? const [],
        ),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}
