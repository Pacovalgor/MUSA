import 'package:flutter/material.dart';

enum MusaWindowClass { compact, medium, expanded }

enum MusaDeviceClass { phone, tablet, desktop }

enum MusaShellKind { capture, compose, studio }

enum MusaNavigationPattern { bottomBar, sidebar, splitView }

enum MusaEditorDensity { comfortable, balanced, immersive }

@immutable
class MusaAdaptiveSpec {
  const MusaAdaptiveSpec({
    required this.windowClass,
    required this.deviceClass,
    required this.shellKind,
    required this.navigationPattern,
    required this.editorDensity,
    required this.contentPadding,
    required this.editorMaxWidth,
    required this.sidebarWidth,
    required this.inspectorWidth,
    required this.supportsSplitView,
    required this.supportsPersistentLibrary,
    required this.supportsPersistentInspector,
    required this.supportsInspectorOverlay,
    required this.supportsBottomNavigation,
  });

  static const double compactMaxWidth = 700;
  static const double mediumMaxWidth = 1100;

  final MusaWindowClass windowClass;
  final MusaDeviceClass deviceClass;
  final MusaShellKind shellKind;
  final MusaNavigationPattern navigationPattern;
  final MusaEditorDensity editorDensity;
  final EdgeInsets contentPadding;
  final double editorMaxWidth;
  final double sidebarWidth;
  final double inspectorWidth;
  final bool supportsSplitView;
  final bool supportsPersistentLibrary;
  final bool supportsPersistentInspector;
  final bool supportsInspectorOverlay;
  final bool supportsBottomNavigation;

  bool get isCompact => windowClass == MusaWindowClass.compact;
  bool get isMedium => windowClass == MusaWindowClass.medium;
  bool get isExpanded => windowClass == MusaWindowClass.expanded;
  bool get isPhone => deviceClass == MusaDeviceClass.phone;
  bool get isTablet => deviceClass == MusaDeviceClass.tablet;
  bool get isDesktop => deviceClass == MusaDeviceClass.desktop;

  factory MusaAdaptiveSpec.fromContext(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final platform = Theme.of(context).platform;
    final width = mediaQuery.size.width;

    final windowClass = width < compactMaxWidth
        ? MusaWindowClass.compact
        : width < mediumMaxWidth
            ? MusaWindowClass.medium
            : MusaWindowClass.expanded;

    final isDesktopPlatform = switch (platform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux =>
        true,
      _ => false,
    };

    final deviceClass = isDesktopPlatform
        ? MusaDeviceClass.desktop
        : windowClass == MusaWindowClass.compact
            ? MusaDeviceClass.phone
            : MusaDeviceClass.tablet;

    final shellKind = isDesktopPlatform
        ? MusaShellKind.studio
        : deviceClass == MusaDeviceClass.phone
            ? MusaShellKind.capture
            : MusaShellKind.compose;

    final navigationPattern = switch (shellKind) {
      MusaShellKind.capture => MusaNavigationPattern.bottomBar,
      MusaShellKind.compose => windowClass == MusaWindowClass.expanded
          ? MusaNavigationPattern.splitView
          : MusaNavigationPattern.sidebar,
      MusaShellKind.studio => MusaNavigationPattern.splitView,
    };

    final editorDensity = switch (shellKind) {
      MusaShellKind.capture => MusaEditorDensity.comfortable,
      MusaShellKind.compose => MusaEditorDensity.balanced,
      MusaShellKind.studio => MusaEditorDensity.immersive,
    };

    final contentPadding = switch (editorDensity) {
      MusaEditorDensity.comfortable => const EdgeInsets.all(16),
      MusaEditorDensity.balanced => const EdgeInsets.all(20),
      MusaEditorDensity.immersive => const EdgeInsets.all(24),
    };

    final editorMaxWidth = switch (editorDensity) {
      MusaEditorDensity.comfortable => 760.0,
      MusaEditorDensity.balanced => 920.0,
      MusaEditorDensity.immersive => 1040.0,
    };

    return MusaAdaptiveSpec(
      windowClass: windowClass,
      deviceClass: deviceClass,
      shellKind: shellKind,
      navigationPattern: navigationPattern,
      editorDensity: editorDensity,
      contentPadding: contentPadding,
      editorMaxWidth: editorMaxWidth,
      sidebarWidth: shellKind == MusaShellKind.studio ? 260.0 : 320.0,
      inspectorWidth: shellKind == MusaShellKind.studio ? 300.0 : 320.0,
      supportsSplitView: shellKind != MusaShellKind.capture &&
          windowClass != MusaWindowClass.compact,
      supportsPersistentLibrary: shellKind == MusaShellKind.studio ||
          shellKind == MusaShellKind.compose,
      supportsPersistentInspector: shellKind == MusaShellKind.studio ||
          (shellKind == MusaShellKind.compose &&
              windowClass == MusaWindowClass.expanded),
      supportsInspectorOverlay: shellKind == MusaShellKind.compose &&
          windowClass == MusaWindowClass.medium,
      supportsBottomNavigation: shellKind == MusaShellKind.capture,
    );
  }
}

extension MusaAdaptiveSpecX on BuildContext {
  MusaAdaptiveSpec get musaAdaptiveSpec => MusaAdaptiveSpec.fromContext(this);
}
