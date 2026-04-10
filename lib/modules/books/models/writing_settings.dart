enum EditorLineHeightMode { compact, standard, relaxed }

enum EditorMaxWidthMode { narrow, medium, wide }

enum EditorParagraphSpacing { normal, generous }

enum FormatRenderMode { visual, markdown }

enum NoteOpenBehavior { sidebar, inspector }

class WritingSettings {
  final EditorLineHeightMode lineHeightMode;
  final EditorMaxWidthMode maxWidthMode;
  final EditorParagraphSpacing paragraphSpacing;
  
  final bool enableItalics;
  final bool enableBold;
  final FormatRenderMode formatRenderMode;
  final bool showFormatShortcutsHelp;
  
  final bool typewriterModeEnabled;

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
      showFormatShortcutsHelp: showFormatShortcutsHelp ?? this.showFormatShortcutsHelp,
      typewriterModeEnabled: typewriterModeEnabled ?? this.typewriterModeEnabled,
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
        'showNoteMarkers': showNoteMarkers,
        'noteOpenBehavior': noteOpenBehavior.name,
      };

  factory WritingSettings.fromJson(Map<String, dynamic> json) => WritingSettings(
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
        showFormatShortcutsHelp: json['showFormatShortcutsHelp'] as bool? ?? true,
        typewriterModeEnabled: json['typewriterModeEnabled'] as bool? ?? false,
        showNoteMarkers: json['showNoteMarkers'] as bool? ?? true,
        noteOpenBehavior: NoteOpenBehavior.values.firstWhere(
          (e) => e.name == json['noteOpenBehavior'],
          orElse: () => NoteOpenBehavior.sidebar,
        ),
      );
}
