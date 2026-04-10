import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../editor/controller/editor_controller.dart';
import '../../../muses/musa.dart';
import '../../../muses/providers/musa_providers.dart';
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
