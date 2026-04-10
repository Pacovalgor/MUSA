import '../../../shared/utils/enum_codec.dart';

enum TimelineEventType { plot, character, world, editorial }

class TimelineEvent {
  final String id;
  final String bookId;
  final String title;
  final String description;
  final TimelineEventType eventType;
  final int? chronologyIndex;
  final DateTime createdAt;
  final List<String> characterIds;
  final List<String> scenarioIds;
  final List<String> documentIds;

  const TimelineEvent({
    required this.id,
    required this.bookId,
    required this.title,
    this.description = '',
    this.eventType = TimelineEventType.plot,
    this.chronologyIndex,
    required this.createdAt,
    this.characterIds = const [],
    this.scenarioIds = const [],
    this.documentIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'title': title,
        'description': description,
        'eventType': eventType.name,
        'chronologyIndex': chronologyIndex,
        'createdAt': createdAt.toIso8601String(),
        'characterIds': characterIds,
        'scenarioIds': scenarioIds,
        'documentIds': documentIds,
      };

  factory TimelineEvent.fromJson(Map<String, dynamic> json) => TimelineEvent(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        eventType: enumFromName(
          TimelineEventType.values,
          json['eventType'] as String?,
          TimelineEventType.plot,
        ),
        chronologyIndex: json['chronologyIndex'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        characterIds:
            List<String>.from(json['characterIds'] as List? ?? const []),
        scenarioIds:
            List<String>.from(json['scenarioIds'] as List? ?? const []),
        documentIds:
            List<String>.from(json['documentIds'] as List? ?? const []),
      );
}
