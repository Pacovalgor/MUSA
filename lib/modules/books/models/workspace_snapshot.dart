/// Saved point-in-time snapshot of a book workspace for recovery or comparison.
class WorkspaceSnapshot {
  final String id;
  final String bookId;
  final String label;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  const WorkspaceSnapshot({
    required this.id,
    required this.bookId,
    required this.label,
    required this.createdAt,
    required this.payload,
  });

  WorkspaceSnapshot copyWith({
    String? label,
    DateTime? createdAt,
    Map<String, dynamic>? payload,
  }) {
    return WorkspaceSnapshot(
      id: id,
      bookId: bookId,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'label': label,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
      };

  factory WorkspaceSnapshot.fromJson(Map<String, dynamic> json) {
    return WorkspaceSnapshot(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      label: json['label'] as String? ?? 'Estado guardado',
      createdAt: DateTime.parse(json['createdAt'] as String),
      payload: Map<String, dynamic>.from(
        json['payload'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
