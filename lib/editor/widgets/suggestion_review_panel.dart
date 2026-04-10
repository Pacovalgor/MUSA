import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../modules/books/models/musa_settings.dart';
import '../../modules/books/providers/workspace_providers.dart';
import '../../muses/musa.dart';
import '../controller/editor_controller.dart';
import 'comparison_view.dart';
import '../../core/theme.dart';

class SuggestionReviewPanel extends ConsumerStatefulWidget {
  const SuggestionReviewPanel({super.key});

  @override
  ConsumerState<SuggestionReviewPanel> createState() =>
      _SuggestionReviewPanelState();
}

class _SuggestionReviewPanelState extends ConsumerState<SuggestionReviewPanel> {
  static const String _positionXKey = 'suggestion_review_panel_position_x';
  static const String _positionYKey = 'suggestion_review_panel_position_y';
  static const double _panelWidth = 600;
  static const double _viewportPadding = 24;
  static const double _defaultBottomMargin = 40;

  Offset? _storedPosition;
  bool _positionLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPosition();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    final editorState = ref.watch(editorProvider);
    final suggestion = editorState.currentSuggestion;
    final streamingText = editorState.streamingText;
    final generationPhase = editorState.generationPhase;
    final activeMusa = editorState.activeMusa;
    final musaSettings = ref.watch(musaSettingsProvider);
    final isChapterFlow = editorState.isChapterAnalysisPending ||
        editorState.currentChapterAnalysis != null;

    if (isChapterFlow) {
      return const SizedBox.shrink();
    }

    if (suggestion == null &&
        streamingText == null &&
        generationPhase == MusaGenerationPhase.idle) {
      return const SizedBox.shrink();
    }

    final displayText = suggestion?.suggestedText ?? streamingText ?? '';
    final isErrorSuggestion =
        suggestion != null && suggestion.id.startsWith('error');
    final isScopeWarning =
        suggestion != null && suggestion.id.startsWith('warning-scope');
    final isBusy = generationPhase == MusaGenerationPhase.invoking ||
        generationPhase == MusaGenerationPhase.thinking ||
        generationPhase == MusaGenerationPhase.streaming;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final availableWidth = math.max(
          260.0,
          viewportSize.width - (_viewportPadding * 2),
        );
        final panelWidth = math.min(
          _panelWidth,
          availableWidth,
        );
        final maxPanelHeight = math.max(
          260.0,
          viewportSize.height - (_viewportPadding * 2),
        );
        final preferredPanelHeight = suggestion != null ? 430.0 : 330.0;
        final panelHeight = math.min(preferredPanelHeight, maxPanelHeight);
        final panelSize = Size(panelWidth, panelHeight);

        if (!_positionLoaded) {
          return const SizedBox.shrink();
        }

        final position = _resolvedPosition(viewportSize, panelSize);

        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              width: panelWidth,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: panelHeight,
                  decoration: MusaTheme.panelDecoration(
                    context,
                    backgroundColor: tokens.canvasBackground,
                    radius: 18,
                    elevated: true,
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          _updatePosition(
                            viewportSize: viewportSize,
                            panelSize: panelSize,
                            delta: details.delta,
                          );
                        },
                        onPanEnd: (_) => _persistPosition(),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                          child: Row(
                            children: [
                              _PanelMuseMark(musa: activeMusa),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activeMusa == null
                                          ? 'PROPUESTA DE LA MUSA'
                                          : activeMusa.name.toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontSize: 11,
                                            letterSpacing: 1.5,
                                            fontWeight: FontWeight.w700,
                                            color: tokens.textMuted,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    _PanelStatusLine(
                                      phase: generationPhase,
                                      musa: activeMusa,
                                      visualPresence:
                                          musaSettings.visualPresence,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.drag_indicator,
                                size: 18,
                                color: tokens.textMuted,
                              ),
                              if (musaSettings.showStreamingChip &&
                                  generationPhase ==
                                      MusaGenerationPhase.streaming) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tokens.hoverBackground,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Generando',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: tokens.textSecondary,
                                          fontSize: 11,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: editorState.isComparisonMode &&
                                  suggestion != null
                              ? const ComparisonView()
                              : Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: MusaTheme.panelDecoration(
                                    context,
                                    backgroundColor: tokens.panelBackground,
                                    radius: 14,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (isScopeWarning) ...[
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(14),
                                          decoration: MusaTheme.panelDecoration(
                                            context,
                                            accent: true,
                                            radius: 12,
                                            backgroundColor:
                                                tokens.warningBackground,
                                          ),
                                          child: Text(
                                            'Se ha alejado un poco del fragmento original. Revísalo antes de aplicarlo.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: tokens.warningText,
                                                  height: 1.45,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                      ],
                                      if (displayText.isNotEmpty)
                                        Text(
                                          displayText,
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayLarge
                                              ?.copyWith(
                                                fontSize: 16,
                                                height: 1.6,
                                                color: tokens.textPrimary,
                                              ),
                                        )
                                      else
                                        _WaitingSurface(
                                          phase: generationPhase,
                                          musa: activeMusa,
                                          visualPresence:
                                              musaSettings.visualPresence,
                                        ),
                                      if (suggestion?.editorComment !=
                                          null) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          width: double.infinity,
                                          height: 1,
                                          color: Colors.black.withValues(
                                            alpha: 0.02,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Nota editorial: ${suggestion!.editorComment}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: tokens.textMuted,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      if (suggestion != null)
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              if (!isErrorSuggestion)
                                TextButton(
                                  onPressed: () => ref
                                      .read(editorProvider.notifier)
                                      .toggleComparisonMode(),
                                  child: Text(
                                    editorState.isComparisonMode
                                        ? 'Ocultar Comparación'
                                        : 'Comparar',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: tokens.textSecondary,
                                          fontSize: 12,
                                        ),
                                  ),
                                ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => ref
                                    .read(editorProvider.notifier)
                                    .discardSuggestion(),
                                child: Text(
                                  'Descartar',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: tokens.textSecondary),
                                ),
                              ),
                              if (!isErrorSuggestion) ...[
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => ref
                                      .read(editorProvider.notifier)
                                      .acceptSuggestion(),
                                  child: const Text('Aplicar'),
                                ),
                              ],
                            ],
                          ),
                        )
                      else if (isBusy)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: musaSettings.showBreathLine
                              ? const _EditorialBreathLine()
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadSavedPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final dx = prefs.getDouble(_positionXKey);
    final dy = prefs.getDouble(_positionYKey);

    if (!mounted) return;
    setState(() {
      _storedPosition = dx == null || dy == null ? null : Offset(dx, dy);
      _positionLoaded = true;
    });
  }

  void _updatePosition({
    required Size viewportSize,
    required Size panelSize,
    required Offset delta,
  }) {
    final next = _clampPosition(
      (_storedPosition ?? _defaultPosition(viewportSize, panelSize)) + delta,
      viewportSize,
      panelSize,
    );

    if (_storedPosition == next) {
      return;
    }

    setState(() {
      _storedPosition = next;
    });
  }

  Offset _resolvedPosition(Size viewportSize, Size panelSize) {
    final base = _storedPosition ?? _defaultPosition(viewportSize, panelSize);
    final clamped = _clampPosition(base, viewportSize, panelSize);

    if (_storedPosition != clamped) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _storedPosition = clamped;
        });
        _persistPosition();
      });
    }

    return clamped;
  }

  Offset _defaultPosition(Size viewportSize, Size panelSize) {
    final left = (viewportSize.width - panelSize.width) / 2;
    final top = viewportSize.height - panelSize.height - _defaultBottomMargin;
    return _clampPosition(Offset(left, top), viewportSize, panelSize);
  }

  Offset _clampPosition(
    Offset position,
    Size viewportSize,
    Size panelSize,
  ) {
    const minX = _viewportPadding;
    const minY = _viewportPadding;
    final maxX =
        math.max(minX, viewportSize.width - panelSize.width - _viewportPadding);
    final maxY = math.max(
        minY, viewportSize.height - panelSize.height - _viewportPadding);

    return Offset(
      position.dx.clamp(minX, maxX).toDouble(),
      position.dy.clamp(minY, maxY).toDouble(),
    );
  }

  Future<void> _persistPosition() async {
    final position = _storedPosition;
    if (position == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_positionXKey, position.dx);
    await prefs.setDouble(_positionYKey, position.dy);
  }
}

class _PanelMuseMark extends StatelessWidget {
  const _PanelMuseMark({required this.musa});

  final Musa? musa;

  @override
  Widget build(BuildContext context) {
    final icon = switch (musa) {
      StyleMusa() => Icons.auto_awesome,
      TensionMusa() => Icons.bolt,
      RhythmMusa() => Icons.multiline_chart,
      ClarityMusa() => Icons.visibility,
      _ => Icons.auto_awesome,
    };

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: MusaTheme.tokensOf(context).hoverBackground,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 15,
        color: MusaTheme.tokensOf(context).textSecondary,
      ),
    );
  }
}

class _PanelStatusLine extends StatefulWidget {
  const _PanelStatusLine({
    required this.phase,
    required this.musa,
    required this.visualPresence,
  });

  final MusaGenerationPhase phase;
  final Musa? musa;
  final VisualPresence visualPresence;

  @override
  State<_PanelStatusLine> createState() => _PanelStatusLineState();
}

class _PanelStatusLineState extends State<_PanelStatusLine> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _PanelStatusLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase ||
        oldWidget.musa?.id != widget.musa?.id) {
      _index = 0;
      _syncTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages;
    final message = messages[_index % messages.length];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Text(
        message,
        key: ValueKey('${widget.phase.name}-$message'),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: MusaTheme.tokensOf(context).textSecondary,
            ),
      ),
    );
  }

  List<String> get _messages {
    final musa = widget.musa;
    if (musa == null) {
      return const ['La Musa está trabajando…'];
    }
    if (widget.visualPresence != VisualPresence.visible) {
      return switch (widget.phase) {
        MusaGenerationPhase.invoking => <String>['Invocando ${musa.name}…'],
        MusaGenerationPhase.thinking => <String>[
            'La Musa está ajustando su intervención.'
          ],
        MusaGenerationPhase.streaming => <String>[
            'La propuesta ya está tomando forma.'
          ],
        MusaGenerationPhase.completed => <String>[
            'Propuesta lista para revisión.'
          ],
        MusaGenerationPhase.failed => <String>[
            'La invocación no pudo completarse.'
          ],
        MusaGenerationPhase.idle => <String>[''],
      };
    }
    return switch (widget.phase) {
      MusaGenerationPhase.invoking => <String>['Invocando ${musa.name}…'],
      MusaGenerationPhase.thinking => musa.thinkingMessages,
      MusaGenerationPhase.streaming => musa.streamingMessages,
      MusaGenerationPhase.completed => <String>[
          'Propuesta lista para revisión.'
        ],
      MusaGenerationPhase.failed => <String>[
          'La invocación no pudo completarse.'
        ],
      MusaGenerationPhase.idle => <String>[''],
    };
  }

  void _syncTimer() {
    _timer?.cancel();
    if (widget.visualPresence != VisualPresence.visible ||
        _messages.length <= 1) {
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % _messages.length;
      });
    });
  }
}

class _WaitingSurface extends StatelessWidget {
  const _WaitingSurface({
    required this.phase,
    required this.musa,
    required this.visualPresence,
  });

  final MusaGenerationPhase phase;
  final Musa? musa;
  final VisualPresence visualPresence;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          switch (phase) {
            MusaGenerationPhase.invoking => 'La invocación ha sido lanzada.',
            MusaGenerationPhase.thinking =>
              'La Musa está leyendo contexto y ajustando su intervención.',
            MusaGenerationPhase.streaming =>
              'La propuesta ya está tomando forma.',
            MusaGenerationPhase.failed => 'La propuesta no pudo generarse.',
            _ => 'Esperando propuesta…',
          },
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MusaTheme.tokensOf(context).textSecondary,
                height: 1.5,
              ),
        ),
        if (visualPresence != VisualPresence.minimal) ...[
          const SizedBox(height: 16),
          const _EditorialBreathLine(),
        ],
        if (visualPresence == VisualPresence.visible &&
            musa != null &&
            phase != MusaGenerationPhase.failed) ...[
          const SizedBox(height: 16),
          Text(
            switch (phase) {
              MusaGenerationPhase.invoking =>
                'Preparando ${musa!.shortName.toLowerCase()}…',
              MusaGenerationPhase.thinking => musa!.thinkingMessages.first,
              MusaGenerationPhase.streaming => musa!.streamingMessages.first,
              _ => '',
            },
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MusaTheme.tokensOf(context).textMuted,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ],
    );
  }
}

class _EditorialBreathLine extends StatefulWidget {
  const _EditorialBreathLine();

  @override
  State<_EditorialBreathLine> createState() => _EditorialBreathLineState();
}

class _EditorialBreathLineState extends State<_EditorialBreathLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
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
        final opacity = 0.2 + (_controller.value * 0.35);
        return Container(
          width: 140,
          height: 4,
          decoration: BoxDecoration(
            color: MusaTheme.tokensOf(context).textMuted.withValues(
                  alpha: opacity,
                ),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      },
    );
  }
}
