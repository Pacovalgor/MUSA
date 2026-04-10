import '../../../shared/utils/enum_codec.dart';

/// Installation progress state for a local model asset.
enum InstalledModelStatus {
  notInstalled,
  downloading,
  paused,
  verifying,
  installed,
  failed,
}

/// Runtime installation record for a model downloaded into the local machine.
class InstalledModel {
  final String id;
  final String modelProfileId;
  final String installPath;
  final int expectedBytes;
  final int actualBytes;
  final InstalledModelStatus status;
  final double downloadProgress;
  final String? lastError;
  final DateTime? installedAt;

  const InstalledModel({
    required this.id,
    required this.modelProfileId,
    required this.installPath,
    this.expectedBytes = 0,
    this.actualBytes = 0,
    this.status = InstalledModelStatus.notInstalled,
    this.downloadProgress = 0,
    this.lastError,
    this.installedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'modelProfileId': modelProfileId,
        'installPath': installPath,
        'expectedBytes': expectedBytes,
        'actualBytes': actualBytes,
        'status': status.name,
        'downloadProgress': downloadProgress,
        'lastError': lastError,
        'installedAt': installedAt?.toIso8601String(),
      };

  factory InstalledModel.fromJson(Map<String, dynamic> json) => InstalledModel(
        id: json['id'] as String,
        modelProfileId: json['modelProfileId'] as String,
        installPath: json['installPath'] as String? ?? '',
        expectedBytes: json['expectedBytes'] as int? ?? 0,
        actualBytes: json['actualBytes'] as int? ?? 0,
        status: enumFromName(
          InstalledModelStatus.values,
          json['status'] as String?,
          InstalledModelStatus.notInstalled,
        ),
        downloadProgress: (json['downloadProgress'] as num?)?.toDouble() ?? 0,
        lastError: json['lastError'] as String?,
        installedAt: json['installedAt'] == null
            ? null
            : DateTime.parse(json['installedAt'] as String),
      );
}
