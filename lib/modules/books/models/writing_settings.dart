/// Vertical density preset for the main editor.
enum EditorLineHeightMode { compact, standard, relaxed }

/// Maximum readable measure for manuscript text blocks.
enum EditorMaxWidthMode { narrow, medium, wide }

/// Paragraph separation density used while writing and reviewing.
enum EditorParagraphSpacing { normal, generous }

/// Rendering mode for inline formatting markers inside the editor.
enum FormatRenderMode { visual, markdown }

/// Preferred place where notes open from manuscript anchors.
enum NoteOpenBehavior { sidebar, inspector }

/// Author-facing preferences that alter the editing experience.
class WritingSettings {
  final EditorLineHeightMode lineHeightMode;
  final EditorMaxWidthMode maxWidthMode;
  final EditorParagraphSpacing paragraphSpacing;

  final bool enableItalics;
  final bool enableBold;
  final FormatRenderMode formatRenderMode;
  final bool showFormatShortcutsHelp;

  final bool typewriterModeEnabled;
  final bool focusModeEnabled;

  final bool showNoteMarkers;
  final NoteOpenBehavior noteOpenBehavior;

  const WritingSettings({
    this.lineHeightMode = EditorLineHeightMode.standard,
    this.maxWidthMode = EditorMaxWidthMode.medium,
    this.paragraphSpacing = EditorParagraphSpacing.normal,
    this.enableItalics = true,
    this.enableBold = true,
    this.formatRenderMode = FormatRenderMode.visual,
    this.showFormatShortcutsHelp = true,
    this.typewriterModeEnabled = false,
    this.focusModeEnabled = false,
    this.showNoteMarkers = true,
    this.noteOpenBehavior = NoteOpenBehavior.sidebar,
  });

  WritingSettings copyWith({
    EditorLineHeightMode? lineHeightMode,
    EditorMaxWidthMode? maxWidthMode,
    EditorParagraphSpacing? paragraphSpacing,
    bool? enableItalics,
    bool? enableBold,
    FormatRenderMode? formatRenderMode,
    bool? showFormatShortcutsHelp,
    bool? typewriterModeEnabled,
    bool? focusModeEnabled,
    bool? showNoteMarkers,
    NoteOpenBehavior? noteOpenBehavior,
  }) {
    return WritingSettings(
      lineHeightMode: lineHeightMode ?? this.lineHeightMode,
      maxWidthMode: maxWidthMode ?? this.maxWidthMode,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      enableItalics: enableItalics ?? this.enableItalics,
      enableBold: enableBold ?? this.enableBold,
      formatRenderMode: formatRenderMode ?? this.formatRenderMode,
      showFormatShortcutsHelp:
          showFormatShortcutsHelp ?? this.showFormatShortcutsHelp,
      typewriterModeEnabled:
          typewriterModeEnabled ?? this.typewriterModeEnabled,
      focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
      showNoteMarkers: showNoteMarkers ?? this.showNoteMarkers,
      noteOpenBehavior: noteOpenBehavior ?? this.noteOpenBehavior,
    );
  }

  Map<String, dynamic> toJson() => {
        'lineHeightMode': lineHeightMode.name,
        'maxWidthMode': maxWidthMode.name,
        'paragraphSpacing': paragraphSpacing.name,
        'enableItalics': enableItalics,
        'enableBold': enableBold,
        'formatRenderMode': formatRenderMode.name,
        'showFormatShortcutsHelp': showFormatShortcutsHelp,
        'typewriterModeEnabled': typewriterModeEnabled,
        'focusModeEnabled': focusModeEnabled,
        'showNoteMarkers': showNoteMarkers,
        'noteOpenBehavior': noteOpenBehavior.name,
      };

  factory WritingSettings.fromJson(Map<String, dynamic> json) =>
      WritingSettings(
        lineHeightMode: EditorLineHeightMode.values.firstWhere(
          (e) => e.name == json['lineHeightMode'],
          orElse: () => EditorLineHeightMode.standard,
        ),
        maxWidthMode: EditorMaxWidthMode.values.firstWhere(
          (e) => e.name == json['maxWidthMode'],
          orElse: () => EditorMaxWidthMode.medium,
        ),
        paragraphSpacing: EditorParagraphSpacing.values.firstWhere(
          (e) => e.name == json['paragraphSpacing'],
          orElse: () => EditorParagraphSpacing.normal,
        ),
        enableItalics: json['enableItalics'] as bool? ?? true,
        enableBold: json['enableBold'] as bool? ?? true,
        formatRenderMode: FormatRenderMode.values.firstWhere(
          (e) => e.name == json['formatRenderMode'],
          orElse: () => FormatRenderMode.visual,
        ),
        showFormatShortcutsHelp:
            json['showFormatShortcutsHelp'] as bool? ?? true,
        typewriterModeEnabled: json['typewriterModeEnabled'] as bool? ?? false,
        focusModeEnabled: json['focusModeEnabled'] as bool? ?? false,
        showNoteMarkers: json['showNoteMarkers'] as bool? ?? true,
        noteOpenBehavior: NoteOpenBehavior.values.firstWhere(
          (e) => e.name == json['noteOpenBehavior'],
          orElse: () => NoteOpenBehavior.sidebar,
        ),
      );
}
