import '../../../shared/utils/enum_codec.dart';

/// High-level document kinds stored inside a book workspace.
enum DocumentKind { chapter, scene, noteDoc, scratch }

/// Editable manuscript unit such as a chapter, scene or scratch page.
class Document {
  final String id;
  final String bookId;
  final String title;
  final DocumentKind kind;
  final int orderIndex;
  final String content;
  final int wordCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentDocumentId;
  final List<String> characterIds;
  final List<String> scenarioIds;

  const Document({
    required this.id,
    required this.bookId,
    required this.title,
    this.kind = DocumentKind.chapter,
    required this.orderIndex,
    this.content = '',
    this.wordCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.parentDocumentId,
    this.characterIds = const [],
    this.scenarioIds = const [],
  });

  Document copyWith({
    String? title,
    DocumentKind? kind,
    int? orderIndex,
    String? content,
    int? wordCount,
    DateTime? updatedAt,
    String? parentDocumentId,
    bool clearParentDocumentId = false,
    List<String>? characterIds,
    List<String>? scenarioIds,
  }) {
    return Document(
      id: id,
      bookId: bookId,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      orderIndex: orderIndex ?? this.orderIndex,
      content: content ?? this.content,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentDocumentId: clearParentDocumentId
          ? null
          : (parentDocumentId ?? this.parentDocumentId),
      characterIds: characterIds ?? this.characterIds,
      scenarioIds: scenarioIds ?? this.scenarioIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'title': title,
        'kind': kind.name,
        'orderIndex': orderIndex,
        'content': content,
        'wordCount': wordCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'parentDocumentId': parentDocumentId,
        'characterIds': characterIds,
        'scenarioIds': scenarioIds,
      };

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        title: json['title'] as String,
        kind: enumFromName(
          DocumentKind.values,
          json['kind'] as String?,
          DocumentKind.chapter,
        ),
        orderIndex: json['orderIndex'] as int? ?? 0,
        content: json['content'] as String? ?? '',
        wordCount: json['wordCount'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        parentDocumentId: json['parentDocumentId'] as String?,
        characterIds:
            List<String>.from(json['characterIds'] as List? ?? const []),
        scenarioIds:
            List<String>.from(json['scenarioIds'] as List? ?? const []),
      );
}
