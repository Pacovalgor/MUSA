import '../../../shared/utils/enum_codec.dart';

enum DocumentRevisionSourceType { manual, musa, import }

class DocumentRevision {
  final String id;
  final String documentId;
  final DocumentRevisionSourceType sourceType;
  final String label;
  final String beforeContent;
  final String afterContent;
  final DateTime createdAt;

  const DocumentRevision({
    required this.id,
    required this.documentId,
    this.sourceType = DocumentRevisionSourceType.manual,
    required this.label,
    required this.beforeContent,
    required this.afterContent,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'documentId': documentId,
        'sourceType': sourceType.name,
        'label': label,
        'beforeContent': beforeContent,
        'afterContent': afterContent,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DocumentRevision.fromJson(Map<String, dynamic> json) =>
      DocumentRevision(
        id: json['id'] as String,
        documentId: json['documentId'] as String,
        sourceType: enumFromName(
          DocumentRevisionSourceType.values,
          json['sourceType'] as String?,
          DocumentRevisionSourceType.manual,
        ),
        label: json['label'] as String? ?? '',
        beforeContent: json['beforeContent'] as String? ?? '',
        afterContent: json['afterContent'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
