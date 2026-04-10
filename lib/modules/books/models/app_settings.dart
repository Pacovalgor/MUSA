import 'musa_settings.dart';
import 'typography_settings.dart';
import 'writing_settings.dart';

/// Global appearance mode for the desktop shell.
enum AppAppearance { light, dark }

/// Stores app-wide preferences that apply across the entire workspace.
class AppSettings {
  final AppAppearance appearance;
  final double editorFontSize;
  final double editorLineHeight;
  final bool zenModeDefault;
  final String? activeBookId;
  final String? activeInstalledModelId;
  final bool backgroundDownloadsEnabled;
  final bool edgeHoverPanelsEnabled;
  final MusaSettings musaSettings;
  final TypographySettings typographySettings;
  final WritingSettings writingSettings;

  const AppSettings({
    this.appearance = AppAppearance.light,
    this.editorFontSize = 21,
    this.editorLineHeight = 1.6,
    this.zenModeDefault = true,
    this.activeBookId,
    this.activeInstalledModelId,
    this.backgroundDownloadsEnabled = true,
    this.edgeHoverPanelsEnabled = true,
    this.musaSettings = const MusaSettings(),
    this.typographySettings = const TypographySettings(),
    this.writingSettings = const WritingSettings(),
  });

  AppSettings copyWith({
    AppAppearance? appearance,
    double? editorFontSize,
    double? editorLineHeight,
    bool? zenModeDefault,
    String? activeBookId,
    bool clearActiveBookId = false,
    String? activeInstalledModelId,
    bool clearActiveInstalledModelId = false,
    bool? backgroundDownloadsEnabled,
    bool? edgeHoverPanelsEnabled,
    MusaSettings? musaSettings,
    TypographySettings? typographySettings,
    WritingSettings? writingSettings,
  }) {
    return AppSettings(
      appearance: appearance ?? this.appearance,
      editorFontSize: editorFontSize ?? this.editorFontSize,
      editorLineHeight: editorLineHeight ?? this.editorLineHeight,
      zenModeDefault: zenModeDefault ?? this.zenModeDefault,
      activeBookId:
          clearActiveBookId ? null : (activeBookId ?? this.activeBookId),
      activeInstalledModelId: clearActiveInstalledModelId
          ? null
          : (activeInstalledModelId ?? this.activeInstalledModelId),
      backgroundDownloadsEnabled:
          backgroundDownloadsEnabled ?? this.backgroundDownloadsEnabled,
      edgeHoverPanelsEnabled:
          edgeHoverPanelsEnabled ?? this.edgeHoverPanelsEnabled,
      musaSettings: musaSettings ?? this.musaSettings,
      typographySettings: typographySettings ?? this.typographySettings,
      writingSettings: writingSettings ?? this.writingSettings,
    );
  }

  Map<String, dynamic> toJson() => {
        'appearance': appearance.name,
        'editorFontSize': editorFontSize,
        'editorLineHeight': editorLineHeight,
        'zenModeDefault': zenModeDefault,
        'activeBookId': activeBookId,
        'activeInstalledModelId': activeInstalledModelId,
        'backgroundDownloadsEnabled': backgroundDownloadsEnabled,
        'edgeHoverPanelsEnabled': edgeHoverPanelsEnabled,
        'musaSettings': musaSettings.toJson(),
        'typographySettings': typographySettings.toJson(),
        'writingSettings': writingSettings.toJson(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        appearance: AppAppearance.values.firstWhere(
          (value) => value.name == (json['appearance'] as String? ?? 'light'),
          orElse: () => AppAppearance.light,
        ),
        editorFontSize: (json['editorFontSize'] as num?)?.toDouble() ?? 21,
        editorLineHeight: (json['editorLineHeight'] as num?)?.toDouble() ?? 1.6,
        zenModeDefault: json['zenModeDefault'] as bool? ?? true,
        activeBookId: json['activeBookId'] as String?,
        activeInstalledModelId: json['activeInstalledModelId'] as String?,
        backgroundDownloadsEnabled:
            json['backgroundDownloadsEnabled'] as bool? ?? true,
        edgeHoverPanelsEnabled: json['edgeHoverPanelsEnabled'] as bool? ?? true,
        musaSettings: MusaSettings.fromJson(
          json['musaSettings'] as Map<String, dynamic>? ?? const {},
        ),
        typographySettings: TypographySettings.fromJson(
          json['typographySettings'] as Map<String, dynamic>? ?? const {},
        ),
        writingSettings: WritingSettings.fromJson(
          json['writingSettings'] as Map<String, dynamic>? ?? const {},
        ),
      );
}
