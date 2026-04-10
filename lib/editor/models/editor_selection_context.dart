import 'package:flutter/material.dart';

class EditorSelectionContext {
  final String selectedText;
  final TextSelection selection;
  final Offset position;

  EditorSelectionContext({
    required this.selectedText,
    required this.selection,
    required this.position,
  });

  bool get hasSelection => selectedText.trim().isNotEmpty;
}
