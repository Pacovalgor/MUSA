import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../modules/books/providers/workspace_providers.dart';
import '../../modules/manuscript/models/document.dart';
import '../../modules/manuscript/providers/document_providers.dart';
import '../../modules/notes/providers/note_providers.dart';
import '../../modules/characters/providers/character_providers.dart';
import '../../modules/scenarios/providers/scenario_providers.dart';
import '../../ui/providers/ui_providers.dart';

class BookEditor extends ConsumerStatefulWidget {
  const BookEditor({super.key});

  @override
  ConsumerState<BookEditor> createState() => _BookEditorState();
}

class _BookEditorState extends ConsumerState<BookEditor> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _toneNotesController = TextEditingController();
  final _scrollController = ScrollController();

  Timer? _saveDebounce;
  String? _bookId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!mounted) return;
    ref.read(topBarContextVisibleProvider.notifier).state =
        _scrollController.offset > 48;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _summaryController.dispose();
    _toneNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(activeBookProvider);
    final documents = ref.watch(documentsProvider);
    final notes = ref.watch(notesProvider);
    final characters = ref.watch(charactersProvider);
    final scenarios = ref.watch(scenariosProvider);

    if (book == null) {
      return const Center(child: Text('No hay libro activo'));
    }

    _syncControllers(book.id, {
      _titleController: book.title,
      _subtitleController: book.subtitle ?? '',
      _summaryController: book.summary,
      _toneNotesController: book.toneNotes,
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final offset =
          _scrollController.hasClients ? _scrollController.offset : 0;
      ref.read(topBarContextVisibleProvider.notifier).state = offset > 48;
    });

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: MusaConstants.editorMaxWidth + 120,
          ),
          padding: const EdgeInsets.fromLTRB(64, 72, 64, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIBRO',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black38,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Título del libro',
                  border: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                onChanged: (_) => _scheduleSave(book.id),
              ),
              TextFormField(
                controller: _subtitleController,
                decoration: InputDecoration(
                  hintText: 'Subtítulo o bajada',
                  hintStyle: TextStyle(
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                  border: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                onChanged: (_) => _scheduleSave(book.id),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricPill(label: 'Capítulos', value: '${documents.length}'),
                  _MetricPill(label: 'Notas', value: '${notes.length}'),
                  _MetricPill(
                      label: 'Personajes', value: '${characters.length}'),
                  _MetricPill(
                      label: 'Escenarios', value: '${scenarios.length}'),
                ],
              ),
              const SizedBox(height: 36),
              _Section(
                title: 'Sinopsis',
                subtitle:
                    'Qué libro es este, qué promete y qué atmósfera persigue.',
                child: _LargeTextField(
                  controller: _summaryController,
                  hintText:
                      'Escribe una sinopsis breve, clara y útil para orientarte.',
                  onChanged: (_) => _scheduleSave(book.id),
                ),
              ),
              const SizedBox(height: 28),
              _Section(
                title: 'Notas de tono',
                subtitle:
                    'Intención, textura, ritmo o reglas editoriales del proyecto.',
                child: _LargeTextField(
                  controller: _toneNotesController,
                  hintText:
                      'Por ejemplo: seco, nocturno, urbano, tensión baja pero constante.',
                  onChanged: (_) => _scheduleSave(book.id),
                ),
              ),
              const SizedBox(height: 28),
              _Section(
                title: 'Índice',
                subtitle: 'Vista rápida de capítulos y estructura actual.',
                actionIcon: Icons.add,
                actionTooltip: 'Nuevo capítulo',
                onAction: () => _handleCreateChapter(context),
                child: Column(
                  children: documents.isEmpty
                      ? [
                          const _EmptyIndexState(),
                        ]
                      : [
                          _ReorderableIndexList(
                            documents: documents,
                            onOpen: (document) => ref
                                .read(narrativeWorkspaceProvider.notifier)
                                .selectDocument(document.id),
                            onReorder: (orderedIds) => ref
                                .read(narrativeWorkspaceProvider.notifier)
                                .reorderActiveBookDocuments(orderedIds),
                          ),
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncControllers(
      String bookId, Map<TextEditingController, String> values) {
    if (_bookId == bookId) return;
    _bookId = bookId;
    for (final entry in values.entries) {
      entry.key.text = entry.value;
    }
  }

  void _scheduleSave(String bookId) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      ref.read(narrativeWorkspaceProvider.notifier).updateBookDetails(
            bookId: bookId,
            title: _titleController.text.trim().isEmpty
                ? 'Libro sin título'
                : _titleController.text.trim(),
            subtitle: _subtitleController.text.trim(),
            clearSubtitle: _subtitleController.text.trim().isEmpty,
            summary: _summaryController.text.trim(),
            toneNotes: _toneNotesController.text.trim(),
          );
    });
  }

  Future<void> _handleCreateChapter(BuildContext context) async {
    final title = await _promptForText(
      context,
      title: 'Nuevo capítulo',
      label: 'Título',
      initialValue: 'Nuevo',
      actionLabel: 'Crear',
    );
    if (title == null || !mounted) return;

    await ref.read(narrativeWorkspaceProvider.notifier).addDocument(
          title: title,
          kind: DocumentKind.chapter,
          selectAfterCreate: false,
        );
  }

  Future<String?> _promptForText(
    BuildContext context, {
    required String title,
    required String label,
    required String initialValue,
    required String actionLabel,
  }) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: label),
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty) {
                Navigator.of(context).pop(trimmed);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) return;
                Navigator.of(context).pop(trimmed);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actionIcon,
    this.actionTooltip,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (actionIcon != null && onAction != null)
                IconButton(
                  onPressed: onAction,
                  tooltip: actionTooltip,
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.black38,
                    minimumSize: const Size(28, 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: Icon(actionIcon, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _LargeTextField extends StatelessWidget {
  const _LargeTextField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: null,
      minLines: 5,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.black.withValues(alpha: 0.14),
        ),
        filled: true,
        fillColor: const Color(0xFFF7F7F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.black.withValues(alpha: 0.03),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.black.withValues(alpha: 0.03),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.black87,
            height: 1.6,
          ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.035)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black45,
                ),
          ),
        ],
      ),
    );
  }
}

class _IndexItem extends StatelessWidget {
  const _IndexItem({
    required this.number,
    required this.title,
    required this.kind,
    required this.onTap,
    this.dragHandle,
  });

  final int number;
  final String title;
  final String kind;
  final VoidCallback onTap;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.035),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kind,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black26,
                          letterSpacing: 0.7,
                        ),
                  ),
                ],
              ),
            ),
            if (dragHandle != null) ...[
              const SizedBox(width: 8),
              dragHandle!,
            ] else
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black12,
              ),
          ],
        ),
      ),
    );
  }
}

class _ReorderableIndexList extends StatelessWidget {
  const _ReorderableIndexList({
    required this.documents,
    required this.onOpen,
    required this.onReorder,
  });

  final List<Document> documents;
  final void Function(Document document) onOpen;
  final Future<void> Function(List<String> orderedIds) onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      onReorder: (oldIndex, newIndex) {
        final reordered = List<Document>.from(documents);
        if (newIndex > oldIndex) newIndex -= 1;
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        onReorder(reordered.map((document) => document.id).toList());
      },
      itemBuilder: (context, index) {
        final document = documents[index];
        return Container(
          key: ValueKey(document.id),
          margin: const EdgeInsets.only(bottom: 10),
          child: _IndexItem(
            number: index + 1,
            title: document.title,
            kind: _documentKindLabel(document.kind),
            onTap: () => onOpen(document),
            dragHandle: ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.drag_indicator_rounded,
                  color: Colors.black12,
                  size: 17,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyIndexState extends StatelessWidget {
  const _EmptyIndexState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      child: Text(
        'Todavía no hay capítulos. Crea el primero con el +.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black38,
              height: 1.45,
            ),
      ),
    );
  }
}

String _documentKindLabel(DocumentKind kind) => switch (kind) {
      DocumentKind.chapter => 'CAPÍTULO',
      DocumentKind.scene => 'ESCENA',
      DocumentKind.noteDoc => 'NOTA',
      DocumentKind.scratch => 'BORRADOR',
    };
