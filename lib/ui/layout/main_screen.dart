import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/books/models/narrative_workspace.dart' as workspace;
import '../../modules/books/providers/workspace_providers.dart';
import '../../editor/widgets/musa_editor_field.dart';
import '../../editor/widgets/character_editor.dart';
import '../../editor/widgets/scenario_editor.dart';
import '../../editor/widgets/book_editor.dart';
import '../../editor/widgets/editor_overlay.dart';
import '../../editor/widgets/chapter_insight_panel.dart';
import '../../editor/widgets/fragment_insight_panel.dart';
import '../../editor/widgets/suggestion_review_panel.dart';
import '../../editor/controller/editor_controller.dart';
import '../../modules/characters/providers/character_providers.dart';
import '../../modules/manuscript/models/document.dart';
import '../../modules/manuscript/providers/document_providers.dart';
import '../../modules/notes/providers/note_providers.dart';
import '../../modules/scenarios/providers/scenario_providers.dart';

import '../providers/ui_providers.dart';
import '../widgets/sidebar.dart';
import '../widgets/inspector.dart';
import '../widgets/musa_settings_dialog.dart';
import '../../services/ia/embedded/management/model_manager.dart';
import '../../services/print/print_service.dart';
import '../../core/theme.dart';

class MusaMainScreen extends ConsumerStatefulWidget {
  const MusaMainScreen({super.key});

  static const double _edgeRevealDistance = 18;
  static const Duration _edgeCollapseDelay = Duration(milliseconds: 180);

  @override
  ConsumerState<MusaMainScreen> createState() => _MusaMainScreenState();
}

class _MusaMainScreenState extends ConsumerState<MusaMainScreen> {
  static const double _sidebarWidth = 260;
  static const double _inspectorWidth = 300;
  static const double _edgeKeepOpenMultiplier = 1.5;

  Timer? _sidebarCloseTimer;
  Timer? _inspectorCloseTimer;

  @override
  void dispose() {
    _sidebarCloseTimer?.cancel();
    _inspectorCloseTimer?.cancel();
    super.dispose();
  }

  void _scheduleSidebarAutoClose() {
    _sidebarCloseTimer?.cancel();
    _sidebarCloseTimer = Timer(MusaMainScreen._edgeCollapseDelay, () {
      if (!mounted) return;
      if (!ref.read(sidebarAutoOpenedProvider)) return;
      ref.read(sidebarVisibilityProvider.notifier).state = false;
      ref.read(sidebarAutoOpenedProvider.notifier).state = false;
    });
  }

  void _scheduleInspectorAutoClose() {
    _inspectorCloseTimer?.cancel();
    _inspectorCloseTimer = Timer(MusaMainScreen._edgeCollapseDelay, () {
      if (!mounted) return;
      if (!ref.read(inspectorAutoOpenedProvider)) return;
      ref.read(inspectorVisibilityProvider.notifier).state = false;
      ref.read(inspectorAutoOpenedProvider.notifier).state = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    final showSidebar = ref.watch(sidebarVisibilityProvider);
    final showInspector = ref.watch(inspectorVisibilityProvider);
    final sidebarAutoOpened = ref.watch(sidebarAutoOpenedProvider);
    final inspectorAutoOpened = ref.watch(inspectorAutoOpenedProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final editorMode = ref.watch(editorModeProvider);
    final isBookMode = editorMode == workspace.WorkspaceEditorMode.book;
    final isCharacterMode =
        editorMode == workspace.WorkspaceEditorMode.character;
    final isScenarioMode = editorMode == workspace.WorkspaceEditorMode.scenario;
    const sidebarKeepOpenDistance = _sidebarWidth * _edgeKeepOpenMultiplier;
    const inspectorKeepOpenDistance = _inspectorWidth * _edgeKeepOpenMultiplier;

    return Scaffold(
      body: MouseRegion(
        onHover: appSettings.edgeHoverPanelsEnabled
            ? (event) {
                final x = event.position.dx;
                final screenWidth = MediaQuery.sizeOf(context).width;

                if (!showSidebar && x <= MusaMainScreen._edgeRevealDistance) {
                  ref.read(sidebarVisibilityProvider.notifier).state = true;
                  ref.read(sidebarAutoOpenedProvider.notifier).state = true;
                }

                if (!showInspector &&
                    x >= screenWidth - MusaMainScreen._edgeRevealDistance) {
                  ref.read(inspectorVisibilityProvider.notifier).state = true;
                  ref.read(inspectorAutoOpenedProvider.notifier).state = true;
                }

                if (showSidebar && sidebarAutoOpened) {
                  if (x <= sidebarKeepOpenDistance) {
                    _sidebarCloseTimer?.cancel();
                  } else {
                    _scheduleSidebarAutoClose();
                  }
                }

                if (showInspector && inspectorAutoOpened) {
                  if (x >= screenWidth - inspectorKeepOpenDistance) {
                    _inspectorCloseTimer?.cancel();
                  } else {
                    _scheduleInspectorAutoClose();
                  }
                }
              }
            : null,
        child: DecoratedBox(
          decoration: BoxDecoration(color: tokens.appBackground),
          child: Row(
            children: [
              AnimatedContainer(
                duration: tokens.motionNormal,
                curve: Curves.ease,
                width: showSidebar ? 260 : 0,
                child: const MusaSidebar(),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: tokens.canvasBackground,
                    border: Border(
                      left: BorderSide(color: tokens.borderSoft),
                      right: BorderSide(color: tokens.borderSoft),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          _buildTopBar(
                            context,
                            ref,
                            showSidebar,
                            showInspector,
                          ),
                          Expanded(
                            child: isCharacterMode
                                ? const CharacterEditor()
                                : isScenarioMode
                                    ? const ScenarioEditor()
                                    : isBookMode
                                        ? const BookEditor()
                                        : const MusaEditor(),
                          ),
                        ],
                      ),
                      if (!isCharacterMode && !isScenarioMode && !isBookMode)
                        const Positioned(
                          top: 0,
                          left: 0,
                          child: MusaEditorOverlay(),
                        ),
                      if (!isCharacterMode && !isScenarioMode && !isBookMode)
                        const SuggestionReviewPanel(),
                      if (!isCharacterMode && !isScenarioMode && !isBookMode)
                        const FragmentInsightPanel(),
                      if (!isCharacterMode && !isScenarioMode && !isBookMode)
                        const ChapterInsightPanel(),
                    ],
                  ),
                ),
              ),
              AnimatedContainer(
                duration: tokens.motionNormal,
                curve: Curves.ease,
                width: showInspector ? 300 : 0,
                child: const MusaInspector(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    bool sidebarVisible,
    bool inspectorVisible,
  ) {
    final tokens = MusaTheme.tokensOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final leadingInset = sidebarVisible ? 0.0 : 68.0;
    final editorState = ref.watch(editorProvider);
    final editorMode = ref.watch(editorModeProvider);
    final showContextInTopBar = ref.watch(topBarContextVisibleProvider);
    final currentDocument = ref.watch(currentDocumentProvider);
    final activeBook = ref.watch(activeBookProvider);
    final documents = ref.watch(documentsProvider);
    final currentNote = ref.watch(currentNoteProvider);
    final selectedCharacter = ref.watch(selectedCharacterProvider);
    final selectedScenario = ref.watch(selectedScenarioProvider);
    final isVisibleChapter =
        editorMode == workspace.WorkspaceEditorMode.document &&
            currentDocument?.kind == DocumentKind.chapter;
    final canAnalyzeChapter =
        isVisibleChapter && currentDocument!.content.trim().isNotEmpty;
    final canPrintChapter =
        isVisibleChapter && currentDocument!.content.trim().isNotEmpty;
    final canPrintBook =
        editorMode == workspace.WorkspaceEditorMode.book && activeBook != null;
    final activeContext = switch (editorMode) {
      workspace.WorkspaceEditorMode.book when activeBook != null =>
        _TopBarContext(
          label: 'Libro',
          title: activeBook.title,
        ),
      workspace.WorkspaceEditorMode.document when currentDocument != null =>
        _TopBarContext(
          label: currentDocument.kind == DocumentKind.chapter
              ? 'Capítulo'
              : 'Documento',
          title: currentDocument.title,
        ),
      workspace.WorkspaceEditorMode.note when currentNote != null =>
        _TopBarContext(
          label: 'Nota',
          title: currentNote.title ?? 'Nota sin título',
        ),
      workspace.WorkspaceEditorMode.character when selectedCharacter != null =>
        _TopBarContext(
          label: 'Personaje',
          title: selectedCharacter.displayName,
        ),
      workspace.WorkspaceEditorMode.scenario when selectedScenario != null =>
        _TopBarContext(
          label: 'Escenario',
          title: selectedScenario.displayName,
        ),
      _ => null,
    };

    return Container(
      height: 52 + topInset,
      padding: EdgeInsets.fromLTRB(18, topInset, 18, 0),
      decoration: BoxDecoration(
        color: tokens.canvasBackground,
        border: Border(bottom: BorderSide(color: tokens.borderSoft)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: tokens.motionNormal,
                curve: Curves.ease,
                width: leadingInset,
              ),
              IconButton(
                icon: Icon(
                  sidebarVisible ? Icons.menu_open : Icons.menu,
                  size: 20,
                  color: tokens.textMuted,
                ),
                onPressed: () {
                  final nextVisible = !sidebarVisible;
                  ref.read(sidebarVisibilityProvider.notifier).state =
                      nextVisible;
                  ref.read(sidebarAutoOpenedProvider.notifier).state = false;
                  _sidebarCloseTimer?.cancel();
                },
              ),
              if (showContextInTopBar && activeContext != null) ...[
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: _TopBarContextView(context: activeContext),
                ),
                const SizedBox(width: 10),
              ],
              if (editorState.previousText != null)
                TextButton.icon(
                  onPressed: () =>
                      ref.read(editorProvider.notifier).undoSuggestion(),
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.textSecondary,
                  ),
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text(
                    'Deshacer Musa',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          Row(
            children: [
              if (canAnalyzeChapter) ...[
                TextButton.icon(
                  onPressed: editorState.isProcessing
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ref
                                .read(editorProvider.notifier)
                                .runChapterAnalysis();
                          });
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.textPrimary,
                    splashFactory: NoSplash.splashFactory,
                  ).copyWith(
                    overlayColor:
                        WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return tokens.hoverBackground;
                      }
                      return Colors.transparent;
                    }),
                  ),
                  icon: const Icon(Icons.menu_book_outlined, size: 16),
                  label: const Text(
                    'Entender capítulo',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (canPrintChapter || canPrintBook) ...[
                PopupMenuButton<_PrintMenuAction>(
                  tooltip:
                      canPrintChapter ? 'Imprimir capítulo' : 'Imprimir libro',
                  color: tokens.canvasBackground,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                    side: BorderSide(color: tokens.borderSoft),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _PrintMenuAction.standard,
                      child: Text(
                        canPrintChapter
                            ? 'Imprimir capítulo'
                            : 'Imprimir libro',
                      ),
                    ),
                    const PopupMenuItem(
                      value: _PrintMenuAction.bookletA5,
                      child: Text('Cuadernillo A5'),
                    ),
                  ],
                  onSelected: (action) async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    try {
                      if (canPrintChapter) {
                        if (action == _PrintMenuAction.standard) {
                          await ref.read(printServiceProvider).printChapter(
                                book: activeBook!,
                                document: currentDocument,
                              );
                        } else {
                          await ref
                              .read(printServiceProvider)
                              .printChapterBooklet(
                                book: activeBook!,
                                document: currentDocument,
                              );
                        }
                      } else if (canPrintBook) {
                        if (action == _PrintMenuAction.standard) {
                          await ref.read(printServiceProvider).printBook(
                                book: activeBook,
                                documents: documents,
                              );
                        } else {
                          await ref.read(printServiceProvider).printBookBooklet(
                                book: activeBook,
                                documents: documents,
                              );
                        }
                      }
                    } on PrintException catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.message)),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      final details = error.toString().trim();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            details.isEmpty
                                ? 'No se pudo abrir la impresion ahora mismo.'
                                : 'No se pudo abrir la impresion: $details',
                          ),
                        ),
                      );
                    }
                  },
                  child: IconButton(
                    onPressed: null,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      foregroundColor: tokens.textPrimary,
                      disabledForegroundColor: tokens.textPrimary,
                      splashFactory: NoSplash.splashFactory,
                    ).copyWith(
                      overlayColor:
                          WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return tokens.hoverBackground;
                        }
                        return Colors.transparent;
                      }),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 16),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              _buildDownloadIndicator(ref),
              IconButton(
                icon: Icon(
                  Icons.tune,
                  size: 20,
                  color: tokens.textMuted,
                ),
                tooltip: 'Ajustes de Musas',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const MusaSettingsDialog(),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  inspectorVisible
                      ? Icons.view_sidebar
                      : Icons.view_sidebar_outlined,
                  size: 20,
                  color: tokens.textMuted,
                ),
                onPressed: () {
                  final nextVisible = !inspectorVisible;
                  ref.read(inspectorVisibilityProvider.notifier).state =
                      nextVisible;
                  ref.read(inspectorAutoOpenedProvider.notifier).state = false;
                  _inspectorCloseTimer?.cancel();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadIndicator(WidgetRef ref) {
    final tokens = MusaTheme.tokensOf(ref.context);
    final modelState = ref.watch(modelManagerProvider);
    final activeId = modelState.downloadProgress.keys.firstOrNull;

    if (activeId == null) return const SizedBox.shrink();

    final state = modelState.installStates[activeId];
    if (state == ModelInstallState.downloading ||
        state == ModelInstallState.verifying) {
      final progress = modelState.downloadProgress[activeId] ?? 0.0;
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Tooltip(
          message: 'Instalando motor IA (${(progress * 100).toInt()}%)',
          child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                value: state == ModelInstallState.verifying ? null : progress,
                strokeWidth: 2,
                color: tokens.textMuted,
              )),
        ),
      );
    } else if (state == ModelInstallState.failed ||
        state == ModelInstallState.cancelled) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Tooltip(
          message:
              'La instalación del motor IA falló. Reintenta desde Ajustes.',
          child: Icon(
            Icons.cloud_off,
            size: 16,
            color: Colors.redAccent.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

enum _PrintMenuAction { standard, bookletA5 }

class _TopBarContext {
  const _TopBarContext({
    required this.label,
    required this.title,
  });

  final String label;
  final String title;
}

class _TopBarContextView extends StatelessWidget {
  const _TopBarContextView({
    required this.context,
  });

  final _TopBarContext context;

  @override
  Widget build(BuildContext buildContext) {
    final tokens = MusaTheme.tokensOf(buildContext);
    final theme = Theme.of(buildContext);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          context.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
