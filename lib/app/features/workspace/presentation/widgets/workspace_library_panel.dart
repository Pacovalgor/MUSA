import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme.dart';
import '../../../../../modules/books/providers/workspace_providers.dart';
import '../../../../../modules/manuscript/models/document.dart';
import '../../../../../modules/manuscript/providers/document_providers.dart';
import '../../../../../modules/notes/models/note.dart';
import '../../../../../modules/notes/providers/note_providers.dart';

class WorkspaceLibraryPanel extends ConsumerWidget {
  const WorkspaceLibraryPanel({
    super.key,
    this.onDocumentSelected,
    this.onNoteSelected,
    this.showDocuments = true,
    this.showNotes = true,
    this.showWorkspaceSummary = true,
  });

  final ValueChanged<Document>? onDocumentSelected;
  final ValueChanged<Note>? onNoteSelected;
  final bool showDocuments;
  final bool showNotes;
  final bool showWorkspaceSummary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = MusaTheme.tokensOf(context);
    final books = ref.watch(booksProvider);
    final activeBook = ref.watch(activeBookProvider);
    final documents = ref.watch(documentsProvider);
    final notes = ref.watch(notesProvider);
    final currentDocument = ref.watch(currentDocumentProvider);
    final currentNote = ref.watch(currentNoteProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.sidebarBackground,
        border: Border(
          right: BorderSide(color: tokens.borderSoft),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          Text(
            'LIBRO ACTIVO',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            activeBook?.title ?? 'Sin libro activo',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (showWorkspaceSummary && activeBook != null) ...[
            const SizedBox(height: 10),
            Text(
              activeBook.summary.trim().isEmpty
                  ? 'Biblioteca narrativa local-first preparada para escritura, revisión y captura.'
                  : activeBook.summary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                    height: 1.45,
                  ),
            ),
          ],
          if (books.length > 1) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final book in books)
                  ChoiceChip(
                    label: Text(book.title),
                    selected: book.id == activeBook?.id,
                    onSelected: (_) => ref
                        .read(narrativeWorkspaceProvider.notifier)
                        .selectBook(book.id),
                  ),
              ],
            ),
          ],
          if (showDocuments) ...[
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'DOCUMENTOS',
              trailing: TextButton(
                onPressed: () => ref
                    .read(narrativeWorkspaceProvider.notifier)
                    .addDocument(title: 'Nuevo documento'),
                child: const Text('Nuevo'),
              ),
            ),
            const SizedBox(height: 8),
            if (documents.isEmpty)
              const _EmptySection(
                title: 'Todavía no hay documentos',
                body: 'Añade un documento para empezar a escribir.',
              )
            else
              for (final document in documents)
                _LibraryTile(
                  title: document.title,
                  subtitle: _documentSubtitle(document),
                  selected: currentDocument?.id == document.id,
                  onTap: () async {
                    await ref
                        .read(narrativeWorkspaceProvider.notifier)
                        .selectDocument(document.id);
                    onDocumentSelected?.call(document);
                  },
                ),
          ],
          if (showNotes) ...[
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'CAPTURAS Y NOTAS',
              trailing: TextButton(
                onPressed: () => ref
                    .read(narrativeWorkspaceProvider.notifier)
                    .createNote(
                      title: 'Captura rápida',
                      kind: NoteKind.idea,
                    ),
                child: const Text('Nueva'),
              ),
            ),
            const SizedBox(height: 8),
            if (notes.isEmpty)
              const _EmptySection(
                title: 'No hay notas recientes',
                body: 'Las capturas ligeras y notas editoriales aparecerán aquí.',
              )
            else
              for (final note in notes.take(6))
                _LibraryTile(
                  title: note.title?.trim().isNotEmpty == true
                      ? note.title!
                      : 'Nota sin título',
                  subtitle: _noteSubtitle(note),
                  selected: currentNote?.id == note.id,
                  onTap: () async {
                    await ref
                        .read(narrativeWorkspaceProvider.notifier)
                        .selectNote(note.id);
                    onNoteSelected?.call(note);
                  },
                ),
          ],
        ],
      ),
    );
  }

  static String _documentSubtitle(Document document) {
    final kindLabel = switch (document.kind) {
      DocumentKind.chapter => 'Capítulo',
      DocumentKind.scene => 'Escena',
      DocumentKind.noteDoc => 'Documento',
      DocumentKind.scratch => 'Borrador',
    };
    return '$kindLabel · ${document.wordCount} palabras';
  }

  static String _noteSubtitle(Note note) {
    final kindLabel = switch (note.kind) {
      NoteKind.research => 'Investigación',
      NoteKind.character => 'Personaje',
      NoteKind.scenario => 'Escenario',
      NoteKind.loose => 'Nota',
      NoteKind.idea => 'Captura',
      NoteKind.structural => 'Estructura',
    };
    final preview = note.content.trim();
    if (preview.isEmpty) return kindLabel;
    final compactPreview =
        preview.replaceAll(RegExp(r'\s+'), ' ').trim().substring(
              0,
              preview.length > 46 ? 46 : preview.length,
            );
    return '$kindLabel · $compactPreview';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    final selectedFill = Color.lerp(
          tokens.sidebarBackground,
          tokens.activeBackground,
          0.72,
        ) ??
        tokens.activeBackground;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? selectedFill : Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selected
                            ? tokens.textPrimary
                            : tokens.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                        height: 1.4,
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

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textMuted,
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
