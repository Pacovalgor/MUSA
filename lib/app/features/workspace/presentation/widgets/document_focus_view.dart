import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/adaptive/adaptive_spec.dart';
import '../../../editor/presentation/editor_surface_style.dart';
import '../../../../../core/theme.dart';
import '../../../../../editor/widgets/musa_editor_field.dart';
import '../../../../../modules/books/models/narrative_workspace.dart';
import '../../../../../modules/books/providers/workspace_providers.dart';
import '../../../../../modules/manuscript/providers/document_providers.dart';
import '../../../../../modules/notes/providers/note_providers.dart';

class DocumentFocusView extends ConsumerWidget {
  const DocumentFocusView({
    super.key,
    this.titleOverride,
    this.subtitle,
    this.emptyTitle = 'Nada abierto todavía',
    this.emptyBody =
        'Selecciona un documento o una nota para empezar a escribir.',
    this.leadingActions = const [],
    this.trailingActions = const [],
    this.editorSurfaceStyle,
  });

  final String? titleOverride;
  final String? subtitle;
  final String emptyTitle;
  final String emptyBody;
  final List<Widget> leadingActions;
  final List<Widget> trailingActions;
  final MusaEditorSurfaceStyle? editorSurfaceStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spec = context.musaAdaptiveSpec;
    final tokens = MusaTheme.tokensOf(context);
    final currentItem = ref.watch(currentEditorContentProvider);
    final currentDocument = ref.watch(currentDocumentProvider);
    final editorMode = ref.watch(editorModeProvider);

    if (currentItem == null) {
      return _DocumentEmptyState(title: emptyTitle, body: emptyBody);
    }

    final headerTitle = titleOverride ?? currentItem.title;
    final defaultSubtitle = switch (editorMode) {
      WorkspaceEditorMode.note => 'Captura o nota en curso',
      WorkspaceEditorMode.book => 'Vista del libro activo',
      WorkspaceEditorMode.creative => 'Mesa creativa del libro',
      WorkspaceEditorMode.document => currentDocument == null
          ? 'Documento activo'
          : '${currentDocument.wordCount} palabras',
      WorkspaceEditorMode.character => 'Ficha de personaje',
      WorkspaceEditorMode.scenario => 'Ficha de escenario',
    };

    return DecoratedBox(
      decoration: BoxDecoration(color: tokens.canvasBackground),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              spec.contentPadding.left,
              spec.contentPadding.top,
              spec.contentPadding.right,
              12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leadingActions.isNotEmpty) ...[
                  ...leadingActions,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: spec.editorMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerTitle,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: tokens.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle ?? defaultSubtitle,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (trailingActions.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: trailingActions,
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: tokens.borderSoft),
          Expanded(
            child: ProviderScope(
              overrides: [
                musaEditorSurfaceStyleProvider.overrideWithValue(
                  editorSurfaceStyle ?? MusaEditorSurfaceStyle.desktop,
                ),
              ],
              child: const MusaEditor(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentEmptyState extends StatelessWidget {
  const _DocumentEmptyState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note_outlined, size: 36, color: tokens.textMuted),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
