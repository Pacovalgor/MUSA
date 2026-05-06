import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/books/models/narrative_workspace.dart';
import '../../modules/books/providers/workspace_providers.dart';
import '../../modules/characters/providers/character_providers.dart';
import '../../modules/characters/widgets/character_picker_sheet.dart';
import '../../modules/continuity/providers/continuity_providers.dart';
import '../../modules/manuscript/providers/document_providers.dart';
import '../../modules/musa/models/guided_rewrite.dart';
import '../../modules/musa/providers/guided_rewrite_providers.dart';
import '../../modules/scenarios/providers/scenario_providers.dart';
import '../../modules/scenarios/widgets/scenario_picker_sheet.dart';
import '../../muses/musa.dart';
import '../../muses/providers/musa_providers.dart';
import '../../ui/widgets/editorial_dialogs.dart';
import '../controller/editor_controller.dart';

class MusaEditorOverlay extends ConsumerWidget {
  const MusaEditorOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final musaSettings = ref.watch(musaSettingsProvider);
    final editorMode = ref.watch(editorModeProvider);
    final currentDocument = ref.watch(currentDocumentProvider);

    if (!editorState.showOverlay || editorState.selectionOffset == null) {
      return const SizedBox.shrink();
    }

    return CompositedTransformFollower(
      link: editorState.layerLink,
      showWhenUnlinked: false,
      targetAnchor: Alignment.topLeft,
      followerAnchor: Alignment.bottomCenter,
      offset: Offset(
        editorState.selectionOffset!.dx,
        editorState.selectionOffset!.dy - 40,
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(28),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPrimaryAction(context, ref),
                      if (editorMode == WorkspaceEditorMode.document &&
                          currentDocument != null) ...[
                        const SizedBox(width: 6),
                        _buildSecondaryActions(context, ref),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (editorState.showSelectionHelper &&
                !editorState.isProcessing) ...[
              const SizedBox(height: 8),
              _SelectionHelperText(
                text: editorMode == WorkspaceEditorMode.document &&
                        currentDocument != null
                    ? 'Puedes entender este fragmento'
                    : 'Puedes trabajar este fragmento',
              ),
            ],
            if (musaSettings.showInvocationBadge &&
                editorState.isProcessing &&
                editorState.activeMusa != null) ...[
              const SizedBox(height: 10),
              _MusaInvocationBadge(
                musa: editorState.activeMusa!,
                phase: editorState.generationPhase,
                showAnimatedMessages: musaSettings.showAnimatedStatusMessages,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryAction(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final recommendation = editorState.editorialRecommendation;
    final isActive = editorState.isProcessing;
    final isBusy = editorState.isProcessing;
    final isEmphasized = editorState.showSelectionHelper && !isBusy;

    return InkWell(
      onTap: isBusy
          ? null
          : () {
              ref.read(editorProvider.notifier).runFragmentAnalysis();
            },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.2)
              : isEmphasized
                  ? const Color(0xFFE7D7B2)
                  : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive
                  ? _getIconForMusa(
                      editorState.activeMusa ?? const ClarityMusa())
                  : recommendation != null
                      ? _getIconForMusa(recommendation.primaryMusa)
                      : Icons.auto_stories_outlined,
              size: 14,
              color: isEmphasized && !isActive ? Colors.black87 : Colors.white,
            ),
            const SizedBox(width: 8),
            if (!isActive && recommendation != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.primaryMusa.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isEmphasized ? Colors.black87 : Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: isEmphasized
                                ? Colors.black54
                                : Colors.white.withValues(alpha: 0.7),
                            height: 1.1,
                          ),
                        ),
                        if (recommendation.secondaryMusas.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            'También podrían ayudar: ${recommendation.secondaryMusas.map((m) => m.name).join(', ')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w400,
                              color: isEmphasized
                                  ? Colors.black45
                                  : Colors.white.withValues(alpha: 0.45),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              )
            else
              Text(
                isActive
                    ? (editorState.activeMusa?.shortName ?? 'Entender')
                    : 'Entender fragmento',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color:
                      isEmphasized && !isActive ? Colors.black87 : Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryActions(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final musas = ref.watch(availableMusesProvider);
    final isBusy = editorState.isProcessing;
    final workspace = ref.watch(narrativeWorkspaceProvider).value;
    final recommendation = ref.watch(guidedRewritePlannerProvider).recommend(
          selection: editorState.selectionContext?.selectedText ?? '',
          book: workspace?.activeBook,
          novelStatus: ref.watch(activeNovelStatusProvider),
          continuityFindings: ref.watch(activeContinuityFindingsProvider),
          memory: workspace?.activeNarrativeMemory,
          storyState: workspace?.activeStoryState,
        );

    return PopupMenuButton<_SelectionMenuAction>(
      enabled: !isBusy,
      tooltip: 'Más opciones',
      color: Colors.white,
      elevation: 18,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      offset: const Offset(0, 44),
      onSelected: (action) async {
        final messenger = ScaffoldMessenger.of(context);
        switch (action.kind) {
          case _SelectionMenuActionKind.createCharacter:
            await Future<void>.delayed(Duration.zero);
            if (!context.mounted) {
              return;
            }
            final suggestedName = ref
                .read(editorProvider.notifier)
                .suggestedCharacterNameForSelection();
            final confirmedName = await _promptForEntityName(
              context,
              title: 'Nuevo personaje',
              initialValue: suggestedName,
              hintText: 'Cómo quieres llamarlo',
              actionLabel: 'Crear',
            );
            if (confirmedName == null || !context.mounted) {
              return;
            }
            await ref
                .read(editorProvider.notifier)
                .createCharacterFromSelection(preferredName: confirmedName);
            if (context.mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    '$confirmedName ya está en personajes. MUSA está dando forma a su ficha.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            break;
          case _SelectionMenuActionKind.enrichCharacter:
            await _handleEnrichCharacter(context, ref);
            break;
          case _SelectionMenuActionKind.linkCharacter:
            await _handleLinkCharacter(context, ref);
            break;
          case _SelectionMenuActionKind.createScenario:
            await Future<void>.delayed(Duration.zero);
            if (!context.mounted) return;
            final suggestedName = ref
                .read(editorProvider.notifier)
                .suggestedScenarioNameForSelection();
            final confirmedName = await _promptForEntityName(
              context,
              title: 'Nuevo escenario',
              initialValue: suggestedName,
              hintText: 'Cómo quieres llamarlo',
              actionLabel: 'Crear',
            );
            if (confirmedName == null || !context.mounted) return;
            await ref
                .read(editorProvider.notifier)
                .createScenarioFromSelection(preferredName: confirmedName);
            if (context.mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    '$confirmedName ya está en escenarios. MUSA está afinando su ficha.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            break;
          case _SelectionMenuActionKind.enrichScenario:
            await _handleEnrichScenario(context, ref);
            break;
          case _SelectionMenuActionKind.linkScenario:
            await _handleLinkScenario(context, ref);
            break;
          case _SelectionMenuActionKind.guidedRewrite:
            final rewriteAction = action.rewriteAction;
            if (rewriteAction != null) {
              ref.read(editorProvider.notifier).runGuidedRewrite(rewriteAction);
            }
            break;
          case _SelectionMenuActionKind.musa:
            final musa = action.musa;
            if (musa != null) {
              await ref.read(editorProvider.notifier).runMusa(musa: musa);
            }
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          enabled: false,
          height: 34,
          child: _SelectionMenuSectionLabel('Texto'),
        ),
        if (recommendation != null) ...[
          PopupMenuItem(
            value: _SelectionMenuAction.guidedRewrite(recommendation.action),
            child: _NarrativeMenuItem(
              icon: _iconForGuidedRewriteAction(recommendation.action),
              label: 'Recomendado: ${recommendation.title}',
              detail: recommendation.reason,
            ),
          ),
          const PopupMenuDivider(),
        ],
        const PopupMenuItem(
          value: _SelectionMenuAction.guidedRewrite(
            GuidedRewriteAction.raiseTension,
          ),
          child: _NarrativeMenuItem(
            icon: Icons.bolt_outlined,
            label: 'Subir tensión',
          ),
        ),
        const PopupMenuItem(
          value: _SelectionMenuAction.guidedRewrite(
            GuidedRewriteAction.clarify,
          ),
          child: _NarrativeMenuItem(
            icon: Icons.visibility_outlined,
            label: 'Aclarar',
          ),
        ),
        const PopupMenuItem(
          value: _SelectionMenuAction.guidedRewrite(
            GuidedRewriteAction.reduceExposition,
          ),
          child: _NarrativeMenuItem(
            icon: Icons.compress_outlined,
            label: 'Reducir exposición',
          ),
        ),
        const PopupMenuItem(
          value: _SelectionMenuAction.guidedRewrite(
            GuidedRewriteAction.naturalizeDialogue,
          ),
          child: _NarrativeMenuItem(
            icon: Icons.forum_outlined,
            label: 'Diálogo natural',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          enabled: false,
          height: 34,
          child: _SelectionMenuSectionLabel('Musas'),
        ),
        ...musas.map(
          (musa) => PopupMenuItem(
            value: _SelectionMenuAction.musa(musa),
            child: _NarrativeMenuItem(
              icon: _getIconForMusa(musa),
              label: musa.shortName,
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _SelectionMenuAction.createCharacter(),
          child: _NarrativeMenuItem(
            icon: Icons.person_add_alt_1_outlined,
            label: 'Crear personaje',
          ),
        ),
        const PopupMenuItem(
          value: _SelectionMenuAction.enrichCharacter(),
          child: _NarrativeMenuItem(
            icon: Icons.auto_fix_high_outlined,
            label: 'Enriquecer personaje',
          ),
        ),
        const PopupMenuItem(
          value: _SelectionMenuAction.linkCharacter(),
          child: _NarrativeMenuItem(
            icon: Icons.link_outlined,
            label: 'Vincular personaje',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _SelectionMenuAction.createScenario(),
          child: _NarrativeMenuItem(
            icon: Icons.place_outlined,
            label: 'Crear escenario',
          ),
        ),
        const PopupMenuItem(
          value: _SelectionMenuAction.enrichScenario(),
          child: _NarrativeMenuItem(
            icon: Icons.auto_fix_high_outlined,
            label: 'Enriquecer escenario',
          ),
        ),
        const PopupMenuItem(
          value: _SelectionMenuAction.linkScenario(),
          child: _NarrativeMenuItem(
            icon: Icons.link_outlined,
            label: 'Vincular escenario',
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.more_horiz,
              size: 16,
              color: Colors.white.withValues(alpha: isBusy ? 0.45 : 1),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLinkScenario(BuildContext context, WidgetRef ref) async {
    final document = ref.read(currentDocumentProvider);
    final scenarios = ref.read(scenariosProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (document == null) return;

    final selected = await showScenarioPickerSheet(
      context,
      scenarios: scenarios,
      linkedScenarioIds: document.scenarioIds,
    );
    if (selected == null || !context.mounted) return;

    final linked = await ref
        .read(editorProvider.notifier)
        .linkSelectionToScenario(selected.id);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          linked
              ? '${selected.displayName} ahora forma parte de este capítulo.'
              : '${selected.displayName} ya estaba vinculado a este capítulo.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleEnrichScenario(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final document = ref.read(currentDocumentProvider);
    final scenarios = ref.read(scenariosProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (document == null) return;

    final selected = await showScenarioPickerSheet(
      context,
      scenarios: scenarios,
      linkedScenarioIds: document.scenarioIds,
      title: 'Enriquecer escenario',
      description: 'Elige qué escenario quieres matizar con este fragmento.',
      showLinkedState: false,
    );
    if (selected == null || !context.mounted) return;

    await ref
        .read(editorProvider.notifier)
        .enrichScenarioFromSelection(selected.id);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'MUSA está revisando ${selected.displayName} con este fragmento.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLinkCharacter(BuildContext context, WidgetRef ref) async {
    final document = ref.read(currentDocumentProvider);
    final characters = ref.read(charactersProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (document == null) return;

    final selected = await showCharacterPickerSheet(
      context,
      characters: characters,
      linkedCharacterIds: document.characterIds,
    );
    if (selected == null || !context.mounted) return;

    final linked = await ref
        .read(editorProvider.notifier)
        .linkSelectionToCharacter(selected.id);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          linked
              ? '${selected.displayName} ahora forma parte de este capítulo. Más adelante podrás completar su ficha con este contexto.'
              : '${selected.displayName} ya estaba vinculado a este capítulo.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleEnrichCharacter(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final document = ref.read(currentDocumentProvider);
    final characters = ref.read(charactersProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (document == null) return;

    final selected = await showCharacterPickerSheet(
      context,
      characters: characters,
      linkedCharacterIds: document.characterIds,
      title: 'Enriquecer personaje',
      description: 'Elige a quién quieres matizar con este fragmento.',
      showLinkedState: false,
    );
    if (selected == null || !context.mounted) return;

    await ref
        .read(editorProvider.notifier)
        .enrichCharacterFromSelection(selected.id);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'MUSA está revisando a ${selected.displayName} con este fragmento.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getIconForMusa(Musa musa) {
    if (musa is StyleMusa) return Icons.auto_awesome;
    if (musa is TensionMusa) return Icons.bolt;
    if (musa is RhythmMusa) return Icons.multiline_chart;
    if (musa is ClarityMusa) return Icons.visibility;
    return Icons.auto_awesome;
  }

  IconData _iconForGuidedRewriteAction(GuidedRewriteAction action) {
    return switch (action) {
      GuidedRewriteAction.raiseTension => Icons.bolt_outlined,
      GuidedRewriteAction.clarify => Icons.visibility_outlined,
      GuidedRewriteAction.reduceExposition => Icons.compress_outlined,
      GuidedRewriteAction.naturalizeDialogue => Icons.forum_outlined,
    };
  }

  Future<String?> _promptForEntityName(
    BuildContext context, {
    required String title,
    required String initialValue,
    required String hintText,
    required String actionLabel,
  }) async {
    return EditorialDialogs.promptForText(
      context,
      title: title,
      label: 'Nombre',
      initialValue: initialValue,
      actionLabel: actionLabel,
      hintText: hintText,
    );
  }
}

enum _SelectionMenuActionKind {
  createCharacter,
  enrichCharacter,
  linkCharacter,
  createScenario,
  enrichScenario,
  linkScenario,
  guidedRewrite,
  musa,
}

class _SelectionMenuAction {
  const _SelectionMenuAction(this.kind, {this.musa, this.rewriteAction});

  const _SelectionMenuAction.createCharacter()
      : this(_SelectionMenuActionKind.createCharacter);

  const _SelectionMenuAction.enrichCharacter()
      : this(_SelectionMenuActionKind.enrichCharacter);

  const _SelectionMenuAction.linkCharacter()
      : this(_SelectionMenuActionKind.linkCharacter);

  const _SelectionMenuAction.createScenario()
      : this(_SelectionMenuActionKind.createScenario);

  const _SelectionMenuAction.enrichScenario()
      : this(_SelectionMenuActionKind.enrichScenario);

  const _SelectionMenuAction.linkScenario()
      : this(_SelectionMenuActionKind.linkScenario);

  const _SelectionMenuAction.guidedRewrite(GuidedRewriteAction action)
      : this(_SelectionMenuActionKind.guidedRewrite, rewriteAction: action);

  const _SelectionMenuAction.musa(Musa musa)
      : this(_SelectionMenuActionKind.musa, musa: musa);

  final _SelectionMenuActionKind kind;
  final Musa? musa;
  final GuidedRewriteAction? rewriteAction;
}

class _NarrativeMenuItem extends StatelessWidget {
  const _NarrativeMenuItem({
    required this.icon,
    required this.label,
    this.detail,
  });

  final IconData icon;
  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black87),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (detail?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  detail!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        height: 1.15,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectionMenuSectionLabel extends StatelessWidget {
  const _SelectionMenuSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.black38,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
    );
  }
}

class _SelectionHelperText extends StatelessWidget {
  const _SelectionHelperText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _MusaInvocationBadge extends StatefulWidget {
  const _MusaInvocationBadge({
    required this.musa,
    required this.phase,
    required this.showAnimatedMessages,
  });

  final Musa musa;
  final MusaGenerationPhase phase;
  final bool showAnimatedMessages;

  @override
  State<_MusaInvocationBadge> createState() => _MusaInvocationBadgeState();
}

class _MusaInvocationBadgeState extends State<_MusaInvocationBadge> {
  Timer? _timer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant _MusaInvocationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase ||
        oldWidget.musa.id != widget.musa.id) {
      _messageIndex = 0;
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messagesForPhase();
    final text = messages[_messageIndex % messages.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulseGlyph(),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              text,
              key: ValueKey('${widget.phase.name}-$text'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    letterSpacing: 0.2,
                    color: Colors.black87,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _messagesForPhase() {
    return switch (widget.phase) {
      MusaGenerationPhase.invoking => <String>[
          'Invocando ${widget.musa.name}…',
        ],
      MusaGenerationPhase.thinking => widget.musa.thinkingMessages,
      MusaGenerationPhase.streaming => widget.musa.streamingMessages,
      MusaGenerationPhase.completed => <String>[
          '${widget.musa.name} ha dejado una propuesta.',
        ],
      MusaGenerationPhase.failed => <String>[
          '${widget.musa.name} no pudo completar la propuesta.',
        ],
      MusaGenerationPhase.idle => <String>[
          widget.musa.name,
        ],
    };
  }

  void _restartTimer() {
    _timer?.cancel();
    final messages = _messagesForPhase();
    if (!widget.showAnimatedMessages || messages.length <= 1) {
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      if (!mounted) return;
      setState(() {
        _messageIndex = (_messageIndex + 1) % messages.length;
      });
    });
  }
}

class _PulseGlyph extends StatefulWidget {
  const _PulseGlyph();

  @override
  State<_PulseGlyph> createState() => _PulseGlyphState();
}

class _PulseGlyphState extends State<_PulseGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.35 + (_controller.value * 0.55);
        final scale = 0.92 + (_controller.value * 0.12);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
