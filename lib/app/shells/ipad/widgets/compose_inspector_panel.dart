import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../domain/ia/engine_status.dart';
import '../../../../editor/controller/editor_controller.dart';
import '../../../../editor/models/chapter_analysis.dart';
import '../../../../editor/models/fragment_analysis.dart';
import '../../../../modules/books/providers/workspace_providers.dart';
import '../../../../modules/continuity/providers/continuity_providers.dart';
import '../../../../modules/manuscript/models/document.dart';
import '../../../../modules/manuscript/providers/document_providers.dart';
import '../../../../modules/notes/models/note.dart';
import '../../../../modules/notes/providers/note_providers.dart';
import '../../../../muses/providers/musa_providers.dart';
import '../../../../services/ia_providers.dart';

enum ComposeInspectorSection { context, analysis, musa }

class ComposeInspectorPanel extends ConsumerStatefulWidget {
  const ComposeInspectorPanel({
    super.key,
    this.compact = false,
    this.onClose,
  });

  final bool compact;
  final VoidCallback? onClose;

  @override
  ConsumerState<ComposeInspectorPanel> createState() =>
      _ComposeInspectorPanelState();
}

class _ComposeInspectorPanelState extends ConsumerState<ComposeInspectorPanel> {
  ComposeInspectorSection _section = ComposeInspectorSection.context;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.panelBackground,
        border: widget.compact
            ? Border(top: BorderSide(color: tokens.borderSoft))
            : Border(left: BorderSide(color: tokens.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Compose Inspector',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (widget.onClose != null)
                      IconButton(
                        onPressed: widget.onClose,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                SegmentedButton<ComposeInspectorSection>(
                  segments: const [
                    ButtonSegment(
                      value: ComposeInspectorSection.context,
                      label: Text('Contexto'),
                      icon: Icon(Icons.menu_book_outlined),
                    ),
                    ButtonSegment(
                      value: ComposeInspectorSection.analysis,
                      label: Text('Análisis'),
                      icon: Icon(Icons.analytics_outlined),
                    ),
                    ButtonSegment(
                      value: ComposeInspectorSection.musa,
                      label: Text('Musa'),
                      icon: Icon(Icons.auto_awesome_outlined),
                    ),
                  ],
                  selected: {_section},
                  onSelectionChanged: (value) =>
                      setState(() => _section = value.first),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.borderSoft),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                switch (_section) {
                  ComposeInspectorSection.context => const _ContextSectionBody(),
                  ComposeInspectorSection.analysis =>
                    const _AnalysisSectionBody(),
                  ComposeInspectorSection.musa => const _MusaSectionBody(),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextSectionBody extends ConsumerWidget {
  const _ContextSectionBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(currentDocumentProvider);
    final workflowNotes = ref.watch(currentDocumentWorkflowNotesProvider);
    final allNotes = ref.watch(notesProvider);
    final linkedCharacters = ref.watch(currentDocumentCharactersProvider);
    final linkedScenarios = ref.watch(currentDocumentScenariosProvider);
    final continuity = ref.watch(continuityStateProvider);
    final activeBook = ref.watch(activeBookProvider);

    final relatedNotes = document == null
        ? const <Note>[]
        : allNotes
            .where((note) =>
                note.documentIds.contains(document.id) &&
                note.workflowType == null)
            .take(4)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InspectorCard(
          title: document?.title ?? activeBook?.title ?? 'Sin documento',
          subtitle: document == null
              ? 'Selecciona un documento para componer.'
              : '${document.wordCount} palabras · ${_documentKindLabel(document.kind)}',
          child: Text(
            _documentPreview(document?.content),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MusaTheme.tokensOf(context).textSecondary,
                  height: 1.5,
                ),
          ),
        ),
        const SizedBox(height: 12),
        _InspectorCard(
          title: 'Continuidad inmediata',
          child: Text(
            continuity?.projectSummary.trim().isNotEmpty == true
                ? continuity!.projectSummary
                : 'La continuidad viva del libro aparecerá aquí para orientar la composición del capítulo activo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MusaTheme.tokensOf(context).textSecondary,
                  height: 1.5,
                ),
          ),
        ),
        const SizedBox(height: 12),
        _PillsCard(
          title: 'Personajes vinculados',
          emptyLabel: 'Todavía no hay personajes vinculados a este documento.',
          values: linkedCharacters.map((item) => item.displayName).toList(),
        ),
        const SizedBox(height: 12),
        _PillsCard(
          title: 'Escenarios vinculados',
          emptyLabel: 'Todavía no hay escenarios vinculados a este documento.',
          values: linkedScenarios.map((item) => item.displayName).toList(),
        ),
        const SizedBox(height: 12),
        _NotesCard(
          title: 'Notas relacionadas',
          notes: relatedNotes,
          emptyLabel: 'No hay notas de contexto vinculadas a este documento.',
        ),
        const SizedBox(height: 12),
        _NotesCard(
          title: 'Flujo editorial',
          notes: workflowNotes,
          emptyLabel:
              'Las direcciones editoriales guardadas a partir del análisis aparecerán aquí.',
        ),
      ],
    );
  }
}

class _AnalysisSectionBody extends ConsumerWidget {
  const _AnalysisSectionBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final controller = ref.read(editorProvider.notifier);
    final selection = editorState.selectionContext;
    final fragment = editorState.currentFragmentAnalysis;
    final chapter = editorState.currentChapterAnalysis;
    final isChapterPending = editorState.isChapterAnalysisPending;
    final document = ref.watch(currentDocumentProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InspectorCard(
          title: 'Lectura editorial',
          subtitle: selection == null
              ? 'Sin selección activa'
              : 'Selección activa · ${selection.selectedText.trim().length} caracteres',
          actions: [
            FilledButton.tonal(
              onPressed: editorState.isProcessing ||
                      selection == null ||
                      document == null
                  ? null
                  : controller.runFragmentAnalysis,
              child: const Text('Entender fragmento'),
            ),
            OutlinedButton(
              onPressed: editorState.isProcessing ||
                      document == null ||
                      (document.content.trim().isEmpty)
                  ? null
                  : controller.runChapterAnalysis,
              child: Text(isChapterPending ? 'Leyendo…' : 'Entender capítulo'),
            ),
          ],
          child: Text(
            selection == null
                ? 'Selecciona un pasaje para análisis fino. Si no hay selección, puedes leer el capítulo completo.'
                : 'El análisis de fragmento usa la selección activa y el contexto vinculado del documento.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MusaTheme.tokensOf(context).textSecondary,
                  height: 1.5,
                ),
          ),
        ),
        const SizedBox(height: 12),
        if (fragment != null) _FragmentAnalysisCard(fragment: fragment),
        if (fragment != null) const SizedBox(height: 12),
        if (isChapterPending)
          const _InspectorCard(
            title: 'Análisis de capítulo',
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Leyendo el capítulo y detectando su función.'),
                  ),
                ],
              ),
            ),
          )
        else if (chapter != null)
          _ChapterAnalysisCard(analysis: chapter),
      ],
    );
  }
}

class _MusaSectionBody extends ConsumerWidget {
  const _MusaSectionBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final controller = ref.read(editorProvider.notifier);
    final availableMuses = ref.watch(availableMusesProvider);
    final iaStatus = ref.watch(iaServiceProvider).status.value;
    final selection = editorState.selectionContext;
    final suggestion = editorState.currentSuggestion;
    final isBusy = editorState.isProcessing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InspectorCard(
          title: 'Invocar Musa',
          subtitle: _engineStatusLabel(iaStatus),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selection == null
                    ? 'Selecciona un fragmento para trabajar con una Musa.'
                    : 'La Musa trabaja sobre la selección activa sin salir del flujo de composición.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MusaTheme.tokensOf(context).textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final musa in availableMuses)
                    FilledButton.tonal(
                      onPressed: selection == null || isBusy
                          ? null
                          : () => controller.runMusa(musa: musa),
                      child: Text(musa.shortName),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (selection != null)
          _InspectorCard(
            title: 'Selección activa',
            child: Text(
              selection.selectedText.trim(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MusaTheme.tokensOf(context).textPrimary,
                    height: 1.55,
                  ),
            ),
          ),
        if (selection != null) const SizedBox(height: 12),
        if (suggestion != null || editorState.streamingText != null || isBusy)
          _MusaSuggestionCard(
            state: editorState,
            onAccept: controller.acceptSuggestion,
            onDiscard: controller.discardSuggestion,
            onToggleCompare: controller.toggleComparisonMode,
          ),
      ],
    );
  }
}

class _FragmentAnalysisCard extends ConsumerWidget {
  const _FragmentAnalysisCard({required this.fragment});

  final FragmentAnalysis fragment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(editorProvider.notifier);

    return _InspectorCard(
      title: 'Resultado de fragmento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricLine(
            label: 'Momento',
            value: fragment.moment.title,
          ),
          if (fragment.narrator != null) ...[
            const SizedBox(height: 10),
            _SummaryBlock(
              title: fragment.narrator!.title,
              body: fragment.narrator!.summary,
              actionLabel: fragment.narrator!.action?.label,
              onAction: fragment.narrator!.action == null
                  ? null
                  : () => controller.performInsightAction(
                        fragment.narrator!.action!,
                      ),
            ),
          ],
          if (fragment.characters.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final item in fragment.characters.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SummaryBlock(
                  title: item.name,
                  body: item.summary,
                  actionLabel: item.action?.label,
                  onAction: item.action == null
                      ? null
                      : () => controller.performInsightAction(item.action!),
                ),
              ),
          ],
          if (fragment.scenario != null) ...[
            const SizedBox(height: 4),
            _SummaryBlock(
              title: fragment.scenario!.name,
              body: fragment.scenario!.summary,
              actionLabel: fragment.scenario!.action?.label,
              onAction: fragment.scenario!.action == null
                  ? null
                  : () => controller.performInsightAction(
                        fragment.scenario!.action!,
                      ),
            ),
          ],
          if (fragment.recommendation != null) ...[
            const SizedBox(height: 10),
            _SummaryBlock(
              title: 'Recomendación',
              body: fragment.recommendation!.reason,
              actionLabel: fragment.recommendation!.action.label,
              onAction: () => controller.performInsightAction(
                fragment.recommendation!.action,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChapterAnalysisCard extends ConsumerWidget {
  const _ChapterAnalysisCard({required this.analysis});

  final ChapterAnalysis analysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(editorProvider.notifier);

    return _InspectorCard(
      title: 'Resultado de capítulo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricLine(
            label: 'Función',
            value: analysis.chapterFunction.label,
          ),
          _MetricLine(
            label: 'Momento dominante',
            value: analysis.dominantNarrativeMoment.title,
          ),
          if (analysis.recommendation != null) ...[
            const SizedBox(height: 10),
            _SummaryBlock(
              title: 'Lectura editorial',
              body: analysis.recommendation!.message,
            ),
          ],
          if (analysis.mainCharacters.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PillsCard(
              title: 'Personajes clave',
              emptyLabel: '',
              values: analysis.mainCharacters.map((item) => item.name).toList(),
            ),
          ],
          if (analysis.mainScenario != null) ...[
            const SizedBox(height: 10),
            _SummaryBlock(
              title: analysis.mainScenario!.name,
              body: analysis.mainScenario!.summary,
            ),
          ],
          if (analysis.nextStep != null) ...[
            const SizedBox(height: 10),
            _SummaryBlock(
              title: 'Siguiente paso',
              body: analysis.nextStep!.label,
              actionLabel: _chapterNextStepLabel(analysis.nextStep!),
              onAction: () => controller.performChapterNextStep(
                analysis.nextStep!,
              ),
            ),
          ],
          if (_shouldShowExpandDirections(analysis.nextStep)) ...[
            const SizedBox(height: 10),
            _ExpandMomentDirectionsCard(analysis: analysis),
          ],
          if (_shouldShowConnectDirections(analysis.nextStep)) ...[
            const SizedBox(height: 10),
            _ConnectToPlotDirectionsCard(analysis: analysis),
          ],
          if (analysis.trajectory != null) ...[
            const SizedBox(height: 10),
            _SummaryBlock(
              title: 'Trayectoria',
              body: analysis.trajectory!.summary,
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpandMomentDirectionsCard extends ConsumerWidget {
  const _ExpandMomentDirectionsCard({required this.analysis});

  final ChapterAnalysis analysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(editorProvider.notifier);
    final aid = controller.buildExpandMomentEditorialAid(analysis);
    if (aid.directions.isEmpty) return const SizedBox.shrink();

    return _InspectorCard(
      title: 'Direcciones de composición',
      subtitle: aid.problem,
      child: Column(
        children: [
          for (final direction in aid.directions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SummaryBlock(
                title: direction.title,
                body: '${direction.summary}\n\n${direction.example}',
                actionLabel: 'Guardar como nota editorial',
                onAction: () async {
                  final ok =
                      await controller.useExpandMomentDirection(direction);
                  if (!context.mounted) return;
                  _showDirectionSavedSnackBar(context, ok);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ConnectToPlotDirectionsCard extends ConsumerWidget {
  const _ConnectToPlotDirectionsCard({required this.analysis});

  final ChapterAnalysis analysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(editorProvider.notifier);
    final aid = controller.buildConnectToPlotEditorialAid(analysis);
    if (aid.directions.isEmpty) return const SizedBox.shrink();

    return _InspectorCard(
      title: 'Conectar con trama',
      subtitle: aid.problem,
      child: Column(
        children: [
          for (final direction in aid.directions.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SummaryBlock(
                title: direction.title,
                body: '${direction.summary}\n\n${direction.example}',
                actionLabel: 'Guardar como nota editorial',
                onAction: () async {
                  final ok =
                      await controller.useConnectToPlotDirection(direction);
                  if (!context.mounted) return;
                  _showDirectionSavedSnackBar(context, ok);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MusaSuggestionCard extends StatelessWidget {
  const _MusaSuggestionCard({
    required this.state,
    required this.onAccept,
    required this.onDiscard,
    required this.onToggleCompare,
  });

  final EditorState state;
  final VoidCallback onAccept;
  final VoidCallback onDiscard;
  final VoidCallback onToggleCompare;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    final suggestion = state.currentSuggestion;
    final streamingText = state.streamingText;
    final body = suggestion?.suggestedText ?? streamingText ?? '';

    return _InspectorCard(
      title: state.activeMusa?.name ?? 'Revisión Musa',
      subtitle: _generationStatusLabel(state.generationPhase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.selectionContext != null && state.isComparisonMode) ...[
            Text(
              'Original',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: tokens.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              state.selectionContext!.selectedText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Propuesta',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: tokens.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            body.isEmpty
                ? 'La Musa está preparando una propuesta editorial.'
                : body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                  height: 1.55,
                ),
          ),
          if (suggestion?.editorComment != null) ...[
            const SizedBox(height: 12),
            Text(
              suggestion!.editorComment!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: suggestion == null ? null : onToggleCompare,
                child: Text(state.isComparisonMode ? 'Texto final' : 'Comparar'),
              ),
              FilledButton(
                onPressed: suggestion == null ? null : onAccept,
                child: const Text('Aceptar'),
              ),
              TextButton(
                onPressed: onDiscard,
                child: const Text('Descartar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InspectorCard extends StatelessWidget {
  const _InspectorCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.canvasBackground,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: tokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PillsCard extends StatelessWidget {
  const _PillsCard({
    required this.title,
    required this.values,
    required this.emptyLabel,
  });

  final String title;
  final List<String> values;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return _InspectorCard(
      title: title,
      child: values.isEmpty
          ? Text(
              emptyLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MusaTheme.tokensOf(context).textSecondary,
                  ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in values)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: MusaTheme.tokensOf(context).subtleBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MusaTheme.tokensOf(context).textPrimary,
                          ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _NotesCard extends ConsumerWidget {
  const _NotesCard({
    required this.title,
    required this.notes,
    required this.emptyLabel,
  });

  final String title;
  final List<Note> notes;
  final String emptyLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _InspectorCard(
      title: title,
      child: notes.isEmpty
          ? Text(
              emptyLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MusaTheme.tokensOf(context).textSecondary,
                  ),
            )
          : Column(
              children: [
                for (final note in notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => ref
                          .read(narrativeWorkspaceProvider.notifier)
                          .selectNote(note.id),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: MusaTheme.tokensOf(context).subtleBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title?.trim().isNotEmpty == true
                                  ? note.title!
                                  : 'Nota sin título',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: MusaTheme.tokensOf(context)
                                        .textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              note.content.trim().isEmpty
                                  ? 'Lista para desarrollarse.'
                                  : note.content.trim(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: MusaTheme.tokensOf(context)
                                        .textSecondary,
                                    height: 1.4,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () => ref
                                      .read(narrativeWorkspaceProvider.notifier)
                                      .selectNote(note.id),
                                  child: const Text('Abrir'),
                                ),
                                TextButton(
                                  onPressed: note.status == NoteStatus.used
                                      ? null
                                      : () => ref
                                          .read(narrativeWorkspaceProvider
                                              .notifier)
                                          .updateNoteStatus(
                                            note.id,
                                            NoteStatus.used,
                                          ),
                                  child: const Text('Usada'),
                                ),
                                TextButton(
                                  onPressed:
                                      note.status == NoteStatus.discarded
                                          ? null
                                          : () => ref
                                              .read(narrativeWorkspaceProvider
                                                  .notifier)
                                              .updateNoteStatus(
                                                note.id,
                                                NoteStatus.discarded,
                                              ),
                                  child: const Text('Descartar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MusaTheme.tokensOf(context).subtleBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MusaTheme.tokensOf(context).textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MusaTheme.tokensOf(context).textSecondary,
                  height: 1.45,
                ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

String _documentPreview(String? content) {
  final normalized = (content ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) {
    return 'Este documento todavía está en blanco. La herramienta Compose prioriza el texto activo y su contexto inmediato.';
  }
  if (normalized.length <= 180) return normalized;
  return '${normalized.substring(0, 179)}…';
}

String _documentKindLabel(DocumentKind kind) {
  return switch (kind) {
    DocumentKind.chapter => 'Capítulo',
    DocumentKind.scene => 'Escena',
    DocumentKind.noteDoc => 'Documento',
    DocumentKind.scratch => 'Borrador',
  };
}

String _engineStatusLabel(EngineStatus status) {
  return switch (status) {
    EngineStatus.ready => 'Motor editorial listo',
    EngineStatus.processing => 'Motor editorial trabajando',
    EngineStatus.initializing => 'Preparando motor editorial',
    EngineStatus.noModelLoaded => 'Sin modelo cargado',
    EngineStatus.unsupported => 'IA local no disponible en esta plataforma',
    EngineStatus.error => 'Motor editorial con error',
  };
}

String _generationStatusLabel(MusaGenerationPhase phase) {
  return switch (phase) {
    MusaGenerationPhase.idle => 'Lista para revisar',
    MusaGenerationPhase.invoking => 'Invocando Musa',
    MusaGenerationPhase.thinking => 'Pensando',
    MusaGenerationPhase.streaming => 'Escribiendo propuesta',
    MusaGenerationPhase.completed => 'Propuesta lista',
    MusaGenerationPhase.failed => 'La propuesta no pudo completarse',
  };
}

String _chapterNextStepLabel(ChapterNextStep step) {
  return switch (step.type) {
    NextStepType.createCharacter => 'Crear personaje',
    NextStepType.enrichCharacter => 'Enriquecer personaje',
    NextStepType.createScenario => 'Crear escenario',
    NextStepType.enrichScenario => 'Enriquecer escenario',
    NextStepType.strengthenConflict => 'Tensión',
    NextStepType.connectToPlot => 'Conectar trama',
    NextStepType.expandMoment => 'Expandir momento',
  };
}

bool _shouldShowExpandDirections(ChapterNextStep? step) {
  return step?.type == NextStepType.expandMoment ||
      step?.type == NextStepType.strengthenConflict;
}

bool _shouldShowConnectDirections(ChapterNextStep? step) {
  return step?.type == NextStepType.connectToPlot;
}

void _showDirectionSavedSnackBar(BuildContext context, bool ok) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        ok
            ? 'Dirección guardada como nota editorial.'
            : 'No se pudo guardar la dirección editorial.',
      ),
    ),
  );
}
