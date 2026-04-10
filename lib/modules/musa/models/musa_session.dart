import '../../../shared/utils/enum_codec.dart';

enum MusaSessionStatus { queued, streaming, completed, failed, cancelled }

class MusaSession {
  final String id;
  final String bookId;
  final String? documentId;
  final String musaProfileId;
  final MusaSessionStatus status;
  final String selectionText;
  final String contextSnapshot;
  final DateTime startedAt;
  final DateTime? endedAt;

  const MusaSession({
    required this.id,
    required this.bookId,
    this.documentId,
    required this.musaProfileId,
    this.status = MusaSessionStatus.queued,
    this.selectionText = '',
    this.contextSnapshot = '',
    required this.startedAt,
    this.endedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'documentId': documentId,
        'musaProfileId': musaProfileId,
        'status': status.name,
        'selectionText': selectionText,
        'contextSnapshot': contextSnapshot,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
      };

  factory MusaSession.fromJson(Map<String, dynamic> json) => MusaSession(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        documentId: json['documentId'] as String?,
        musaProfileId: json['musaProfileId'] as String,
        status: enumFromName(
          MusaSessionStatus.values,
          json['status'] as String?,
          MusaSessionStatus.queued,
        ),
        selectionText: json['selectionText'] as String? ?? '',
        contextSnapshot: json['contextSnapshot'] as String? ?? '',
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] == null
            ? null
            : DateTime.parse(json['endedAt'] as String),
      );
}
