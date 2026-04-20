import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/theme.dart';
import '../../../editor/controller/editor_controller.dart';
import '../../../muses/musa.dart';
import '../../../muses/providers/musa_providers.dart';
import '../../../modules/books/providers/workspace_providers.dart';
import '../../../shared/storage/macos_secure_file_picker.dart';
import '../../../shared/storage/musa_project_document.dart';
import '../../adaptive/adaptive_spec.dart';
import '../../features/editor/presentation/editor_surface_style.dart';
import '../../features/workspace/presentation/widgets/document_focus_view.dart';
import '../../features/workspace/presentation/widgets/workspace_library_panel.dart';
import '../../../ui/widgets/musa_wordmark.dart';
import 'widgets/compose_inspector_panel.dart';

class ComposeToolShell extends ConsumerStatefulWidget {
  const ComposeToolShell({super.key});

  @override
  ConsumerState<ComposeToolShell> createState() => _ComposeToolShellState();
}

class _ComposeToolShellState extends ConsumerState<ComposeToolShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final spec = context.musaAdaptiveSpec;
    final tokens = MusaTheme.tokensOf(context);
    final editorState = ref.watch(editorProvider);
    final selection = editorState.selectionContext;

    final documentSurface = DocumentFocusView(
      titleOverride: 'Composición activa',
      subtitle: selection == null
          ? 'Documento en foco con contexto editorial adaptado a tablet'
          : 'Selección activa lista para análisis o intervención de Musa',
      leadingActions: spec.supportsPersistentLibrary
          ? const []
          : [
              IconButton.filledTonal(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                tooltip: 'Biblioteca',
                icon: const Icon(Icons.menu_book_outlined, size: 18),
              ),
            ],
      trailingActions: [
        _buildProjectMenu(context),
        _ComposeAnalysisButton(
          onPressed: editorState.isProcessing
              ? null
              : () {
                  if (selection != null) {
                    ref.read(editorProvider.notifier).runFragmentAnalysis();
                    return;
                  }
                  ref.read(editorProvider.notifier).runChapterAnalysis();
                },
          hasSelection: selection != null,
        ),
        _ComposeMusaButton(
          enabled: selection != null && !editorState.isProcessing,
        ),
        if (!spec.supportsPersistentInspector)
          IconButton(
            onPressed: () => _openInspectorSheet(context),
            tooltip: 'Inspector',
            icon: const Icon(Icons.tune, size: 18),
          ),
      ],
      editorSurfaceStyle: MusaEditorSurfaceStyle.compose(spec),
    );

    if (spec.supportsPersistentLibrary) {
      return Scaffold(
        key: _scaffoldKey,
        body: SafeArea(
          child: DecoratedBox(
            decoration: BoxDecoration(color: tokens.appBackground),
            child: Row(
              children: [
                SizedBox(
                  width: spec.sidebarWidth,
                  child: const _ComposeSidebar(),
                ),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.canvasBackground,
                      border: Border(
                        left: BorderSide(color: tokens.borderSoft),
                        right: BorderSide(color: tokens.borderSoft),
                      ),
                    ),
                    child: documentSurface,
                  ),
                ),
                if (spec.supportsPersistentInspector)
                  SizedBox(
                    width: spec.inspectorWidth,
                    child: const ComposeInspectorPanel(),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: math.min(MediaQuery.sizeOf(context).width * 0.82, 360),
        child: SafeArea(
          child: _ComposeSidebar(
            onItemChosen: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(color: tokens.canvasBackground),
          child: documentSurface,
        ),
      ),
    );
  }

  Future<void> _openInspectorSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height * 0.84;
        return SizedBox(
          height: height,
          child: ComposeInspectorPanel(
            compact: true,
            onClose: () => Navigator.of(context).pop(),
          ),
        );
      },
    );
  }

  Widget _buildProjectMenu(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    final activeBook = ref.watch(activeBookProvider);
    final activeProjectPath = ref.watch(activeProjectPathProvider).valueOrNull;
    final recentProjects =
        ref.watch(recentProjectsProvider).valueOrNull ?? const [];
    final projectLabel = activeProjectPath == null || activeProjectPath.isEmpty
        ? 'Proyecto'
        : p.basename(activeProjectPath);

    return PopupMenuButton<_ComposeProjectAction>(
      tooltip: 'Proyecto',
      color: tokens.canvasBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        side: BorderSide(color: tokens.borderSoft),
      ),
      onSelected: (selection) =>
          _handleProjectAction(selection, activeBook?.title),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _ComposeProjectAction.open,
          child: Text('Abrir proyecto .musa'),
        ),
        const PopupMenuItem(
          value: _ComposeProjectAction.saveAs,
          child: Text('Guardar en iCloud...'),
        ),
        const PopupMenuItem(
          value: _ComposeProjectAction.create,
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
              value: _ComposeProjectAction.recent(project.path),
              child: Text(project.name),
            ),
        ],
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _ComposeProjectAction.useLocal,
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
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            projectLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Future<void> _handleProjectAction(
    _ComposeProjectAction selection,
    String? activeBookTitle,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final picker = ref.read(projectDocumentPickerProvider);
      final notifier = ref.read(narrativeWorkspaceProvider.notifier);

      switch (selection.kind) {
        case _ComposeProjectActionKind.open:
          final Uint8List? fileBytes;
          if (Platform.isMacOS) {
            fileBytes = await pickMusaFileNative();
          } else {
            final file = await picker.openProjectFile();
            fileBytes = await file?.readAsBytes();
          }
          if (fileBytes == null) return;
          await notifier.openProjectFile(fileBytes);
          _throwIfWorkspaceError();
          ref.invalidate(activeProjectPathProvider);
          ref.invalidate(recentProjectsProvider);
          if (!mounted) return;
          _showProjectMessage('Proyecto abierto');
          break;
        case _ComposeProjectActionKind.saveAs:
          final workspace = ref.read(narrativeWorkspaceProvider).value;
          if (workspace == null) return;
          final suggestedName = _projectSuggestedName(activeBookTitle);
          final String? path;
          if (Platform.isMacOS) {
            final bytes = const MusaProjectDocument().encodeWorkspace(
              workspace,
              preserveProjectIdentity: false,
            );
            path = await saveMusaFileNative(
              Uint8List.fromList(bytes),
              suggestedName: suggestedName,
            );
          } else {
            path = await picker.chooseSaveProjectPath(
              suggestedName: suggestedName,
            );
            if (path == null) return;
            await notifier.saveProjectFileAs(path);
            _throwIfWorkspaceError();
            ref.invalidate(activeProjectPathProvider);
            ref.invalidate(recentProjectsProvider);
          }
          if (path == null || !mounted) return;
          _showProjectMessage('Proyecto guardado: ${p.basename(path)}');
          break;
        case _ComposeProjectActionKind.create:
          final path = await picker.chooseSaveProjectPath(
            suggestedName: _projectSuggestedName(null),
          );
          if (path == null) return;
          await notifier.createProjectFile(path);
          _throwIfWorkspaceError();
          ref.invalidate(activeProjectPathProvider);
          ref.invalidate(recentProjectsProvider);
          if (!mounted) return;
          _showProjectMessage('Proyecto creado: ${p.basename(path)}');
          break;
        case _ComposeProjectActionKind.recent:
          final path = selection.path;
          if (path == null) return;
          final file = File(path);
          if (!await file.exists()) {
            if (!mounted) return;
            _showProjectMessage('El proyecto ya no existe');
            return;
          }
          final fileBytes = await file.readAsBytes();
          await notifier.openProjectFile(fileBytes);
          _throwIfWorkspaceError();
          ref.invalidate(activeProjectPathProvider);
          ref.invalidate(recentProjectsProvider);
          if (!mounted) return;
          _showProjectMessage('Proyecto abierto: ${p.basename(path)}');
          break;
        case _ComposeProjectActionKind.useLocal:
          await notifier.useLocalProjectFile();
          _throwIfWorkspaceError();
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

  void _throwIfWorkspaceError() {
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

enum _ComposeProjectActionKind { open, saveAs, create, recent, useLocal }

class _ComposeProjectAction {
  const _ComposeProjectAction(this.kind, {this.path});

  const _ComposeProjectAction.recent(String path)
      : this(_ComposeProjectActionKind.recent, path: path);

  static const open = _ComposeProjectAction(_ComposeProjectActionKind.open);
  static const saveAs = _ComposeProjectAction(_ComposeProjectActionKind.saveAs);
  static const create = _ComposeProjectAction(_ComposeProjectActionKind.create);
  static const useLocal =
      _ComposeProjectAction(_ComposeProjectActionKind.useLocal);

  final _ComposeProjectActionKind kind;
  final String? path;
}

class _ComposeSidebar extends StatelessWidget {
  const _ComposeSidebar({
    this.onItemChosen,
  });

  final VoidCallback? onItemChosen;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.subtleBackground,
        border: Border(right: BorderSide(color: tokens.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 14),
            child: MusaWordmark(),
          ),
          const Divider(height: 1),
          Expanded(
            child: WorkspaceLibraryPanel(
              onDocumentSelected: (_) => onItemChosen?.call(),
              onNoteSelected: (_) => onItemChosen?.call(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposeAnalysisButton extends StatelessWidget {
  const _ComposeAnalysisButton({
    required this.onPressed,
    required this.hasSelection,
  });

  final VoidCallback? onPressed;
  final bool hasSelection;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: tokens.textPrimary,
        splashFactory: NoSplash.splashFactory,
      ).copyWith(
        overlayColor: WidgetStatePropertyAll(tokens.hoverBackground),
      ),
      icon: const Icon(Icons.menu_book_outlined, size: 16),
      label: Text(hasSelection ? 'Entender fragmento' : 'Entender capítulo'),
    );
  }
}

class _ComposeMusaButton extends ConsumerWidget {
  const _ComposeMusaButton({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musas = ref.watch(availableMusesProvider);

    return PopupMenuButton<Musa>(
      enabled: enabled,
      tooltip: 'Invocar Musa',
      onSelected: (musa) =>
          ref.read(editorProvider.notifier).runMusa(musa: musa),
      itemBuilder: (context) => [
        for (final musa in musas)
          PopupMenuItem<Musa>(
            value: musa,
            child: Text(musa.name),
          ),
      ],
      child: TextButton.icon(
        onPressed: null,
        style: TextButton.styleFrom(
          foregroundColor: MusaTheme.tokensOf(context).textPrimary,
          disabledForegroundColor: enabled
              ? MusaTheme.tokensOf(context).textPrimary
              : MusaTheme.tokensOf(context).textDisabled,
        ),
        icon: const Icon(Icons.auto_awesome_outlined, size: 16),
        label: const Text('Musa'),
      ),
    );
  }
}
