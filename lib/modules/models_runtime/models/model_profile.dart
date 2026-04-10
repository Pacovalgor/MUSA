import '../../../shared/utils/enum_codec.dart';

enum ModelFamily { lite, standard, pro }

class ModelProfile {
  final String id;
  final String displayName;
  final ModelFamily family;
  final String runtime;
  final String filename;
  final String downloadUrl;
  final int expectedBytes;
  final int recommendedMinRamGb;
  final String recommendedCpuType;
  final bool isDefault;

  const ModelProfile({
    required this.id,
    required this.displayName,
    required this.family,
    this.runtime = 'llama_cpp',
    required this.filename,
    this.downloadUrl = '',
    this.expectedBytes = 0,
    this.recommendedMinRamGb = 8,
    this.recommendedCpuType = 'apple_silicon',
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'family': family.name,
        'runtime': runtime,
        'filename': filename,
        'downloadUrl': downloadUrl,
        'expectedBytes': expectedBytes,
        'recommendedMinRamGb': recommendedMinRamGb,
        'recommendedCpuType': recommendedCpuType,
        'isDefault': isDefault,
      };

  factory ModelProfile.fromJson(Map<String, dynamic> json) => ModelProfile(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        family: enumFromName(
          ModelFamily.values,
          json['family'] as String?,
          ModelFamily.standard,
        ),
        runtime: json['runtime'] as String? ?? 'llama_cpp',
        filename: json['filename'] as String? ?? '',
        downloadUrl: json['downloadUrl'] as String? ?? '',
        expectedBytes: json['expectedBytes'] as int? ?? 0,
        recommendedMinRamGb: json['recommendedMinRamGb'] as int? ?? 8,
        recommendedCpuType:
            json['recommendedCpuType'] as String? ?? 'apple_silicon',
        isDefault: json['isDefault'] as bool? ?? false,
      );
}
