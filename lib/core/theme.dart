import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class MusaThemeTokens extends ThemeExtension<MusaThemeTokens> {
  const MusaThemeTokens({
    required this.appBackground,
    required this.subtleBackground,
    required this.sidebarBackground,
    required this.panelBackground,
    required this.canvasBackground,
    required this.hoverBackground,
    required this.activeBackground,
    required this.borderSubtle,
    required this.borderSoft,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.editorSelection,
    required this.editorCaret,
    required this.infoBackground,
    required this.warningBackground,
    required this.warningText,
    required this.successBackground,
    required this.successBorder,
    required this.successText,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.space2xs,
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.space2xl,
    required this.space3xl,
    required this.motionFast,
    required this.motionNormal,
  });

  final Color appBackground;
  final Color subtleBackground;
  final Color sidebarBackground;
  final Color panelBackground;
  final Color canvasBackground;
  final Color hoverBackground;
  final Color activeBackground;
  final Color borderSubtle;
  final Color borderSoft;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color editorSelection;
  final Color editorCaret;
  final Color infoBackground;
  final Color warningBackground;
  final Color warningText;
  final Color successBackground;
  final Color successBorder;
  final Color successText;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double space2xs;
  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;
  final double space2xl;
  final double space3xl;
  final Duration motionFast;
  final Duration motionNormal;

  static const light = MusaThemeTokens(
    appBackground: Color(0xFFFFFFFF),
    subtleBackground: Color(0xFFFAFAFA),
    sidebarBackground: Color(0xFFF5F5F5),
    panelBackground: Color(0xFFF7F7F6),
    canvasBackground: Color(0xFFFFFFFF),
    hoverBackground: Color(0xFFF1F1EF),
    activeBackground: Color(0xFFEBEBE8),
    borderSubtle: Color(0xFFE7E5E4),
    borderSoft: Color(0xFFEFEDEA),
    borderStrong: Color(0xFFD6D3D1),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF9CA3AF),
    textDisabled: Color(0xFFC4C7CC),
    editorSelection: Color(0xFFECE9E4),
    editorCaret: Color(0xFF111111),
    infoBackground: Color(0xFFF6F6F3),
    warningBackground: Color(0xFFF3EFE6),
    warningText: Color(0xFF5F5647),
    successBackground: Color(0xFFF3F5F0),
    successBorder: Color(0xFFD7DDD0),
    successText: Color(0xFF56604B),
    radiusSm: 8,
    radiusMd: 12,
    radiusLg: 16,
    radiusXl: 20,
    space2xs: 4,
    spaceXs: 8,
    spaceSm: 12,
    spaceMd: 16,
    spaceLg: 24,
    spaceXl: 32,
    space2xl: 48,
    space3xl: 64,
    motionFast: Duration(milliseconds: 120),
    motionNormal: Duration(milliseconds: 160),
  );

  static const dark = MusaThemeTokens(
    appBackground: Color(0xFF111214),
    subtleBackground: Color(0xFF17191C),
    sidebarBackground: Color(0xFF15171A),
    panelBackground: Color(0xFF1A1D21),
    canvasBackground: Color(0xFF111315),
    hoverBackground: Color(0xFF23272C),
    activeBackground: Color(0xFF2A2E34),
    borderSubtle: Color(0xFF2A2E34),
    borderSoft: Color(0xFF22262B),
    borderStrong: Color(0xFF353A41),
    textPrimary: Color(0xFFF3F2EF),
    textSecondary: Color(0xFFB4BBC5),
    textMuted: Color(0xFF7D8591),
    textDisabled: Color(0xFF555B64),
    editorSelection: Color(0xFF2A2B30),
    editorCaret: Color(0xFFF3F2EF),
    infoBackground: Color(0xFF1D2126),
    warningBackground: Color(0xFF272219),
    warningText: Color(0xFFE4CC9C),
    successBackground: Color(0xFF1B241D),
    successBorder: Color(0xFF2E4332),
    successText: Color(0xFFB9D1B5),
    radiusSm: 8,
    radiusMd: 12,
    radiusLg: 16,
    radiusXl: 20,
    space2xs: 4,
    spaceXs: 8,
    spaceSm: 12,
    spaceMd: 16,
    spaceLg: 24,
    spaceXl: 32,
    space2xl: 48,
    space3xl: 64,
    motionFast: Duration(milliseconds: 120),
    motionNormal: Duration(milliseconds: 160),
  );

  @override
  ThemeExtension<MusaThemeTokens> copyWith({
    Color? appBackground,
    Color? subtleBackground,
    Color? sidebarBackground,
    Color? panelBackground,
    Color? canvasBackground,
    Color? hoverBackground,
    Color? activeBackground,
    Color? borderSubtle,
    Color? borderSoft,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? editorSelection,
    Color? editorCaret,
    Color? infoBackground,
    Color? warningBackground,
    Color? warningText,
    Color? successBackground,
    Color? successBorder,
    Color? successText,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? space2xs,
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? space2xl,
    double? space3xl,
    Duration? motionFast,
    Duration? motionNormal,
  }) {
    return MusaThemeTokens(
      appBackground: appBackground ?? this.appBackground,
      subtleBackground: subtleBackground ?? this.subtleBackground,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      panelBackground: panelBackground ?? this.panelBackground,
      canvasBackground: canvasBackground ?? this.canvasBackground,
      hoverBackground: hoverBackground ?? this.hoverBackground,
      activeBackground: activeBackground ?? this.activeBackground,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderSoft: borderSoft ?? this.borderSoft,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      editorSelection: editorSelection ?? this.editorSelection,
      editorCaret: editorCaret ?? this.editorCaret,
      infoBackground: infoBackground ?? this.infoBackground,
      warningBackground: warningBackground ?? this.warningBackground,
      warningText: warningText ?? this.warningText,
      successBackground: successBackground ?? this.successBackground,
      successBorder: successBorder ?? this.successBorder,
      successText: successText ?? this.successText,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      space2xs: space2xs ?? this.space2xs,
      spaceXs: spaceXs ?? this.spaceXs,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceXl: spaceXl ?? this.spaceXl,
      space2xl: space2xl ?? this.space2xl,
      space3xl: space3xl ?? this.space3xl,
      motionFast: motionFast ?? this.motionFast,
      motionNormal: motionNormal ?? this.motionNormal,
    );
  }

  @override
  ThemeExtension<MusaThemeTokens> lerp(
    covariant ThemeExtension<MusaThemeTokens>? other,
    double t,
  ) {
    if (other is! MusaThemeTokens) {
      return this;
    }

    return MusaThemeTokens(
      appBackground: Color.lerp(appBackground, other.appBackground, t)!,
      subtleBackground:
          Color.lerp(subtleBackground, other.subtleBackground, t)!,
      sidebarBackground:
          Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      panelBackground: Color.lerp(panelBackground, other.panelBackground, t)!,
      canvasBackground:
          Color.lerp(canvasBackground, other.canvasBackground, t)!,
      hoverBackground: Color.lerp(hoverBackground, other.hoverBackground, t)!,
      activeBackground:
          Color.lerp(activeBackground, other.activeBackground, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderSoft: Color.lerp(borderSoft, other.borderSoft, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      editorSelection:
          Color.lerp(editorSelection, other.editorSelection, t)!,
      editorCaret: Color.lerp(editorCaret, other.editorCaret, t)!,
      infoBackground: Color.lerp(infoBackground, other.infoBackground, t)!,
      warningBackground:
          Color.lerp(warningBackground, other.warningBackground, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      successBackground:
          Color.lerp(successBackground, other.successBackground, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusXl: lerpDouble(radiusXl, other.radiusXl, t)!,
      space2xs: lerpDouble(space2xs, other.space2xs, t)!,
      spaceXs: lerpDouble(spaceXs, other.spaceXs, t)!,
      spaceSm: lerpDouble(spaceSm, other.spaceSm, t)!,
      spaceMd: lerpDouble(spaceMd, other.spaceMd, t)!,
      spaceLg: lerpDouble(spaceLg, other.spaceLg, t)!,
      spaceXl: lerpDouble(spaceXl, other.spaceXl, t)!,
      space2xl: lerpDouble(space2xl, other.space2xl, t)!,
      space3xl: lerpDouble(space3xl, other.space3xl, t)!,
      motionFast: t < 0.5 ? motionFast : other.motionFast,
      motionNormal: t < 0.5 ? motionNormal : other.motionNormal,
    );
  }
}

double? lerpDouble(num? a, num? b, double t) =>
    a == null || b == null ? null : a + (b - a) * t;

class MusaTheme {
  static ThemeData get light {
    const tokens = MusaThemeTokens.light;
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: tokens.textPrimary,
      onPrimary: Colors.white,
      secondary: tokens.textSecondary,
      onSecondary: Colors.white,
      error: const Color(0xFF8B5A57),
      onError: Colors.white,
      surface: tokens.canvasBackground,
      onSurface: tokens.textPrimary,
      outline: tokens.borderSubtle,
      outlineVariant: tokens.borderSoft,
      shadow: Colors.black.withValues(alpha: 0.04),
      scrim: Colors.black.withValues(alpha: 0.08),
      inverseSurface: tokens.textPrimary,
      onInverseSurface: Colors.white,
      inversePrimary: tokens.textPrimary,
      tertiary: tokens.warningBackground,
      onTertiary: tokens.warningText,
      surfaceContainerHighest: tokens.panelBackground,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.appBackground,
      extensions: const [tokens],
    );

    final ui = GoogleFonts.interTextTheme(base.textTheme);
    final textTheme = ui.copyWith(
      bodySmall: ui.bodySmall?.copyWith(
        fontSize: 12,
        color: tokens.textSecondary,
      ),
      bodyMedium: ui.bodyMedium?.copyWith(
        fontSize: 14,
        color: tokens.textSecondary,
      ),
      bodyLarge: ui.bodyLarge?.copyWith(
        fontSize: 16,
        color: tokens.textPrimary,
      ),
      titleMedium: ui.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      titleLarge: ui.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      headlineSmall: ui.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      labelLarge: ui.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      displayLarge: GoogleFonts.sourceSerif4(
        fontSize: 21,
        height: 1.68,
        color: tokens.textPrimary,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      dividerTheme: DividerThemeData(
        color: tokens.borderSoft,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: tokens.editorCaret,
        selectionColor: tokens.editorSelection,
        selectionHandleColor: tokens.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.appBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.canvasBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          side: BorderSide(color: tokens.borderSubtle),
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.panelBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          side: BorderSide(color: tokens.borderSoft),
        ),
      ),
      iconTheme: IconThemeData(
        color: tokens.textSecondary,
        size: 18,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(tokens.textSecondary),
          iconSize: const WidgetStatePropertyAll(18),
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
          ),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)
                ? tokens.hoverBackground
                : null,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: tokens.spaceXs,
        ),
        iconColor: tokens.textSecondary,
        textColor: tokens.textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.canvasBackground,
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: tokens.spaceMd,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(color: tokens.borderStrong),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(tokens.textSecondary),
          textStyle: WidgetStatePropertyAll(
            textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: tokens.spaceMd,
              vertical: tokens.spaceSm,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          overlayColor: WidgetStatePropertyAll(tokens.hoverBackground),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? tokens.textDisabled
                : tokens.textPrimary,
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(0),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: tokens.spaceLg,
              vertical: tokens.spaceSm,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(tokens.textPrimary),
          side: WidgetStatePropertyAll(BorderSide(color: tokens.borderSubtle)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: tokens.spaceMd,
              vertical: tokens.spaceSm,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(tokens.textPrimary),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(0),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: tokens.spaceLg,
              vertical: tokens.spaceSm,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: tokens.canvasBackground,
        side: BorderSide(color: tokens.borderSubtle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: textTheme.bodySmall?.copyWith(color: tokens.textPrimary),
        secondaryLabelStyle:
            textTheme.bodySmall?.copyWith(color: tokens.textPrimary),
        deleteIconColor: tokens.textSecondary,
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: tokens.textPrimary,
        inactiveTrackColor: tokens.borderStrong,
        thumbColor: tokens.textPrimary,
        overlayColor: tokens.textPrimary.withValues(alpha: 0.08),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        trackHeight: 2,
      ),
    );
  }

  static ThemeData get dark {
    const tokens = MusaThemeTokens.dark;
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: tokens.textPrimary,
      onPrimary: tokens.canvasBackground,
      secondary: tokens.textSecondary,
      onSecondary: tokens.canvasBackground,
      error: const Color(0xFFE08A82),
      onError: tokens.canvasBackground,
      surface: tokens.canvasBackground,
      onSurface: tokens.textPrimary,
      outline: tokens.borderSubtle,
      outlineVariant: tokens.borderSoft,
      shadow: Colors.black.withValues(alpha: 0.34),
      scrim: Colors.black.withValues(alpha: 0.44),
      inverseSurface: tokens.textPrimary,
      onInverseSurface: tokens.canvasBackground,
      inversePrimary: tokens.canvasBackground,
      tertiary: tokens.warningBackground,
      onTertiary: tokens.warningText,
      surfaceContainerHighest: tokens.panelBackground,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.appBackground,
      extensions: const [tokens],
    );

    final ui = GoogleFonts.interTextTheme(base.textTheme);
    final textTheme = ui.copyWith(
      bodySmall: ui.bodySmall?.copyWith(
        fontSize: 12,
        color: tokens.textSecondary,
      ),
      bodyMedium: ui.bodyMedium?.copyWith(
        fontSize: 14,
        color: tokens.textSecondary,
      ),
      bodyLarge: ui.bodyLarge?.copyWith(
        fontSize: 16,
        color: tokens.textPrimary,
      ),
      titleMedium: ui.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      titleLarge: ui.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      headlineSmall: ui.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      labelLarge: ui.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      displayLarge: GoogleFonts.sourceSerif4(
        fontSize: 21,
        height: 1.68,
        color: tokens.textPrimary,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      dividerTheme: DividerThemeData(
        color: tokens.borderSoft,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: tokens.editorCaret,
        selectionColor: tokens.editorSelection,
        selectionHandleColor: tokens.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.appBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.canvasBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          side: BorderSide(color: tokens.borderSubtle),
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.panelBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          side: BorderSide(color: tokens.borderSoft),
        ),
      ),
      iconTheme: IconThemeData(
        color: tokens.textSecondary,
        size: 18,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(tokens.textSecondary),
          iconSize: const WidgetStatePropertyAll(18),
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
          ),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)
                ? tokens.hoverBackground
                : null,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: tokens.spaceXs,
        ),
        iconColor: tokens.textSecondary,
        textColor: tokens.textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.textPrimary,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: tokens.canvasBackground),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.canvasBackground,
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: tokens.spaceMd,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(color: tokens.borderStrong),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(tokens.textSecondary),
          textStyle: WidgetStatePropertyAll(
            textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: tokens.spaceMd,
              vertical: tokens.spaceSm,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          overlayColor: WidgetStatePropertyAll(tokens.hoverBackground),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? tokens.textDisabled
                : tokens.textPrimary,
          ),
          foregroundColor:
              WidgetStatePropertyAll(tokens.canvasBackground),
          elevation: const WidgetStatePropertyAll(0),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: tokens.spaceLg,
              vertical: tokens.spaceSm,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(tokens.textPrimary),
          side: WidgetStatePropertyAll(BorderSide(color: tokens.borderSubtle)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: tokens.spaceMd,
              vertical: tokens.spaceSm,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(tokens.textPrimary),
          foregroundColor:
              WidgetStatePropertyAll(tokens.canvasBackground),
          elevation: const WidgetStatePropertyAll(0),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: tokens.spaceLg,
              vertical: tokens.spaceSm,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: tokens.canvasBackground,
        side: BorderSide(color: tokens.borderSubtle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: textTheme.bodySmall?.copyWith(color: tokens.textPrimary),
        secondaryLabelStyle:
            textTheme.bodySmall?.copyWith(color: tokens.textPrimary),
        deleteIconColor: tokens.textSecondary,
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: tokens.textPrimary,
        inactiveTrackColor: tokens.borderStrong,
        thumbColor: tokens.textPrimary,
        overlayColor: tokens.textPrimary.withValues(alpha: 0.08),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        trackHeight: 2,
      ),
    );
  }

  static MusaThemeTokens tokensOf(BuildContext context) =>
      Theme.of(context).extension<MusaThemeTokens>()!;

  static TextStyle wordmarkStyle(BuildContext context, {double? size}) {
    final tokens = tokensOf(context);
    return GoogleFonts.playfairDisplay(
      fontSize: size ?? 28,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.14 * (size ?? 28) / 28,
      color: tokens.textPrimary,
      height: 1,
    );
  }

  static BoxDecoration panelDecoration(
    BuildContext context, {
    bool accent = false,
    bool elevated = false,
    double? radius,
    Color? backgroundColor,
  }) {
    final tokens = tokensOf(context);
    return BoxDecoration(
      color: backgroundColor ??
          (accent ? tokens.infoBackground : tokens.panelBackground),
      borderRadius: BorderRadius.circular(radius ?? tokens.radiusLg),
      border: Border.all(
        color: accent ? tokens.borderStrong : tokens.borderSoft,
      ),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration pillDecoration(
    BuildContext context, {
    Color? backgroundColor,
    Color? borderColor,
  }) {
    final tokens = tokensOf(context);
    return BoxDecoration(
      color: backgroundColor ?? tokens.canvasBackground,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: borderColor ?? tokens.borderSubtle),
    );
  }

  static TextStyle sectionEyebrow(BuildContext context) {
    final tokens = tokensOf(context);
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: tokens.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        );
  }

  static String get brandFontFamily =>
      GoogleFonts.playfairDisplay().fontFamily ?? 'serif';

  static String get editorFontFamily =>
      GoogleFonts.sourceSerif4().fontFamily ?? 'serif';
}
