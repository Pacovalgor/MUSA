import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controller/editor_controller.dart';

/// Custom selection controls that intercept the toolbar position.
/// Instead of building a native toolbar, it notifies the EditorController
/// of the real bounding box/coordinate calculated by Flutter's render engine.
class MusaSelectionControls extends DesktopTextSelectionControls {
  final EditorController controller;

  MusaSelectionControls(this.controller);

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    // 1. Calculate the preferred position based on endpoints
    // For multiline, we use the average of the top endpoints or the midpoint
    final Offset position;

    if (endpoints.length >= 2) {
      // Multiline selection
      final topY = endpoints.first.point.dy - textLineHeight;
      final centerX = (endpoints.first.point.dx + endpoints.last.point.dx) / 2;
      position = Offset(centerX, topY);
    } else {
      position = selectionMidpoint;
    }

    // 2. Notify controller (post-frame to avoid build-phase state updates)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Convert global/relative coordinates to what the overlay expects
      // Since we use CompositedTransformFollower, we just need the local offset
      // from the start of the editable region.
      final localOffset = position - globalEditableRegion.topLeft;
      controller.updateSelectionOffset(localOffset);
    });

    // 3. Return a shrink widget because we use a custom Overlay widget elsewhere
    return const SizedBox.shrink();
  }
}
