import '../../../shared/utils/enum_codec.dart';

enum CreativeCardType {
  idea,
  sketch,
  character,
  scenario,
  image,
  research,
  question
}

enum CreativeCardStatus {
  inbox,
  exploring,
  promising,
  readyToUse,
  converted,
  archived,
}

enum CreativeCardSource { manual, inbox, iphone, ipad, imported }

enum CreativeCardAttachmentKind { link, image }

enum CreativeCardConversionKind { note, character, scenario, document }

class CreativeCardAttachment {
  final String id;
  final CreativeCardAttachmentKind kind;
  final String uri;
  final String title;
  final DateTime createdAt;

  CreativeCardAttachment({
    required this.id,
    this.kind = CreativeCardAttachmentKind.link,
    this.uri = '',
    this.title = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'uri': uri,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CreativeCardAttachment.fromJson(Map<String, dynamic> json) {
    return CreativeCardAttachment(
      id: json['id'] as String? ?? '',
      kind: enumFromName(
        CreativeCardAttachmentKind.values,
        json['kind'] as String?,
        CreativeCardAttachmentKind.link,
      ),
      uri: json['uri'] as String? ?? '',
      title: json['title'] as String? ?? '',
      createdAt: _dateFromJson(json['createdAt']),
    );
  }
}

class CreativeCardConversion {
  final CreativeCardConversionKind kind;
  final String targetId;

  const CreativeCardConversion({
    this.kind = CreativeCardConversionKind.note,
    this.targetId = '',
  });

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'targetId': targetId,
      };

  factory CreativeCardConversion.fromJson(Map<String, dynamic> json) {
    return CreativeCardConversion(
      kind: enumFromName(
        CreativeCardConversionKind.values,
        json['kind'] as String?,
        CreativeCardConversionKind.note,
      ),
      targetId: json['targetId'] as String? ?? '',
    );
  }
}

class CreativeCard {
  final String id;
  final String bookId;
  final String title;
  final String body;
  final CreativeCardType type;
  final CreativeCardStatus status;
  final List<String> tags;
  final List<CreativeCardAttachment> attachments;
  final CreativeCardSource source;
  final List<String> linkedCharacterIds;
  final List<String> linkedScenarioIds;
  final List<String> linkedDocumentIds;
  final List<String> linkedNoteIds;
  final CreativeCardConversion? convertedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  CreativeCard({
    required this.id,
    required this.bookId,
    this.title = '',
    this.body = '',
    this.type = CreativeCardType.idea,
    this.status = CreativeCardStatus.inbox,
    List<String> tags = const [],
    List<CreativeCardAttachment> attachments = const [],
    this.source = CreativeCardSource.manual,
    List<String> linkedCharacterIds = const [],
    List<String> linkedScenarioIds = const [],
    List<String> linkedDocumentIds = const [],
    List<String> linkedNoteIds = const [],
    this.convertedTo,
    required this.createdAt,
    required this.updatedAt,
  })  : tags = List.unmodifiable(tags),
        attachments = List.unmodifiable(attachments),
        linkedCharacterIds = List.unmodifiable(linkedCharacterIds),
        linkedScenarioIds = List.unmodifiable(linkedScenarioIds),
        linkedDocumentIds = List.unmodifiable(linkedDocumentIds),
        linkedNoteIds = List.unmodifiable(linkedNoteIds);

  CreativeCard copyWith({
    String? title,
    String? body,
    CreativeCardType? type,
    CreativeCardStatus? status,
    List<String>? tags,
    List<CreativeCardAttachment>? attachments,
    CreativeCardSource? source,
    List<String>? linkedCharacterIds,
    List<String>? linkedScenarioIds,
    List<String>? linkedDocumentIds,
    List<String>? linkedNoteIds,
    CreativeCardConversion? convertedTo,
    bool clearConvertedTo = false,
    DateTime? updatedAt,
  }) {
    return CreativeCard(
      id: id,
      bookId: bookId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      source: source ?? this.source,
      linkedCharacterIds: linkedCharacterIds ?? this.linkedCharacterIds,
      linkedScenarioIds: linkedScenarioIds ?? this.linkedScenarioIds,
      linkedDocumentIds: linkedDocumentIds ?? this.linkedDocumentIds,
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
      convertedTo: clearConvertedTo ? null : (convertedTo ?? this.convertedTo),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'title': title,
        'body': body,
        'type': type.name,
        'status': status.name,
        'tags': tags,
        'attachments':
            attachments.map((attachment) => attachment.toJson()).toList(),
        'source': source.name,
        'linkedCharacterIds': linkedCharacterIds,
        'linkedScenarioIds': linkedScenarioIds,
        'linkedDocumentIds': linkedDocumentIds,
        'linkedNoteIds': linkedNoteIds,
        'convertedTo': convertedTo?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CreativeCard.fromJson(Map<String, dynamic> json) {
    return CreativeCard(
      id: json['id'] as String? ?? '',
      bookId: json['bookId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: enumFromName(
        CreativeCardType.values,
        json['type'] as String?,
        CreativeCardType.idea,
      ),
      status: enumFromName(
        CreativeCardStatus.values,
        json['status'] as String?,
        CreativeCardStatus.inbox,
      ),
      tags: _stringListFromJson(json['tags']),
      attachments: _attachmentsFromJson(json['attachments']),
      source: enumFromName(
        CreativeCardSource.values,
        json['source'] as String?,
        CreativeCardSource.manual,
      ),
      linkedCharacterIds: _stringListFromJson(json['linkedCharacterIds']),
      linkedScenarioIds: _stringListFromJson(json['linkedScenarioIds']),
      linkedDocumentIds: _stringListFromJson(json['linkedDocumentIds']),
      linkedNoteIds: _stringListFromJson(json['linkedNoteIds']),
      convertedTo: _conversionFromJson(json['convertedTo']),
      createdAt: _dateFromJson(json['createdAt']),
      updatedAt: _dateFromJson(json['updatedAt']),
    );
  }
}

DateTime _dateFromJson(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? _fallbackDate;
  }
  return _fallbackDate;
}

List<String> _stringListFromJson(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return const [];
}

List<CreativeCardAttachment> _attachmentsFromJson(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map(CreativeCardAttachment.fromJson)
      .toList();
}

CreativeCardConversion? _conversionFromJson(Object? value) {
  if (value is Map<String, dynamic>) {
    return CreativeCardConversion.fromJson(value);
  }
  return null;
}

final _fallbackDate = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
