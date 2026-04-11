import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

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
import '../../shared/storage/local_workspace_storage.dart';
import '../../shared/storage/musa_project_document.dart';

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
    final workspaceState = ref.watch(narrativeWorkspaceProvider);
    if (workspaceState.hasError) {
      return _buildProjectUnavailableScaffold(tokens);
    }
    final showSidebar = ref.watch(sidebarVisibilityProvider);
    final showInspector = ref.watch(inspectorVisibilityProvider);
    final sidebarAutoOpened = ref.watch(sidebarAutoOpenedProvider);
    final inspectorAutoOpened = ref.watch(inspectorAutoOpenedProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final writingSettings = ref.watch(writingSettingsProvider);
    final editorMode = ref.watch(editorModeProvider);
    final isEditorFocused = ref.watch(editorFocusProvider);
    final isBookMode = editorMode == workspace.WorkspaceEditorMode.book;
    final isCharacterMode =
        editorMode == workspace.WorkspaceEditorMode.character;
    final isScenarioMode = editorMode == workspace.WorkspaceEditorMode.scenario;
    final focusFadeEnabled = writingSettings.focusModeEnabled &&
        isEditorFocused &&
        !isCharacterMode &&
        !isScenarioMode &&
        !isBookMode;
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
                child: AnimatedOpacity(
                  duration: tokens.motionNormal,
                  opacity: focusFadeEnabled ? 0.46 : 1,
                  child: const MusaSidebar(),
                ),
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
                child: AnimatedOpacity(
                  duration: tokens.motionNormal,
                  opacity: focusFadeEnabled ? 0.52 : 1,
                  child: const MusaInspector(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectUnavailableScaffold(MusaThemeTokens tokens) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(color: tokens.canvasBackground),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'El proyecto necesita atención',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'El archivo anterior no está disponible o cambió fuera de MUSA. Abre la versión actual, vuelve al proyecto local o crea uno nuevo.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _handleProjectMenuAction(
                      ref,
                      const _ProjectMenuSelection(_ProjectMenuAction.open),
                      null,
                    ),
                    icon: const Icon(Icons.folder_open_outlined, size: 18),
                    label: const Text('Abrir otro .musa'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _handleProjectMenuAction(
                      ref,
                      const _ProjectMenuSelection(_ProjectMenuAction.useLocal),
                      null,
                    ),
                    icon: const Icon(Icons.storage_outlined, size: 18),
                    label: const Text('Usar proyecto local'),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => _handleProjectMenuAction(
                      ref,
                      const _ProjectMenuSelection(_ProjectMenuAction.create),
                      null,
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Crear proyecto nuevo'),
                  ),
                ],
              ),
            ),
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
              const SizedBox(width: 6),
              _buildProjectMenu(context, ref, activeBook?.title),
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

  Widget _buildProjectMenu(
    BuildContext context,
    WidgetRef ref,
    String? activeBookTitle,
  ) {
    final tokens = MusaTheme.tokensOf(context);
    final activeProjectPath = ref.watch(activeProjectPathProvider).valueOrNull;
    final recentProjects =
        ref.watch(recentProjectsProvider).valueOrNull ?? const [];
    final projectLabel = activeProjectPath == null || activeProjectPath.isEmpty
        ? 'Proyecto'
        : p.basename(activeProjectPath);

    return PopupMenuButton<_ProjectMenuSelection>(
      tooltip: 'Proyecto',
      color: tokens.canvasBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        side: BorderSide(color: tokens.borderSoft),
      ),
      onSelected: (selection) => _handleProjectMenuAction(
        ref,
        selection,
        activeBookTitle,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _ProjectMenuSelection(_ProjectMenuAction.open),
          child: Text('Abrir proyecto...'),
        ),
        const PopupMenuItem(
          value: _ProjectMenuSelection(_ProjectMenuAction.saveAs),
          child: Text('Guardar como...'),
        ),
        const PopupMenuItem(
          value: _ProjectMenuSelection(_ProjectMenuAction.create),
          child: Text('Crear proyecto nuevo...'),
        ),
        if (recentProjects.isNotEmpty) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            enabled: false,
            child: Text('Recientes'),
          ),
          for (final project in recentProjects)
            PopupMenuItem(
              value: _ProjectMenuSelection(
                _ProjectMenuAction.recent,
                path: project.path,
              ),
              child: _RecentProjectMenuItem(project: project),
            ),
        ],
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _ProjectMenuSelection(_ProjectMenuAction.useLocal),
          child: Text('Usar proyecto local'),
        ),
      ],
      child: TextButton.icon(
        onPressed: null,
        style: TextButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          disabledForegroundColor: tokens.textPrimary,
          splashFactory: NoSplash.splashFactory,
        ),
        icon: const Icon(Icons.folder_open_outlined, size: 16),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            projectLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Future<void> _handleProjectMenuAction(
    WidgetRef ref,
    _ProjectMenuSelection selection,
    String? activeBookTitle,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final picker = ref.read(projectDocumentPickerProvider);
      final notifier = ref.read(narrativeWorkspaceProvider.notifier);

      switch (selection.action) {
        case _ProjectMenuAction.open:
          final path = await picker.openProjectPath();
          if (path == null) return;
          await notifier.openProjectFile(path);
          _throwIfWorkspaceError(ref);
          ref.invalidate(activeProjectPathProvider);
          ref.invalidate(recentProjectsProvider);
          if (!mounted) return;
          _showProjectMessage('Proyecto abierto: ${p.basename(path)}');
          break;
        case _ProjectMenuAction.saveAs:
          final path = await picker.chooseSaveProjectPath(
            suggestedName: _projectSuggestedName(activeBookTitle),
          );
          if (path == null) return;
          await notifier.saveProjectFileAs(path);
          _throwIfWorkspaceError(ref);
          ref.invalidate(activeProjectPathProvider);
          ref.invalidate(recentProjectsProvider);
          if (!mounted) return;
          _showProjectMessage('Proyecto guardado: ${p.basename(path)}');
          break;
        case _ProjectMenuAction.create:
          final path = await picker.chooseSaveProjectPath(
            suggestedName: _projectSuggestedName(null),
          );
          if (path == null) return;
          await notifier.createProjectFile(path);
          _throwIfWorkspaceError(ref);
          ref.invalidate(activeProjectPathProvider);
          ref.invalidate(recentProjectsProvider);
          if (!mounted) return;
          _showProjectMessage('Proyecto creado: ${p.basename(path)}');
          break;
        case _ProjectMenuAction.recent:
          final path = selection.path;
          if (path == null) return;
          await notifier.openProjectFile(path);
          _throwIfWorkspaceError(ref);
          ref.invalidate(activeProjectPathProvider);
          ref.invalidate(recentProjectsProvider);
          if (!mounted) return;
          _showProjectMessage('Proyecto abierto: ${p.basename(path)}');
          break;
        case _ProjectMenuAction.useLocal:
          await notifier.useLocalProjectFile();
          _throwIfWorkspaceError(ref);
          ref.invalidate(activeProjectPathProvider);
          ref.invalidate(recentProjectsProvider);
          if (!mounted) return;
          _showProjectMessage('Proyecto local activo');
          break;
      }
    } catch (error) {
      if (!mounted) return;
      final details = error.toString().trim();
      _showProjectMessage(
        details.isEmpty
            ? 'No se pudo completar la operación del proyecto.'
            : 'No se pudo completar la operación: $details',
      );
    }
  }

  void _throwIfWorkspaceError(WidgetRef ref) {
    final workspace = ref.read(narrativeWorkspaceProvider);
    if (workspace.hasError) {
      throw workspace.error ?? StateError('No se pudo cargar el proyecto.');
    }
  }

  String _projectSuggestedName(String? activeBookTitle) {
    final cleaned = (activeBookTitle ?? 'Musa')
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '-');
    final baseName = cleaned.isEmpty ? 'Musa' : cleaned;
    return '$baseName${MusaProjectDocument.extension}';
  }

  void _showProjectMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

enum _PrintMenuAction { standard, bookletA5 }

enum _ProjectMenuAction { open, saveAs, create, recent, useLocal }

class _ProjectMenuSelection {
  const _ProjectMenuSelection(this.action, {this.path});

  final _ProjectMenuAction action;
  final String? path;
}

class _RecentProjectMenuItem extends StatelessWidget {
  const _RecentProjectMenuItem({required this.project});

  final RecentProject project;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            project.path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textMuted,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

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
