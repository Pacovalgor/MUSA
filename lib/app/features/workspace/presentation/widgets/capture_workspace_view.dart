import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme.dart';
import '../../../../../modules/books/providers/workspace_providers.dart';
import '../../../../../modules/manuscript/providers/document_providers.dart';
import '../../../../../modules/notes/models/note.dart';
import '../../../../../modules/notes/providers/note_providers.dart';
import 'document_focus_view.dart';

class CaptureWorkspaceView extends ConsumerWidget {
  const CaptureWorkspaceView({
    super.key,
    this.onDocumentRequested,
  });

  final VoidCallback? onDocumentRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = MusaTheme.tokensOf(context);
    final currentDocument = ref.watch(currentDocumentProvider);
    final notes = ref.watch(notesProvider);
    final currentNote = ref.watch(currentNoteProvider);

    return DecoratedBox(
      decoration: BoxDecoration(color: tokens.canvasBackground),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Captura ligera',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Un espacio rápido para fijar una idea, abrir una nota y volver al manuscrito sin traer la densidad del estudio desktop.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () => ref
                          .read(narrativeWorkspaceProvider.notifier)
                          .createNote(
                            title: 'Captura rápida',
                            kind: NoteKind.idea,
                          ),
                      child: const Text('Nueva captura'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: onDocumentRequested,
                      child: Text(
                        currentDocument == null
                            ? 'Volver al documento'
                            : 'Abrir ${currentDocument.title}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (currentNote != null)
            const Expanded(
              child: DocumentFocusView(
                titleOverride: 'Captura activa',
                subtitle: 'Nota ligera en edición',
                emptyTitle: 'Sin captura activa',
                emptyBody: 'Crea una nueva captura para escribir de inmediato.',
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    'Recientes',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 10),
                  if (notes.isEmpty)
                    const _CaptureHintCard(
                      title: 'No hay capturas recientes',
                      body:
                          'Empieza con una idea, una imagen o una frase. MUSA la guardará en el workspace local.',
                    )
                  else
                    for (final note in notes.take(8))
                      _CaptureNoteTile(note: note),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CaptureNoteTile extends ConsumerWidget {
  const _CaptureNoteTile({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = MusaTheme.tokensOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: tokens.subtleBackground,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          onTap: () =>
              ref.read(narrativeWorkspaceProvider.notifier).selectNote(note.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title?.trim().isNotEmpty == true
                      ? note.title!
                      : 'Nota sin título',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  note.content.trim().isEmpty
                      ? 'Lista para capturar una idea breve.'
                      : note.content.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureHintCard extends StatelessWidget {
  const _CaptureHintCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.subtleBackground,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: tokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}
