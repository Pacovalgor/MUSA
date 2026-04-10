import '../../../shared/utils/enum_codec.dart';

enum MusaProfileKind {
  style,
  tension,
  atmosphere,
  continuity,
  character,
  scenario,
}

class MusaProfile {
  final String id;
  final String name;
  final MusaProfileKind kind;
  final String description;
  final String promptTemplate;
  final bool isEnabled;

  const MusaProfile({
    required this.id,
    required this.name,
    required this.kind,
    required this.description,
    required this.promptTemplate,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'description': description,
        'promptTemplate': promptTemplate,
        'isEnabled': isEnabled,
      };

  factory MusaProfile.fromJson(Map<String, dynamic> json) => MusaProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: enumFromName(
          MusaProfileKind.values,
          json['kind'] as String?,
          MusaProfileKind.style,
        ),
        description: json['description'] as String? ?? '',
        promptTemplate: json['promptTemplate'] as String? ?? '',
        isEnabled: json['isEnabled'] as bool? ?? true,
      );
}
