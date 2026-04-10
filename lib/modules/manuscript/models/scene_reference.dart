/// Lightweight pointer to a scene-like span inside a larger manuscript document.
class SceneReference {
  final String id;
  final String documentId;
  final String bookId;
  final String title;
  final int startOffset;
  final int endOffset;
  final String? summary;

  const SceneReference({
    required this.id,
    required this.documentId,
    required this.bookId,
    required this.title,
    required this.startOffset,
    required this.endOffset,
    this.summary,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'documentId': documentId,
        'bookId': bookId,
        'title': title,
        'startOffset': startOffset,
        'endOffset': endOffset,
        'summary': summary,
      };

  factory SceneReference.fromJson(Map<String, dynamic> json) => SceneReference(
        id: json['id'] as String,
        documentId: json['documentId'] as String,
        bookId: json['bookId'] as String,
        title: json['title'] as String,
        startOffset: json['startOffset'] as int? ?? 0,
        endOffset: json['endOffset'] as int? ?? 0,
        summary: json['summary'] as String?,
      );
}
