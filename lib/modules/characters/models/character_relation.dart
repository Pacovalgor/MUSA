import '../../../shared/utils/enum_codec.dart';

enum CharacterRelationType { family, romance, conflict, ally, mentor, unknown }

class CharacterRelation {
  final String id;
  final String bookId;
  final String fromCharacterId;
  final String toCharacterId;
  final CharacterRelationType relationType;
  final String description;
  final int tensionLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CharacterRelation({
    required this.id,
    required this.bookId,
    required this.fromCharacterId,
    required this.toCharacterId,
    this.relationType = CharacterRelationType.unknown,
    this.description = '',
    this.tensionLevel = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'fromCharacterId': fromCharacterId,
        'toCharacterId': toCharacterId,
        'relationType': relationType.name,
        'description': description,
        'tensionLevel': tensionLevel,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CharacterRelation.fromJson(Map<String, dynamic> json) =>
      CharacterRelation(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        fromCharacterId: json['fromCharacterId'] as String,
        toCharacterId: json['toCharacterId'] as String,
        relationType: enumFromName(
          CharacterRelationType.values,
          json['relationType'] as String?,
          CharacterRelationType.unknown,
        ),
        description: json['description'] as String? ?? '',
        tensionLevel: json['tensionLevel'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
