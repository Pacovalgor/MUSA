/// Legacy project summary with prose synopsis and plot-point digest.
class Summary {
  final String content;
  final String plotPoints;
  final DateTime lastUpdated;

  Summary({
    required this.content,
    required this.plotPoints,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'plotPoints': plotPoints,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
        content: json['content'],
        plotPoints: json['plotPoints'],
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );
}
