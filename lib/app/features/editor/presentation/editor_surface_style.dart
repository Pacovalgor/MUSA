import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/adaptive/adaptive_spec.dart';

@immutable
class MusaEditorSurfaceStyle {
  const MusaEditorSurfaceStyle({
    required this.maxWidthOverride,
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.typewriterBottomFactor,
    required this.titleToBodySpacing,
  });

  static const desktop = MusaEditorSurfaceStyle(
    maxWidthOverride: null,
    horizontalPadding: 72,
    topPadding: 112,
    bottomPadding: 112,
    typewriterBottomFactor: 0.6,
    titleToBodySpacing: 60,
  );

  final double? maxWidthOverride;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double typewriterBottomFactor;
  final double titleToBodySpacing;

  factory MusaEditorSurfaceStyle.compose(MusaAdaptiveSpec spec) {
    return spec.windowClass == MusaWindowClass.expanded
        ? const MusaEditorSurfaceStyle(
            maxWidthOverride: 900,
            horizontalPadding: 48,
            topPadding: 64,
            bottomPadding: 80,
            typewriterBottomFactor: 0.42,
            titleToBodySpacing: 42,
          )
        : const MusaEditorSurfaceStyle(
            maxWidthOverride: 820,
            horizontalPadding: 28,
            topPadding: 48,
            bottomPadding: 64,
            typewriterBottomFactor: 0.34,
            titleToBodySpacing: 32,
          );
  }
}

final musaEditorSurfaceStyleProvider = Provider<MusaEditorSurfaceStyle>(
  (ref) => MusaEditorSurfaceStyle.desktop,
);
