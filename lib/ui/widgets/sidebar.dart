import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../modules/books/models/book.dart';
import '../../modules/books/models/narrative_workspace.dart';
import '../../modules/books/providers/workspace_providers.dart';
import '../../modules/characters/models/character.dart';
import '../../modules/characters/providers/character_providers.dart';
import '../../modules/manuscript/models/document.dart';
import '../../modules/manuscript/providers/document_providers.dart';
import '../../modules/notes/models/note.dart';
import '../../modules/notes/models/voice_memo.dart';
import '../../modules/notes/providers/note_providers.dart';
import 'editorial_dialogs.dart';
import '../../modules/scenarios/models/scenario.dart';
import '../../modules/scenarios/providers/scenario_providers.dart';
import '../../core/theme.dart';
import '../../editor/controller/editor_controller.dart';
import 'musa_wordmark.dart';

class MusaSidebar extends ConsumerStatefulWidget {
  const MusaSidebar({super.key});

  @override
  ConsumerState<MusaSidebar> createState() => _MusaSidebarState();
}

class _MusaSidebarState extends ConsumerState<MusaSidebar> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    final workspace = ref.watch(narrativeWorkspaceProvider);
    final books = ref.watch(booksProvider);
    final book = ref.watch(activeBookProvider);
    final documents = ref.watch(documentsProvider);
    final notes = ref.watch(notesProvider);
    final voiceMemos = ref.watch(voiceMemosProvider);
    final characters = ref.watch(charactersProvider);
    final scenarios = ref.watch(scenariosProvider);
    final editorMode = ref.watch(editorModeProvider);

    return Container(
      width: MusaConstants.sidebarWidth,
      color: tokens.sidebarBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          width: MusaConstants.sidebarWidth,
          child: Column(
            children: [
              _buildHeader(context, ref, workspace, books, book),
              Expanded(
                child: _buildWorkspaceLists(
                  context,
                  ref,
                  workspace,
                  book,
                  documents,
                  notes,
                  voiceMemos,
                  characters,
                  scenarios,
                  editorMode,
                ),
              ),
              _buildFooter(context, ref, book),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<NarrativeWorkspace> workspace,
    List<Book> books,
    Book? activeBook,
  ) {
    final tokens = MusaTheme.tokensOf(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 32 + topInset, 24, 24),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: MusaWordmark()),
              IconButton(
                onPressed: workspace.isLoading
                    ? null
                    : () => _handleCreateBook(context, ref),
                tooltip: 'Nuevo libro',
                icon: const Icon(Icons.library_add_outlined, size: 18),
                color: tokens.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildBookSelector(
            context,
            ref,
            books,
            activeBook,
          ),
          const SizedBox(height: 10),
          _buildSearchField(context),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: tokens.borderSoft),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 18,
            color: tokens.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar en capítulos',
                hintStyle: TextStyle(color: tokens.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textPrimary,
                    height: 1.2,
                  ),
            ),
          ),
          if (_searchQuery.trim().isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              tooltip: 'Limpiar búsqueda',
              icon: const Icon(Icons.close, size: 16),
              color: tokens.textMuted,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildBookSelector(
    BuildContext context,
    WidgetRef ref,
    List<Book> books,
    Book? activeBook,
  ) {
    final tokens = MusaTheme.tokensOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _showBookSwitcher(context, ref, books, activeBook),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                'Libro activo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => ref
                .read(narrativeWorkspaceProvider.notifier)
                .openActiveBookView(),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                activeBook?.title ?? 'Selecciona un libro',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            height: 1,
            color: tokens.borderSoft,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> workspace,
    Book? activeBook,
    List<Document> documents,
    List<Note> notes,
    List<VoiceMemo> voiceMemos,
    List<Character> characters,
    List<Scenario> scenarios,
    WorkspaceEditorMode editorMode,
  ) {
    if (workspace.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (workspace.hasError) {
      return const Center(child: Text('No se pudo cargar el libro'));
    }
    if (documents.isEmpty) {
      return const Center(child: Text('No hay documentos todavía'));
    }
    final workspaceValue = ref.watch(narrativeWorkspaceProvider).value;
    final characterAutofill = ref.watch(characterAutofillProvider);
    final currentDocumentId = workspaceValue?.selectedDocumentId;
    final currentNoteId = workspaceValue?.selectedNoteId;
    final currentCharacterId = workspaceValue?.selectedCharacterId;
    final currentScenarioId = workspaceValue?.selectedScenarioId;
    final trimmedQuery = _searchQuery.trim();

    if (trimmedQuery.isNotEmpty) {
      return _buildSearchResultsList(
        context,
        ref,
        activeBook,
        documents,
        trimmedQuery,
        currentDocumentId,
      );
    }

    final noteEntries = <_SidebarNoteEntry>[
      ...notes.map(
        (note) => _SidebarNoteEntry(
          title: note.title ?? 'Nota sin título',
          subtitle: _labelForNoteKind(note.kind),
          sortDate: note.updatedAt,
          isSelected: editorMode == WorkspaceEditorMode.note &&
              note.id == currentNoteId,
          onTap: () {
            ref.read(narrativeWorkspaceProvider.notifier).selectNote(note.id);
          },
          onRename: () => _handleRenameNote(context, ref, note),
        ),
      ),
      ...voiceMemos.map(
        (memo) => _SidebarNoteEntry(
          title: memo.title ?? 'Nota oral',
          subtitle: memo.summary ?? 'Pendiente de captura o importación.',
          sortDate: memo.createdAt,
        ),
      ),
    ]..sort((a, b) => b.sortDate.compareTo(a.sortDate));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildSectionHeader(
          context,
          'CAPÍTULOS',
          onAdd: workspaceValue?.activeBook == null
              ? null
              : () => _handleCreateDocument(context, ref),
        ),
        ...documents.map(
          (document) {
            final isSelected = editorMode == WorkspaceEditorMode.document &&
                document.id == currentDocumentId;
            final showReturnUnderline = document.kind == DocumentKind.chapter &&
                document.id == currentDocumentId &&
                !isSelected;
            return _buildItem(
              context,
              document.title,
              leadingPrefix: document.kind == DocumentKind.chapter
                  ? _formatChapterNumber(document.orderIndex + 1)
                  : null,
              subtitle: document.kind == DocumentKind.chapter
                  ? null
                  : _labelForKind(document.kind.name),
              isSelected: isSelected,
              underlineTitle: showReturnUnderline,
              onTap: () {
                ref
                    .read(narrativeWorkspaceProvider.notifier)
                    .selectDocument(document.id);
              },
              onDelete: () => _handleDeleteDocument(context, ref, document),
            );
          },
        ),
        const SizedBox(height: 8),
        _buildSeparator(),
        const SizedBox(height: 12),
        _buildSectionHeader(
          context,
          'PERSONAJES',
          onAdd: workspaceValue?.activeBook == null
              ? null
              : () => _handleCreateCharacter(context, ref),
        ),
        if (characters.isEmpty)
          _buildEmptyLabel(
            context,
            'Selecciona un nombre o personaje en el texto para empezar.',
          ),
        ...characters.map(
          (character) {
            final isDrafting = characterAutofill.appliesTo(character.id) &&
                characterAutofill.phase == CharacterAutofillPhase.drafting;
            final isCompleted = characterAutofill.appliesTo(character.id) &&
                characterAutofill.phase == CharacterAutofillPhase.completed;
            return _buildItem(
              context,
              character.displayName,
              subtitle: isDrafting
                  ? characterAutofill.message
                  : isCompleted
                      ? characterAutofill.message
                      : _characterSubtitle(character),
              isSelected: editorMode == WorkspaceEditorMode.character &&
                  character.id == currentCharacterId,
              onTap: isDrafting
                  ? null
                  : () {
                      ref
                          .read(narrativeWorkspaceProvider.notifier)
                          .selectCharacter(character.id);
                    },
              isLoading: isDrafting,
              showReadyPulse: isCompleted,
            );
          },
        ),
        const SizedBox(height: 8),
        _buildSeparator(),
        const SizedBox(height: 12),
        _buildSectionHeader(
          context,
          'ESCENARIOS',
          onAdd: workspaceValue?.activeBook == null
              ? null
              : () => _handleCreateScenario(context, ref),
        ),
        if (scenarios.isEmpty)
          _buildEmptyLabel(
            context,
            'Selecciona un fragmento con un lugar para crear un escenario.',
          ),
        ...scenarios.map(
          (scenario) {
            final scenarioAutofill = ref.watch(scenarioAutofillProvider);
            final isDrafting = scenarioAutofill.appliesTo(scenario.id) &&
                scenarioAutofill.phase == ScenarioAutofillPhase.drafting;
            final isCompleted = scenarioAutofill.appliesTo(scenario.id) &&
                scenarioAutofill.phase == ScenarioAutofillPhase.completed;
            return _buildItem(
              context,
              scenario.displayName,
              subtitle: isDrafting
                  ? scenarioAutofill.message
                  : isCompleted
                      ? scenarioAutofill.message
                      : _scenarioSubtitle(scenario),
              isSelected: editorMode == WorkspaceEditorMode.scenario &&
                  scenario.id == currentScenarioId,
              onTap: isDrafting
                  ? null
                  : () {
                      ref
                          .read(narrativeWorkspaceProvider.notifier)
                          .selectScenario(scenario.id);
                    },
              isLoading: isDrafting,
              showReadyPulse: isCompleted,
            );
          },
        ),
        const SizedBox(height: 12),
        _buildSectionHeader(
          context,
          'NOTAS',
          onAdd: workspaceValue?.activeBook == null
              ? null
              : () => _handleCreateNoteEntry(context, ref),
        ),
        if (noteEntries.isEmpty)
          _buildEmptyLabel(context, 'No hay notas todavía'),
        ...noteEntries.map(
          (entry) => _buildItem(
            context,
            entry.title,
            subtitle: entry.subtitle,
            isSelected: entry.isSelected,
            onTap: entry.onTap,
            onRename: entry.onRename,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceLists(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> workspace,
    Book? activeBook,
    List<Document> documents,
    List<Note> notes,
    List<VoiceMemo> voiceMemos,
    List<Character> characters,
    List<Scenario> scenarios,
    WorkspaceEditorMode editorMode,
  ) {
    return _buildDocumentList(
      context,
      ref,
      workspace,
      activeBook,
      documents,
      notes,
      voiceMemos,
      characters,
      scenarios,
      editorMode,
    );
  }

  Widget _buildSearchResultsList(
    BuildContext context,
    WidgetRef ref,
    Book? activeBook,
    List<Document> documents,
    String query,
    String? currentDocumentId,
  ) {
    final results = _searchDocuments(
      query: query,
      documents: documents,
      currentDocumentId: currentDocumentId,
    );
    final inCurrent =
        results.where((item) => item.document.id == currentDocumentId).toList();
    final inOthers =
        results.where((item) => item.document.id != currentDocumentId).toList();

    if (results.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionHeader(context, 'RESULTADOS'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              activeBook == null
                  ? 'No hay un libro activo para buscar.'
                  : 'No encuentro "$query" en este libro.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MusaTheme.tokensOf(context).textMuted,
                  ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildSectionHeader(
          context,
          'RESULTADOS',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            'Buscando "$query" en ${activeBook?.title ?? 'el libro activo'}.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MusaTheme.tokensOf(context).textMuted,
                ),
          ),
        ),
        if (inCurrent.isNotEmpty) ...[
          _buildSectionHeader(context, 'EN ESTE CAPÍTULO'),
          ...inCurrent.map(
            (result) => _buildSearchResultItem(context, ref, result),
          ),
          const SizedBox(height: 8),
        ],
        if (inOthers.isNotEmpty) ...[
          _buildSectionHeader(context, 'EN OTROS CAPÍTULOS'),
          ...inOthers.map(
            (result) => _buildSearchResultItem(context, ref, result),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResultItem(
    BuildContext context,
    WidgetRef ref,
    _DocumentSearchResult result,
  ) {
    final chapterLabel = result.document.kind == DocumentKind.chapter
        ? 'Capítulo ${result.document.orderIndex + 1}'
        : _labelForKind(result.document.kind.name);
    final subtitle = result.snippet == null
        ? chapterLabel
        : '$chapterLabel · ${result.snippet}';

    return _buildItem(
      context,
      result.document.title,
      leadingPrefix: result.document.kind == DocumentKind.chapter
          ? _formatChapterNumber(result.document.orderIndex + 1)
          : null,
      subtitle: subtitle,
      onTap: () => ref.read(editorProvider.notifier).openDocumentAtRange(
            documentId: result.document.id,
            range: result.range,
          ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String? title, {
    VoidCallback? onAdd,
  }) {
    final tokens = MusaTheme.tokensOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: title == null
                ? const SizedBox.shrink()
                : Text(
                    title,
                    style: MusaTheme.sectionEyebrow(context).copyWith(
                      color: tokens.textMuted,
                    ),
                  ),
          ),
          IconButton(
            onPressed: onAdd,
            tooltip: 'Crear',
            icon: const Icon(Icons.add, size: 16),
            color: tokens.textMuted,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    const tokens = MusaThemeTokens.light;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 1,
        color: tokens.borderSoft,
      ),
    );
  }

  Widget _buildEmptyLabel(BuildContext context, String text) {
    final tokens = MusaTheme.tokensOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.textMuted,
            ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    String title, {
    String? leadingPrefix,
    String? subtitle,
    int? titleMaxLines = 1,
    bool isSelected = false,
    VoidCallback? onTap,
    VoidCallback? onRename,
    String renameTooltip = 'Renombrar',
    VoidCallback? onDelete,
    String deleteTooltip = 'Eliminar',
    bool isLoading = false,
    bool showReadyPulse = false,
    bool underlineTitle = false,
  }) {
    final tokens = MusaTheme.tokensOf(context);
    final selectedFill = Color.lerp(
          tokens.sidebarBackground,
          tokens.activeBackground,
          0.72,
        ) ??
        tokens.activeBackground;
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedFill : Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          border: Border.all(
            color: showReadyPulse
                ? tokens.successBorder.withValues(alpha: 0.35)
                : isSelected
                    ? Colors.transparent
                    : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (leadingPrefix != null) ...[
                  SizedBox(
                    width: 24,
                    child: Text(
                      leadingPrefix,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? tokens.textSecondary
                                : tokens.textMuted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: titleMaxLines == null
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? tokens.textPrimary
                              : underlineTitle
                                  ? tokens.textMuted
                                  : tokens.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          decoration: underlineTitle
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: tokens.textDisabled,
                          decorationThickness: underlineTitle ? 0.7 : null,
                        ),
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                    ),
                  ),
                ],
                if (showReadyPulse) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: tokens.successText,
                  ),
                ],
                if (onRename != null)
                  IconButton(
                    onPressed: onRename,
                    tooltip: renameTooltip,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    color: isSelected ? tokens.textSecondary : tokens.textMuted,
                    visualDensity: VisualDensity.compact,
                  ),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    tooltip: deleteTooltip,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    color: isSelected ? tokens.textSecondary : tokens.textMuted,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          showReadyPulse ? tokens.textMuted : tokens.textMuted,
                      letterSpacing: 0.3,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatChapterNumber(int number) {
    if (number < 10) {
      return '0$number';
    }
    return '$number';
  }

  String _labelForKind(String kind) {
    switch (kind) {
      case 'scene':
        return 'ESCENA';
      case 'noteDoc':
        return 'NOTA';
      case 'scratch':
        return 'BORRADOR';
      default:
        return 'CAPITULO';
    }
  }

  String _labelForNoteKind(NoteKind kind) {
    switch (kind) {
      case NoteKind.idea:
        return 'IDEA';
      case NoteKind.research:
        return 'INVESTIGACION';
      case NoteKind.structural:
        return 'ESTRUCTURA';
      case NoteKind.character:
        return 'PERSONAJE';
      case NoteKind.scenario:
        return 'ESCENARIO';
      case NoteKind.loose:
        return 'LIBRE';
    }
  }

  String _characterSubtitle(Character character) {
    final pieces = <String>[
      if (character.role.trim().isNotEmpty) character.role.trim(),
      if (character.currentState.trim().isNotEmpty)
        character.currentState.trim(),
      if (character.summary.trim().isNotEmpty) character.summary.trim(),
    ];
    return pieces.isEmpty ? 'Ficha narrativa en construcción' : pieces.first;
  }

  String _scenarioSubtitle(Scenario scenario) {
    final pieces = <String>[
      if (scenario.role.trim().isNotEmpty) scenario.role.trim(),
      if (scenario.currentState.trim().isNotEmpty) scenario.currentState.trim(),
      if (scenario.summary.trim().isNotEmpty) scenario.summary.trim(),
    ];
    return pieces.isEmpty ? 'Ficha editorial en construcción' : pieces.first;
  }

  List<_DocumentSearchResult> _searchDocuments({
    required String query,
    required List<Document> documents,
    required String? currentDocumentId,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final results = <_DocumentSearchResult>[];
    final orderedDocuments = [...documents]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    for (final document in orderedDocuments) {
      final lowerTitle = document.title.toLowerCase();
      final lowerContent = document.content.toLowerCase();
      final seenStarts = <int>{};

      if (lowerTitle.contains(normalizedQuery)) {
        results.add(
          _DocumentSearchResult(
            document: document,
            range: null,
            snippet: 'Coincide en el título.',
          ),
        );
      }

      var start = 0;
      var hitsInDocument = 0;
      while (hitsInDocument < 3) {
        final matchIndex = lowerContent.indexOf(normalizedQuery, start);
        if (matchIndex < 0) {
          break;
        }
        if (seenStarts.add(matchIndex)) {
          results.add(
            _DocumentSearchResult(
              document: document,
              range: TextRange(
                start: matchIndex,
                end: matchIndex + normalizedQuery.length,
              ),
              snippet: _buildSearchSnippet(
                  document.content, matchIndex, normalizedQuery.length),
            ),
          );
          hitsInDocument += 1;
        }
        start = matchIndex + normalizedQuery.length;
      }
    }

    results.sort((a, b) {
      final aCurrent = a.document.id == currentDocumentId ? 0 : 1;
      final bCurrent = b.document.id == currentDocumentId ? 0 : 1;
      if (aCurrent != bCurrent) {
        return aCurrent.compareTo(bCurrent);
      }
      final orderCompare =
          a.document.orderIndex.compareTo(b.document.orderIndex);
      if (orderCompare != 0) {
        return orderCompare;
      }
      final aStart = a.range?.start ?? -1;
      final bStart = b.range?.start ?? -1;
      return aStart.compareTo(bStart);
    });

    return results.take(14).toList();
  }

  String _buildSearchSnippet(String content, int start, int length) {
    final safeStart = (start - 44).clamp(0, content.length);
    final safeEnd = (start + length + 64).clamp(0, content.length);
    final raw = content.substring(safeStart, safeEnd).replaceAll('\n', ' ');
    final compact = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 110) {
      return compact;
    }
    return '${compact.substring(0, 107).trim()}...';
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref, Book? activeBook) {
    return const SizedBox.shrink();
  }

  Future<void> _handleCreateBook(BuildContext context, WidgetRef ref) async {
    final title = await _promptForText(
      context,
      title: 'Nuevo libro',
      label: 'Título del libro',
      initialValue: 'Nuevo libro',
      actionLabel: 'Crear',
    );
    if (title == null) return;

    await ref.read(narrativeWorkspaceProvider.notifier).createBook(
          title: title,
          firstDocumentTitle: 'Apertura',
        );
  }

  Future<void> _handleCreateScenario(
      BuildContext context, WidgetRef ref) async {
    final name = await _promptForText(
      context,
      title: 'Nuevo escenario',
      label: 'Nombre del escenario',
      initialValue: 'Escenario nuevo',
      actionLabel: 'Crear',
    );
    if (name == null) return;

    await ref.read(narrativeWorkspaceProvider.notifier).createScenario(
          name: name,
          selectAfterCreate: true,
        );
  }

  Future<void> _showBookSwitcher(
    BuildContext context,
    WidgetRef ref,
    List<Book> books,
    Book? activeBook,
  ) async {
    final selectedId = await showDialog<String>(
      context: context,
      builder: (context) {
        final tokens = MusaTheme.tokensOf(context);
        return Dialog(
          backgroundColor: tokens.panelBackground,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cambiar de libro',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Elige el espacio narrativo en el que quieres trabajar.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: tokens.textSecondary,
                                    height: 1.45,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: tokens.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...books.map(
                    (book) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(book.id),
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: tokens.motionNormal,
                          padding: const EdgeInsets.all(16),
                          decoration: MusaTheme.panelDecoration(
                            context,
                            radius: 18,
                            backgroundColor: activeBook?.id == book.id
                                ? tokens.activeBackground
                                : tokens.canvasBackground,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  book.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: tokens.textPrimary,
                                        fontWeight: activeBook?.id == book.id
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                ),
                              ),
                              if (activeBook?.id == book.id)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: Color(0xFF6B7280),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selectedId == null || selectedId == activeBook?.id) return;
    await ref.read(narrativeWorkspaceProvider.notifier).selectBook(selectedId);
  }

  Future<void> _handleCreateDocument(
      BuildContext context, WidgetRef ref) async {
    final title = await _promptForText(
      context,
      title: 'Nuevo',
      label: 'Título',
      initialValue: 'Nuevo',
      actionLabel: 'Crear',
    );
    if (title == null) return;

    await ref.read(narrativeWorkspaceProvider.notifier).addDocument(
          title: title,
          kind: DocumentKind.chapter,
        );
  }

  Future<void> _handleDeleteDocument(
    BuildContext context,
    WidgetRef ref,
    Document document,
  ) async {
    final confirmed = await EditorialDialogs.confirmDestructive(
      context,
      title: 'Eliminar capítulo',
      message:
          'Se eliminará "${document.title}". Esta acción no se puede deshacer.',
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(narrativeWorkspaceProvider.notifier).deleteDocument(document.id);
  }

  Future<void> _handleCreateNote(BuildContext context, WidgetRef ref) async {
    final title = await _promptForText(
      context,
      title: 'Nueva nota',
      label: 'Título de la nota',
      initialValue: 'Nueva nota',
      actionLabel: 'Crear',
    );
    if (title == null) return;

    await ref
        .read(narrativeWorkspaceProvider.notifier)
        .createNote(title: title);
  }

  Future<void> _handleCreateNoteEntry(
      BuildContext context, WidgetRef ref) async {
    final type = await showDialog<_NewNoteType>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva nota'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNoteTypeAction(
                context,
                title: 'Escrita',
                subtitle:
                    'Una nota textual para ideas, estructura o investigación.',
                onTap: () => Navigator.of(context).pop(_NewNoteType.written),
              ),
              const SizedBox(height: 10),
              _buildNoteTypeAction(
                context,
                title: 'Oral',
                subtitle: 'Una nota de voz para capturas rápidas y dictado.',
                onTap: () => Navigator.of(context).pop(_NewNoteType.voice),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: MusaTheme.tokensOf(context).textSecondary,
              ),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (type == null || !context.mounted) return;
    if (type == _NewNoteType.written) {
      await _handleCreateNote(context, ref);
      return;
    }
    await _handleCreateVoiceMemo(context, ref);
  }

  Future<void> _handleCreateCharacter(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final name = await _promptForText(
      context,
      title: 'Nuevo personaje',
      label: 'Nombre del personaje',
      initialValue: 'Nuevo personaje',
      actionLabel: 'Crear',
    );
    if (name == null) return;

    await ref.read(narrativeWorkspaceProvider.notifier).createCharacter(
          name: name,
        );
  }

  Future<void> _handleRenameNote(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    final title = await _promptForText(
      context,
      title: 'Renombrar nota',
      label: 'Título de la nota',
      initialValue: note.title ?? 'Nota sin título',
      actionLabel: 'Guardar',
    );
    if (title == null) return;

    await ref.read(narrativeWorkspaceProvider.notifier).updateNoteTitle(
          note.id,
          title,
        );
  }

  Future<void> _handleCreateVoiceMemo(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final title = await _promptForText(
      context,
      title: 'Nueva nota oral',
      label: 'Título de la nota oral',
      initialValue: 'Nueva nota oral',
      actionLabel: 'Crear',
    );
    if (title == null) return;

    await ref
        .read(narrativeWorkspaceProvider.notifier)
        .createVoiceMemoStub(title: title);
  }

  Future<String?> _promptForText(
    BuildContext context, {
    required String title,
    required String label,
    required String initialValue,
    required String actionLabel,
  }) async {
    return EditorialDialogs.promptForText(
      context,
      title: title,
      label: label,
      initialValue: initialValue,
      actionLabel: actionLabel,
    );
  }

  Widget _buildNoteTypeAction(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final tokens = MusaTheme.tokensOf(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: MusaTheme.panelDecoration(
          context,
          backgroundColor: tokens.panelBackground,
          radius: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNoteEntry {
  const _SidebarNoteEntry({
    required this.title,
    required this.subtitle,
    required this.sortDate,
    this.isSelected = false,
    this.onTap,
    this.onRename,
  });

  final String title;
  final String subtitle;
  final DateTime sortDate;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
}

class _DocumentSearchResult {
  const _DocumentSearchResult({
    required this.document,
    required this.range,
    required this.snippet,
  });

  final Document document;
  final TextRange? range;
  final String? snippet;
}

enum _NewNoteType { written, voice }
