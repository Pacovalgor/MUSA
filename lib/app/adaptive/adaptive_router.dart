import 'package:flutter/material.dart';

import '../shells/desktop/desktop_studio_shell.dart';
import '../shells/ipad/compose_tool_shell.dart';
import '../shells/iphone/capture_tool_shell.dart';
import 'adaptive_spec.dart';

class MusaAdaptiveRouter extends StatelessWidget {
  const MusaAdaptiveRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final spec = context.musaAdaptiveSpec;

    return switch (spec.shellKind) {
      MusaShellKind.capture => const CaptureToolShell(),
      MusaShellKind.compose => const ComposeToolShell(),
      MusaShellKind.studio => const DesktopStudioShell(),
    };
  }
}
