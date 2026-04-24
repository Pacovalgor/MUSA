import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/rendering.dart';

import '../models/editor_selection_context.dart';
import '../../domain/musa/musa_objects.dart' as narrative;
import '../../domain/ia/engine_status.dart';
import '../../modules/books/models/narrative_workspace.dart';
import '../../modules/books/models/narrative_copilot.dart';
import '../../services/ia_providers.dart';
import '../../services/character_autofill_providers.dart';
import '../../services/scenario_autofill_providers.dart';
import '../../services/characters/character_autofill_service.dart';
import '../../services/scenarios/scenario_autofill_service.dart';
import '../../modules/books/providers/workspace_providers.dart';
import '../../modules/characters/models/character.dart';
import '../../modules/characters/models/character_autofill_draft.dart';
import '../../modules/characters/providers/character_providers.dart';
import '../../modules/manuscript/models/document.dart';
import '../../modules/manuscript/providers/document_providers.dart';
import '../../modules/notes/models/note.dart';
import '../../modules/notes/providers/note_providers.dart';
import '../../modules/scenarios/models/scenario.dart';
import '../../modules/scenarios/models/scenario_autofill_draft.dart';
import '../../modules/scenarios/providers/scenario_providers.dart';
import '../../muses/editorial_recommendation.dart';
import '../../muses/musa.dart';
import '../../muses/providers/musa_providers.dart';
import '../models/chapter_analysis.dart';
import '../models/fragment_analysis.dart';
import '../services/chapter_analysis_service.dart';
import '../services/fragment_analysis_service.dart';
import '../services/fragment_inference_utils.dart';
import '../../muses/editorial_signals.dart';
import 'musa_text_editing_controller.dart';
import '../../modules/books/models/writing_settings.dart';
import '../../modules/books/services/story_state_updater.dart';

enum MusaGenerationPhase {
  idle,
  invoking,
  thinking,
  streaming,
  completed,
  failed,
}

/// Immutable state snapshot for the editor surface and its editorial overlays.
class EditorState {
  final TextEditingController controller;
  final FocusNode focusNode;
  final EditorSelectionContext? selectionContext;
  final bool showOverlay;
  final LayerLink layerLink;
  final String? streamingText;
  final narrative.MusaSuggestion? currentSuggestion;
  final String? previousText;
  final bool isComparisonMode;
  final Offset? selectionOffset; // Real pixel-perfect coordinates
  final double viewportWidth;
  final String? documentId;
  final MusaGenerationPhase generationPhase;
  final Musa? activeMusa;
  final EditorialRecommendation? editorialRecommendation;
  final List<Musa> activePipeline;
  final int pipelineStepIndex;
  final List<Musa> musaExecutionHistory;
  final int selectionActionUsageCount;
  final FragmentAnalysis? currentFragmentAnalysis;
  final ChapterAnalysis? currentChapterAnalysis;
  final bool isChapterAnalysisPending;

  EditorState({
    required this.controller,
    required this.focusNode,
    this.selectionContext,
    this.showOverlay = false,
    required this.layerLink,
    this.streamingText,
    this.currentSuggestion,
    this.previousText,
    this.isComparisonMode = false,
    this.selectionOffset,
    this.viewportWidth = 800.0,
    this.documentId,
    this.generationPhase = MusaGenerationPhase.idle,
    this.activeMusa,
    this.editorialRecommendation,
    this.activePipeline = const [],
    this.pipelineStepIndex = 0,
    this.musaExecutionHistory = const [],
    this.selectionActionUsageCount = 0,
    this.currentFragmentAnalysis,
    this.currentChapterAnalysis,
    this.isChapterAnalysisPending = false,
  });

  bool get isProcessing => generationPhase != MusaGenerationPhase.idle;
  bool get hasStartedStreaming =>
      generationPhase == MusaGenerationPhase.streaming;
  bool get hasFinalSuggestion => currentSuggestion != null;
  bool get showSelectionHelper => selectionActionUsageCount < 3;

  EditorState copyWith({
    EditorSelectionContext? selectionContext,
    bool? showOverlay,
    String? streamingText,
    bool clearStreamingText = false,
    narrative.MusaSuggestion? currentSuggestion,
    bool clearSuggestion = false,
    String? previousText,
    bool clearPreviousText = false,
    bool? isComparisonMode,
    Offset? selectionOffset,
    bool clearSelectionOffset = false,
    double? viewportWidth,
    String? documentId,
    MusaGenerationPhase? generationPhase,
    Musa? activeMusa,
    bool clearActiveMusa = false,
    EditorialRecommendation? editorialRecommendation,
    bool clearEditorialRecommendation = false,
    List<Musa>? activePipeline,
    bool clearActivePipeline = false,
    int? pipelineStepIndex,
    List<Musa>? musaExecutionHistory,
    bool clearMusaExecutionHistory = false,
    int? selectionActionUsageCount,
    FragmentAnalysis? currentFragmentAnalysis,
    bool clearFragmentAnalysis = false,
    ChapterAnalysis? currentChapterAnalysis,
    bool clearChapterAnalysis = false,
    bool? isChapterAnalysisPending,
  }) {
    return EditorState(
      controller: controller,
      focusNode: focusNode,
      selectionContext: selectionContext ?? this.selectionContext,
      showOverlay: showOverlay ?? this.showOverlay,
      layerLink: layerLink,
      streamingText:
          clearStreamingText ? null : (streamingText ?? this.streamingText),
      currentSuggestion: clearSuggestion
          ? null
          : (currentSuggestion ?? this.currentSuggestion),
      previousText:
          clearPreviousText ? null : (previousText ?? this.previousText),
      isComparisonMode: isComparisonMode ?? this.isComparisonMode,
      selectionOffset: clearSelectionOffset
          ? null
          : (selectionOffset ?? this.selectionOffset),
      viewportWidth: viewportWidth ?? this.viewportWidth,
      documentId: documentId ?? this.documentId,
      generationPhase: generationPhase ?? this.generationPhase,
      activeMusa: clearActiveMusa ? null : (activeMusa ?? this.activeMusa),
      editorialRecommendation: clearEditorialRecommendation
          ? null
          : (editorialRecommendation ?? this.editorialRecommendation),
      activePipeline: clearActivePipeline
          ? const []
          : (activePipeline ?? this.activePipeline),
      pipelineStepIndex: pipelineStepIndex ?? this.pipelineStepIndex,
      musaExecutionHistory: clearMusaExecutionHistory
          ? const []
          : (musaExecutionHistory ?? this.musaExecutionHistory),
      selectionActionUsageCount:
          selectionActionUsageCount ?? this.selectionActionUsageCount,
      currentFragmentAnalysis: clearFragmentAnalysis
          ? null
          : (currentFragmentAnalysis ?? this.currentFragmentAnalysis),
      currentChapterAnalysis: clearChapterAnalysis
          ? null
          : (currentChapterAnalysis ?? this.currentChapterAnalysis),
      isChapterAnalysisPending:
          isChapterAnalysisPending ?? this.isChapterAnalysisPending,
    );
  }
}

/// Coordinates editor text, selection UI, analysis and Musa invocation flows.
class EditorController extends StateNotifier<EditorState> {
  final Ref _ref;
  final GlobalKey editorKey = GlobalKey();
  StreamSubscription? _aiSubscription;
  bool _isSyncingControllers = false;
  bool _suppressSelectionOverlayOnce = false;
  int _activeRunToken = 0;
  Timer? _narrativeRefreshDebounce;
  Timer? _contentPersistDebounce;

  EditorController(this._ref)
      : super(EditorState(
          controller: MusaTextEditingController(
            writingSettings: _ref.read(writingSettingsProvider),
          ),
          focusNode: FocusNode(),
          layerLink: LayerLink(),
        )) {
    _ref.listen<WritingSettings>(writingSettingsProvider, (_, next) {
      final ctrl = state.controller;
      if (ctrl is MusaTextEditingController) {
        ctrl.updateSettings(next);
      }
    });

    _ref.listen<EditorContentItem?>(currentEditorContentProvider, (_, next) {
      _syncFromItem(next);
    });

    state.controller.addListener(_handleSelectionChange);
    state.controller.addListener(_handleContentChanged);
  }

  void _syncFromItem(EditorContentItem? item) {
    if (item == null) return;
    if (state.documentId == item.id && state.controller.text == item.content) {
      return;
    }

    _isSyncingControllers = true;
    state.controller.value = TextEditingValue(
      text: item.content,
      selection: TextSelection.collapsed(offset: item.content.length),
    );
    _isSyncingControllers = false;

    state = state.copyWith(
      documentId: item.id,
      selectionContext: null,
      showOverlay: false,
      clearSelectionOffset: true,
      clearSuggestion: true,
      clearStreamingText: true,
      clearEditorialRecommendation: true,
      clearActivePipeline: true,
      clearMusaExecutionHistory: true,
      pipelineStepIndex: 0,
      generationPhase: MusaGenerationPhase.idle,
      clearActiveMusa: true,
      clearFragmentAnalysis: true,
      clearChapterAnalysis: true,
      isChapterAnalysisPending: false,
    );
  }

  void _handleContentChanged() {
    if (_isSyncingControllers) return;
    final selectedId = state.documentId;
    if (selectedId == null) return;
    final editorMode = _ref.read(editorModeProvider);
    final currentText = state.controller.text;

    _contentPersistDebounce?.cancel();
    _contentPersistDebounce = Timer(const Duration(milliseconds: 500), () {
      if (editorMode == WorkspaceEditorMode.note) {
        unawaited(
          _ref
              .read(narrativeWorkspaceProvider.notifier)
              .updateNoteContent(selectedId, currentText),
        );
        return;
      }
      unawaited(
        _ref
            .read(narrativeWorkspaceProvider.notifier)
            .updateDocumentContent(selectedId, currentText),
      );
    });
    _scheduleNarrativeRefresh(selectedId);
  }

  void _handleSelectionChange() {
    if (_suppressSelectionOverlayOnce) {
      _suppressSelectionOverlayOnce = false;
      state = state.copyWith(
        selectionContext: null,
        showOverlay: false,
        clearSelectionOffset: true,
      );
      return;
    }

    final selection = state.controller.selection;

    if (selection.isCollapsed) {
      if (state.generationPhase == MusaGenerationPhase.idle) {
        state = state.copyWith(
          selectionContext: null,
          showOverlay: false,
          clearSelectionOffset: true,
          clearFragmentAnalysis: true,
          clearChapterAnalysis: true,
        );
      }
      return;
    }

    final selectedText = state.controller.text.substring(
      selection.start,
      selection.end,
    );

    // 1. Try to get absolute "source of truth" coordinates from RenderEditable
    Offset? realOffset = _getRenderEditableOffset(selection);

    // 2. Fallback to TextPainter if RenderEditable is not available or hasn't rendered yet
    final offset = realOffset ?? _calculateSelectionOffset(selection);

    state = state.copyWith(
      selectionContext: EditorSelectionContext(
        selectedText: selectedText,
        selection: selection,
        position: offset,
      ),
      showOverlay: true,
      selectionOffset: offset,
      clearEditorialRecommendation: true,
      clearActivePipeline: true,
      clearMusaExecutionHistory: true,
      pipelineStepIndex: 0,
      clearFragmentAnalysis: true,
      clearChapterAnalysis: true,
    );
  }

  /// Extracts real coordinates from the Flutter rendering engine.
  Offset? _getRenderEditableOffset(TextSelection selection) {
    try {
      final RenderObject? root = editorKey.currentContext?.findRenderObject();
      if (root == null) return null;

      // Find the RenderEditable deep in the TextField/EditableText tree
      RenderEditable? renderEditable;
      void findRenderEditable(RenderObject object) {
        if (object is RenderEditable) {
          renderEditable = object;
          return;
        }
        object.visitChildren((child) => findRenderEditable(child));
      }

      findRenderEditable(root);

      if (renderEditable == null) return null;

      final editable = renderEditable!;

      // Get real pixel-perfect boxes for the selection
      final endpoints = editable.getEndpointsForSelection(selection);
      if (endpoints.isEmpty) return null;

      // Extract the local points from the RenderEditable
      final startLocal = endpoints.first.point;
      final endLocal = endpoints.last.point;

      // Map these points back to the coordinate system of the TextField (root)
      // This accounts for padding, input decoration offsets, etc.
      final startInTextField =
          editable.localToGlobal(startLocal, ancestor: root);
      final endInTextField = editable.localToGlobal(endLocal, ancestor: root);

      // Calculate top-mid of the selection block in TextField coordinates
      return Offset(
        (startInTextField.dx + endInTextField.dx) / 2,
        startInTextField.dy,
      );
    } catch (_) {
      return null;
    }
  }

  Offset _calculateSelectionOffset(TextSelection selection) {
    final text = state.controller.text;
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 21,
          height: 1.6,
          fontFamily: 'SourceSerif4',
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    // Align with actual editor container width
    const horizontalPadding = 120.0;
    final maxWidth = (state.viewportWidth < 800 ? state.viewportWidth : 800) -
        horizontalPadding;
    textPainter.layout(maxWidth: maxWidth);

    final boxes = textPainter.getBoxesForSelection(selection);
    if (boxes.isEmpty) {
      // Fallback for end of line or empty selections: use the cursor position
      final cursorOffset = textPainter.getOffsetForCaret(
        TextPosition(offset: selection.extentOffset),
        Rect.zero,
      );
      return Offset(cursorOffset.dx, cursorOffset.dy - 10);
    }

    // Calculate centering based on the total bounding box of the selection
    double minTop = boxes.first.top;
    double minLeft = boxes.first.left;
    double maxRight = boxes.first.right;

    for (final box in boxes) {
      if (box.top < minTop) minTop = box.top;
      if (box.left < minLeft) minLeft = box.left;
      if (box.right > maxRight) maxRight = box.right;
    }

    return Offset(
      (minLeft + maxRight) / 2,
      minTop - 10, // 10px lift from the top line
    );
  }

  void updateViewportWidth(double width) {
    if (state.viewportWidth == width) return;
    state = state.copyWith(viewportWidth: width);
    if (!state.controller.selection.isCollapsed) {
      _handleSelectionChange();
    }
  }

  void updateSelectionOffset(Offset offset) {
    if (state.selectionOffset == offset) return;
    state = state.copyWith(selectionOffset: offset);
  }

  Future<void> runMusa({required Musa musa}) async {
    if (state.selectionContext == null || state.isProcessing) {
      return;
    }

    _markSelectionActionUsed();
    await _runMusaSequence(
      musas: <Musa>[musa],
      recommendation: null,
    );
  }

  Future<void> runAutopilotFromSelection() async {
    if (state.selectionContext == null || state.isProcessing) {
      return;
    }

    requestAutopilotRecommendation();
    _markSelectionActionUsed();
    await runRecommendedFirstMusa();
  }

  Future<void> runFragmentAnalysis() async {
    final selectionContext = state.selectionContext;
    final document = _ref.read(currentDocumentProvider);
    if (selectionContext == null || document == null || state.isProcessing) {
      return;
    }

    final analysis = _ref.read(fragmentAnalysisServiceProvider).analyze(
          selection: selectionContext.selectedText,
          characters: _ref.read(charactersProvider),
          scenarios: _ref.read(scenariosProvider),
          linkedCharacterIds: document.characterIds,
          linkedScenarioIds: document.scenarioIds,
        );

    _markSelectionActionUsed();
    state = state.copyWith(
      currentFragmentAnalysis: analysis,
      showOverlay: false,
      clearSuggestion: true,
      clearStreamingText: true,
      clearEditorialRecommendation: true,
      clearActivePipeline: true,
      clearMusaExecutionHistory: true,
      pipelineStepIndex: 0,
      generationPhase: MusaGenerationPhase.idle,
      clearActiveMusa: true,
      clearChapterAnalysis: true,
    );
  }

  Future<void> runChapterAnalysis() async {
    final document = _ref.read(currentDocumentProvider);
    if (document == null || state.isProcessing) {
      return;
    }

    final chapterText = document.content.trim();
    if (chapterText.isEmpty) {
      return;
    }

    state = state.copyWith(
      generationPhase: MusaGenerationPhase.invoking,
      currentChapterAnalysis: null,
      isChapterAnalysisPending: true,
      showOverlay: false,
      selectionContext: null,
      clearSelectionOffset: true,
      clearSuggestion: true,
      clearStreamingText: true,
      clearEditorialRecommendation: true,
      clearActivePipeline: true,
      clearMusaExecutionHistory: true,
      pipelineStepIndex: 0,
      clearActiveMusa: true,
      clearFragmentAnalysis: true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 16));

    final analysis =
        await _ref.read(chapterAnalysisServiceProvider).analyzeAsync(
              chapterText: chapterText,
              characters: _ref.read(charactersProvider),
              scenarios: _ref.read(scenariosProvider),
              linkedCharacterIds: document.characterIds,
              linkedScenarioIds: document.scenarioIds,
            );

    state = state.copyWith(
      currentChapterAnalysis: analysis,
      showOverlay: false,
      selectionContext: null,
      clearSelectionOffset: true,
      clearSuggestion: true,
      clearStreamingText: true,
      clearEditorialRecommendation: true,
      clearActivePipeline: true,
      clearMusaExecutionHistory: true,
      pipelineStepIndex: 0,
      generationPhase: MusaGenerationPhase.idle,
      clearActiveMusa: true,
      clearFragmentAnalysis: true,
      isChapterAnalysisPending: false,
    );
    unawaited(_refreshNarrativeCopilot(
      documentId: document.id,
      chapterAnalysis: analysis,
    ));
  }

  void dismissFragmentAnalysis() {
    state = state.copyWith(clearFragmentAnalysis: true);
  }

  void dismissChapterAnalysis() {
    state = state.copyWith(
      clearChapterAnalysis: true,
      isChapterAnalysisPending: false,
      generationPhase: MusaGenerationPhase.idle,
    );
  }

  Future<void> performInsightAction(InsightAction action) async {
    switch (action.type) {
      case InsightActionType.createProtagonist:
        await createCharacterFromSelection(preferredName: 'Protagonista');
        break;
      case InsightActionType.enrichProtagonist:
      case InsightActionType.enrichCharacter:
        if (action.targetId != null) {
          await enrichCharacterFromSelection(action.targetId!);
        }
        break;
      case InsightActionType.createCharacter:
        await createCharacterFromSelection(preferredName: action.entityName);
        break;
      case InsightActionType.linkCharacter:
        if (action.targetId != null) {
          await linkSelectionToCharacter(action.targetId!);
        }
        break;
      case InsightActionType.createScenario:
        await createScenarioFromSelection(preferredName: action.entityName);
        break;
      case InsightActionType.linkScenario:
        if (action.targetId != null) {
          await linkSelectionToScenario(action.targetId!);
        }
        break;
      case InsightActionType.enrichScenario:
        if (action.targetId != null) {
          await enrichScenarioFromSelection(action.targetId!);
        }
        break;
    }
  }

  Future<void> performChapterNextStep(ChapterNextStep step) async {
    switch (step.type) {
      case NextStepType.createCharacter:
        await createCharacterFromChapterAnalysis(
            preferredName: step.entityName);
        break;
      case NextStepType.enrichCharacter:
        if (step.targetId != null) {
          await enrichCharacterFromChapterAnalysis(step.targetId!);
        }
        break;
      case NextStepType.createScenario:
        await createScenarioFromChapterAnalysis(preferredName: step.entityName);
        break;
      case NextStepType.enrichScenario:
        if (step.targetId != null) {
          await enrichScenarioFromChapterAnalysis(step.targetId!);
        }
        break;
      case NextStepType.strengthenConflict:
      case NextStepType.connectToPlot:
      case NextStepType.expandMoment:
        break;
    }
  }

  ExpandMomentEditorialAid buildExpandMomentEditorialAid(
    ChapterAnalysis analysis,
  ) {
    final isSpanish = _inferChapterAnalysisLanguage(analysis) == 'Spanish';
    final problem = _buildExpandMomentProblem(
      analysis: analysis,
      isSpanish: isSpanish,
    );
    final directions = _pickExpandMomentDirections(
      analysis: analysis,
      isSpanish: isSpanish,
    );
    return ExpandMomentEditorialAid(
      problem: problem,
      directions: directions.take(3).toList(),
    );
  }

  Future<bool> useExpandMomentDirection(
    ExpandMomentDirection direction,
  ) async {
    final analysis = state.currentChapterAnalysis;
    final document = _ref.read(currentDocumentProvider);
    if (analysis == null || document == null) {
      return false;
    }

    final isSpanish = _inferChapterAnalysisLanguage(analysis) == 'Spanish';
    final title = isSpanish
        ? 'Empujar momento en ${document.title}'
        : 'Push moment in ${document.title}';
    final content = _buildExpandMomentNoteContent(
      analysis: analysis,
      direction: direction,
      documentTitle: document.title,
      isSpanish: isSpanish,
    );
    final note =
        await _ref.read(narrativeWorkspaceProvider.notifier).createWorkflowNote(
              title: title,
              content: content,
              workflowType: EditorialWorkflowType.expandMoment,
              workflowDirectionKey: direction.type.name,
              sourceDocumentId: document.id,
              sourceDocumentTitle: document.title,
            );
    return note != null;
  }

  ConnectToPlotEditorialAid buildConnectToPlotEditorialAid(
    ChapterAnalysis analysis,
  ) {
    final isSpanish = _inferChapterAnalysisLanguage(analysis) == 'Spanish';
    return ConnectToPlotEditorialAid(
      problem: isSpanish
          ? 'El capítulo ya sostiene una línea de investigación, pero todavía necesita amarrarse mejor a la trama que viene empujando el libro.'
          : 'The chapter already sustains an investigative line, but it still needs a clearer tie back into the book-wide plot.',
      directions: _buildConnectToPlotDirections(isSpanish: isSpanish),
    );
  }

  Future<bool> useConnectToPlotDirection(
    ConnectToPlotDirection direction,
  ) async {
    final analysis = state.currentChapterAnalysis;
    final document = _ref.read(currentDocumentProvider);
    if (analysis == null || document == null) {
      return false;
    }

    final isSpanish = _inferChapterAnalysisLanguage(analysis) == 'Spanish';
    final title = isSpanish
        ? 'Conectar trama en ${document.title}'
        : 'Connect plot in ${document.title}';
    final content = _buildConnectToPlotNoteContent(
      analysis: analysis,
      direction: direction,
      documentTitle: document.title,
      isSpanish: isSpanish,
    );
    final note =
        await _ref.read(narrativeWorkspaceProvider.notifier).createWorkflowNote(
              title: title,
              content: content,
              workflowType: EditorialWorkflowType.connectToPlot,
              workflowDirectionKey: direction.type.name,
              sourceDocumentId: document.id,
              sourceDocumentTitle: document.title,
            );
    return note != null;
  }

  void requestAutopilotRecommendation() {
    if (state.selectionContext == null || state.isProcessing) {
      return;
    }

    final contextBundle = _buildEditorialContext();
    final autopilot = _ref.read(musaAutopilotProvider);
    final recommendation = autopilot.recommend(
      selection: state.selectionContext!.selectedText,
      context: contextBundle.narrativeContext,
    );

    state = state.copyWith(
      editorialRecommendation: recommendation,
      showOverlay: true,
      clearSuggestion: true,
      clearStreamingText: true,
      clearActivePipeline: true,
      clearMusaExecutionHistory: true,
      pipelineStepIndex: 0,
      generationPhase: MusaGenerationPhase.idle,
      clearActiveMusa: true,
      clearFragmentAnalysis: true,
      clearChapterAnalysis: true,
    );
  }

  Future<void> runRecommendedPipeline() async {
    final recommendation = state.editorialRecommendation;
    if (recommendation == null) {
      return;
    }
    await _runMusaSequence(
      musas: recommendation.musas,
      recommendation: recommendation,
    );
  }

  Future<void> runRecommendedFirstMusa() async {
    final recommendation = state.editorialRecommendation;
    if (recommendation == null) {
      return;
    }
    await _runMusaSequence(
      musas: <Musa>[recommendation.primaryMusa],
      recommendation: recommendation,
    );
  }

  void clearEditorialRecommendation() {
    if (state.isProcessing) {
      return;
    }
    state = state.copyWith(
      clearEditorialRecommendation: true,
      clearActivePipeline: true,
      clearMusaExecutionHistory: true,
      pipelineStepIndex: 0,
      clearFragmentAnalysis: true,
      clearChapterAnalysis: true,
    );
  }

  Future<void> createCharacterFromSelection({String? preferredName}) async {
    final selectionContext = state.selectionContext;
    final workspace = _ref.read(narrativeWorkspaceProvider).value;
    final document = _ref.read(currentDocumentProvider);
    final book = _ref.read(activeBookProvider);

    if (selectionContext == null ||
        workspace == null ||
        document == null ||
        book == null) {
      return;
    }

    final selectedText = selectionContext.selectedText.trim();
    if (selectedText.isEmpty) return;

    _markSelectionActionUsed();
    final isProtagonist = _shouldCreateAsProtagonist(
      selectedText: selectedText,
      preferredName: preferredName,
    );
    final inferredName = _inferCharacterName(selectedText);
    final provisionalName =
        (preferredName != null && preferredName.trim().isNotEmpty)
            ? preferredName.trim()
            : isProtagonist
                ? 'Protagonista'
                : inferredName.isNotEmpty
                    ? inferredName
                    : 'Narrador';
    final inferredRole = _inferCharacterRole(
      selectedText,
      provisionalName,
      isProtagonist: isProtagonist,
    );
    final inferredSummary = _inferCharacterSummary(
      selectedText,
      provisionalName,
      isProtagonist: isProtagonist,
    );
    final notes = isProtagonist
        ? 'Creado desde el manuscrito en "${document.title}". Posible protagonista o narrador en primera persona.'
        : 'Creado desde el manuscrito en "${document.title}".';

    final createdCharacter =
        await _ref.read(narrativeWorkspaceProvider.notifier).createCharacter(
              name: provisionalName,
              role: inferredRole,
              summary: inferredSummary,
              notes: notes,
              isProtagonist: isProtagonist,
              linkToSelectedDocument: true,
              selectAfterCreate: false,
            );

    state = state.copyWith(
      selectionContext: null,
      showOverlay: false,
      clearSelectionOffset: true,
      clearFragmentAnalysis: true,
    );

    if (createdCharacter != null) {
      unawaited(
        _autofillCharacterFromSelection(
          character: createdCharacter,
          selectionContext: selectionContext,
          documentTitle: document.title,
          bookTitle: book.title,
          bookSummary: book.summary,
          workspace: workspace,
          linkedCharacterIds: document.characterIds,
        ),
      );
    }
  }

  Future<void> createCharacterFromChapterAnalysis(
      {String? preferredName}) async {
    final workspace = _ref.read(narrativeWorkspaceProvider).value;
    final document = _ref.read(currentDocumentProvider);
    final book = _ref.read(activeBookProvider);

    if (workspace == null || document == null || book == null) {
      return;
    }

    final provisionalName =
        (preferredName != null && preferredName.trim().isNotEmpty)
            ? preferredName.trim()
            : 'Nuevo personaje';
    final chapterSelection =
        _buildFocusedChapterSelection(document.content, provisionalName);
    final focusedText = chapterSelection.selectedText.trim();
    final inferredRole = _inferCharacterRole(
      focusedText,
      provisionalName,
      isProtagonist: false,
    );
    final inferredSummary = _inferCharacterSummary(
      focusedText,
      provisionalName,
      isProtagonist: false,
    );
    final chapterContext =
        _buildFocusedChapterContext(document.content, provisionalName);

    final createdCharacter =
        await _ref.read(narrativeWorkspaceProvider.notifier).createCharacter(
              name: provisionalName,
              role: inferredRole,
              summary: inferredSummary,
              notes:
                  'Creado desde el análisis del capítulo en "${document.title}".',
              linkToSelectedDocument: true,
              selectAfterCreate: false,
            );

    if (createdCharacter != null && focusedText.isNotEmpty) {
      unawaited(
        _autofillCharacterFromSelection(
          character: createdCharacter,
          selectionContext: chapterSelection,
          documentTitle: document.title,
          bookTitle: book.title,
          bookSummary: book.summary,
          workspace: workspace,
          linkedCharacterIds: document.characterIds,
          nearbyContextOverride: chapterContext,
        ),
      );
    }

    state = state.copyWith(clearChapterAnalysis: true);
  }

  Future<void> enrichCharacterFromChapterAnalysis(String characterId) async {
    final workspace = _ref.read(narrativeWorkspaceProvider).value;
    final document = _ref.read(currentDocumentProvider);
    final book = _ref.read(activeBookProvider);

    if (workspace == null || document == null || book == null) {
      return;
    }

    Character? character;
    for (final item in workspace.characters) {
      if (item.id == characterId) {
        character = item;
        break;
      }
    }
    if (character == null) return;

    final chapterSelection =
        _buildFocusedChapterSelection(document.content, character.displayName);
    final focusedText = chapterSelection.selectedText.trim();
    if (focusedText.isEmpty) {
      await _ref
          .read(narrativeWorkspaceProvider.notifier)
          .selectCharacter(character.id);
      state = state.copyWith(clearChapterAnalysis: true);
      return;
    }

    await _ref
        .read(narrativeWorkspaceProvider.notifier)
        .linkCharacterToDocument(
          documentId: document.id,
          characterId: character.id,
        );
    await _ref
        .read(narrativeWorkspaceProvider.notifier)
        .selectCharacter(character.id);

    unawaited(
      _enrichCharacterFromSelection(
        character: character,
        selectionContext: chapterSelection,
        documentTitle: document.title,
        bookTitle: book.title,
        bookSummary: book.summary,
        workspace: workspace,
        linkedCharacterIds: document.characterIds,
      ),
    );

    state = state.copyWith(clearChapterAnalysis: true);
  }

  String suggestedCharacterNameForSelection() {
    final selectionContext = state.selectionContext;
    if (selectionContext == null) {
      return 'Nuevo personaje';
    }

    final selectedText = selectionContext.selectedText.trim();
    if (selectedText.isEmpty) {
      return 'Nuevo personaje';
    }

    return _looksLikeFirstPersonNarrator(selectedText)
        ? 'Protagonista'
        : (() {
            final inferredName = _inferCharacterName(selectedText);
            return inferredName.isNotEmpty ? inferredName : 'Narrador';
          })();
  }

  Future<bool> linkSelectionToCharacter(String characterId) async {
    final document = _ref.read(currentDocumentProvider);
    if (document == null) return false;
    _markSelectionActionUsed();
    final alreadyLinked = document.characterIds.contains(characterId);
    if (!alreadyLinked) {
      await _ref
          .read(narrativeWorkspaceProvider.notifier)
          .linkCharacterToDocument(
            documentId: document.id,
            characterId: characterId,
          );
    }
    state = state.copyWith(clearFragmentAnalysis: true);
    return !alreadyLinked;
  }

  Future<void> enrichCharacterFromSelection(String characterId) async {
    final selectionContext = state.selectionContext;
    final workspace = _ref.read(narrativeWorkspaceProvider).value;
    final document = _ref.read(currentDocumentProvider);
    final book = _ref.read(activeBookProvider);

    if (selectionContext == null ||
        workspace == null ||
        document == null ||
        book == null) {
      return;
    }

    Character? character;
    for (final item in workspace.characters) {
      if (item.id == characterId) {
        character = item;
        break;
      }
    }
    if (character == null) return;

    final selectedText = selectionContext.selectedText.trim();
    await _ref
        .read(narrativeWorkspaceProvider.notifier)
        .linkCharacterToDocument(
          documentId: document.id,
          characterId: character.id,
        );
    await _ref
        .read(narrativeWorkspaceProvider.notifier)
        .selectCharacter(character.id);
    if (selectedText.isEmpty) {
      state = state.copyWith(
        selectionContext: null,
        showOverlay: false,
        clearSelectionOffset: true,
        clearFragmentAnalysis: true,
      );
      return;
    }

    _markSelectionActionUsed();

    state = state.copyWith(
      selectionContext: null,
      showOverlay: false,
      clearSelectionOffset: true,
      clearFragmentAnalysis: true,
    );

    unawaited(
      _enrichCharacterFromSelection(
        character: character,
        selectionContext: selectionContext,
        documentTitle: document.title,
        bookTitle: book.title,
        bookSummary: book.summary,
        workspace: workspace,
        linkedCharacterIds: document.characterIds,
      ),
    );
  }

  Future<void> createScenarioFromSelection({String? preferredName}) async {
    final selectionContext = state.selectionContext;
    final workspace = _ref.read(narrativeWorkspaceProvider).value;
    final document = _ref.read(currentDocumentProvider);
    final book = _ref.read(activeBookProvider);

    if (selectionContext == null ||
        workspace == null ||
        document == null ||
        book == null) {
      return;
    }

    final selectedText = selectionContext.selectedText.trim();
    if (selectedText.isEmpty) return;

    _markSelectionActionUsed();
    final inferredName = _inferScenarioName(selectedText);
    final provisionalName =
        (preferredName != null && preferredName.trim().isNotEmpty)
            ? preferredName.trim()
            : inferredName.isNotEmpty
                ? inferredName
                : 'Escenario nuevo';

    final createdScenario =
        await _ref.read(narrativeWorkspaceProvider.notifier).createScenario(
              name: provisionalName,
              notes: 'Creado desde el manuscrito en "${document.title}".',
              linkToSelectedDocument: true,
              selectAfterCreate: false,
            );

    state = state.copyWith(
      selectionContext: null,
      showOverlay: false,
      clearSelectionOffset: true,
      clearFragmentAnalysis: true,
    );

    if (createdScenario != null) {
      unawaited(
        _autofillScenarioFromSelection(
          scenario: createdScenario,
          selectionContext: selectionContext,
          documentTitle: document.title,
          bookTitle: book.title,
          bookSummary: book.summary,
          workspace: workspace,
          linkedScenarioIds: document.scenarioIds,
        ),
      );
    }
  }

  Future<void> createScenarioFromChapterAnalysis(
      {String? preferredName}) async {
    final workspace = _ref.read(narrativeWorkspaceProvider).value;
    final document = _ref.read(currentDocumentProvider);
    final book = _ref.read(activeBookProvider);
    if (workspace == null || document == null || book == null) {
      return;
    }

    final provisionalName =
        (preferredName != null && preferredName.trim().isNotEmpty)
            ? preferredName.trim()
            : 'Escenario nuevo';
    final chapterSelection =
        _buildFocusedChapterSelection(document.content, provisionalName);
    final focusedText = chapterSelection.selectedText.trim();
    final inferredRole = _inferScenarioRole(focusedText, provisionalName);
    final inferredSummary = _inferScenarioSummary(focusedText, provisionalName);
    final chapterContext =
        _buildFocusedChapterContext(document.content, provisionalName);

    final createdScenario =
        await _ref.read(narrativeWorkspaceProvider.notifier).createScenario(
              name: provisionalName,
              role: inferredRole,
              summary: inferredSummary,
              notes:
                  'Creado desde el análisis del capítulo en "${document.title}".',
              linkToSelectedDocument: true,
              selectAfterCreate: false,
            );

    if (createdScenario != null && focusedText.isNotEmpty) {
      unawaited(
        _autofillScenarioFromSelection(
          scenario: createdScenario,
          selectionContext: chapterSelection,
          documentTitle: document.title,
          bookTitle: book.title,
          bookSummary: book.summary,
          workspace: workspace,
          linkedScenarioIds: document.scenarioIds,
          nearbyContextOverride: chapterContext,
        ),
      );
    }

    state = state.copyWith(clearChapterAnalysis: true);
  }

  Future<void> enrichScenarioFromChapterAnalysis(String scenarioId) async {
    final workspace = _ref.read(narrativeWorkspaceProvider).value;
    final document = _ref.read(currentDocumentProvider);
    final book = _ref.read(activeBookProvider);

    if (workspace == null || document == null || book == null) {
      return;
    }

    Scenario? scenario;
    for (final item in workspace.scenarios) {
      if (item.id == scenarioId) {
        scenario = item;
        break;
      }
    }
    if (scenario == null) return;

    final chapterSelection =
        _buildFocusedChapterSelection(document.content, scenario.displayName);
    final focusedText = chapterSelection.selectedText.trim();
    if (focusedText.isEmpty) {
      await _ref.read(narrativeWorkspaceProvider.notifier).selectScenario(
            scenario.id,
          );
      state = state.copyWith(clearChapterAnalysis: true);
      return;
    }

    await _ref.read(narrativeWorkspaceProvider.notifier).linkScenarioToDocument(
          documentId: document.id,
          scenarioId: scenario.id,
        );
    await _ref
        .read(narrativeWorkspaceProvider.notifier)
        .selectScenario(scenario.id);

    unawaited(
      _enrichScenarioFromSelection(
        scenario: scenario,
        selectionContext: chapterSelection,
        documentTitle: document.title,
        bookTitle: book.title,
        bookSummary: book.summary,
        workspace: workspace,
        linkedScenarioIds: document.scenarioIds,
      ),
    );

    state = state.copyWith(clearChapterAnalysis: true);
  }

  String suggestedScenarioNameForSelection() {
    final selectionContext = state.selectionContext;
    if (selectionContext == null) {
      return 'Escenario nuevo';
    }

    final inferred = _inferScenarioName(selectionContext.selectedText.trim());
    return inferred.isEmpty ? 'Escenario nuevo' : inferred;
  }

  Future<bool> linkSelectionToScenario(String scenarioId) async {
    final document = _ref.read(currentDocumentProvider);
    if (document == null) return false;
    _markSelectionActionUsed();
    final alreadyLinked = document.scenarioIds.contains(scenarioId);
    if (!alreadyLinked) {
      await _ref
          .read(narrativeWorkspaceProvider.notifier)
          .linkScenarioToDocument(
            documentId: document.id,
            scenarioId: scenarioId,
          );
    }
    state = state.copyWith(clearFragmentAnalysis: true);
    return !alreadyLinked;
  }

  Future<void> enrichScenarioFromSelection(String scenarioId) async {
    final selectionContext = state.selectionContext;
    final workspace = _ref.read(narrativeWorkspaceProvider).value;
    final document = _ref.read(currentDocumentProvider);
    final book = _ref.read(activeBookProvider);

    if (selectionContext == null ||
        workspace == null ||
        document == null ||
        book == null) {
      return;
    }

    Scenario? scenario;
    for (final item in workspace.scenarios) {
      if (item.id == scenarioId) {
        scenario = item;
        break;
      }
    }
    if (scenario == null) return;

    final selectedText = selectionContext.selectedText.trim();
    await _ref.read(narrativeWorkspaceProvider.notifier).linkScenarioToDocument(
          documentId: document.id,
          scenarioId: scenario.id,
        );
    await _ref
        .read(narrativeWorkspaceProvider.notifier)
        .selectScenario(scenario.id);
    if (selectedText.isEmpty) {
      state = state.copyWith(
        selectionContext: null,
        showOverlay: false,
        clearSelectionOffset: true,
        clearFragmentAnalysis: true,
      );
      return;
    }

    _markSelectionActionUsed();

    state = state.copyWith(
      selectionContext: null,
      showOverlay: false,
      clearSelectionOffset: true,
      clearFragmentAnalysis: true,
    );

    unawaited(
      _enrichScenarioFromSelection(
        scenario: scenario,
        selectionContext: selectionContext,
        documentTitle: document.title,
        bookTitle: book.title,
        bookSummary: book.summary,
        workspace: workspace,
        linkedScenarioIds: document.scenarioIds,
      ),
    );
  }

  void acceptSuggestion() {
    if (state.currentSuggestion == null || state.selectionContext == null) {
      return;
    }

    final result = state.currentSuggestion!.suggestedText;
    final selection = state.selectionContext!.selection;
    final text = state.controller.text;
    final originalText = text;

    final newText = text.replaceRange(selection.start, selection.end, result);

    state.controller.value = TextEditingValue(
      text: newText,
      selection:
          TextSelection.collapsed(offset: selection.start + result.length),
    );

    state = state.copyWith(
      clearSuggestion: true,
      selectionContext: null,
      previousText: originalText,
      isComparisonMode: false,
      clearSelectionOffset: true,
      generationPhase: MusaGenerationPhase.idle,
      clearActiveMusa: true,
      clearEditorialRecommendation: true,
      clearActivePipeline: true,
      clearMusaExecutionHistory: true,
      pipelineStepIndex: 0,
      clearFragmentAnalysis: true,
    );
  }

  void discardSuggestion() {
    _activeRunToken += 1;
    _aiSubscription?.cancel();
    state = state.copyWith(
      clearSuggestion: true,
      clearStreamingText: true,
      clearSelectionOffset: true,
      generationPhase: MusaGenerationPhase.idle,
      clearActiveMusa: true,
      clearEditorialRecommendation: true,
      clearActivePipeline: true,
      clearMusaExecutionHistory: true,
      pipelineStepIndex: 0,
      clearFragmentAnalysis: true,
    );
  }

  void undoSuggestion() {
    if (state.previousText == null) return;
    state.controller.text = state.previousText!;
    state = state.copyWith(clearPreviousText: true);
  }

  void toggleComparisonMode() =>
      state = state.copyWith(isComparisonMode: !state.isComparisonMode);
  void hideOverlay() => state = state.copyWith(showOverlay: false);

  void highlightDocumentRange({
    required int start,
    required int end,
  }) {
    final textLength = state.controller.text.length;
    if (textLength == 0) return;

    final safeStart = start.clamp(0, textLength);
    final safeEnd = end.clamp(safeStart, textLength);
    if (safeStart == safeEnd) return;

    _suppressSelectionOverlayOnce = true;
    state.focusNode.requestFocus();
    state.controller.selection = TextSelection(
      baseOffset: safeStart,
      extentOffset: safeEnd,
    );
  }

  Future<void> openDocumentAtRange({
    required String documentId,
    TextRange? range,
  }) async {
    final currentDocument = _ref.read(currentDocumentProvider);
    final editorMode = _ref.read(editorModeProvider);

    if (currentDocument?.id != documentId ||
        editorMode != WorkspaceEditorMode.document) {
      await _ref.read(narrativeWorkspaceProvider.notifier).selectDocument(
            documentId,
          );
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    if (range != null && !range.isCollapsed) {
      highlightDocumentRange(
        start: range.start,
        end: range.end,
      );
      return;
    }

    state.focusNode.requestFocus();
    state = state.copyWith(
      showOverlay: false,
      selectionContext: null,
      clearSelectionOffset: true,
    );
  }

  void _markSelectionActionUsed() {
    final currentCount = state.selectionActionUsageCount;
    if (currentCount >= 3) return;
    state = state.copyWith(selectionActionUsageCount: currentCount + 1);
  }

  Future<void> _runMusaSequence({
    required List<Musa> musas,
    required EditorialRecommendation? recommendation,
  }) async {
    if (state.selectionContext == null || musas.isEmpty) {
      return;
    }

    final contextBundle = _buildEditorialContext();
    final iaService = _ref.read(iaServiceProvider);
    final selection = state.selectionContext!;
    final originalSelection = selection.selectedText;

    if (iaService.status.value != EngineStatus.ready) {
      state = state.copyWith(
        currentSuggestion: narrative.MusaSuggestion(
          id: 'error',
          originalText: originalSelection,
          suggestedText:
              'El motor de IA local se está preparando. Vuelve a intentarlo en unos segundos.',
          editorComment:
              'Asegúrate de que los recursos del sistema estén disponibles para cargar el modelo.',
        ),
        generationPhase: MusaGenerationPhase.failed,
        clearFragmentAnalysis: true,
      );
      return;
    }

    _activeRunToken += 1;
    final runToken = _activeRunToken;

    state = state.copyWith(
      generationPhase: MusaGenerationPhase.invoking,
      showOverlay: true,
      clearSuggestion: true,
      clearStreamingText: true,
      activeMusa: musas.first,
      editorialRecommendation: recommendation,
      activePipeline: musas,
      pipelineStepIndex: 0,
      musaExecutionHistory: const [],
      isComparisonMode: false,
      clearFragmentAnalysis: true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 16));

    var currentInput = originalSelection;
    narrative.MusaSuggestion? finalSuggestion;

    for (var index = 0; index < musas.length; index += 1) {
      if (runToken != _activeRunToken) {
        return;
      }

      final musa = musas[index];

      // Feedback loop: check if next musa is still needed
      // If current input no longer has the signal this musa targets, skip it
      if (index > 0 && _shouldSkipMusaByFeedback(musa, currentInput)) {
        final updatedHistory = <Musa>[
          ...state.musaExecutionHistory,
          musa, // still record it, but mark as "skipped by feedback"
        ];
        state = state.copyWith(musaExecutionHistory: updatedHistory);
        continue; // Skip execution
      }

      state = state.copyWith(
        activeMusa: musa,
        generationPhase: MusaGenerationPhase.invoking,
        pipelineStepIndex: index,
        clearStreamingText: true,
      );

      final stepSuggestion = await _executeMusaStep(
        runToken: runToken,
        musa: musa,
        inputText: currentInput,
        contextBundle: contextBundle,
        originalSelection: originalSelection,
        stepIndex: index,
      );

      if (stepSuggestion == null || runToken != _activeRunToken) {
        return;
      }

      if (stepSuggestion.id == 'error' ||
          stepSuggestion.id.startsWith('error')) {
        state = state.copyWith(
          currentSuggestion: stepSuggestion,
          generationPhase: MusaGenerationPhase.failed,
          showOverlay: false,
        );
        return;
      }

      final updatedHistory = <Musa>[
        ...state.musaExecutionHistory,
        musa,
      ];

      state = state.copyWith(musaExecutionHistory: updatedHistory);
      currentInput = stepSuggestion.suggestedText;
      finalSuggestion = stepSuggestion;
    }

    if (finalSuggestion == null || runToken != _activeRunToken) {
      return;
    }

    state = state.copyWith(
      currentSuggestion: narrative.MusaSuggestion(
        id: finalSuggestion.id,
        originalText: originalSelection,
        suggestedText: finalSuggestion.suggestedText,
        editorComment: _buildPipelineEditorComment(
            recommendation, state.musaExecutionHistory),
      ),
      clearStreamingText: true,
      generationPhase: MusaGenerationPhase.completed,
      showOverlay: false,
    );
  }

  Future<narrative.MusaSuggestion?> _executeMusaStep({
    required int runToken,
    required Musa musa,
    required String inputText,
    required _EditorialContextBundle contextBundle,
    required String originalSelection,
    required int stepIndex,
  }) async {
    final iaService = _ref.read(iaServiceProvider);
    final musaSettings = _ref.read(musaSettingsProvider);
    final request = narrative.MusaRequest(
      selection: inputText,
      documentTitle: contextBundle.documentTitle,
      documentContext: contextBundle.documentContent,
      narrativeContext: contextBundle.narrativeContext,
      musa: musa,
      settings: musaSettings,
    );

    final completer = Completer<narrative.MusaSuggestion?>();
    var accumulatedText = '';
    _aiSubscription?.cancel();
    state = state.copyWith(generationPhase: MusaGenerationPhase.thinking);
    await Future<void>.delayed(const Duration(milliseconds: 16));

    _aiSubscription = iaService.processRequest(request).listen(
      (response) {
        if (runToken != _activeRunToken) {
          return;
        }

        if (response is narrative.MusaChunk) {
          accumulatedText += response.delta;
          state = state.copyWith(
            streamingText: accumulatedText,
            generationPhase: MusaGenerationPhase.streaming,
          );
        } else if (response is narrative.MusaSuggestion) {
          if (!completer.isCompleted) {
            completer.complete(response);
          }
        }
      },
      onError: (e) {
        if (!completer.isCompleted) {
          completer.complete(
            narrative.MusaSuggestion(
              id: 'error',
              originalText: originalSelection,
              suggestedText: 'Error en el motor local: $e',
              editorComment: 'Revisa los logs del sistema para más detalles.',
            ),
          );
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );

    return completer.future;
  }

  _EditorialContextBundle _buildEditorialContext() {
    final workspace = _ref.read(narrativeWorkspaceProvider).value;
    final book = _ref.read(activeBookProvider);
    final document = _ref.read(currentDocumentProvider);
    final note = _ref.read(currentNoteProvider);
    final editorMode = _ref.read(editorModeProvider);
    final continuity = workspace?.activeContinuityState;

    final documentTitle = editorMode == WorkspaceEditorMode.note
        ? (note?.title ?? 'Nota sin titulo')
        : (document?.title ?? 'Documento sin titulo');
    final documentContent = editorMode == WorkspaceEditorMode.note
        ? (note?.content ?? state.controller.text)
        : (document?.content ?? state.controller.text);
    final linkedCharacterIds = (editorMode == WorkspaceEditorMode.note
            ? note?.characterIds
            : document?.characterIds) ??
        const <String>[];
    final linkedScenarioIds = (editorMode == WorkspaceEditorMode.note
            ? note?.scenarioIds
            : document?.scenarioIds) ??
        const <String>[];
    final characterSummary = _buildCharacterSummary(
      workspace: workspace,
      linkedCharacterIds: linkedCharacterIds,
    );
    final scenarioSummary = _buildScenarioSummary(
      workspace: workspace,
      linkedScenarioIds: linkedScenarioIds,
    );

    final narrativeContext = narrative.NarrativeContext(
      bookTitle: book?.title ?? 'Libro sin titulo',
      documentTitle: documentTitle,
      projectSummary: continuity?.projectSummary ??
          book?.summary ??
          'Borrador inicial de historia.',
      knownFacts: continuity?.knownFacts ?? const [],
      openQuestions: continuity?.openQuestions ?? const [],
      motifs: continuity?.motifs ?? const [],
      tensionLevel: continuity?.currentTensionLevel ?? 'neutral',
      metadata: {
        'bookId': book?.id,
        'documentId': document?.id,
        'noteId': note?.id,
        'characterIds': linkedCharacterIds,
        'charactersSummary': characterSummary,
        'scenarioIds': linkedScenarioIds,
        'scenariosSummary': scenarioSummary,
        'sourceType': editorMode.name,
      },
    );

    return _EditorialContextBundle(
      documentTitle: documentTitle,
      documentContent: documentContent,
      narrativeContext: narrativeContext,
    );
  }

  List<String> _buildCharacterSummary({
    required NarrativeWorkspace? workspace,
    required List<String> linkedCharacterIds,
  }) {
    final activeBookId = workspace?.activeBook?.id;
    if (workspace == null || activeBookId == null) return const [];

    final protagonists = <Character>[];
    final linked = <Character>[];
    final recent = <Character>[];
    for (final character in workspace.characters) {
      if (character.bookId != activeBookId) continue;
      if (character.isProtagonist) {
        protagonists.add(character);
      } else if (linkedCharacterIds.contains(character.id)) {
        linked.add(character);
      } else {
        recent.add(character);
      }
    }

    linked.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    recent.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    protagonists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final selected = protagonists.isNotEmpty
        ? protagonists
        : (linked.isNotEmpty ? linked : recent);

    final summaries = <String>[];
    for (final character in selected.take(4)) {
      summaries.add(_compactCharacterSummary(character));
    }
    return summaries;
  }

  String _compactCharacterSummary(Character character) {
    final segments = <String>[
      character.displayName,
      if (character.isProtagonist) 'protagonista',
      if (character.role.trim().isNotEmpty) 'rol: ${character.role.trim()}',
      if (character.summary.trim().isNotEmpty)
        'quien es: ${_truncate(character.summary.trim(), 120)}',
      if (character.voice.trim().isNotEmpty)
        'voz: ${_truncate(character.voice.trim(), 80)}',
      if (character.motivation.trim().isNotEmpty)
        'quiere: ${_truncate(character.motivation.trim(), 80)}',
      if (character.currentState.trim().isNotEmpty)
        'estado: ${_truncate(character.currentState.trim(), 80)}',
    ];
    return segments.join(' | ');
  }

  List<String> _buildScenarioSummary({
    required NarrativeWorkspace? workspace,
    required List<String> linkedScenarioIds,
  }) {
    final activeBookId = workspace?.activeBook?.id;
    if (workspace == null || activeBookId == null) return const [];

    final linked = <Scenario>[];
    final recent = <Scenario>[];
    for (final scenario in workspace.scenarios) {
      if (scenario.bookId != activeBookId) continue;
      if (linkedScenarioIds.contains(scenario.id)) {
        linked.add(scenario);
      } else {
        recent.add(scenario);
      }
    }

    linked.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    recent.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final selected = linked.isNotEmpty ? linked : recent;

    final summaries = <String>[];
    for (final scenario in selected.take(4)) {
      summaries.add(_compactScenarioSummary(scenario));
    }
    return summaries;
  }

  String _compactScenarioSummary(Scenario scenario) {
    final segments = <String>[
      scenario.displayName,
      if (scenario.role.trim().isNotEmpty)
        'funcion: ${_truncate(scenario.role.trim(), 70)}',
      if (scenario.summary.trim().isNotEmpty)
        'resumen: ${_truncate(scenario.summary.trim(), 120)}',
      if (scenario.atmosphere.trim().isNotEmpty)
        'atmosfera: ${_truncate(scenario.atmosphere.trim(), 80)}',
      if (scenario.currentState.trim().isNotEmpty)
        'estado: ${_truncate(scenario.currentState.trim(), 80)}',
    ];
    return segments.join(' | ');
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 1)}…';
  }

  String _inferCharacterName(String selection) {
    final normalized = selection.trim().replaceAll(RegExp(r'\s+'), ' ');
    const blockedSingleWords = <String>{
      'Me',
      'Mi',
      'Yo',
      'Lo',
      'La',
      'Le',
      'El',
      'Ella',
      'Él',
      'Esto',
      'Ese',
      'Esa',
      'Aquel',
      'Aquella',
      'Un',
      'Una',
      'No',
      'Pero',
      'Y',
      'Mission',
      'San',
      'Francisco',
      'District',
      'Hoy',
      'Ayer',
      'Mañana',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
      'Norte',
      'Sur',
      'Este',
      'Oeste',
      'Twitter',
      'X',
      'Instagram',
      'Google',
      'WhatsApp',
    };

    final matches = RegExp(
      r'([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+){0,2})',
    ).allMatches(normalized);

    for (final match in matches) {
      final candidate = match.group(0)!.trim();
      if (blockedSingleWords.contains(candidate) ||
          FragmentInferenceUtils.isBlockedCapitalizedWord(candidate) ||
          FragmentInferenceUtils.isCommonNonEntityWord(candidate)) {
        continue;
      }
      if (candidate.length <= 2) {
        continue;
      }
      if (FragmentInferenceUtils.appearsOnlyAtSentenceStart(
              normalized, candidate) &&
          !FragmentInferenceUtils.hasLikelyHumanContext(
              normalized, candidate)) {
        continue;
      }
      return candidate;
    }

    return '';
  }

  String _inferScenarioName(String selection) {
    final normalized = selection.trim().replaceAll(RegExp(r'\s+'), ' ');
    final quotedMatch = RegExp(r'["“]([^"”]{3,40})["”]').firstMatch(normalized);
    if (quotedMatch != null) {
      final candidate = quotedMatch.group(1)!.trim();
      if (_looksLikeScenarioName(candidate)) return candidate;
    }

    final placePattern = RegExp(
      r'\b(?:en|desde|hacia|hasta|sobre|bajo|frente a|junto a|junto al|junto a la|dentro de|cerca de|al fondo de|a las afueras de|entre|tras)\s+([A-ZÁÉÍÓÚÑ][\wÁÉÍÓÚÑáéíóúñ]+(?:\s+(?:del?|de la|de los|de las|y|[A-ZÁÉÍÓÚÑ][\wÁÉÍÓÚÑáéíóúñ]+)){0,4})',
      caseSensitive: false,
    );
    for (final match in placePattern.allMatches(normalized)) {
      final candidate = match.group(1)!.trim();
      if (_looksLikeScenarioName(candidate)) return candidate;
    }

    final titleCase = RegExp(
      r'([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+){0,3})',
    ).allMatches(normalized);
    for (final match in titleCase) {
      final candidate = match.group(0)!.trim();
      if (_looksLikeScenarioName(candidate)) return candidate;
    }

    final genericCue = RegExp(
      r'\b(casa|hotel|bar|calle|puerto|estación|piso|habitación|cocina|patio|jardín|bosque|playa|hospital|iglesia|plaza|ciudad|pueblo|oficina|archivo|comisaría|cementerio|cafetería|restaurante|taller|almacén|muelle|redacción|apartamento|pasillo|despacho|azotea|garaje|portal|instituto|universidad|biblioteca|laboratorio|parque|carretera|avenida|barrio|mercado|centro|clínica)\b',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (genericCue != null) {
      final value = genericCue.group(0)!;
      return '${value[0].toUpperCase()}${value.substring(1)}';
    }

    return '';
  }

  bool _looksLikeScenarioName(String candidate) {
    const blocked = <String>{
      'Yo',
      'Ella',
      'Él',
      'Mi',
      'Me',
      'Pero',
      'No',
      'Aquel',
      'Aquella',
      'Narrador',
      'Protagonista',
      'Hoy',
      'Ayer',
      'Mañana',
    };
    return candidate.length > 2 && !blocked.contains(candidate);
  }

  bool _looksLikeFirstPersonNarrator(String selection) {
    return FragmentInferenceUtils.isLikelyFirstPersonNarrator(selection);
  }

  bool _shouldCreateAsProtagonist({
    required String selectedText,
    String? preferredName,
  }) {
    final normalizedPreferred = preferredName?.trim().toLowerCase() ?? '';
    if (normalizedPreferred.isNotEmpty) {
      if (normalizedPreferred == 'protagonista' ||
          normalizedPreferred == 'narradora' ||
          normalizedPreferred == 'narrador') {
        return true;
      }
      return false;
    }
    return _looksLikeFirstPersonNarrator(selectedText);
  }

  String _inferCharacterRole(
    String selection,
    String name, {
    required bool isProtagonist,
  }) {
    if (isProtagonist) {
      return 'Protagonista';
    }

    final normalized = ' ${selection.trim().toLowerCase()} ';
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'madre') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'padre') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'hermana') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'hermano') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'tía') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'tio') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'tío') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'prima') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'primo') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'hija') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'hijo')) {
      return 'Figura familiar';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'novia') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'novio') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'pareja') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'marido') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'mujer') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'amiga') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'amigo')) {
      return 'Entorno afectivo';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'jefa') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'jefe') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'editora') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'editor') ||
        FragmentInferenceUtils.mentionsRelationshipCue(
            normalized, 'profesora') ||
        FragmentInferenceUtils.mentionsRelationshipCue(
            normalized, 'profesor') ||
        FragmentInferenceUtils.mentionsRelationshipCue(
            normalized, 'compañera') ||
        FragmentInferenceUtils.mentionsRelationshipCue(
            normalized, 'compañero')) {
      return 'Entorno profesional';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(
            normalized, 'inspectora') ||
        FragmentInferenceUtils.mentionsRelationshipCue(
            normalized, 'inspector')) {
      return 'Figura de autoridad';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'vecina') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'vecino')) {
      return 'Figura cercana';
    }

    final profession = FragmentInferenceUtils.inferProfession(selection, name);
    if (profession.isNotEmpty) {
      return profession;
    }

    if (_hasProfessionalEnvironmentCue(normalized)) {
      return 'Entorno profesional';
    }

    return '';
  }

  String _inferCharacterSummary(
    String selection,
    String name, {
    required bool isProtagonist,
  }) {
    if (isProtagonist) {
      return 'Voz en primera persona de la escena.';
    }

    final normalized = ' ${selection.trim().toLowerCase()} ';
    final profession = FragmentInferenceUtils.inferProfession(selection, name);

    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'madre')) {
      return profession.isNotEmpty
          ? 'Madre de la protagonista, $profession.'
          : 'Madre de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'padre')) {
      return profession.isNotEmpty
          ? 'Padre de la protagonista, $profession.'
          : 'Padre de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'hermana')) {
      return 'Hermana de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'hermano')) {
      return 'Hermano de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'tía') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'tio') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'tío')) {
      return 'Tía o tío de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'prima') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'primo')) {
      return 'Prima o primo de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'hija')) {
      return 'Hija de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'hijo')) {
      return 'Hijo de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'novia') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'novio') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'pareja') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'marido') ||
        FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'mujer')) {
      return profession.isNotEmpty
          ? 'Pareja de la protagonista, $profession.'
          : 'Pareja de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'amiga')) {
      return profession.isNotEmpty
          ? 'Amiga de la protagonista, $profession.'
          : 'Amiga de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'amigo')) {
      return profession.isNotEmpty
          ? 'Amigo de la protagonista, $profession.'
          : 'Amigo de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'jefa')) {
      return profession.isNotEmpty
          ? 'Jefa de la protagonista, $profession.'
          : 'Jefa de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'jefe')) {
      return profession.isNotEmpty
          ? 'Jefe de la protagonista, $profession.'
          : 'Jefe de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'vecina')) {
      return 'Vecina de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(normalized, 'vecino')) {
      return 'Vecino de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(
        normalized, 'compañera')) {
      return profession.isNotEmpty
          ? 'Compañera de la protagonista, $profession.'
          : 'Compañera de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(
        normalized, 'compañero')) {
      return profession.isNotEmpty
          ? 'Compañero de la protagonista, $profession.'
          : 'Compañero de la protagonista.';
    }
    if (FragmentInferenceUtils.mentionsRelationshipCue(
            normalized, 'inspectora') ||
        FragmentInferenceUtils.mentionsRelationshipCue(
            normalized, 'inspector')) {
      return profession.isNotEmpty
          ? 'Figura de autoridad en la escena, $profession.'
          : 'Figura de autoridad en la escena.';
    }

    if (profession.isNotEmpty) {
      return '${profession[0].toUpperCase()}${profession.substring(1)}.';
    }

    if (_hasProfessionalEnvironmentCue(normalized)) {
      return 'Figura del entorno profesional de la protagonista.';
    }

    return '';
  }

  String _inferScenarioRole(String selection, String name) {
    final function = FragmentInferenceUtils.inferScenarioFunction(selection);
    if (function != null && function.trim().isNotEmpty) {
      return function;
    }

    final normalized = ' ${selection.trim().toLowerCase()} ';
    if (_looksLikeWorkplaceScenario(normalized)) {
      return 'Lugar de trabajo';
    }
    if (_looksLikeIntimateScenario(normalized)) {
      return 'Espacio de intimidad';
    }
    if (_looksLikeTransitScenario(normalized)) {
      return 'Zona de tránsito';
    }

    return '';
  }

  String _inferScenarioSummary(String selection, String name) {
    final normalized = ' ${selection.trim().toLowerCase()} ';
    if (_looksLikeWorkplaceScenario(normalized)) {
      return 'Espacio de trabajo con presencia funcional en el capítulo.';
    }
    if (_looksLikeIntimateScenario(normalized)) {
      return 'Espacio íntimo que ayuda a perfilar a la protagonista.';
    }
    if (_looksLikeTransitScenario(normalized)) {
      return 'Lugar de paso que acompaña el estado del capítulo.';
    }
    if (normalized.contains(' sangre ') ||
        normalized.contains(' cinta ') ||
        normalized.contains(' móvil caído ')) {
      return 'Lugar con huellas narrativas claras en la escena.';
    }
    return '';
  }

  Future<void> _autofillCharacterFromSelection({
    required Character character,
    required EditorSelectionContext selectionContext,
    required String documentTitle,
    required String bookTitle,
    required String bookSummary,
    required NarrativeWorkspace workspace,
    required List<String> linkedCharacterIds,
    String? nearbyContextOverride,
  }) async {
    final statusNotifier = _ref.read(characterAutofillProvider.notifier);
    final service = _ref.read(characterAutofillServiceProvider);

    statusNotifier.start(character.id);
    unawaited(Future<void>.delayed(
      const Duration(milliseconds: 700),
      () => statusNotifier.updateMessage(character.id, 'Buscando su voz…'),
    ));
    unawaited(Future<void>.delayed(
      const Duration(milliseconds: 1400),
      () =>
          statusNotifier.updateMessage(character.id, 'Afinando su conflicto…'),
    ));

    final request = CharacterAutofillRequest(
      mode: CharacterAutofillMode.create,
      selection: selectionContext.selectedText.trim(),
      nearbyContext: nearbyContextOverride ??
          _buildNearbyCharacterContext(selectionContext.selection),
      documentTitle: documentTitle,
      bookTitle: bookTitle,
      bookSummary: bookSummary,
      knownCharacters: _buildCharacterSummary(
        workspace: workspace,
        linkedCharacterIds: linkedCharacterIds,
      ),
      provisionalName: character.name.trim(),
      isProtagonist: character.isProtagonist,
      sourceLanguage: _inferSourceLanguage(selectionContext.selectedText),
      existingCharacterProfile: _buildExistingCharacterProfile(character),
    );

    CharacterAutofillDraft? draft;
    try {
      draft = await service.buildDraft(request);
    } catch (_) {
      draft = null;
    }
    if (draft == null || draft.isEmpty) {
      statusNotifier.fail(character.id);
      unawaited(Future<void>.delayed(
        const Duration(seconds: 4),
        () => statusNotifier.clear(character.id),
      ));
      return;
    }

    await _ref
        .read(narrativeWorkspaceProvider.notifier)
        .mergeCharacterAutofillDraft(
          characterId: character.id,
          draft: draft,
          onlyFillEmpty: true,
        );

    statusNotifier.complete(character.id);
    unawaited(Future<void>.delayed(
      const Duration(seconds: 4),
      () => statusNotifier.clear(character.id),
    ));
  }

  Future<void> _autofillScenarioFromSelection({
    required Scenario scenario,
    required EditorSelectionContext selectionContext,
    required String documentTitle,
    required String bookTitle,
    required String bookSummary,
    required NarrativeWorkspace workspace,
    required List<String> linkedScenarioIds,
    String? nearbyContextOverride,
  }) async {
    final statusNotifier = _ref.read(scenarioAutofillProvider.notifier);
    final service = _ref.read(scenarioAutofillServiceProvider);

    statusNotifier.start(scenario.id);
    unawaited(Future<void>.delayed(
      const Duration(milliseconds: 700),
      () => statusNotifier.updateMessage(scenario.id, 'Afinando su atmósfera…'),
    ));
    unawaited(Future<void>.delayed(
      const Duration(milliseconds: 1400),
      () => statusNotifier.updateMessage(
          scenario.id, 'Buscando qué lo hace importante…'),
    ));

    final request = ScenarioAutofillRequest(
      mode: ScenarioAutofillMode.create,
      selection: selectionContext.selectedText.trim(),
      nearbyContext: nearbyContextOverride ??
          _buildNearbyCharacterContext(selectionContext.selection),
      documentTitle: documentTitle,
      bookTitle: bookTitle,
      bookSummary: bookSummary,
      knownScenarios: _buildScenarioSummary(
        workspace: workspace,
        linkedScenarioIds: linkedScenarioIds,
      ),
      provisionalName: scenario.name.trim(),
      sourceLanguage: _inferSourceLanguage(selectionContext.selectedText),
      existingScenarioProfile: '',
    );

    ScenarioAutofillDraft? draft;
    try {
      draft = await service.buildDraft(request);
    } catch (_) {
      draft = null;
    }
    if (draft == null || draft.isEmpty) {
      statusNotifier.fail(scenario.id);
      unawaited(Future<void>.delayed(
        const Duration(seconds: 4),
        () => statusNotifier.clear(scenario.id),
      ));
      return;
    }

    await _ref
        .read(narrativeWorkspaceProvider.notifier)
        .mergeScenarioAutofillDraft(
          scenarioId: scenario.id,
          draft: draft,
          onlyFillEmpty: true,
        );

    statusNotifier.complete(scenario.id);
    unawaited(Future<void>.delayed(
      const Duration(seconds: 4),
      () => statusNotifier.clear(scenario.id),
    ));
  }

  Future<void> _enrichScenarioFromSelection({
    required Scenario scenario,
    required EditorSelectionContext selectionContext,
    required String documentTitle,
    required String bookTitle,
    required String bookSummary,
    required NarrativeWorkspace workspace,
    required List<String> linkedScenarioIds,
  }) async {
    final statusNotifier = _ref.read(scenarioAutofillProvider.notifier);
    final service = _ref.read(scenarioAutofillServiceProvider);

    statusNotifier.startEnrichment(scenario.id, scenario.displayName);
    unawaited(Future<void>.delayed(
      const Duration(milliseconds: 700),
      () => statusNotifier.updateMessage(
          scenario.id, 'Buscando nuevas capas del lugar…'),
    ));
    unawaited(Future<void>.delayed(
      const Duration(milliseconds: 1400),
      () => statusNotifier.updateMessage(
          scenario.id, 'Ajustando su ficha editorial…'),
    ));

    final request = ScenarioAutofillRequest(
      mode: ScenarioAutofillMode.enrich,
      selection: selectionContext.selectedText.trim(),
      nearbyContext: _buildNearbyCharacterContext(selectionContext.selection),
      documentTitle: documentTitle,
      bookTitle: bookTitle,
      bookSummary: bookSummary,
      knownScenarios: _buildScenarioSummary(
        workspace: workspace,
        linkedScenarioIds: linkedScenarioIds,
      ),
      provisionalName: scenario.name.trim(),
      sourceLanguage: _inferSourceLanguage(selectionContext.selectedText),
      existingScenarioProfile: _buildExistingScenarioProfile(scenario),
    );

    ScenarioAutofillDraft? draft;
    try {
      draft = await service.buildDraft(request);
    } catch (_) {
      draft = null;
    }

    if (draft == null || draft.isEmpty) {
      statusNotifier.fail(scenario.id);
      unawaited(Future<void>.delayed(
        const Duration(seconds: 4),
        () => statusNotifier.clear(scenario.id),
      ));
      return;
    }

    await _ref
        .read(narrativeWorkspaceProvider.notifier)
        .enrichScenarioFromDraft(
          scenarioId: scenario.id,
          draft: draft,
          sourceDocumentTitle: documentTitle,
        );

    statusNotifier.complete(scenario.id);
    unawaited(Future<void>.delayed(
      const Duration(seconds: 4),
      () => statusNotifier.clear(scenario.id),
    ));
  }

  Future<void> _enrichCharacterFromSelection({
    required Character character,
    required EditorSelectionContext selectionContext,
    required String documentTitle,
    required String bookTitle,
    required String bookSummary,
    required NarrativeWorkspace workspace,
    required List<String> linkedCharacterIds,
  }) async {
    final statusNotifier = _ref.read(characterAutofillProvider.notifier);
    final service = _ref.read(characterAutofillServiceProvider);

    statusNotifier.startEnrichment(character.id, character.displayName);
    unawaited(Future<void>.delayed(
      const Duration(milliseconds: 700),
      () => statusNotifier.updateMessage(
          character.id, 'Buscando nuevas capas del personaje…'),
    ));
    unawaited(Future<void>.delayed(
      const Duration(milliseconds: 1400),
      () => statusNotifier.updateMessage(character.id, 'Afinando su ficha…'),
    ));

    final request = CharacterAutofillRequest(
      mode: CharacterAutofillMode.enrich,
      selection: selectionContext.selectedText.trim(),
      nearbyContext: _buildNearbyCharacterContext(selectionContext.selection),
      documentTitle: documentTitle,
      bookTitle: bookTitle,
      bookSummary: bookSummary,
      knownCharacters: _buildCharacterSummary(
        workspace: workspace,
        linkedCharacterIds: linkedCharacterIds,
      ),
      provisionalName: character.name.trim(),
      isProtagonist: character.isProtagonist,
      sourceLanguage: _inferSourceLanguage(selectionContext.selectedText),
      existingCharacterProfile: _buildExistingCharacterProfile(character),
    );

    CharacterAutofillDraft? draft;
    try {
      draft = await service.buildDraft(request);
    } catch (_) {
      draft = null;
    }

    if (draft == null || draft.isEmpty) {
      statusNotifier.fail(character.id);
      unawaited(Future<void>.delayed(
        const Duration(seconds: 4),
        () => statusNotifier.clear(character.id),
      ));
      return;
    }

    await _ref
        .read(narrativeWorkspaceProvider.notifier)
        .enrichCharacterFromDraft(
          characterId: character.id,
          draft: draft,
          sourceDocumentTitle: documentTitle,
        );

    statusNotifier.complete(character.id);
    unawaited(Future<void>.delayed(
      const Duration(seconds: 4),
      () => statusNotifier.clear(character.id),
    ));
  }

  String _buildExistingCharacterProfile(Character character) {
    final lines = <String>[
      'Name: ${character.displayName}',
      if (character.isProtagonist) 'Protagonist: yes',
      if (character.role.trim().isNotEmpty) 'Role: ${character.role.trim()}',
      if (character.summary.trim().isNotEmpty)
        'Summary: ${character.summary.trim()}',
      if (character.voice.trim().isNotEmpty) 'Voice: ${character.voice.trim()}',
      if (character.motivation.trim().isNotEmpty)
        'Motivation: ${character.motivation.trim()}',
      if (character.internalConflict.trim().isNotEmpty)
        'Internal conflict: ${character.internalConflict.trim()}',
      if (character.whatTheyHide.trim().isNotEmpty)
        'What they hide: ${character.whatTheyHide.trim()}',
      if (character.currentState.trim().isNotEmpty)
        'Current state: ${character.currentState.trim()}',
      if (character.notes.trim().isNotEmpty) 'Notes: ${character.notes.trim()}',
    ];
    return lines.join('\n');
  }

  String _buildExistingScenarioProfile(Scenario scenario) {
    final lines = <String>[
      'Name: ${scenario.displayName}',
      if (scenario.role.trim().isNotEmpty) 'Role: ${scenario.role.trim()}',
      if (scenario.summary.trim().isNotEmpty)
        'Summary: ${scenario.summary.trim()}',
      if (scenario.atmosphere.trim().isNotEmpty)
        'Atmosphere: ${scenario.atmosphere.trim()}',
      if (scenario.importance.trim().isNotEmpty)
        'Importance: ${scenario.importance.trim()}',
      if (scenario.whatItHides.trim().isNotEmpty)
        'What it hides: ${scenario.whatItHides.trim()}',
      if (scenario.currentState.trim().isNotEmpty)
        'Current state: ${scenario.currentState.trim()}',
      if (scenario.notes.trim().isNotEmpty) 'Notes: ${scenario.notes.trim()}',
    ];
    return lines.join('\n');
  }

  String _buildNearbyCharacterContext(TextSelection selection) {
    final text = state.controller.text;
    final start = selection.start < 280 ? 0 : selection.start - 280;
    final end =
        selection.end + 280 > text.length ? text.length : selection.end + 280;
    return text.substring(start, end).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  EditorSelectionContext _buildFocusedChapterSelection(
    String chapterText,
    String target,
  ) {
    final trimmedTarget = target.trim();
    if (trimmedTarget.isEmpty || chapterText.trim().isEmpty) {
      return EditorSelectionContext(
        selectedText: '',
        selection: const TextSelection(
          baseOffset: 0,
          extentOffset: 0,
        ),
        position: Offset.zero,
      );
    }

    final chunks = _splitChapterIntoChunks(chapterText);
    final matchingChunks = chunks
        .where((chunk) => _containsLooseTarget(chunk.text, trimmedTarget))
        .take(3)
        .toList();

    if (matchingChunks.isEmpty) {
      return EditorSelectionContext(
        selectedText: '',
        selection: const TextSelection(
          baseOffset: 0,
          extentOffset: 0,
        ),
        position: Offset.zero,
      );
    }

    final selectedText = matchingChunks
        .map((chunk) => chunk.text.trim())
        .where((text) => text.isNotEmpty && text != '---')
        .join('\n\n---\n\n')
        .trim();

    return EditorSelectionContext(
      selectedText: selectedText,
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: selectedText.length,
      ),
      position: Offset.zero,
    );
  }

  String _buildFocusedChapterContext(
    String chapterText,
    String target,
  ) {
    final trimmedTarget = target.trim();
    if (chapterText.trim().isEmpty || trimmedTarget.isEmpty) return '';

    final lowerText = chapterText.toLowerCase();
    final lowerTarget = trimmedTarget.toLowerCase();
    final matches = RegExp(
      r'(?<!\p{L})' + RegExp.escape(lowerTarget) + r'(?!\p{L})',
      unicode: true,
      caseSensitive: false,
    ).allMatches(lowerText).toList();

    if (matches.isEmpty) {
      return '';
    }

    final ranges = <({int start, int end})>[];
    for (final match in matches.take(3)) {
      var start = match.start - 220;
      var end = match.end + 320;
      if (start < 0) start = 0;
      if (end > chapterText.length) end = chapterText.length;
      ranges.add((start: start, end: end));
    }

    final merged = <({int start, int end})>[];
    for (final range in ranges) {
      if (merged.isEmpty) {
        merged.add(range);
        continue;
      }
      final last = merged.last;
      if (range.start <= last.end) {
        merged[merged.length - 1] = (
          start: last.start,
          end: range.end > last.end ? range.end : last.end,
        );
      } else {
        merged.add(range);
      }
    }

    return merged
        .map((range) => chapterText
            .substring(range.start, range.end)
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim())
        .where((part) => part.isNotEmpty)
        .join(' … ');
  }

  bool _hasProfessionalEnvironmentCue(String normalized) {
    return normalized.contains(' redacción ') ||
        normalized.contains(' oficina ') ||
        normalized.contains(' despacho ') ||
        normalized.contains(' artículo ') ||
        normalized.contains(' periodista ') ||
        normalized.contains(' editora ') ||
        normalized.contains(' editor ') ||
        normalized.contains(' reportaje ') ||
        normalized.contains(' llamada ') ||
        normalized.contains(' teléfono ') ||
        normalized.contains(' escritorio ') ||
        normalized.contains(' fotocopiadora ') ||
        normalized.contains(' muelle ') ||
        normalized.contains(' cubriendo ');
  }

  bool _looksLikeWorkplaceScenario(String normalized) {
    return normalized.contains(' redacción ') ||
        normalized.contains(' oficina ') ||
        normalized.contains(' despacho ') ||
        normalized.contains(' escritorio ') ||
        normalized.contains(' fotocopiadora ');
  }

  bool _looksLikeIntimateScenario(String normalized) {
    return normalized.contains(' apartamento ') ||
        normalized.contains(' estudio ') ||
        normalized.contains(' cama ') ||
        normalized.contains(' habitación ') ||
        normalized.contains(' patio interior ');
  }

  bool _looksLikeTransitScenario(String normalized) {
    return normalized.contains(' calle ') ||
        normalized.contains(' avenida ') ||
        normalized.contains(' camino ') ||
        normalized.contains(' trayecto ') ||
        normalized.contains(' grafitis ') ||
        normalized.contains(' asfalto ');
  }

  bool _containsLooseTarget(String text, String target) {
    final normalizedText = text.toLowerCase();
    final normalizedTarget = target.toLowerCase();
    if (normalizedText.contains(normalizedTarget)) {
      return true;
    }

    final coreWords = normalizedTarget
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().length >= 4)
        .toList();
    for (final word in coreWords) {
      if (RegExp(r'(?<!\p{L})' + RegExp.escape(word) + r'(?!\p{L})',
              unicode: true, caseSensitive: false)
          .hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  List<_ChapterChunk> _splitChapterIntoChunks(String chapterText) {
    final matches = RegExp(r'\n\s*\n').allMatches(chapterText).toList();
    if (matches.isEmpty) {
      return <_ChapterChunk>[
        _ChapterChunk(start: 0, end: chapterText.length, text: chapterText),
      ];
    }

    final chunks = <_ChapterChunk>[];
    var start = 0;
    for (final match in matches) {
      final end = match.start;
      final text = chapterText.substring(start, end);
      if (text.trim().isNotEmpty) {
        chunks.add(_ChapterChunk(start: start, end: end, text: text));
      }
      start = match.end;
    }
    if (start < chapterText.length) {
      final text = chapterText.substring(start);
      if (text.trim().isNotEmpty) {
        chunks.add(
          _ChapterChunk(start: start, end: chapterText.length, text: text),
        );
      }
    }
    return chunks;
  }

  String _inferSourceLanguage(String selection) {
    final normalized = ' ${selection.trim().toLowerCase()} ';
    const spanishSignals = <String>[
      ' el ',
      ' la ',
      ' de ',
      ' que ',
      ' y ',
      ' en ',
      ' un ',
      ' una ',
      ' no ',
      ' pero ',
      '¿',
      '¡',
      'á',
      'é',
      'í',
      'ó',
      'ú',
      'ñ',
    ];

    for (final signal in spanishSignals) {
      if (normalized.contains(signal)) {
        return 'Spanish';
      }
    }

    return 'English';
  }

  String _buildPipelineEditorComment(
    EditorialRecommendation? recommendation,
    List<Musa> history,
  ) {
    if (history.isEmpty) {
      return 'Intervención editorial completada.';
    }

    final sequence = history.map((musa) => musa.shortName).join(' > ');
    if (recommendation == null) {
      return 'Secuencia editorial aplicada: $sequence.';
    }

    return 'Secuencia editorial aplicada: $sequence. Motivo: ${recommendation.reason}';
  }

  String _inferChapterAnalysisLanguage(ChapterAnalysis analysis) {
    final corpus = <String>[
      analysis.dominantNarrativeMoment.title,
      analysis.dominantNarrativeMoment.summary,
      analysis.recommendation?.message ?? '',
      analysis.nextStep?.label ?? '',
      analysis.nextStep?.exampleText ?? '',
    ].join(' ');
    return _inferSourceLanguage(corpus);
  }

  String _buildExpandMomentProblem({
    required ChapterAnalysis analysis,
    required bool isSpanish,
  }) {
    final moment = analysis.dominantNarrativeMoment.title.toLowerCase();
    final summary = analysis.dominantNarrativeMoment.summary.toLowerCase();
    if (moment.contains('crimen') ||
        summary.contains('observación e inquietud') ||
        summary.contains('vacío de respuestas')) {
      return isSpanish
          ? 'La escena ya tiene atmósfera y foco, pero todavía puede empujar mejor la mirada o la sospecha.'
          : 'The scene already has atmosphere and focus, but it can still push the gaze or suspicion further.';
    }
    if (moment.contains('indicios') || moment.contains('investig')) {
      return isSpanish
          ? 'El momento apunta a algo importante, pero todavía puede pesar más en la lectura.'
          : 'The moment points toward something important, but it can still carry more weight.';
    }
    if (moment.contains('tensión')) {
      return isSpanish
          ? 'La escena ya inquieta, pero aún puede apretar un poco más antes de resolverse.'
          : 'The scene is already uneasy, but it can still tighten a little more before resolving.';
    }
    if (analysis.chapterFunction == ChapterFunction.discovery) {
      return isSpanish
          ? 'Aquí ya hay una promesa narrativa; conviene darle un poco más de cuerpo sin cerrarla.'
          : 'There is already narrative promise here; it needs a bit more shape without closing it.';
    }
    return isSpanish
        ? 'El momento funciona, pero todavía admite un empuje más concreto dentro de la escena.'
        : 'The moment works, but it still allows a more concrete push inside the scene.';
  }

  List<ExpandMomentDirection> _pickExpandMomentDirections({
    required ChapterAnalysis analysis,
    required bool isSpanish,
  }) {
    final orderedTypes = <ExpandMomentDirectionType>[];
    final dominant = analysis.dominantNarrativeMoment.title.toLowerCase();
    final summary = analysis.dominantNarrativeMoment.summary.toLowerCase();
    final trajectoryEnd = analysis.trajectory?.endLabel.toLowerCase() ?? '';
    final hasScenarioDevelopment = analysis.scenarioDevelopments.isNotEmpty;
    final topCharacterDevelopment = analysis.characterDevelopments.isEmpty
        ? null
        : analysis.characterDevelopments.first;
    final crimeSceneMoment = dominant.contains('crimen') ||
        dominant.contains('escena de crimen') ||
        summary.contains('observación e inquietud') ||
        summary.contains('vacío de respuestas');

    void add(ExpandMomentDirectionType type) {
      if (!orderedTypes.contains(type)) {
        orderedTypes.add(type);
      }
    }

    if (crimeSceneMoment) {
      add(ExpandMomentDirectionType.clarify_clue);
      add(ExpandMomentDirectionType.raise_tension);
      add(ExpandMomentDirectionType.extend_observation);
    }
    if (dominant.contains('indicios') ||
        dominant.contains('investig') ||
        trajectoryEnd == 'investigación') {
      add(ExpandMomentDirectionType.clarify_clue);
    }
    if (dominant.contains('tensión') ||
        analysis.chapterFunction == ChapterFunction.discovery) {
      add(ExpandMomentDirectionType.raise_tension);
    }
    if (analysis.chapterFunction == ChapterFunction.character_building ||
        topCharacterDevelopment?.type ==
            CharacterDevelopmentType.voice_definition ||
        topCharacterDevelopment?.type ==
            CharacterDevelopmentType.conflict_signal) {
      add(ExpandMomentDirectionType.link_emotion_to_action);
    }
    if (analysis.chapterFunction == ChapterFunction.development ||
        dominant.contains('observ') ||
        hasScenarioDevelopment) {
      add(ExpandMomentDirectionType.extend_observation);
    }
    if (analysis.chapterFunction == ChapterFunction.setup ||
        dominant.contains('descubr') ||
        trajectoryEnd == 'investigación') {
      add(ExpandMomentDirectionType.add_consequence);
    }

    add(ExpandMomentDirectionType.raise_tension);
    add(ExpandMomentDirectionType.add_consequence);
    add(ExpandMomentDirectionType.extend_observation);
    add(ExpandMomentDirectionType.link_emotion_to_action);
    add(ExpandMomentDirectionType.clarify_clue);

    return orderedTypes
        .take(3)
        .map((type) => _buildExpandMomentDirection(
              type: type,
              analysis: analysis,
              isSpanish: isSpanish,
            ))
        .toList();
  }

  ExpandMomentDirection _buildExpandMomentDirection({
    required ExpandMomentDirectionType type,
    required ChapterAnalysis analysis,
    required bool isSpanish,
  }) {
    return switch (type) {
      ExpandMomentDirectionType.add_consequence => ExpandMomentDirection(
          type: type,
          title: isSpanish ? 'Añadir consecuencia' : 'Add consequence',
          summary: isSpanish
              ? 'Haz que lo que acaba de pasar deje una pequeña marca inmediata.'
              : 'Let what just happened leave a small immediate mark.',
          example: isSpanish
              ? 'No cambió la escena por completo. Pero desde entonces ya no pude mirarla igual.'
              : 'It did not change the scene completely. But from then on I could no longer look at it the same way.',
        ),
      ExpandMomentDirectionType.raise_tension => ExpandMomentDirection(
          type: type,
          title: isSpanish ? 'Subir la incomodidad' : 'Raise tension',
          summary: isSpanish
              ? 'Aprieta un poco la escena antes de que avance o se enfríe.'
              : 'Tighten the scene a little before it moves on or cools down.',
          example: isSpanish
              ? 'Durante un segundo pensé que alguien iba a interrumpirme. Y ese segundo pesó demasiado.'
              : 'For a second I thought someone was about to interrupt me. That second weighed too much.',
        ),
      ExpandMomentDirectionType.clarify_clue => ExpandMomentDirection(
          type: type,
          title: isSpanish ? 'Concretar la pista' : 'Clarify the clue',
          summary: isSpanish
              ? 'Vuelve la pista un poco más legible sin resolverla todavía.'
              : 'Make the clue slightly more legible without resolving it yet.',
          example: isSpanish
              ? 'No era una prueba todavía, pero el detalle ya no parecía casual.'
              : 'It was not proof yet, but the detail no longer felt accidental.',
        ),
      ExpandMomentDirectionType.extend_observation => ExpandMomentDirection(
          type: type,
          title: isSpanish ? 'Extender la observación' : 'Extend observation',
          summary: isSpanish
              ? 'Detente un poco más en lo que la escena deja ver antes de explicarlo.'
              : 'Stay a little longer with what the scene reveals or suggests.',
          example: isSpanish
              ? 'No era solo el callejón. Era lo que parecía resistirse a quedar quieto dentro de él.'
              : 'There was something slight in the scene, but it kept pulling at my attention.',
        ),
      ExpandMomentDirectionType.link_emotion_to_action => ExpandMomentDirection(
          type: type,
          title:
              isSpanish ? 'Ligar emoción y acción' : 'Link emotion to action',
          summary: isSpanish
              ? 'Haz que la emoción empuje un gesto, una decisión o una reacción breve.'
              : 'Let the emotion push a gesture, a decision, or a short reaction.',
          example: isSpanish
              ? 'No fue solo inquietud. Fue lo que me hizo moverme un paso más.'
              : 'It was not only unease. It was what made me move one step further.',
        ),
    };
  }

  List<ConnectToPlotDirection> _buildConnectToPlotDirections({
    required bool isSpanish,
  }) {
    return <ConnectToPlotDirection>[
      ConnectToPlotDirection(
        type: ConnectToPlotDirectionType.connect_symbol,
        title: isSpanish ? 'Conectar con el símbolo' : 'Connect to the symbol',
        summary: isSpanish
            ? 'Haz que el elemento recurrente vuelva a cargar sentido dentro del capítulo.'
            : 'Let the recurring element gain clearer narrative meaning inside the chapter.',
        example: isSpanish
            ? 'El símbolo dejó de parecer una rareza aislada. Empezó a comportarse como una firma.'
            : 'The symbol stopped feeling isolated. It started behaving like a signature.',
      ),
      ConnectToPlotDirection(
        type: ConnectToPlotDirectionType.introduce_consequence,
        title: isSpanish ? 'Introducir consecuencia' : 'Introduce consequence',
        summary: isSpanish
            ? 'Haz visible qué cambia ahora que este capítulo ya ha visto lo que vio.'
            : 'Make visible what changes now that the chapter has already seen what it saw.',
        example: isSpanish
            ? 'No resolví nada esa noche, pero salí con una obligación nueva pegada al cuerpo.'
            : 'I did not solve anything that night, but I left carrying a new obligation.',
      ),
      ConnectToPlotDirection(
        type: ConnectToPlotDirectionType.link_character,
        title: isSpanish ? 'Enlazar con personaje' : 'Tie it to character',
        summary: isSpanish
            ? 'Haz que la trama toque una relación, una voz o un conflicto personal concreto.'
            : 'Let the plot line touch a concrete relationship, voice, or personal conflict.',
        example: isSpanish
            ? 'De pronto ya no era solo una pista. Era algo que también rozaba a Julia.'
            : 'Suddenly it was no longer just a clue. It also brushed against Julia.',
      ),
    ];
  }

  String _buildExpandMomentNoteContent({
    required ChapterAnalysis analysis,
    required ExpandMomentDirection direction,
    required String documentTitle,
    required bool isSpanish,
  }) {
    if (isSpanish) {
      return [
        'Nota editorial para "$documentTitle"',
        '',
        'Momento dominante: ${analysis.dominantNarrativeMoment.title}',
        'Foco de ajuste: ${_buildExpandMomentProblem(analysis: analysis, isSpanish: true)}',
        '',
        'Dirección elegida',
        '${direction.title}: ${direction.summary}',
        '',
        'Empuje posible',
        direction.example,
        '',
        'Límite',
        'Empuja este momento sin resolverlo ni reescribir la escena completa.',
      ].join('\n');
    }

    return [
      'Editorial note for "$documentTitle"',
      '',
      'Dominant moment: ${analysis.dominantNarrativeMoment.title}',
      'Adjustment focus: ${_buildExpandMomentProblem(analysis: analysis, isSpanish: false)}',
      '',
      'Chosen direction',
      '${direction.title}: ${direction.summary}',
      '',
      'Possible push',
      direction.example,
      '',
      'Limit',
      'Push this moment without resolving it or rewriting the whole scene.',
    ].join('\n');
  }

  String _buildConnectToPlotNoteContent({
    required ChapterAnalysis analysis,
    required ConnectToPlotDirection direction,
    required String documentTitle,
    required bool isSpanish,
  }) {
    if (isSpanish) {
      return [
        'Nota editorial para "$documentTitle"',
        '',
        'Trayectoria: ${analysis.trajectory?.summary ?? analysis.dominantNarrativeMoment.title}',
        'Foco de ajuste: conectar mejor este capítulo con la trama que está emergiendo.',
        '',
        'Dirección elegida',
        '${direction.title}: ${direction.summary}',
        '',
        'Empuje posible',
        direction.example,
        '',
        'Límite',
        'Conecta la línea del capítulo con la trama sin explicarlo todo ni adelantar resoluciones.',
      ].join('\n');
    }

    return [
      'Editorial note for "$documentTitle"',
      '',
      'Trajectory: ${analysis.trajectory?.summary ?? analysis.dominantNarrativeMoment.title}',
      'Adjustment focus: tie this chapter more clearly into the emerging plot.',
      '',
      'Chosen direction',
      '${direction.title}: ${direction.summary}',
      '',
      'Possible push',
      direction.example,
      '',
      'Limit',
      'Connect the chapter to the plot without overexplaining or resolving it too early.',
    ].join('\n');
  }

  void _scheduleNarrativeRefresh(String documentId) {
    _narrativeRefreshDebounce?.cancel();
    _narrativeRefreshDebounce = Timer(const Duration(milliseconds: 1400), () {
      unawaited(_refreshNarrativeCopilot(documentId: documentId));
    });
  }

  Future<void> _refreshNarrativeCopilot({
    String? documentId,
    ChapterAnalysis? chapterAnalysis,
  }) async {
    final workspace = _ref.read(narrativeWorkspaceProvider).value;
    if (workspace == null) return;

    final document = documentId == null
        ? _ref.read(currentDocumentProvider)
        : workspace.documents.cast<Document?>().firstWhere(
              (item) => item?.id == documentId,
              orElse: () => null,
            );
    final bookId = document?.bookId ?? workspace.activeBook?.id;
    if (bookId == null) return;

    await _ref
        .read(narrativeWorkspaceProvider.notifier)
        .recalculateNarrativeCopilot(
          bookId: bookId,
          input: chapterAnalysis == null
              ? const StoryStateInput()
              : _storyStateInputFromChapterAnalysis(chapterAnalysis),
        );
  }

  StoryStateInput _storyStateInputFromChapterAnalysis(
    ChapterAnalysis analysis,
  ) {
    final realProgress = analysis.characterDevelopments.isNotEmpty ||
        analysis.scenarioDevelopments.isNotEmpty ||
        analysis.chapterFunction == ChapterFunction.discovery ||
        analysis.chapterFunction == ChapterFunction.escalation;
    return StoryStateInput(
      chapterFunction: _mapChapterFunction(analysis.chapterFunction),
      realProgress: realProgress,
      keyEvents: [
        if (analysis.trajectory != null) analysis.trajectory!.summary,
        ...analysis.characterDevelopments.map((item) => item.summary),
        ...analysis.scenarioDevelopments.map((item) => item.summary),
      ],
      diagnostics: [
        if (!realProgress)
          'El análisis de capítulo no detectó desarrollo claro de personaje, escenario, amenaza o descubrimiento.',
      ],
    );
  }

  CurrentChapterFunction _mapChapterFunction(ChapterFunction function) {
    return switch (function) {
      ChapterFunction.introduction => CurrentChapterFunction.introduce,
      ChapterFunction.development => CurrentChapterFunction.complicate,
      ChapterFunction.escalation => CurrentChapterFunction.confront,
      ChapterFunction.discovery => CurrentChapterFunction.reveal,
      ChapterFunction.transition => CurrentChapterFunction.transition,
      ChapterFunction.character_building =>
        CurrentChapterFunction.deepenCharacter,
      ChapterFunction.setup => CurrentChapterFunction.setup,
    };
  }

  @override
  void dispose() {
    _contentPersistDebounce?.cancel();
    _narrativeRefreshDebounce?.cancel();
    unawaited(_refreshNarrativeCopilot(documentId: state.documentId));
    _aiSubscription?.cancel();
    state.controller.removeListener(_handleSelectionChange);
    state.controller.removeListener(_handleContentChanged);
    state.controller.dispose();
    state.focusNode.dispose();
    super.dispose();
  }

  /// Feedback loop: determine if next musa should be skipped based on current input analysis
  /// If a previous musa already solved the problem this one targets, skip it (conservative approach)
  bool _shouldSkipMusaByFeedback(Musa musa, String currentInput) {
    final signals = buildEditorialSignals(currentInput);
    final dialogueMarks = signals.dialogueMarksCount;
    final isDialogueHeavy = dialogueMarks >= 4;

    // RhythmMusa: skip if rhythm issues already resolved by previous steps
    if (musa.id == 'rhythm') {
      // Rhythm was needed if there were long sentences OR short streaks
      // If both are now mild, skip it
      final hasLongSentences = signals.longSentenceCount >= 2;
      final hasShortStreaks = signals.shortSentenceStreak >= 3;
      if (!hasLongSentences && !hasShortStreaks) {
        return true; // Previous musa fixed it, no need for Rhythm
      }
    }

    // ClarityMusa: skip if clarity issues were already present before (can't help more)
    if (musa.id == 'clarity') {
      // Clarity targets: multiple questions + short dialogue
      final hasQuestions = signals.questionCount >= 2;
      final hasDialogue = isDialogueHeavy;
      if (!hasQuestions && !hasDialogue) {
        return true; // No clarity issues left to fix
      }
    }

    // StyleMusa: skip if no lexical issues remain
    if (musa.id == 'style') {
      // Style targets low lexical diversity + adverbs
      // Conservative: only skip if diversity is strong
      if (signals.lexicalDiversity > 0.75) {
        return true; // Already has good vocabulary variety
      }
    }

    // TensionMusa: skip if no action signals exist
    if (musa.id == 'tension') {
      final actionStrength = signals.contextualActionStrength(isDialogueHeavy);
      if (actionStrength > 0.6) {
        return true; // Already has strong action/drama
      }
    }

    return false; // Default: execute this musa
  }
}

class _EditorialContextBundle {
  final String documentTitle;
  final String documentContent;
  final narrative.NarrativeContext narrativeContext;

  const _EditorialContextBundle({
    required this.documentTitle,
    required this.documentContent,
    required this.narrativeContext,
  });
}

class _ChapterChunk {
  final int start;
  final int end;
  final String text;

  const _ChapterChunk({
    required this.start,
    required this.end,
    required this.text,
  });
}

final editorProvider =
    StateNotifierProvider<EditorController, EditorState>((ref) {
  return EditorController(ref);
});
