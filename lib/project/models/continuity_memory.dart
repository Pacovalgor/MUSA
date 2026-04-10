class ContinuityMemory {
  final List<String> knownFacts;
  final List<String> openQuestions;
  final List<String> motifs;
  final Map<DateTime, String> timeline;

  ContinuityMemory({
    this.knownFacts = const [],
    this.openQuestions = const [],
    this.motifs = const [],
    this.timeline = const {},
  });

  Map<String, dynamic> toJson() => {
    'knownFacts': knownFacts,
    'openQuestions': openQuestions,
    'motifs': motifs,
    'timeline': timeline.map((key, value) => MapEntry(key.toIso8601String(), value)),
  };

  factory ContinuityMemory.fromJson(Map<String, dynamic> json) => ContinuityMemory(
    knownFacts: List<String>.from(json['knownFacts'] ?? []),
    openQuestions: List<String>.from(json['openQuestions'] ?? []),
    motifs: List<String>.from(json['motifs'] ?? []),
    timeline: (json['timeline'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(DateTime.parse(key), value as String),
        ) ?? {},
  );
}
