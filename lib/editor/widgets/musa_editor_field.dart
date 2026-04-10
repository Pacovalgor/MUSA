import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/editor_controller.dart';
import '../controller/musa_text_editing_controller.dart';
import 'musa_selection_controls.dart';
import '../../core/constants.dart';
import '../../modules/books/models/writing_settings.dart';
import '../../modules/books/models/narrative_workspace.dart';
import '../../modules/books/providers/workspace_providers.dart';
import '../../modules/manuscript/providers/document_providers.dart';
import '../../modules/notes/providers/note_providers.dart';
import '../../ui/providers/ui_providers.dart';
import '../../ui/widgets/editorial_dialogs.dart';
import '../../core/theme.dart';
import '../../modules/manuscript/models/document.dart';

class MusaEditor extends ConsumerStatefulWidget {
  const MusaEditor({super.key});

  @override
  ConsumerState<MusaEditor> createState() => _MusaEditorState();
}

class _MusaEditorState extends ConsumerState<MusaEditor> {
  final ScrollController _scrollController = ScrollController();
  TextEditingController? _activeController;
  List<String> _lastSyncedNoteSignature = const [];
  List<String> _lastResolvedAnchorSignature = const [];

  void _handleTypewriterScroll() {
    if (!mounted) return;
    final writingSettings = ref.read(writingSettingsProvider);
    if (!writingSettings.typewriterModeEnabled) return;

    final controller = ref.read(editorProvider).controller;
    final selection = controller.selection;
    if (!selection.isValid || selection.baseOffset < 0) return;

    final textToCaret = controller.text.substring(0, selection.baseOffset);
    final typography = ref.read(typographySettingsProvider);
    final editorMode = ref.read(editorModeProvider);

    final mappedLineHeight = switch (writingSettings.lineHeightMode) {
      EditorLineHeightMode.compact => 1.4,
      EditorLineHeightMode.standard => 1.65,
      EditorLineHeightMode.relaxed => 1.95,
    };

    final mappedMaxWidth = switch (writingSettings.maxWidthMode) {
      EditorMaxWidthMode.narrow => 680.0,
      EditorMaxWidthMode.medium => MusaConstants.editorMaxWidth,
      EditorMaxWidthMode.wide => 920.0,
    };

    final tokens = MusaTheme.tokensOf(context);
    final bodyStyle = (editorMode == WorkspaceEditorMode.note
            ? typography.note
            : typography.body)
        .applyTo(Theme.of(context).textTheme.displayLarge)
        .copyWith(
          color: tokens.textPrimary,
          height: mappedLineHeight,
        );

    final span = TextSpan(text: textToCaret, style: bodyStyle);
    final textPainter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    );
    // Calculate the actual available width for the text inside the TextField
    // Container padding (72 * 2 = 144) + TextField contentPadding (22 * 2 = 44) = 188
    final availableWidth = mappedMaxWidth - 188.0;
    textPainter.layout(maxWidth: availableWidth);

    final topPadding =
        112.0 + (editorMode == WorkspaceEditorMode.note ? 40.0 : 80.0);
    final contextHeight = MediaQuery.of(context).size.height;

    // We try to place the caret exactly in the middle of the screen
    final targetScroll = textPainter.height +
        topPadding -
        (contextHeight / 2) +
        60; // 60 for comfortable visual offset

    if (targetScroll > 0 && _scrollController.hasClients) {
      // Avoid spamming animations if the difference is tiny (e.g. typing horizontally)
      if ((_scrollController.offset - targetScroll).abs() > 30) {
        _scrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  void _applyFormat(TextEditingController controller, String marker) {
    final text = controller.text;
    final selection = controller.selection;
    if (!selection.isValid) return;

    if (selection.isCollapsed) {
      // Si el cursor está justo delante de un marcador de cierre, lo saltamos (para "salir" del modo)
      final textAfter = text.substring(selection.start);
      if (textAfter.startsWith(marker)) {
        controller.selection =
            TextSelection.collapsed(offset: selection.start + marker.length);
        return;
      }

      // Si no, insertamos los marcadores y ponemos el cursor en el medio para que escriba
      final newText = '$marker$marker';
      controller.value = TextEditingValue(
        text: text.replaceRange(selection.start, selection.end, newText),
        selection:
            TextSelection.collapsed(offset: selection.start + marker.length),
      );
      return;
    }

    final selectedText = selection.textInside(text);

    if (selectedText.startsWith(marker) &&
        selectedText.endsWith(marker) &&
        selectedText.length >= marker.length * 2) {
      final newText = selectedText.substring(
          marker.length, selectedText.length - marker.length);
      controller.value = TextEditingValue(
        text: text.replaceRange(selection.start, selection.end, newText),
        selection: TextSelection(
            baseOffset: selection.start,
            extentOffset: selection.start + newText.length),
      );
    } else {
      final newText = '$marker$selectedText$marker';
      controller.value = TextEditingValue(
        text: text.replaceRange(selection.start, selection.end, newText),
        selection: TextSelection(
            baseOffset: selection.start,
            extentOffset: selection.start + newText.length),
      );
    }
  }

  void _toggleBulletList(TextEditingController controller) {
    final selection = controller.selection;
    if (!selection.isValid) return;

    final text = controller.text;
    final lineStart = text.lastIndexOf('\n', selection.start - 1);
    final start = lineStart == -1 ? 0 : lineStart + 1;
    final lineEnd = text.indexOf('\n', selection.end);
    final end = lineEnd == -1 ? text.length : lineEnd;
    final line = text.substring(start, end);

    if (line.trim().isEmpty) {
      controller.value = TextEditingValue(
        text: text.replaceRange(start, end, '• '),
        selection: TextSelection.collapsed(offset: start + 2),
      );
      return;
    }

    if (line.startsWith('• ')) {
      controller.value = TextEditingValue(
        text: text.replaceRange(start, end, line.substring(2)),
        selection: selection.copyWith(
          baseOffset: (selection.baseOffset - 2).clamp(start, text.length),
          extentOffset: (selection.extentOffset - 2).clamp(start, text.length),
        ),
      );
      return;
    }

    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, '• $line'),
      selection: selection.copyWith(
        baseOffset: selection.baseOffset + 2,
        extentOffset: selection.extentOffset + 2,
      ),
    );
  }

  void _createAnchoredNote() {
    if (!mounted) return;
    final controller = _activeController;
    if (controller == null) return;

    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    final text = controller.text;
    final selectedText = selection.textInside(text);

    final currentDocument = ref.read(currentDocumentProvider);

    ref.read(narrativeWorkspaceProvider.notifier).createAnchoredNote(
          anchorTextSnapshot: selectedText,
          anchorStartOffset: selection.start,
          anchorEndOffset: selection.end,
          currentDocumentId: currentDocument?.id,
          openBehavior: ref.read(writingSettingsProvider).noteOpenBehavior,
        );
    if (ref.read(writingSettingsProvider).noteOpenBehavior ==
        NoteOpenBehavior.inspector) {
      ref.read(inspectorVisibilityProvider.notifier).state = true;
    }
  }

  void _returnToLinkedDocument(Document? document) {
    if (!mounted || document == null) return;
    ref.read(narrativeWorkspaceProvider.notifier).selectDocument(document.id);
  }

  void _handleEditorTap() {
    final controller = _activeController;
    if (controller is! MusaTextEditingController) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selection = controller.selection;
      if (!selection.isValid ||
          !selection.isCollapsed ||
          selection.baseOffset < 0) {
        return;
      }
      final noteId = controller.noteIdAtOffset(selection.baseOffset);
      if (noteId == null) return;
      controller.onNoteTap?.call(noteId);
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _activeController?.removeListener(_handleTypewriterScroll);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted) return;
    ref.read(topBarContextVisibleProvider.notifier).state =
        _scrollController.offset > 96;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    final editorState = ref.watch(editorProvider);

    // Always ensure the active controller has our scroll listener
    if (_activeController != editorState.controller) {
      _activeController?.removeListener(_handleTypewriterScroll);
      _activeController = editorState.controller;
      _activeController?.addListener(_handleTypewriterScroll);
    }
    final currentItem = ref.watch(currentEditorContentProvider);
    final editorMode = ref.watch(editorModeProvider);
    final typography = ref.watch(typographySettingsProvider);
    final writingSettings = ref.watch(writingSettingsProvider);
    final documents = ref.watch(documentsProvider);
    final notes = ref.watch(notesProvider);
    final currentNote = ref.watch(currentNoteProvider);
    final activeBook = ref.watch(activeBookProvider);
    final currentDocument = ref.watch(currentDocumentProvider);
    final notifier = ref.read(editorProvider.notifier);

    // Provide the visible notes to the Markdown parser logic
    if (_activeController is MusaTextEditingController) {
      final musaController = _activeController as MusaTextEditingController;
      final documentNotes = notes.where((n) {
        return currentDocument != null &&
            n.documentIds.contains(currentDocument.id);
      }).toList();
      final nextNoteSignature = documentNotes
          .map(
            (note) => [
              note.id,
              note.anchorTextSnapshot ?? '',
              note.anchorStartOffset?.toString() ?? '',
              note.anchorEndOffset?.toString() ?? '',
            ].join('|'),
          )
          .toList(growable: false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        musaController.onNoteTap = (String noteId) {
          final workspaceNotifier =
              ref.read(narrativeWorkspaceProvider.notifier);
          if (writingSettings.noteOpenBehavior == NoteOpenBehavior.inspector) {
            ref.read(inspectorVisibilityProvider.notifier).state = true;
            workspaceNotifier.focusNoteInInspector(noteId);
            return;
          }
          workspaceNotifier.selectNote(noteId);
        };
        if (_sameStringList(_lastSyncedNoteSignature, nextNoteSignature)) {
          return;
        }
        _lastSyncedNoteSignature = nextNoteSignature;
        musaController.updateNotes(documentNotes);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final resolutions = musaController.resolveAnchors();
        final nextResolutionSignature = resolutions
            .map(
              (resolution) => [
                resolution.noteId,
                resolution.state.name,
                resolution.resolvedTextSnapshot ?? '',
                resolution.resolvedStartOffset?.toString() ?? '',
                resolution.resolvedEndOffset?.toString() ?? '',
              ].join('|'),
            )
            .toList(growable: false);
        if (_sameStringList(
          _lastResolvedAnchorSignature,
          nextResolutionSignature,
        )) {
          return;
        }
        _lastResolvedAnchorSignature = nextResolutionSignature;
        ref
            .read(narrativeWorkspaceProvider.notifier)
            .reconcileAnchoredNotes(resolutions);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller =
          _scrollController.hasClients ? _scrollController : null;
      final offset = controller?.offset ?? 0;
      ref.read(topBarContextVisibleProvider.notifier).state = offset > 96;
    });

    // custom selection controls to capture real coordinates
    final customControls = MusaSelectionControls(notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        // notify controller of current width for TextPainter sync
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifier.updateViewportWidth(constraints.maxWidth);
        });

        if (currentItem == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(topBarContextVisibleProvider.notifier).state = false;
          });
          return _EmptyEditorState(
            hasActiveBook: activeBook != null,
            hasDocuments: documents.isNotEmpty,
            hasNotes: notes.isNotEmpty,
          );
        }

        final titleStyle = typography.title
            .applyTo(
              Theme.of(context).textTheme.titleLarge,
            )
            .copyWith(
              color: tokens.textPrimary,
            );
        final mappedLineHeight = switch (writingSettings.lineHeightMode) {
          EditorLineHeightMode.compact => 1.4,
          EditorLineHeightMode.standard => 1.65,
          EditorLineHeightMode.relaxed => 1.95,
        };

        final mappedMaxWidth = switch (writingSettings.maxWidthMode) {
          EditorMaxWidthMode.narrow => 680.0,
          EditorMaxWidthMode.medium => MusaConstants.editorMaxWidth,
          EditorMaxWidthMode.wide => 920.0,
        };

        final bodyStyle = (editorMode == WorkspaceEditorMode.note
                ? typography.note
                : typography.body)
            .applyTo(Theme.of(context).textTheme.displayLarge)
            .copyWith(
              color: tokens.textPrimary,
              height: mappedLineHeight,
            );
        final linkedReturnDocument = editorMode == WorkspaceEditorMode.note &&
                currentNote != null &&
                currentNote.documentIds.isNotEmpty
            ? () {
                if (currentDocument != null &&
                    currentNote.documentIds.contains(currentDocument.id)) {
                  return currentDocument;
                }
                for (final document in documents) {
                  if (currentNote.documentIds.contains(document.id)) {
                    return document;
                  }
                }
                return null;
              }()
            : null;

        return SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: mappedMaxWidth,
              ),
              padding: EdgeInsets.only(
                left: 72.0,
                right: 72.0,
                top: 112.0,
                bottom: writingSettings.typewriterModeEnabled
                    ? MediaQuery.of(context).size.height * 0.6
                    : 112.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (linkedReturnDocument != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 14, right: 16),
                          child: IconButton(
                            onPressed: () =>
                                _returnToLinkedDocument(linkedReturnDocument),
                            tooltip: linkedReturnDocument.kind ==
                                    DocumentKind.chapter
                                ? 'Volver al capítulo'
                                : 'Volver al texto',
                            icon: const Icon(Icons.arrow_back, size: 18),
                            color: tokens.textMuted,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                      if (editorMode == WorkspaceEditorMode.document &&
                          currentDocument?.kind == DocumentKind.chapter) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 18, right: 16),
                          child: Text(
                            _formatChapterNumber(
                                currentDocument!.orderIndex + 1),
                            style: titleStyle.copyWith(
                              color: tokens.textMuted,
                              fontSize: titleStyle.fontSize != null
                                  ? titleStyle.fontSize! * 0.72
                                  : null,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(
                            '${editorMode.name}-title-${currentItem.id}',
                          ),
                          initialValue: currentItem.title,
                          maxLines:
                              editorMode == WorkspaceEditorMode.note ? null : 1,
                          minLines:
                              editorMode == WorkspaceEditorMode.note ? 1 : null,
                          decoration: InputDecoration(
                            hintText: editorMode == WorkspaceEditorMode.note
                                ? 'Nota sin título'
                                : 'Sin título',
                            hintStyle: TextStyle(
                              color: tokens.textMuted,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: titleStyle,
                          onFieldSubmitted: (value) => _persistCurrentTitle(
                            ref: ref,
                            editorMode: editorMode,
                            itemId: currentItem.id,
                            currentTitle: currentItem.title,
                            nextTitle: value,
                          ),
                          onChanged: (value) => _persistCurrentTitle(
                            ref: ref,
                            editorMode: editorMode,
                            itemId: currentItem.id,
                            currentTitle: currentItem.title,
                            nextTitle: value,
                          ),
                          onEditingComplete: () => _persistCurrentTitle(
                            ref: ref,
                            editorMode: editorMode,
                            itemId: currentItem.id,
                            currentTitle: currentItem.title,
                            nextTitle: null,
                          ),
                          onTapOutside: (_) {
                            final focusScope = FocusScope.of(context);
                            if (focusScope.hasFocus) {
                              focusScope.unfocus();
                            }
                          },
                        ),
                      ),
                      if (editorMode == WorkspaceEditorMode.note) ...[
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: IconButton(
                            onPressed: () async {
                              final shouldDelete = await _confirmDeleteNote(
                                context,
                                currentItem.title,
                              );
                              if (shouldDelete != true || !context.mounted) {
                                return;
                              }
                              await ref
                                  .read(narrativeWorkspaceProvider.notifier)
                                  .deleteNote(currentItem.id);
                            },
                            tooltip: 'Eliminar nota',
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 60),
                  CompositedTransformTarget(
                    link: editorState.layerLink,
                    child: Shortcuts(
                      shortcuts: <LogicalKeySet, Intent>{
                        LogicalKeySet(LogicalKeyboardKey.meta,
                            LogicalKeyboardKey.keyB): const BoldIntent(),
                        LogicalKeySet(LogicalKeyboardKey.control,
                            LogicalKeyboardKey.keyB): const BoldIntent(),
                        LogicalKeySet(LogicalKeyboardKey.meta,
                            LogicalKeyboardKey.keyI): const ItalicIntent(),
                        LogicalKeySet(LogicalKeyboardKey.control,
                            LogicalKeyboardKey.keyI): const ItalicIntent(),
                        LogicalKeySet(LogicalKeyboardKey.meta,
                            LogicalKeyboardKey.keyN): const NoteIntent(),
                        LogicalKeySet(LogicalKeyboardKey.control,
                            LogicalKeyboardKey.keyN): const NoteIntent(),
                        LogicalKeySet(LogicalKeyboardKey.tab):
                            const BulletListIntent(),
                        LogicalKeySet(LogicalKeyboardKey.escape):
                            const ReturnToLinkedDocumentIntent(),
                      },
                      child: Actions(
                        actions: <Type, Action<Intent>>{
                          BoldIntent: CallbackAction<BoldIntent>(
                            onInvoke: (intent) {
                              if (writingSettings.enableBold) {
                                _applyFormat(editorState.controller, '**');
                              }
                              return null;
                            },
                          ),
                          ItalicIntent: CallbackAction<ItalicIntent>(
                            onInvoke: (intent) {
                              if (writingSettings.enableItalics) {
                                _applyFormat(editorState.controller, '*');
                              }
                              return null;
                            },
                          ),
                          NoteIntent: CallbackAction<NoteIntent>(
                            onInvoke: (intent) {
                              _createAnchoredNote();
                              return null;
                            },
                          ),
                          BulletListIntent: CallbackAction<BulletListIntent>(
                            onInvoke: (intent) {
                              _toggleBulletList(editorState.controller);
                              return null;
                            },
                          ),
                          ReturnToLinkedDocumentIntent:
                              CallbackAction<ReturnToLinkedDocumentIntent>(
                            onInvoke: (intent) {
                              _returnToLinkedDocument(linkedReturnDocument);
                              return null;
                            },
                          ),
                        },
                        child: TextField(
                          key: notifier.editorKey,
                          controller: editorState.controller,
                          focusNode: editorState.focusNode,
                          onTap: _handleEditorTap,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          cursorColor: tokens.editorCaret,
                          cursorWidth: 1.0,
                          selectionControls: customControls,
                          style: bodyStyle,
                          decoration: InputDecoration(
                            hintText: 'Comienza tu historia aquí...',
                            hintStyle: TextStyle(
                              color: tokens.textMuted,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: false,
                            contentPadding:
                                const EdgeInsets.fromLTRB(22, 4, 22, 8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class BoldIntent extends Intent {
  const BoldIntent();
}

class ItalicIntent extends Intent {
  const ItalicIntent();
}

class NoteIntent extends Intent {
  const NoteIntent();
}

class ReturnToLinkedDocumentIntent extends Intent {
  const ReturnToLinkedDocumentIntent();
}

class BulletListIntent extends Intent {
  const BulletListIntent();
}

void _persistCurrentTitle({
  required WidgetRef ref,
  required WorkspaceEditorMode editorMode,
  required String itemId,
  required String currentTitle,
  required String? nextTitle,
}) {
  final trimmedTitle = (nextTitle ?? '').trim();
  if (trimmedTitle.isEmpty || trimmedTitle == currentTitle.trim()) {
    return;
  }

  final notifier = ref.read(narrativeWorkspaceProvider.notifier);
  if (editorMode == WorkspaceEditorMode.note) {
    notifier.updateNoteTitle(itemId, trimmedTitle);
    return;
  }
  notifier.updateDocumentTitle(itemId, trimmedTitle);
}

String _formatChapterNumber(int number) {
  if (number < 10) {
    return '0$number';
  }
  return '$number';
}

Future<bool?> _confirmDeleteNote(BuildContext context, String title) {
  return EditorialDialogs.confirmDestructive(
    context,
    title: 'Eliminar nota',
    message:
        'Se eliminará "${title.trim().isEmpty ? 'esta nota' : title}". Esta acción no se puede deshacer.',
  );
}

class _EmptyEditorState extends StatelessWidget {
  const _EmptyEditorState({
    required this.hasActiveBook,
    required this.hasDocuments,
    required this.hasNotes,
  });

  final bool hasActiveBook;
  final bool hasDocuments;
  final bool hasNotes;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    final title = switch ((hasActiveBook, hasDocuments, hasNotes)) {
      (false, _, _) => 'No hay ningún libro activo',
      (true, false, false) => 'Este libro aún está vacío',
      _ => 'No hay nada seleccionado',
    };
    final subtitle = switch ((hasActiveBook, hasDocuments, hasNotes)) {
      (false, _, _) => 'Crea o selecciona un libro para empezar a escribir.',
      (true, false, false) =>
        'Añade un capítulo, una nota o un personaje desde la barra lateral.',
      _ => 'Selecciona un elemento de la barra lateral para seguir trabajando.',
    };

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(32),
        decoration: MusaTheme.panelDecoration(
          context,
          backgroundColor: tokens.panelBackground,
          radius: 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: tokens.hoverBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_stories_outlined,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: tokens.textSecondary,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
