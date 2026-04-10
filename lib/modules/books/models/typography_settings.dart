import 'package:flutter/material.dart';

enum TypographyRole { title, subtitle, body, note }

enum TypographyStylePreset {
  light,
  regular,
  medium,
  semibold,
  bold,
  italic,
  semiboldItalic,
}

class TypographyStyleSettings {
  final String fontFamily;
  final double fontSize;
  final TypographyStylePreset stylePreset;
  final double lineHeight;
  final double letterSpacing;

  const TypographyStyleSettings({
    required this.fontFamily,
    required this.fontSize,
    required this.stylePreset,
    required this.lineHeight,
    this.letterSpacing = 0,
  });

  FontWeight get fontWeight => switch (stylePreset) {
        TypographyStylePreset.light => FontWeight.w300,
        TypographyStylePreset.regular => FontWeight.w400,
        TypographyStylePreset.medium => FontWeight.w500,
        TypographyStylePreset.semibold => FontWeight.w600,
        TypographyStylePreset.bold => FontWeight.w700,
        TypographyStylePreset.italic => FontWeight.w400,
        TypographyStylePreset.semiboldItalic => FontWeight.w600,
      };

  FontStyle get fontStyle => switch (stylePreset) {
        TypographyStylePreset.italic => FontStyle.italic,
        TypographyStylePreset.semiboldItalic => FontStyle.italic,
        _ => FontStyle.normal,
      };

  TextStyle applyTo(TextStyle? base) {
    return (base ?? const TextStyle()).copyWith(
      fontFamily: fontFamily.isEmpty ? null : fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      height: lineHeight,
      letterSpacing: letterSpacing,
    );
  }

  TypographyStyleSettings copyWith({
    String? fontFamily,
    double? fontSize,
    TypographyStylePreset? stylePreset,
    double? lineHeight,
    double? letterSpacing,
  }) {
    return TypographyStyleSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      stylePreset: stylePreset ?? this.stylePreset,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'stylePreset': stylePreset.name,
        'lineHeight': lineHeight,
        'letterSpacing': letterSpacing,
      };

  factory TypographyStyleSettings.fromJson(Map<String, dynamic> json) {
    return TypographyStyleSettings(
      fontFamily: json['fontFamily'] as String? ?? '',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16,
      stylePreset: TypographyStylePreset.values.firstWhere(
        (value) => value.name == json['stylePreset'],
        orElse: () => TypographyStylePreset.regular,
      ),
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.5,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TypographySettings {
  final TypographyStyleSettings title;
  final TypographyStyleSettings subtitle;
  final TypographyStyleSettings body;
  final TypographyStyleSettings note;

  const TypographySettings({
    this.title = const TypographyStyleSettings(
      fontFamily: 'Georgia',
      fontSize: 32,
      stylePreset: TypographyStylePreset.light,
      lineHeight: 1.15,
      letterSpacing: -0.5,
    ),
    this.subtitle = const TypographyStyleSettings(
      fontFamily: '',
      fontSize: 20,
      stylePreset: TypographyStylePreset.medium,
      lineHeight: 1.3,
      letterSpacing: 0,
    ),
    this.body = const TypographyStyleSettings(
      fontFamily: 'Georgia',
      fontSize: 22,
      stylePreset: TypographyStylePreset.regular,
      lineHeight: 1.6,
      letterSpacing: 0.2,
    ),
    this.note = const TypographyStyleSettings(
      fontFamily: '',
      fontSize: 19,
      stylePreset: TypographyStylePreset.regular,
      lineHeight: 1.55,
      letterSpacing: 0.1,
    ),
  });

  TypographyStyleSettings styleFor(TypographyRole role) => switch (role) {
        TypographyRole.title => title,
        TypographyRole.subtitle => subtitle,
        TypographyRole.body => body,
        TypographyRole.note => note,
      };

  TypographySettings copyWith({
    TypographyStyleSettings? title,
    TypographyStyleSettings? subtitle,
    TypographyStyleSettings? body,
    TypographyStyleSettings? note,
  }) {
    return TypographySettings(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      body: body ?? this.body,
      note: note ?? this.note,
    );
  }

  TypographySettings copyWithRole(
    TypographyRole role,
    TypographyStyleSettings style,
  ) {
    return switch (role) {
      TypographyRole.title => copyWith(title: style),
      TypographyRole.subtitle => copyWith(subtitle: style),
      TypographyRole.body => copyWith(body: style),
      TypographyRole.note => copyWith(note: style),
    };
  }

  Map<String, dynamic> toJson() => {
        'title': title.toJson(),
        'subtitle': subtitle.toJson(),
        'body': body.toJson(),
        'note': note.toJson(),
      };

  factory TypographySettings.fromJson(Map<String, dynamic> json) {
    const defaults = TypographySettings();
    return TypographySettings(
      title: _styleFromJson(
        json['title'] as Map<String, dynamic>?,
        defaults.title,
      ),
      subtitle: _styleFromJson(
        json['subtitle'] as Map<String, dynamic>?,
        defaults.subtitle,
      ),
      body: _styleFromJson(
        json['body'] as Map<String, dynamic>?,
        defaults.body,
      ),
      note: _styleFromJson(
        json['note'] as Map<String, dynamic>?,
        defaults.note,
      ),
    );
  }

  static TypographyStyleSettings _styleFromJson(
    Map<String, dynamic>? json,
    TypographyStyleSettings fallback,
  ) {
    if (json == null || json.isEmpty) {
      return fallback;
    }

    final parsed = TypographyStyleSettings.fromJson(json);
    return fallback.copyWith(
      fontFamily: parsed.fontFamily,
      fontSize: parsed.fontSize,
      stylePreset: parsed.stylePreset,
      lineHeight: parsed.lineHeight,
      letterSpacing: parsed.letterSpacing,
    );
  }
}
