/// Final editorial suggestion produced by a Musa session.
class MusaSuggestion {
  final String id;
  final String musaSessionId;
  final String originalText;
  final String suggestedText;
  final String? editorComment;
  final bool applied;
  final DateTime createdAt;
  final DateTime? appliedAt;

  const MusaSuggestion({
    required this.id,
    required this.musaSessionId,
    required this.originalText,
    required this.suggestedText,
    this.editorComment,
    this.applied = false,
    required this.createdAt,
    this.appliedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'musaSessionId': musaSessionId,
        'originalText': originalText,
        'suggestedText': suggestedText,
        'editorComment': editorComment,
        'applied': applied,
        'createdAt': createdAt.toIso8601String(),
        'appliedAt': appliedAt?.toIso8601String(),
      };

  factory MusaSuggestion.fromJson(Map<String, dynamic> json) => MusaSuggestion(
        id: json['id'] as String,
        musaSessionId: json['musaSessionId'] as String,
        originalText: json['originalText'] as String? ?? '',
        suggestedText: json['suggestedText'] as String? ?? '',
        editorComment: json['editorComment'] as String?,
        applied: json['applied'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        appliedAt: json['appliedAt'] == null
            ? null
            : DateTime.parse(json['appliedAt'] as String),
      );
}
