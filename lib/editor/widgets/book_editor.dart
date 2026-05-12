import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../modules/books/models/narrative_copilot.dart';
import '../../modules/books/models/novel_status.dart';
import '../../modules/books/providers/workspace_providers.dart';
import '../../modules/continuity/models/continuity_audit.dart';
import '../../modules/continuity/providers/continuity_providers.dart';
import '../../modules/editorial/models/chapter_editorial_map.dart';
import '../../modules/editorial/models/editorial_director.dart';
import '../../modules/editorial/providers/editorial_audit_providers.dart';
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
  final _subgenreController = TextEditingController();
  final _narrativeToneController = TextEditingController();
  final _readerPromiseController = TextEditingController();
  final _scrollController = ScrollController();

  Timer? _saveDebounce;
  Timer? _profileSaveDebounce;
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
    _profileSaveDebounce?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _summaryController.dispose();
    _toneNotesController.dispose();
    _subgenreController.dispose();
    _narrativeToneController.dispose();
    _readerPromiseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(activeBookProvider);
    final documents = ref.watch(documentsProvider);
    final notes = ref.watch(notesProvider);
    final characters = ref.watch(charactersProvider);
    final scenarios = ref.watch(scenariosProvider);
    final workspace = ref.watch(narrativeWorkspaceProvider).value;
    final storyState = workspace?.activeStoryState;
    final novelStatus = ref.watch(activeNovelStatusProvider);
    final continuityFindings = ref.watch(activeContinuityFindingsProvider);
    final chapterMap = ref.watch(activeChapterEditorialMapProvider);
    final editorialDirector = ref.watch(activeEditorialDirectorProvider);

    if (book == null) {
      return const Center(child: Text('No hay libro activo'));
    }

    _syncControllers(book.id, {
      _titleController: book.title,
      _subtitleController: book.subtitle ?? '',
      _summaryController: book.summary,
      _toneNotesController: book.toneNotes,
      _subgenreController: book.narrativeProfile.subgenre ?? '',
      _narrativeToneController: book.narrativeProfile.tone ?? '',
      _readerPromiseController: book.narrativeProfile.readerPromise ?? '',
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
                title: 'ADN narrativo',
                subtitle:
                    'La promesa editorial que orienta el estado narrativo del libro.',
                child: _NarrativeProfileEditor(
                  profile: book.narrativeProfile,
                  subgenreController: _subgenreController,
                  toneController: _narrativeToneController,
                  readerPromiseController: _readerPromiseController,
                  onChanged: (profile) => _updateNarrativeProfile(
                    book.id,
                    profile,
                  ),
                  onTextChanged: (_) => _scheduleNarrativeProfileSave(book.id),
                ),
              ),
              const SizedBox(height: 28),
              _Section(
                title: 'Estado de la novela',
                subtitle:
                    'Salud narrativa, memoria viva y comparación con el perfil profesional.',
                child: _NovelStatusPanel(
                  report: novelStatus,
                  storyState: storyState,
                ),
              ),
              const SizedBox(height: 28),
              _Section(
                title: 'Dirección editorial',
                subtitle:
                    'La prioridad más importante ahora mismo según memoria, riesgos y capítulos.',
                child: _EditorialDirectorPanel(report: editorialDirector),
              ),
              const SizedBox(height: 28),
              _Section(
                title: 'Riesgos de continuidad',
                subtitle:
                    'Promesas, contradicciones y elementos que necesitan ficha o pago narrativo.',
                child: _ContinuityAuditPanel(
                  findings: continuityFindings,
                  onDismiss: (id) => ref
                      .read(narrativeWorkspaceProvider.notifier)
                      .dismissContinuityFinding(id),
                ),
              ),
              const SizedBox(height: 28),
              _Section(
                title: 'Siguiente mejor movimiento',
                subtitle: 'Una recomendación breve para empujar la novela.',
                child: _NextBestMoveBlock(storyState: storyState),
              ),
              const SizedBox(height: 28),
              _Section(
                title: 'Mapa editorial por capítulos',
                subtitle:
                    'Prioridad local de tensión, ritmo, promesa o consecuencia por tramo.',
                child: _ChapterEditorialMapPanel(report: chapterMap),
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

  void _scheduleNarrativeProfileSave(String bookId) {
    _profileSaveDebounce?.cancel();
    _profileSaveDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      _updateNarrativeProfile(
        bookId,
        _currentNarrativeProfile(
            ref.read(activeBookProvider)?.narrativeProfile),
      );
    });
  }

  void _updateNarrativeProfile(String bookId, BookNarrativeProfile profile) {
    if (!mounted) return;
    ref.read(narrativeWorkspaceProvider.notifier).updateBookNarrativeProfile(
          bookId: bookId,
          narrativeProfile: profile,
        );
  }

  BookNarrativeProfile _currentNarrativeProfile(
    BookNarrativeProfile? current,
  ) {
    final base = current ?? const BookNarrativeProfile();
    return base.copyWith(
      subgenre: _subgenreController.text.trim(),
      clearSubgenre: _subgenreController.text.trim().isEmpty,
      tone: _narrativeToneController.text.trim(),
      clearTone: _narrativeToneController.text.trim().isEmpty,
      readerPromise: _readerPromiseController.text.trim(),
      clearReaderPromise: _readerPromiseController.text.trim().isEmpty,
    );
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

class _NarrativeProfileEditor extends StatelessWidget {
  const _NarrativeProfileEditor({
    required this.profile,
    required this.subgenreController,
    required this.toneController,
    required this.readerPromiseController,
    required this.onChanged,
    required this.onTextChanged,
  });

  final BookNarrativeProfile profile;
  final TextEditingController subgenreController;
  final TextEditingController toneController;
  final TextEditingController readerPromiseController;
  final ValueChanged<BookNarrativeProfile> onChanged;
  final ValueChanged<String> onTextChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _EnumField<BookPrimaryGenre>(
              label: 'Género',
              value: profile.primaryGenre,
              values: BookPrimaryGenre.values,
              labelFor: _primaryGenreLabel,
              onChanged: (value) => onChanged(profile.copyWith(
                primaryGenre: value,
              )),
            ),
            _EnumField<NarrativeScale>(
              label: 'Escala',
              value: profile.scale,
              values: NarrativeScale.values,
              labelFor: _scaleLabel,
              onChanged: (value) => onChanged(profile.copyWith(scale: value)),
            ),
            _EnumField<TargetPace>(
              label: 'Ritmo objetivo',
              value: profile.targetPace,
              values: TargetPace.values,
              labelFor: _targetPaceLabel,
              onChanged: (value) => onChanged(profile.copyWith(
                targetPace: value,
              )),
            ),
            _EnumField<DominantPriority>(
              label: 'Prioridad',
              value: profile.dominantPriority,
              values: DominantPriority.values,
              labelFor: _dominantPriorityLabel,
              onChanged: (value) => onChanged(profile.copyWith(
                dominantPriority: value,
              )),
            ),
            _EnumField<EndingType>(
              label: 'Final',
              value: profile.endingType,
              values: EndingType.values,
              labelFor: _endingTypeLabel,
              onChanged: (value) => onChanged(profile.copyWith(
                endingType: value,
              )),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InlineTextField(
          controller: subgenreController,
          label: 'Subgénero',
          hintText: 'noir, space opera, fantasía urbana...',
          onChanged: onTextChanged,
        ),
        const SizedBox(height: 10),
        _InlineTextField(
          controller: toneController,
          label: 'Tono',
          hintText: 'seco, íntimo, oscuro, luminoso...',
          onChanged: onTextChanged,
        ),
        const SizedBox(height: 10),
        _InlineTextField(
          controller: readerPromiseController,
          label: 'Promesa de lectura',
          hintText: 'Qué experiencia debe recibir la lectora.',
          onChanged: onTextChanged,
          minLines: 2,
        ),
      ],
    );
  }
}

class _EnumField<T extends Enum> extends StatelessWidget {
  const _EnumField({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: values
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(labelFor(item), overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        decoration: _fieldDecoration(context, label),
        borderRadius: BorderRadius.circular(8),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _InlineTextField extends StatelessWidget {
  const _InlineTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.onChanged,
    this.minLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final ValueChanged<String> onChanged;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines == 1 ? 1 : 4,
      onChanged: onChanged,
      decoration: _fieldDecoration(context, label).copyWith(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.18)),
      ),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.black87,
            height: 1.45,
          ),
    );
  }
}

class _NovelStatusPanel extends StatelessWidget {
  const _NovelStatusPanel({
    required this.report,
    required this.storyState,
  });

  final NovelStatusReport? report;
  final StoryState? storyState;

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return const _NarrativeEmptyText(
        'Aún no hay memoria narrativa calculada. Se calculará al guardar o analizar un capítulo.',
      );
    }

    final criticalSignals = report!.signals.take(3).toList();
    final actions = report!.nextActions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _healthColor(report!.healthLevel),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _healthLabel(report!.healthLevel),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    '${report!.overallScore}/100',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricPill(
                    label: 'Tensión',
                    value: '${report!.tensionScore}',
                  ),
                  _MetricPill(
                    label: 'Ritmo',
                    value: '${report!.rhythmScore}',
                  ),
                  _MetricPill(
                    label: 'Promesa',
                    value: '${report!.promiseScore}',
                  ),
                  _MetricPill(
                    label: 'Memoria',
                    value: '${report!.memoryScore}',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (criticalSignals.isNotEmpty)
          Column(
            children: criticalSignals
                .map(
                  (signal) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NovelStatusSignalRow(signal: signal),
                  ),
                )
                .toList(),
          ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Acciones siguientes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          _NarrativeBulletList(items: actions),
        ],
        if (report!.professionalComparisons.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ProfessionalComparisonList(
            comparisons: report!.professionalComparisons.take(3).toList(),
          ),
        ],
        const SizedBox(height: 14),
        _StoryStateSummary(storyState: storyState),
      ],
    );
  }

  Color _healthColor(NovelStatusHealth health) {
    return switch (health) {
      NovelStatusHealth.critical => const Color(0xFFB42318),
      NovelStatusHealth.watch => const Color(0xFFB54708),
      NovelStatusHealth.stable => const Color(0xFF027A48),
      NovelStatusHealth.strong => const Color(0xFF175CD3),
    };
  }

  String _healthLabel(NovelStatusHealth health) {
    return switch (health) {
      NovelStatusHealth.critical => 'Necesita atención',
      NovelStatusHealth.watch => 'En vigilancia',
      NovelStatusHealth.stable => 'Estable',
      NovelStatusHealth.strong => 'Fuerte',
    };
  }
}

class _NovelStatusSignalRow extends StatelessWidget {
  const _NovelStatusSignalRow({required this.signal});

  final NovelStatusSignal signal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _areaLabel(signal.area),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black38,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  signal.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            signal.detail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.45,
                ),
          ),
          if (signal.evidence.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              signal.evidence,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black38,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _areaLabel(NovelStatusArea area) {
    return switch (area) {
      NovelStatusArea.tension => 'TENSIÓN',
      NovelStatusArea.rhythm => 'RITMO',
      NovelStatusArea.promise => 'PROMESA',
      NovelStatusArea.memory => 'MEMORIA',
      NovelStatusArea.professional => 'CORPUS',
    };
  }
}

class _ProfessionalComparisonList extends StatelessWidget {
  const _ProfessionalComparisonList({required this.comparisons});

  final List<ProfessionalMetricComparison> comparisons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparación profesional',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ...comparisons.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.metric,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ),
                Text(
                  item.differenceLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorialDirectorPanel extends StatelessWidget {
  const _EditorialDirectorPanel({required this.report});

  final EditorialDirectorReport? report;

  @override
  Widget build(BuildContext context) {
    if (report == null || report!.missions.isEmpty) {
      return const _NarrativeEmptyText(
        'Aún no hay suficientes señales para proponer una dirección editorial.',
      );
    }

    final missions = report!.missions.take(3).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: _readinessColor(report!.readiness).withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _readinessColor(report!.readiness),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _readinessLabel(report!.readiness),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report!.summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 14),
          ...missions.map(
            (mission) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EditorialDirectorMissionRow(mission: mission),
            ),
          ),
        ],
      ),
    );
  }

  Color _readinessColor(EditorialDirectorReadiness readiness) {
    return switch (readiness) {
      EditorialDirectorReadiness.setup => const Color(0xFF175CD3),
      EditorialDirectorReadiness.intervention => const Color(0xFFB42318),
      EditorialDirectorReadiness.revision => const Color(0xFFB54708),
      EditorialDirectorReadiness.advance => const Color(0xFF027A48),
    };
  }

  String _readinessLabel(EditorialDirectorReadiness readiness) {
    return switch (readiness) {
      EditorialDirectorReadiness.setup => 'Preparar base',
      EditorialDirectorReadiness.intervention => 'Intervenir antes de avanzar',
      EditorialDirectorReadiness.revision => 'Revisión prioritaria',
      EditorialDirectorReadiness.advance => 'Avanzar con seguimiento',
    };
  }
}

class _EditorialDirectorMissionRow extends StatelessWidget {
  const _EditorialDirectorMissionRow({required this.mission});

  final EditorialDirectorMission mission;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _priorityColor(mission.priority).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _priorityLabel(mission.priority),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _priorityColor(mission.priority),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mission.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mission.detail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            mission.action,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (mission.evidence.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              mission.evidence,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black38,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Color _priorityColor(EditorialDirectorPriority priority) {
    return switch (priority) {
      EditorialDirectorPriority.critical => const Color(0xFFB42318),
      EditorialDirectorPriority.high => const Color(0xFFB54708),
      EditorialDirectorPriority.normal => const Color(0xFF175CD3),
    };
  }

  String _priorityLabel(EditorialDirectorPriority priority) {
    return switch (priority) {
      EditorialDirectorPriority.critical => 'CRÍTICO',
      EditorialDirectorPriority.high => 'ALTA',
      EditorialDirectorPriority.normal => 'NORMAL',
    };
  }
}

class _ContinuityAuditPanel extends StatelessWidget {
  const _ContinuityAuditPanel({
    required this.findings,
    required this.onDismiss,
  });

  final List<ContinuityFinding> findings;
  final void Function(String id) onDismiss;

  @override
  Widget build(BuildContext context) {
    if (findings.isEmpty) {
      return const _NarrativeEmptyText(
        'No hay riesgos de continuidad detectados en el libro activo.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: findings.take(4).map((finding) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ContinuityFindingRow(
            finding: finding,
            onDismiss: () => onDismiss(finding.id),
          ),
        );
      }).toList(),
    );
  }
}

class _ContinuityFindingRow extends StatelessWidget {
  const _ContinuityFindingRow({
    required this.finding,
    required this.onDismiss,
  });

  final ContinuityFinding finding;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _severityColor(finding.severity).withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _severityColor(finding.severity),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _findingTypeLabel(finding.type),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black38,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  finding.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Text(
                  'Descartar',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            finding.detail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.45,
                ),
          ),
          if (finding.evidence.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              finding.evidence,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black38,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          if (finding.action.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              finding.action,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    height: 1.45,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Color _severityColor(ContinuityFindingSeverity severity) {
    return switch (severity) {
      ContinuityFindingSeverity.info => const Color(0xFF175CD3),
      ContinuityFindingSeverity.warning => const Color(0xFFB54708),
      ContinuityFindingSeverity.critical => const Color(0xFFB42318),
    };
  }

  String _findingTypeLabel(ContinuityFindingType type) {
    return switch (type) {
      ContinuityFindingType.unresolvedPromise => 'PROMESA',
      ContinuityFindingType.contradiction => 'CONTRADICCIÓN',
      ContinuityFindingType.untrackedCharacter => 'PERSONAJE',
      ContinuityFindingType.untrackedScenario => 'ESCENARIO',
      ContinuityFindingType.repeatedPattern => 'PATRÓN',
    };
  }
}

class _StoryStateSummary extends StatelessWidget {
  const _StoryStateSummary({required this.storyState});

  final StoryState? storyState;

  @override
  Widget build(BuildContext context) {
    if (storyState == null) {
      return const _NarrativeEmptyText(
        'Aún no hay estado narrativo. Se calculará al guardar o analizar un capítulo.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricPill(
                label: 'Acto', value: _actLabel(storyState!.currentAct)),
            _MetricPill(
              label: 'Función',
              value: _chapterFunctionLabel(storyState!.currentChapterFunction),
            ),
            _MetricPill(
              label: 'Tensión',
              value: '${storyState!.globalTension}/100',
            ),
            _MetricPill(
              label: 'Ritmo',
              value: _rhythmLabel(storyState!.perceivedRhythm),
            ),
          ],
        ),
        if (storyState!.diagnostics.isNotEmpty) ...[
          const SizedBox(height: 14),
          _NarrativeBulletList(items: storyState!.diagnostics.take(3).toList()),
        ],
      ],
    );
  }
}

class _NextBestMoveBlock extends StatelessWidget {
  const _NextBestMoveBlock({required this.storyState});

  final StoryState? storyState;

  @override
  Widget build(BuildContext context) {
    final move = storyState?.nextBestMove.trim();
    final reason = storyState?.nextBestMoveReason.trim();
    if (move == null || move.isEmpty) {
      return const _NarrativeEmptyText(
        'Define el ADN narrativo o analiza un capítulo para recibir una recomendación.',
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            move,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black87,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Motivo: $reason',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black45,
                    height: 1.45,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChapterEditorialMapPanel extends StatelessWidget {
  const _ChapterEditorialMapPanel({required this.report});

  final ChapterEditorialMapReport? report;

  @override
  Widget build(BuildContext context) {
    final chapters = report?.chapters ?? const [];
    if (chapters.isEmpty) {
      return const _NarrativeEmptyText(
        'Aún no hay capítulos narrativos suficientes para construir el mapa editorial.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...chapters.take(6).map(
              (chapter) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChapterEditorialMapRow(chapter: chapter),
              ),
            ),
        if (report!.summaryActions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Prioridades del tramo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          _NarrativeBulletList(items: report!.summaryActions.take(3).toList()),
        ],
      ],
    );
  }
}

class _ChapterEditorialMapRow extends StatelessWidget {
  const _ChapterEditorialMapRow({required this.chapter});

  final ChapterEditorialMapItem chapter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: _needColor(chapter.primaryNeed).withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _needColor(chapter.primaryNeed),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _stageLabel(chapter.stage),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black38,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chapter.title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                _needLabel(chapter.primaryNeed),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricPill(label: 'Tensión', value: '${chapter.tensionScore}'),
              _MetricPill(label: 'Ritmo', value: '${chapter.rhythmScore}'),
              _MetricPill(label: 'Promesa', value: '${chapter.promiseScore}'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            chapter.nextAction,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${chapter.professionalRhythmLabel} · ${chapter.evidence}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black38,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Color _needColor(ChapterEditorialNeed need) {
    return switch (need) {
      ChapterEditorialNeed.tension => const Color(0xFFB42318),
      ChapterEditorialNeed.rhythm => const Color(0xFFB54708),
      ChapterEditorialNeed.promise => const Color(0xFF7A5AF8),
      ChapterEditorialNeed.consequence => const Color(0xFF175CD3),
      ChapterEditorialNeed.stable => const Color(0xFF027A48),
    };
  }

  String _stageLabel(ChapterEditorialStage stage) {
    return switch (stage) {
      ChapterEditorialStage.opening => 'APERTURA',
      ChapterEditorialStage.middle => 'NUDO',
      ChapterEditorialStage.closing => 'CIERRE',
    };
  }

  String _needLabel(ChapterEditorialNeed need) {
    return switch (need) {
      ChapterEditorialNeed.tension => 'TENSIÓN',
      ChapterEditorialNeed.rhythm => 'RITMO',
      ChapterEditorialNeed.promise => 'PROMESA',
      ChapterEditorialNeed.consequence => 'CONSECUENCIA',
      ChapterEditorialNeed.stable => 'ESTABLE',
    };
  }
}

class _NarrativeBulletList extends StatelessWidget {
  const _NarrativeBulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $item',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      height: 1.45,
                    ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NarrativeEmptyText extends StatelessWidget {
  const _NarrativeEmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.black38,
            height: 1.45,
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

InputDecoration _fieldDecoration(BuildContext context, String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF7F7F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.03)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.03)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

String _primaryGenreLabel(BookPrimaryGenre value) => switch (value) {
      BookPrimaryGenre.literary => 'Literaria',
      BookPrimaryGenre.thriller => 'Thriller',
      BookPrimaryGenre.scienceFiction => 'Ciencia ficción',
      BookPrimaryGenre.fantasy => 'Fantasía',
      BookPrimaryGenre.mystery => 'Misterio',
      BookPrimaryGenre.romance => 'Romance',
      BookPrimaryGenre.historical => 'Histórica',
      BookPrimaryGenre.other => 'Otra',
    };

String _scaleLabel(NarrativeScale value) => switch (value) {
      NarrativeScale.intimate => 'Íntima',
      NarrativeScale.ensemble => 'Coral',
      NarrativeScale.epic => 'Épica',
    };

String _targetPaceLabel(TargetPace value) => switch (value) {
      TargetPace.slow => 'Lento',
      TargetPace.measured => 'Medido',
      TargetPace.agile => 'Ágil',
      TargetPace.urgent => 'Urgente',
    };

String _dominantPriorityLabel(DominantPriority value) => switch (value) {
      DominantPriority.character => 'Personaje',
      DominantPriority.plot => 'Trama',
      DominantPriority.atmosphere => 'Atmósfera',
      DominantPriority.idea => 'Idea',
      DominantPriority.tension => 'Tensión',
    };

String _endingTypeLabel(EndingType value) => switch (value) {
      EndingType.open => 'Abierto',
      EndingType.bittersweet => 'Agridulce',
      EndingType.resolved => 'Resuelto',
      EndingType.tragic => 'Trágico',
      EndingType.ambiguous => 'Ambiguo',
    };

String _actLabel(StoryAct value) => switch (value) {
      StoryAct.actI => 'I',
      StoryAct.actII => 'II',
      StoryAct.actIII => 'III',
    };

String _chapterFunctionLabel(CurrentChapterFunction value) => switch (value) {
      CurrentChapterFunction.introduce => 'Introduce',
      CurrentChapterFunction.complicate => 'Complica',
      CurrentChapterFunction.confront => 'Confronta',
      CurrentChapterFunction.reveal => 'Revela',
      CurrentChapterFunction.transition => 'Transición',
      CurrentChapterFunction.deepenCharacter => 'Personaje',
      CurrentChapterFunction.setup => 'Preparación',
    };

String _rhythmLabel(PerceivedRhythm value) => switch (value) {
      PerceivedRhythm.slow => 'Lento',
      PerceivedRhythm.steady => 'Estable',
      PerceivedRhythm.uneven => 'Irregular',
      PerceivedRhythm.tense => 'Tenso',
      PerceivedRhythm.rushed => 'Precipitado',
    };
