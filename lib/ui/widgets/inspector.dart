import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../modules/books/models/book.dart';
import '../../modules/books/models/narrative_workspace.dart';
import '../../modules/books/models/workspace_snapshot.dart';
import '../../modules/books/models/writing_settings.dart';
import '../../modules/books/providers/workspace_providers.dart';
import '../../modules/characters/models/character.dart';
import '../../modules/characters/providers/character_providers.dart';
import '../../modules/characters/widgets/character_picker_sheet.dart';
import '../../modules/manuscript/models/document.dart';
import '../../modules/manuscript/providers/document_providers.dart';
import '../../modules/notes/models/note.dart';
import '../../modules/notes/providers/note_providers.dart';
import '../../modules/scenarios/models/scenario.dart';
import '../../modules/scenarios/providers/scenario_providers.dart';
import '../../modules/scenarios/widgets/scenario_picker_sheet.dart';
import '../../core/theme.dart';
import '../../editor/controller/editor_controller.dart';
import '../../editor/models/chapter_analysis.dart';

class MusaInspector extends ConsumerWidget {
  const MusaInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = MusaTheme.tokensOf(context);
    final workspace = ref.watch(narrativeWorkspaceProvider).value;
    final book = ref.watch(activeBookProvider);
    final editorMode = ref.watch(editorModeProvider);
    final writingSettings = ref.watch(writingSettingsProvider);
    final document = ref.watch(currentDocumentProvider);
    final note = ref.watch(currentNoteProvider);
    final character = ref.watch(selectedCharacterProvider);
    final scenario = ref.watch(selectedScenarioProvider);
    final documents = ref.watch(documentsProvider);
    final notes = ref.watch(notesProvider);
    final characters = ref.watch(charactersProvider);
    final scenarios = ref.watch(scenariosProvider);
    final linkedCharacters = ref.watch(currentDocumentCharactersProvider);
    final linkedScenarios = ref.watch(currentDocumentScenariosProvider);
    final characterDocuments = ref.watch(selectedCharacterDocumentsProvider);
    final scenarioDocuments = ref.watch(selectedScenarioDocumentsProvider);
    final snapshots = ref.watch(snapshotsProvider);
    final continuity = workspace?.activeContinuityState;

    return Container(
      width: MusaConstants.inspectorWidth,
      decoration: BoxDecoration(
        color: tokens.panelBackground,
        border: Border(left: BorderSide(color: tokens.borderSoft)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 24),
            _PanelSection(
              title: 'Proyecto',
              child: _BookCard(
                book: book,
                documentsCount: documents.length,
                notesCount: notes.length,
                charactersCount: characters.length,
                scenariosCount: scenarios.length,
                onOpen: book == null
                    ? null
                    : () => ref
                        .read(narrativeWorkspaceProvider.notifier)
                        .openActiveBookView(),
              ),
            ),
            const SizedBox(height: 18),
            switch (editorMode) {
              WorkspaceEditorMode.book => _buildBookMode(
                  context,
                  ref,
                  book,
                  documents,
                  notes,
                  characters,
                  scenarios,
                  snapshots,
                ),
              WorkspaceEditorMode.document => _buildDocumentMode(
                  context,
                  ref,
                  writingSettings,
                  document,
                  note,
                  linkedCharacters,
                  linkedScenarios,
                  characters,
                  scenarios,
                ),
              WorkspaceEditorMode.note => _buildNoteMode(
                  context,
                  ref,
                  note,
                  documents,
                ),
              WorkspaceEditorMode.character => _buildCharacterMode(
                  context,
                  ref,
                  character,
                  characterDocuments,
                ),
              WorkspaceEditorMode.scenario => _buildScenarioMode(
                  context,
                  ref,
                  scenario,
                  scenarioDocuments,
                ),
            },
            const SizedBox(height: 18),
            _PanelSection(
              title: 'Continuidad',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReadOnlyBlock(
                    label: 'Resumen vivo',
                    text: continuity?.projectSummary.isNotEmpty == true
                        ? continuity!.projectSummary
                        : 'Todavía no hay un resumen de continuidad consolidado.',
                  ),
                  const SizedBox(height: 14),
                  _MetricRow(
                    label: 'Tensión actual',
                    value: continuity?.currentTensionLevel ?? 'neutral',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookMode(
    BuildContext context,
    WidgetRef ref,
    Book? book,
    List<Document> documents,
    List<Note> notes,
    List<Character> characters,
    List<Scenario> scenarios,
    List<WorkspaceSnapshot> snapshots,
  ) {
    if (book == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _PanelSection(
          title: 'Libro activo',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EditableTextBlock(
                label: 'Sinopsis',
                initialValue: book.summary,
                hintText: 'Añade una sinopsis breve para orientar el proyecto.',
                minLines: 5,
                onSaved: (value) => ref
                    .read(narrativeWorkspaceProvider.notifier)
                    .updateBookDetails(
                      bookId: book.id,
                      summary: value,
                    ),
              ),
              const SizedBox(height: 14),
              _EditableTextBlock(
                label: 'Notas de tono',
                initialValue: book.toneNotes,
                hintText:
                    'Tono, voz, atmósfera, ritmo o cualquier regla editorial del libro.',
                minLines: 4,
                onSaved: (value) => ref
                    .read(narrativeWorkspaceProvider.notifier)
                    .updateBookDetails(
                      bookId: book.id,
                      toneNotes: value,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _PanelSection(
          title: 'Índice',
          trailing: '${documents.length}',
          child: documents.isEmpty
              ? const _MutedMessage('Todavía no hay capítulos.')
              : _ReorderableIndexList(
                  documents: documents,
                  onOpen: (document) => ref
                      .read(narrativeWorkspaceProvider.notifier)
                      .selectDocument(document.id),
                  onReorder: (orderedIds) => ref
                      .read(narrativeWorkspaceProvider.notifier)
                      .reorderActiveBookDocuments(orderedIds),
                ),
        ),
        const SizedBox(height: 18),
        _PanelSection(
          title: 'Mapa narrativo',
          child: Column(
            children: [
              _MetricRow(label: 'Notas', value: '${notes.length}'),
              _MetricRow(label: 'Personajes', value: '${characters.length}'),
              _MetricRow(label: 'Escenarios', value: '${scenarios.length}'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _PanelSection(
          title: 'Snapshots',
          trailingActionLabel: 'Guardar',
          onTrailingAction: () => ref
              .read(narrativeWorkspaceProvider.notifier)
              .createSnapshot(),
          child: snapshots.isEmpty
              ? const _MutedMessage(
                  'Guarda estados del libro para volver atrás sin miedo.',
                )
              : Column(
                  children: snapshots.take(4).map((snapshot) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration:
                            MusaTheme.panelDecoration(context, radius: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    snapshot.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: MusaTheme.tokensOf(context)
                                              .textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateTime(snapshot.createdAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: MusaTheme.tokensOf(context)
                                              .textMuted,
                                          letterSpacing: 0.3,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => ref
                                  .read(narrativeWorkspaceProvider.notifier)
                                  .restoreSnapshot(snapshot.id),
                              child: const Text('Restaurar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  _DocumentContinuityState _buildDocumentContinuityState(
    Document document,
    List<Character> linkedCharacters,
    List<Scenario> linkedScenarios,
    ChapterAnalysis? analysis,
  ) {
    final alerts = <String>[];

    if (analysis != null) {
      for (final item in analysis.mainCharacters) {
        if (item.existingCharacterId == null) {
          alerts.add('Aparece ${item.name} sin ficha o vínculo claro.');
        } else if (!document.characterIds.contains(item.existingCharacterId)) {
          alerts.add('${item.name} pesa en el capítulo pero no está vinculada.');
        }
      }
      final mainScenario = analysis.mainScenario;
      if (mainScenario != null) {
        if (mainScenario.existingScenarioId == null) {
          alerts.add(
            'El espacio "${mainScenario.name}" gana peso sin escenario consolidado.',
          );
        } else if (!document.scenarioIds.contains(mainScenario.existingScenarioId)) {
          alerts.add(
            '${mainScenario.name} pesa en el capítulo pero no está vinculado.',
          );
        }
      }
    }

    return _DocumentContinuityState(
      activeCharacters: linkedCharacters,
      activeScenarios: linkedScenarios,
      alerts: alerts,
    );
  }

  Widget _buildContinuityPanel(
    BuildContext context,
    _DocumentContinuityState continuityState,
  ) {
    if (continuityState.activeCharacters.isEmpty &&
        continuityState.activeScenarios.isEmpty &&
        continuityState.alerts.isEmpty) {
      return const _MutedMessage(
        'Aquí aparecerán señales de continuidad de este capítulo.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (continuityState.activeCharacters.isNotEmpty)
          _MetricRow(
            label: 'Personajes activos',
            value: continuityState.activeCharacters
                .map((item) => item.displayName)
                .join(', '),
          ),
        if (continuityState.activeScenarios.isNotEmpty)
          _MetricRow(
            label: 'Escenarios activos',
            value: continuityState.activeScenarios
                .map((item) => item.displayName)
                .join(', '),
          ),
        if (continuityState.alerts.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...continuityState.alerts.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• $item',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MusaTheme.tokensOf(context).warningText,
                      height: 1.35,
                    ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _workflowSummary(Note note) {
    final workflowLabel = switch (note.workflowType) {
      EditorialWorkflowType.expandMoment => 'Expandir momento',
      EditorialWorkflowType.connectToPlot => 'Conectar con trama',
      null => 'Dirección editorial',
    };
    return '$workflowLabel · ${_noteStatusLabel(note.status)}';
  }

  Widget _buildDocumentMode(
    BuildContext context,
    WidgetRef ref,
    WritingSettings writingSettings,
    Document? document,
    Note? focusedNote,
    List<Character> linkedCharacters,
    List<Scenario> linkedScenarios,
    List<Character> allCharacters,
    List<Scenario> allScenarios,
  ) {
    if (document == null) {
      return const SizedBox.shrink();
    }
    final chapterAnalysis =
        ref.watch(editorProvider.select((state) => state.currentChapterAnalysis));
    final workflowNotes = ref.watch(currentDocumentWorkflowNotesProvider);
    final continuityState = _buildDocumentContinuityState(
      document,
      linkedCharacters,
      linkedScenarios,
      chapterAnalysis,
    );

    final suggestion = _buildDocumentSuggestion(
      context,
      ref,
      document,
      linkedCharacters,
      linkedScenarios,
      allCharacters,
      allScenarios,
    );

    return Column(
      children: [
        if (writingSettings.noteOpenBehavior == NoteOpenBehavior.inspector &&
            focusedNote != null &&
            focusedNote.documentIds.contains(document.id)) ...[
          _buildInspectorNotePanel(
            context,
            ref,
            focusedNote,
            canPromoteToEditor: true,
          ),
          const SizedBox(height: 14),
        ],
        if (suggestion != null) ...[
          suggestion,
          const SizedBox(height: 14),
        ],
        _PanelSection(
          title: 'Capítulo',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LinkTile(
                title: document.title,
                subtitle: _documentKindLabel(document.kind),
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _MetricRow(label: 'Palabras', value: '${document.wordCount}'),
              _MetricRow(
                label: 'Última edición',
                value: _formatDateTime(document.updatedAt),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _PanelSection(
          title: 'Contexto del capítulo',
          child: _MutedMessage(
            linkedCharacters.isEmpty && linkedScenarios.isEmpty
                ? 'Aquí verás el contexto narrativo de este capítulo.'
                : 'Personajes y escenarios se reúnen aquí mientras escribes.',
          ),
        ),
        const SizedBox(height: 18),
        _PanelSection(
          title: 'Continuidad',
          child: _buildContinuityPanel(context, continuityState),
        ),
        const SizedBox(height: 18),
        _PanelSection(
          title: 'Flujo editorial',
          child: workflowNotes.isEmpty
              ? const _MutedMessage(
                  'Las direcciones editoriales guardadas para este capítulo aparecerán aquí.',
                )
              : Column(
                  children: workflowNotes
                      .map(
                        (note) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration:
                                MusaTheme.panelDecoration(context, radius: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.title ?? 'Dirección editorial',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color:
                                            MusaTheme.tokensOf(context).textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _workflowSummary(note),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color:
                                            MusaTheme.tokensOf(context).textSecondary,
                                        height: 1.35,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Row(
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
                                              .read(narrativeWorkspaceProvider.notifier)
                                              .updateNoteStatus(
                                                note.id,
                                                NoteStatus.used,
                                              ),
                                      child: const Text('Usada'),
                                    ),
                                    TextButton(
                                      onPressed: note.status == NoteStatus.discarded
                                          ? null
                                          : () => ref
                                              .read(narrativeWorkspaceProvider.notifier)
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
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 18),
        _PanelSection(
          title: 'Texto',
          child: Column(
            children: [
              _InspectorActionTile(
                title: 'Dar formato',
                subtitle:
                    'Normaliza párrafos, espacios y signos para que el texto respire mejor.',
                actionLabel: 'Aplicar',
                onAction: () =>
                    _applyDocumentFormatting(context, ref, document),
              ),
              const SizedBox(height: 10),
              _InspectorActionTile(
                title: 'Revisar ortografía',
                subtitle:
                    'Aplica una corrección básica local de signos, mayúsculas y errores frecuentes.',
                actionLabel: 'Revisar',
                onAction: () => _applyBasicSpellcheck(context, ref, document),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _PanelSection(
          title: 'Ritmo del texto',
          child: _TextRhythmSection(
            suggestions: _buildTextRhythmSuggestions(document.content),
            onSuggestionTap: (item) {
              final range = item.range;
              if (range == null || range.isCollapsed) {
                return;
              }
              ref.read(editorProvider.notifier).highlightDocumentRange(
                    start: range.start,
                    end: range.end,
                  );
            },
          ),
        ),
        const SizedBox(height: 18),
        _PanelSection(
          title: 'Personajes vinculados',
          trailingActionLabel: 'Vincular',
          onTrailingAction: () => _handleLinkCharacter(
            context,
            ref,
            document.id,
            allCharacters,
            document.characterIds,
          ),
          child: linkedCharacters.isEmpty
              ? const _MutedMessage(
                  'Los personajes de este capítulo aparecerán aquí.',
                )
              : _EntityChipList<Character>(
                  items: linkedCharacters,
                  labelFor: (item) => item.displayName,
                  onTap: (item) => ref
                      .read(narrativeWorkspaceProvider.notifier)
                      .selectCharacter(item.id),
                  onRemove: (item) => ref
                      .read(narrativeWorkspaceProvider.notifier)
                      .unlinkCharacterFromDocument(
                        documentId: document.id,
                        characterId: item.id,
                      ),
                ),
        ),
        const SizedBox(height: 18),
        _PanelSection(
          title: 'Escenarios vinculados',
          trailingActionLabel: 'Vincular',
          onTrailingAction: () => _handleLinkScenario(
            context,
            ref,
            document.id,
            allScenarios,
            document.scenarioIds,
          ),
          child: linkedScenarios.isEmpty
              ? const _MutedMessage(
                  'Los escenarios de este capítulo aparecerán aquí.',
                )
              : _EntityChipList<Scenario>(
                  items: linkedScenarios,
                  labelFor: (item) => item.displayName,
                  onTap: (item) => ref
                      .read(narrativeWorkspaceProvider.notifier)
                      .selectScenario(item.id),
                  onRemove: (item) => ref
                      .read(narrativeWorkspaceProvider.notifier)
                      .unlinkScenarioFromDocument(
                        documentId: document.id,
                        scenarioId: item.id,
                      ),
                ),
        ),
      ],
    );
  }

  Widget? _buildDocumentSuggestion(
    BuildContext context,
    WidgetRef ref,
    Document document,
    List<Character> linkedCharacters,
    List<Scenario> linkedScenarios,
    List<Character> allCharacters,
    List<Scenario> allScenarios,
  ) {
    if (linkedScenarios.isEmpty) {
      return _AssistiveHint(
        text: allScenarios.isEmpty
            ? 'Si aquí aparece un lugar, puedes crear un escenario.'
            : 'Este capítulo todavía no tiene un escenario vinculado.',
        actionLabel: allScenarios.isEmpty ? null : 'Vincular',
        onAction: allScenarios.isEmpty
            ? null
            : () => _handleLinkScenario(
                  context,
                  ref,
                  document.id,
                  allScenarios,
                  document.scenarioIds,
                ),
      );
    }

    final unlinkedCharacter = _findUnlinkedCharacterMention(
      content: document.content,
      characters: allCharacters,
      linkedCharacterIds: document.characterIds,
    );
    if (unlinkedCharacter != null) {
      return _AssistiveHint(
        text: '${unlinkedCharacter.displayName} aparece en el texto.',
        actionLabel: 'Vincular',
        onAction: () => _handleLinkCharacter(
          context,
          ref,
          document.id,
          allCharacters,
          document.characterIds,
        ),
      );
    }

    if (document.content.trim().isNotEmpty &&
        linkedCharacters.isEmpty &&
        linkedScenarios.isEmpty) {
      return const _AssistiveHint(
        text: 'Este capítulo aún no tiene contexto visible.',
      );
    }

    return null;
  }

  Widget _buildNoteMode(
    BuildContext context,
    WidgetRef ref,
    Note? note,
    List<Document> documents,
  ) {
    if (note == null) {
      return const SizedBox.shrink();
    }

    final linkedDocuments = documents
        .where((document) => note.documentIds.contains(document.id))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Column(
      children: [
        _buildInspectorNotePanel(
          context,
          ref,
          note,
          canPromoteToEditor: false,
        ),
        const SizedBox(height: 18),
        _PanelSection(
          title: 'Capítulos relacionados',
          child: linkedDocuments.isEmpty
              ? const _MutedMessage('Todavía no hay capítulos relacionados.')
              : Column(
                  children: linkedDocuments
                      .map(
                        (document) => _LinkTile(
                          title: document.title,
                          subtitle: 'Capítulo ${document.orderIndex + 1}',
                          onTap: () => ref
                              .read(narrativeWorkspaceProvider.notifier)
                              .selectDocument(document.id),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildInspectorNotePanel(
    BuildContext context,
    WidgetRef ref,
    Note note, {
    required bool canPromoteToEditor,
  }) {
    final anchorState = note.anchorState;
    return _PanelSection(
      title: canPromoteToEditor ? 'Nota vinculada' : 'Nota activa',
      trailingActionLabel: canPromoteToEditor ? 'Abrir' : null,
      onTrailingAction: canPromoteToEditor
          ? () =>
              ref.read(narrativeWorkspaceProvider.notifier).selectNote(note.id)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LinkTile(
            title: note.title ?? 'Nota sin título',
            subtitle: _noteKindLabel(note.kind),
            onTap: canPromoteToEditor
                ? () => ref
                    .read(narrativeWorkspaceProvider.notifier)
                    .selectNote(note.id)
                : () {},
          ),
          const SizedBox(height: 8),
          _MetricRow(label: 'Estado', value: _noteStatusLabel(note.status)),
          if (note.workflowType != null)
            _MetricRow(
              label: 'Workflow',
              value: switch (note.workflowType!) {
                EditorialWorkflowType.expandMoment => 'Expandir momento',
                EditorialWorkflowType.connectToPlot => 'Conectar con trama',
              },
            ),
          if (anchorState != null)
            _MetricRow(
              label: 'Ancla',
              value: _anchorStateLabel(anchorState),
            ),
          if ((note.sourceDocumentTitle ?? '').trim().isNotEmpty)
            _MetricRow(
              label: 'Origen',
              value: note.sourceDocumentTitle!.trim(),
            ),
          _MetricRow(
            label: 'Actualizada',
            value: _formatDateTime(note.updatedAt),
          ),
          if ((note.anchorTextSnapshot ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReadOnlyBlock(
              label: 'Texto anclado',
              text: note.anchorTextSnapshot!.trim(),
            ),
          ],
          const SizedBox(height: 14),
          _EditableTextBlock(
            label: 'Contenido',
            initialValue: note.content,
            hintText:
                'Escribe aquí la idea, duda o recordatorio que no quieres perder.',
            minLines: 5,
            onSaved: (value) => ref
                .read(narrativeWorkspaceProvider.notifier)
                .updateNoteContent(note.id, value),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterMode(
    BuildContext context,
    WidgetRef ref,
    Character? character,
    List<Document> linkedDocuments,
  ) {
    if (character == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _PanelSection(
          title: 'Personaje',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LinkTile(
                title: character.displayName,
                subtitle: character.role.trim().isEmpty
                    ? 'Sin rol definido'
                    : character.role,
                onTap: () {},
              ),
              const SizedBox(height: 14),
              _ReadOnlyBlock(
                label: 'Quién es',
                text: character.summary.trim().isEmpty
                    ? 'La ficha todavía no tiene una descripción principal.'
                    : character.summary,
              ),
              if (character.currentState.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _ReadOnlyBlock(
                  label: 'Estado actual',
                  text: character.currentState,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _PanelSection(
          title: 'Aparece en',
          child: linkedDocuments.isEmpty
              ? const _MutedMessage(
                  'Todavía no aparece vinculado a ningún capítulo.')
              : Column(
                  children: linkedDocuments
                      .map(
                        (document) => _LinkTile(
                          title: document.title,
                          subtitle: 'Capítulo ${document.orderIndex + 1}',
                          onTap: () => ref
                              .read(narrativeWorkspaceProvider.notifier)
                              .selectDocument(document.id),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildScenarioMode(
    BuildContext context,
    WidgetRef ref,
    Scenario? scenario,
    List<Document> linkedDocuments,
  ) {
    if (scenario == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _PanelSection(
          title: 'Escenario',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LinkTile(
                title: scenario.displayName,
                subtitle: scenario.role.trim().isEmpty
                    ? 'Sin función narrativa definida'
                    : scenario.role,
                onTap: () {},
              ),
              const SizedBox(height: 14),
              _ReadOnlyBlock(
                label: 'Descripción',
                text: scenario.summary.trim().isEmpty
                    ? 'Todavía no hay una descripción de este escenario.'
                    : scenario.summary,
              ),
              if (scenario.atmosphere.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _ReadOnlyBlock(
                  label: 'Atmósfera',
                  text: scenario.atmosphere,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _PanelSection(
          title: 'Se usa en',
          child: linkedDocuments.isEmpty
              ? const _MutedMessage(
                  'Todavía no está vinculado a ningún capítulo.')
              : Column(
                  children: linkedDocuments
                      .map(
                        (document) => _LinkTile(
                          title: document.title,
                          subtitle: 'Capítulo ${document.orderIndex + 1}',
                          onTap: () => ref
                              .read(narrativeWorkspaceProvider.notifier)
                              .selectDocument(document.id),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Text(
      'CONTEXTO',
      style: MusaTheme.sectionEyebrow(context),
    );
  }

  Future<void> _handleLinkCharacter(
    BuildContext context,
    WidgetRef ref,
    String documentId,
    List<Character> characters,
    List<String> linkedCharacterIds,
  ) async {
    final selected = await showCharacterPickerSheet(
      context,
      characters: characters,
      linkedCharacterIds: linkedCharacterIds,
      title: 'Personajes en este capítulo',
    );
    if (selected == null || !context.mounted) return;

    final alreadyLinked = linkedCharacterIds.contains(selected.id);
    if (!alreadyLinked) {
      await ref
          .read(narrativeWorkspaceProvider.notifier)
          .linkCharacterToDocument(
            documentId: documentId,
            characterId: selected.id,
          );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alreadyLinked
              ? '${selected.displayName} ya estaba en este capítulo.'
              : '${selected.displayName} ahora acompaña este capítulo.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLinkScenario(
    BuildContext context,
    WidgetRef ref,
    String documentId,
    List<Scenario> scenarios,
    List<String> linkedScenarioIds,
  ) async {
    final selected = await showScenarioPickerSheet(
      context,
      scenarios: scenarios,
      linkedScenarioIds: linkedScenarioIds,
      title: 'Escenarios en este capítulo',
    );
    if (selected == null || !context.mounted) return;

    final alreadyLinked = linkedScenarioIds.contains(selected.id);
    if (!alreadyLinked) {
      await ref
          .read(narrativeWorkspaceProvider.notifier)
          .linkScenarioToDocument(
            documentId: documentId,
            scenarioId: selected.id,
          );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alreadyLinked
              ? '${selected.displayName} ya estaba en este capítulo.'
              : '${selected.displayName} ahora acompaña este capítulo.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _applyDocumentFormatting(
    BuildContext context,
    WidgetRef ref,
    Document document,
  ) async {
    final formatted = _formatDocumentText(document.content);
    if (formatted == document.content) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No había ajustes claros de formato.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await ref
        .read(narrativeWorkspaceProvider.notifier)
        .updateDocumentContent(document.id, formatted);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formato aplicado al capítulo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _applyBasicSpellcheck(
    BuildContext context,
    WidgetRef ref,
    Document document,
  ) async {
    final corrected = _applyOrthographyHeuristics(document.content);
    if (corrected == document.content) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No detecté correcciones ortográficas claras.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await ref
        .read(narrativeWorkspaceProvider.notifier)
        .updateDocumentContent(document.id, corrected);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisión ortográfica básica aplicada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _PanelSection extends StatelessWidget {
  const _PanelSection({
    required this.title,
    required this.child,
    this.trailing,
    this.trailingActionLabel,
    this.onTrailingAction,
  });

  final String title;
  final String? trailing;
  final String? trailingActionLabel;
  final VoidCallback? onTrailingAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: MusaTheme.panelDecoration(
        context,
        backgroundColor: tokens.canvasBackground,
        radius: 18,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleWidget = Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          );
          final trailingWidget = trailing == null
              ? null
              : Text(
                  trailing!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                );
          final actionWidget =
              trailingActionLabel != null && onTrailingAction != null
                  ? TextButton(
                      onPressed: onTrailingAction,
                      style: TextButton.styleFrom(
                        foregroundColor: tokens.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(trailingActionLabel!),
                    )
                  : null;
          final isCompact = constraints.maxWidth < 180;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompact) ...[
                titleWidget,
                if (trailingWidget != null) ...[
                  const SizedBox(height: 6),
                  trailingWidget,
                ],
                if (actionWidget != null) ...[
                  const SizedBox(height: 6),
                  actionWidget,
                ],
              ] else
                Row(
                  children: [
                    Expanded(child: titleWidget),
                    if (trailingWidget != null) ...[
                      const SizedBox(width: 8),
                      Flexible(child: trailingWidget),
                    ],
                    if (actionWidget != null) actionWidget,
                  ],
                ),
              const SizedBox(height: 14),
              child,
            ],
          );
        },
      ),
    );
  }
}

class _InspectorActionTile extends StatelessWidget {
  const _InspectorActionTile({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: MusaTheme.panelDecoration(
        context,
        backgroundColor: tokens.subtleBackground,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.textPrimary,
              side: BorderSide(color: tokens.borderSoft),
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _TextRhythmSection extends StatelessWidget {
  const _TextRhythmSection({
    required this.suggestions,
    required this.onSuggestionTap,
  });

  final List<_RhythmSuggestion> suggestions;
  final ValueChanged<_RhythmSuggestion> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const _MutedMessage(
        'No veo problemas claros de respiración o puntuación en este capítulo.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: suggestions
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RhythmSuggestionRow(
                item: item,
                onTap: () => onSuggestionTap(item),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RhythmSuggestionRow extends StatelessWidget {
  const _RhythmSuggestionRow({
    required this.item,
    required this.onTap,
  });

  final _RhythmSuggestion item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.range == null ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: MusaTheme.panelDecoration(
            context,
            backgroundColor: tokens.subtleBackground,
            radius: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                item.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                      height: 1.35,
                    ),
              ),
              if (item.contextHint != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Dónde: ${item.contextHint}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textMuted,
                        height: 1.35,
                      ),
                ),
              ],
              if (item.example != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Ejemplo: ${item.example}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textMuted,
                        height: 1.35,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.documentsCount,
    required this.notesCount,
    required this.charactersCount,
    required this.scenariosCount,
    required this.onOpen,
  });

  final Book? book;
  final int documentsCount;
  final int notesCount;
  final int charactersCount;
  final int scenariosCount;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(MusaTheme.tokensOf(context).radiusLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: MusaTheme.panelDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book?.title ?? 'Sin libro activo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MusaTheme.tokensOf(context).textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if ((book?.subtitle ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                book!.subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MusaTheme.tokensOf(context).textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TinyBadge(text: '$documentsCount cap.'),
                _TinyBadge(text: '$notesCount notas'),
                _TinyBadge(text: '$charactersCount personajes'),
                _TinyBadge(text: '$scenariosCount escenarios'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyBlock extends StatelessWidget {
  const _ReadOnlyBlock({
    required this.label,
    required this.text,
  });

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: MusaTheme.sectionEyebrow(context),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MusaTheme.tokensOf(context).textSecondary,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}

class _EditableTextBlock extends ConsumerStatefulWidget {
  const _EditableTextBlock({
    required this.label,
    required this.initialValue,
    required this.hintText,
    required this.onSaved,
    this.minLines = 4,
  });

  final String label;
  final String initialValue;
  final String hintText;
  final int minLines;
  final Future<void> Function(String value) onSaved;

  @override
  ConsumerState<_EditableTextBlock> createState() => _EditableTextBlockState();
}

class _EditableTextBlockState extends ConsumerState<_EditableTextBlock> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  Timer? _debounce;

  @override
  void didUpdateWidget(covariant _EditableTextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: MusaTheme.sectionEyebrow(context),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          minLines: widget.minLines,
          maxLines: null,
          onChanged: _scheduleSave,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: MusaTheme.tokensOf(context).textMuted,
            ),
            filled: true,
            fillColor: MusaTheme.tokensOf(context).canvasBackground,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(MusaTheme.tokensOf(context).radiusLg),
              borderSide: BorderSide(
                color: MusaTheme.tokensOf(context).borderSubtle,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(MusaTheme.tokensOf(context).radiusLg),
              borderSide: BorderSide(
                color: MusaTheme.tokensOf(context).borderSubtle,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(MusaTheme.tokensOf(context).radiusLg),
              borderSide: BorderSide(
                color: MusaTheme.tokensOf(context).borderStrong,
              ),
            ),
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MusaTheme.tokensOf(context).textPrimary,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  void _scheduleSave(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      widget.onSaved(value.trim());
    });
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dragHandle = ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: MusaTheme.panelDecoration(
                    context,
                    backgroundColor:
                        MusaTheme.tokensOf(context).subtleBackground,
                    radius: 14,
                  ),
                  child: const Icon(
                    Icons.drag_indicator_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 18,
                  ),
                ),
              );

              final tile = _LinkTile(
                title: document.title,
                subtitle: 'Capítulo ${document.orderIndex + 1}',
                onTap: () => onOpen(document),
              );

              if (constraints.maxWidth < 180) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tile,
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: dragHandle,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: tile),
                  const SizedBox(width: 8),
                  dragHandle,
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelText = Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
          );

          final valueText = Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          );

          if (constraints.maxWidth < 140) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelText,
                const SizedBox(height: 4),
                valueText,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: labelText),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: valueText,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(MusaTheme.tokensOf(context).radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: MusaTheme.panelDecoration(context, radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: MusaTheme.tokensOf(context).textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MusaTheme.tokensOf(context).textMuted,
                      letterSpacing: 0.3,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntityChipList<T> extends StatelessWidget {
  const _EntityChipList({
    required this.items,
    required this.labelFor,
    required this.onTap,
    required this.onRemove,
  });

  final List<T> items;
  final String Function(T item) labelFor;
  final void Function(T item) onTap;
  final void Function(T item) onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => InputChip(
              label: Text(labelFor(item)),
              onPressed: () => onTap(item),
              onDeleted: () => onRemove(item),
              deleteIcon: const Icon(Icons.close, size: 16),
              avatar: const Icon(Icons.open_in_new, size: 14),
              side: BorderSide(color: MusaTheme.tokensOf(context).borderSubtle),
              backgroundColor: MusaTheme.tokensOf(context).canvasBackground,
            ),
          )
          .toList(),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MusaTheme.tokensOf(context).hoverBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MusaTheme.tokensOf(context).textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _MutedMessage extends StatelessWidget {
  const _MutedMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: MusaTheme.tokensOf(context).textMuted,
            height: 1.45,
          ),
    );
  }
}

class _DocumentContinuityState {
  const _DocumentContinuityState({
    required this.activeCharacters,
    required this.activeScenarios,
    required this.alerts,
  });

  final List<Character> activeCharacters;
  final List<Scenario> activeScenarios;
  final List<String> alerts;
}

class _AssistiveHint extends StatelessWidget {
  const _AssistiveHint({
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: MusaTheme.panelDecoration(
        context,
        accent: true,
        radius: 16,
        backgroundColor: tokens.warningBackground,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showAction = actionLabel != null && onAction != null;
          final isCompact = constraints.maxWidth < 220;

          final message = Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.warningText,
                  height: 1.35,
                ),
          );

          if (!showAction) {
            return message;
          }

          final actionButton = TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: tokens.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                message,
                const SizedBox(height: 10),
                actionButton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: message),
              const SizedBox(width: 12),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: actionButton,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Character? _findUnlinkedCharacterMention({
  required String content,
  required List<Character> characters,
  required List<String> linkedCharacterIds,
}) {
  final normalizedContent = content.toLowerCase();
  for (final character in characters) {
    final name = character.displayName.trim();
    if (name.isEmpty || linkedCharacterIds.contains(character.id)) {
      continue;
    }
    final escapedName = RegExp.escape(name.toLowerCase());
    final pattern = RegExp('(^|[^a-záéíóúñü])$escapedName([^a-záéíóúñü]|\\\$)');
    if (pattern.hasMatch(normalizedContent)) {
      return character;
    }
  }
  return null;
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

String _formatDocumentText(String input) {
  var text = input.replaceAll('\r\n', '\n');
  text = text.replaceAllMapped(
    RegExp(r'^\s*-{3,}\s*$', multiLine: true),
    (_) => '\n\n',
  );
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  final rawBlocks = text
      .split(RegExp(r'\n\s*\n'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  final paragraphs = <String>[];
  for (final block in rawBlocks) {
    paragraphs.addAll(_splitFormattedBlock(block));
  }

  if (paragraphs.isEmpty) {
    return text.trim();
  }

  return _joinFormattedParagraphs(paragraphs).trim();
}

String _applyOrthographyHeuristics(String input) {
  var text = _formatDocumentText(input);

  text = text.replaceAll(RegExp(r'\s+([,.;:!?])'), r'$1');
  text = text.replaceAllMapped(
    RegExp(r'([,.;:!?])(?!\s|$|[”»"\)\]])'),
    (match) => '${match.group(1)} ',
  );
  text = text.replaceAllMapped(
    RegExp(r'(^|[.!?]\s+|¿\s*|¡\s*|\n\n)([a-záéíóúñ])'),
    (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}',
  );
  text = text.replaceAll(' ,', ',');
  text = text.replaceAll(' .', '.');
  text = text.replaceAll(' ;', ';');
  text = text.replaceAll(' :', ':');
  text = text.replaceAll(' ?', '?');
  text = text.replaceAll(' !', '!');

  const replacements = <MapEntry<String, String>>[
    MapEntry(' q ', ' que '),
    MapEntry(' xq ', ' porque '),
    MapEntry(' tb ', ' también '),
    MapEntry(' d q ', ' de que '),
    MapEntry(' solo ', ' solo '),
  ];

  for (final replacement in replacements) {
    text = text.replaceAll(
      RegExp(replacement.key, caseSensitive: false),
      replacement.value,
    );
  }

  return text.trim();
}

String _normalizeInlineSpacing(String text) {
  return text
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\s+([,.;:!?])'), r'$1')
      .replaceAllMapped(
        RegExp(r'([,.;:!?])(?!\s|$|[”»"\)\]])'),
        (match) => '${match.group(1)} ',
      )
      .trim();
}

List<String> _splitFormattedBlock(String block) {
  final lines = block
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) {
    return const [];
  }

  final paragraphs = <String>[];
  final buffer = <String>[];
  var prefersLooseList = false;

  void flush() {
    if (buffer.isEmpty) return;
    final joined = buffer.join(' ').trim();
    if (joined.isNotEmpty) {
      paragraphs.add(_normalizeInlineSpacing(joined));
    }
    buffer.clear();
  }

  for (var index = 0; index < lines.length; index += 1) {
    final line = lines[index];
    final normalizedLine = _normalizeInlineSpacing(line);

    if (_isStructuralLine(normalizedLine)) {
      flush();
      paragraphs.add(normalizedLine);
      prefersLooseList = normalizedLine.endsWith(':');
      continue;
    }

    if (_isListLine(normalizedLine)) {
      flush();
      paragraphs.add(normalizedLine);
      prefersLooseList = true;
      continue;
    }

    if (prefersLooseList && _looksLikeLooseListItem(normalizedLine)) {
      flush();
      paragraphs.add('• $normalizedLine');
      continue;
    }

    prefersLooseList = false;

    if (buffer.isNotEmpty &&
        _shouldBreakBeforeLine(buffer.last, normalizedLine)) {
      flush();
    }

    buffer.add(normalizedLine);
  }

  flush();
  return paragraphs;
}

bool _isStructuralLine(String line) {
  if (line.isEmpty) return false;
  return RegExp(r'^\d+[.)]\s').hasMatch(line) ||
      RegExp(r'^\d+\.\s*\d+[.)]?\s').hasMatch(line) ||
      RegExp(r'^(fase|cap[ií]tulo|parte)\s+\d+', caseSensitive: false)
          .hasMatch(line) ||
      line.endsWith(':');
}

bool _isListLine(String line) {
  return RegExp(r'^[•\-\*]\s+').hasMatch(line);
}

bool _shouldBreakBeforeLine(String previousLine, String nextLine) {
  if (_isStructuralLine(nextLine) || _isListLine(nextLine)) {
    return true;
  }

  if (_looksLikeStandaloneQuote(nextLine)) {
    return true;
  }

  if (_looksLikeTransitionLine(previousLine, nextLine)) {
    return true;
  }

  return false;
}

bool _looksLikeLooseListItem(String line) {
  if (line.isEmpty || _isListLine(line) || _isStructuralLine(line)) {
    return false;
  }

  final wordCount = _countWords(line);
  if (wordCount == 0 || wordCount > 14) {
    return false;
  }

  final startsLikeSentence = RegExp(r'^[A-ZÁÉÍÓÚÑ¿¡"“]').hasMatch(line);
  final hasStrongEnding = RegExp(r'[.!?…]$').hasMatch(line);
  if (startsLikeSentence && hasStrongEnding && wordCount > 8) {
    return false;
  }

  return true;
}

bool _looksLikeStandaloneQuote(String line) {
  return RegExp(r'^[“"¿¡]?[^.]{0,90}[”"]?$').hasMatch(line) &&
      (line.startsWith('“') ||
          line.startsWith('"') ||
          line.startsWith('—') ||
          line.startsWith('¿'));
}

bool _looksLikeTransitionLine(String previousLine, String nextLine) {
  final previousIsShort = _countWords(previousLine) <= 8;
  final nextIsShort = _countWords(nextLine) <= 8;
  final previousEndsStrong = RegExp(r'[.!?…]$').hasMatch(previousLine);
  final nextStartsWithPivot = RegExp(
    r'^(Pero|Y|O|Entonces|Aun así|Aun asi|Sin embargo)\b',
  ).hasMatch(nextLine);

  return previousIsShort &&
      nextIsShort &&
      previousEndsStrong &&
      nextStartsWithPivot &&
      !_looksLikeLooseListItem(nextLine);
}

String _joinFormattedParagraphs(List<String> paragraphs) {
  final buffer = StringBuffer();

  for (var index = 0; index < paragraphs.length; index += 1) {
    final current = paragraphs[index];
    if (index > 0) {
      final previous = paragraphs[index - 1];
      final compactBreak = (_isListLine(previous) && _isListLine(current)) ||
          (previous.endsWith(':') && _isListLine(current));
      buffer.write(compactBreak ? '\n' : '\n\n');
    }
    buffer.write(current);
  }

  return buffer.toString();
}

List<_RhythmSuggestion> _buildTextRhythmSuggestions(String content) {
  final normalized = content.trim();
  if (normalized.isEmpty) {
    return const [];
  }

  final suggestions = <_RhythmSuggestion>[];
  final paragraphs = normalized
      .split(RegExp(r'\n\s*\n'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  final narrativeParagraphs =
      paragraphs.where((part) => !_isDialogueParagraph(part)).toList();

  for (final paragraph in narrativeParagraphs) {
    final sentenceCount = _countSentences(paragraph);
    final wordCount = _countWords(paragraph);
    final averageSentenceLength =
        sentenceCount == 0 ? wordCount : wordCount / sentenceCount;

    if (wordCount >= 110 &&
        sentenceCount >= 2 &&
        sentenceCount <= 4 &&
        averageSentenceLength >= 22) {
      suggestions.add(
        _RhythmSuggestion(
          title: 'Bloque muy compacto',
          message:
              'Este párrafo concentra demasiada información seguida. Puede ganar claridad con un corte.',
          range: _findTextRange(content, paragraph),
          contextHint: _trimExample(paragraph),
          example:
              'Prueba a separar cuando cambie la acción, la idea o el foco emocional.',
        ),
      );
      break;
    }
  }

  final sentences = narrativeParagraphs
      .expand(_extractSentences)
      .where((part) => part.isNotEmpty)
      .toList();
  for (final sentence in sentences) {
    final wordCount = _countWords(sentence);
    final commaCount = ','.allMatches(sentence).length;
    if (wordCount >= 34 &&
        commaCount >= 2 &&
        !sentence.contains(':') &&
        !sentence.contains(';') &&
        !_looksLikeEnumerativeSentence(sentence)) {
      suggestions.add(
        _RhythmSuggestion(
          title: 'Frase larga',
          message:
              'Aquí quizá falta una pausa más fuerte. Revisa si pide dos puntos, punto y coma o una frase nueva.',
          range: _findTextRange(content, sentence),
          contextHint: _trimExample(sentence),
          example:
              'Prueba a cortar antes del detalle final o a separar la imagen del dato.',
        ),
      );
      break;
    }
  }

  for (final sentence in sentences) {
    final wordCount = _countWords(sentence);
    final commaCount = ','.allMatches(sentence).length;
    if (commaCount >= 3 &&
        wordCount >= 22 &&
        (sentence.contains(' y ') || sentence.contains(' pero ')) &&
        !sentence.contains(':') &&
        !sentence.contains(';') &&
        !_looksLikeEnumerativeSentence(sentence)) {
      suggestions.add(
        _RhythmSuggestion(
          title: 'Acumulación en una sola frase',
          message:
              'Este tramo encadena varias piezas seguidas. Puede respirar mejor con dos puntos, punto y coma o una división más clara.',
          range: _findTextRange(content, sentence),
          contextHint: _trimExample(sentence),
          example:
              'Aquí puede funcionar mejor una pausa antes del último detalle o una frase breve de remate.',
        ),
      );
      break;
    }
  }

  for (final paragraph in narrativeParagraphs) {
    final pivotSentence = _findDirectionShiftSentence(paragraph);
    if (pivotSentence != null) {
      suggestions.add(
        _RhythmSuggestion(
          title: 'Cambio de giro visible',
          message:
              'Aquí parece cambiar la dirección del párrafo. Revisa si conviene marcarlo con un salto de línea.',
          range: _findTextRange(content, pivotSentence),
          contextHint: _trimExample(pivotSentence),
          example:
              'Si el giro importa, un salto de párrafo puede darle más peso.',
        ),
      );
      break;
    }
  }

  return suggestions.take(3).toList();
}

String _trimExample(String sentence) {
  final compact = sentence.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= 120) {
    return compact;
  }
  return '${compact.substring(0, 117).trim()}...';
}

List<String> _extractSentences(String paragraph) {
  return paragraph
      .split(RegExp(r'(?<=[.!?…])\s+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

int _countWords(String text) {
  return text.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).length;
}

int _countSentences(String text) {
  return _extractSentences(text).length;
}

bool _isDialogueParagraph(String paragraph) {
  final trimmed = paragraph.trimLeft();
  if (trimmed.startsWith('—') ||
      trimmed.startsWith('“') ||
      trimmed.startsWith('"')) {
    return true;
  }

  final lines = paragraph
      .split('\n')
      .map((line) => line.trimLeft())
      .where((line) => line.isNotEmpty)
      .toList();
  final dialogueLines = lines
      .where(
        (line) =>
            line.startsWith('—') ||
            line.startsWith('“') ||
            line.startsWith('"'),
      )
      .length;
  return lines.isNotEmpty && dialogueLines >= 2;
}

bool _looksLikeEnumerativeSentence(String sentence) {
  final trimmed = sentence.trim();
  return trimmed.startsWith('—') ||
      trimmed.startsWith('“') ||
      trimmed.startsWith('"');
}

String? _findDirectionShiftSentence(String paragraph) {
  final sentences = _extractSentences(paragraph);
  if (sentences.length < 3 || _countWords(paragraph) < 24) {
    return null;
  }

  const pivots = <String>[
    'Pero ',
    'Sin embargo',
    'Entonces ',
    'De pronto',
    'Aun así',
    'Aun asi',
  ];

  for (var index = 1; index < sentences.length; index += 1) {
    final sentence = sentences[index];
    if (pivots.any((pivot) => sentence.startsWith(pivot))) {
      return sentence;
    }
  }

  return null;
}

TextRange? _findTextRange(String content, String snippet) {
  final trimmedSnippet = snippet.trim();
  if (trimmedSnippet.isEmpty) {
    return null;
  }

  final start = content.indexOf(trimmedSnippet);
  if (start < 0) {
    return null;
  }

  return TextRange(start: start, end: start + trimmedSnippet.length);
}

class _RhythmSuggestion {
  final String title;
  final String message;
  final TextRange? range;
  final String? contextHint;
  final String? example;

  const _RhythmSuggestion({
    required this.title,
    required this.message,
    this.range,
    this.contextHint,
    this.example,
  });
}

String _documentKindLabel(DocumentKind kind) => switch (kind) {
      DocumentKind.chapter => 'Capítulo',
      DocumentKind.scene => 'Escena',
      DocumentKind.noteDoc => 'Nota',
      DocumentKind.scratch => 'Borrador',
    };

String _noteKindLabel(NoteKind kind) => switch (kind) {
      NoteKind.idea => 'Idea',
      NoteKind.research => 'Investigación',
      NoteKind.structural => 'Estructura',
      NoteKind.character => 'Personaje',
      NoteKind.scenario => 'Escenario',
      NoteKind.loose => 'Libre',
    };

String _noteStatusLabel(NoteStatus status) => switch (status) {
      NoteStatus.inbox => 'inbox',
      NoteStatus.linked => 'vinculada',
      NoteStatus.used => 'usada',
      NoteStatus.discarded => 'descartada',
      NoteStatus.archived => 'archivada',
    };

String _anchorStateLabel(NoteAnchorState state) => switch (state) {
      NoteAnchorState.exact => 'exacta',
      NoteAnchorState.fuzzy => 'relocalizada',
      NoteAnchorState.detached => 'desanclada',
    };
