import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/editor_controller.dart';
import '../models/chapter_analysis.dart';
import '../models/fragment_analysis.dart';
import '../../core/theme.dart';

class ChapterInsightPanel extends ConsumerStatefulWidget {
  const ChapterInsightPanel({super.key});

  @override
  ConsumerState<ChapterInsightPanel> createState() =>
      _ChapterInsightPanelState();
}

class _ChapterInsightPanelState extends ConsumerState<ChapterInsightPanel> {
  static const double _panelWidth = 460;
  static const double _bottomInset = 36;
  static const double _sideInset = 16;
  static const double _topInset = 16;

  Offset _dragOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    final editorState = ref.watch(editorProvider);
    final analysis = editorState.currentChapterAnalysis;
    final isPending = editorState.isChapterAnalysisPending;
    if (analysis == null && !isPending) {
      if (_dragOffset != Offset.zero) {
        _dragOffset = Offset.zero;
      }
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxPanelHeight = (constraints.maxHeight - 72).clamp(320.0, 760.0);
        final availableHorizontal =
            ((constraints.maxWidth - _panelWidth) / 2) - _sideInset;
        final clampedDx = _dragOffset.dx.clamp(
          availableHorizontal > 0 ? -availableHorizontal : 0,
          availableHorizontal > 0 ? availableHorizontal : 0,
        );
        final maxUpwardTravel =
            (constraints.maxHeight - 320).clamp(_topInset, 1200).toDouble();
        final clampedDy = _dragOffset.dy.clamp(-maxUpwardTravel, 0.0);
        final visualOffset = Offset(clampedDx.toDouble(), clampedDy.toDouble());

        return Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: visualOffset,
            child: Padding(
              padding: const EdgeInsets.only(bottom: _bottomInset),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: _panelWidth,
                  constraints: BoxConstraints(
                    maxHeight: maxPanelHeight,
                  ),
                  padding: const EdgeInsets.all(18),
                  decoration: MusaTheme.panelDecoration(
                    context,
                    backgroundColor: tokens.canvasBackground,
                    radius: 20,
                    elevated: true,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PanelHeader(
                        onClose: () => ref
                            .read(editorProvider.notifier)
                            .dismissChapterAnalysis(),
                        onDragUpdate: (delta) {
                          setState(() {
                            _dragOffset = Offset(
                              _dragOffset.dx + delta.dx,
                              _dragOffset.dy + delta.dy,
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(right: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isPending) ...[
                                const _ChapterAnalysisLoadingState(),
                              ] else ...[
                                if (analysis!.mainCharacters.isNotEmpty)
                                  _CharactersSection(
                                      items: analysis.mainCharacters),
                                if (analysis.mainScenario != null) ...[
                                  const SizedBox(height: 10),
                                  _ScenarioSection(
                                      item: analysis.mainScenario!),
                                ],
                                const SizedBox(height: 10),
                                _MomentSection(
                                  dominant: analysis.dominantNarrativeMoment,
                                  moments: analysis.narrativeMoments,
                                ),
                                const SizedBox(height: 10),
                                _FunctionSection(
                                    item: analysis.chapterFunction),
                                if (analysis.characterDevelopments.isNotEmpty ||
                                    analysis.scenarioDevelopments.isNotEmpty ||
                                    analysis.trajectory != null) ...[
                                  const SizedBox(height: 10),
                                  _ChangesSection(analysis: analysis),
                                ],
                                if (analysis.recommendation != null) ...[
                                  const SizedBox(height: 10),
                                  _RecommendationSection(
                                      item: analysis.recommendation!),
                                ],
                                if (analysis.nextStep != null) ...[
                                  const SizedBox(height: 10),
                                  _NextStepSection(item: analysis.nextStep!),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.onClose,
    required this.onDragUpdate,
  });

  final VoidCallback onClose;
  final ValueChanged<Offset> onDragUpdate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => onDragUpdate(details.delta),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Entendiendo el capítulo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MusaTheme.tokensOf(context).textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close, size: 18),
            color: MusaTheme.tokensOf(context).textMuted,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _ChapterAnalysisLoadingState extends StatelessWidget {
  const _ChapterAnalysisLoadingState();

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: tokens.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Leyendo el capítulo…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CharactersSection extends StatelessWidget {
  const _CharactersSection({required this.items});

  final List<DetectedCharacter> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Personajes clave',
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _EntityRow(
                  icon: Icons.person_outline,
                  title: item.name,
                  subtitle: item.summary,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ScenarioSection extends StatelessWidget {
  const _ScenarioSection({required this.item});

  final DetectedScenario item;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Escenario principal',
      child: _EntityRow(
        icon: Icons.place_outlined,
        title: item.name,
        subtitle: item.summary,
      ),
    );
  }
}

class _MomentSection extends StatelessWidget {
  const _MomentSection({
    required this.dominant,
    required this.moments,
  });

  final NarrativeMoment dominant;
  final List<NarrativeMoment> moments;

  @override
  Widget build(BuildContext context) {
    final secondary =
        moments.where((item) => item.title != dominant.title).toList();
    return _SectionCard(
      title: 'Momento dominante',
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dominant.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MusaTheme.tokensOf(context).textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            dominant.summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MusaTheme.tokensOf(context).textSecondary,
                  height: 1.35,
                ),
          ),
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'También aparecen: ${secondary.map((item) => item.title).join(' · ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MusaTheme.tokensOf(context).textMuted,
                    height: 1.3,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FunctionSection extends StatelessWidget {
  const _FunctionSection({required this.item});

  final ChapterFunction item;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Función del capítulo',
      child: _EntityRow(
        icon: Icons.auto_stories_outlined,
        title: item.label,
        subtitle: item.summary,
      ),
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({required this.item});

  final ChapterRecommendation item;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recomendación de MUSA',
      accent: true,
      child: Text(
        item.message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MusaTheme.tokensOf(context).textPrimary,
              height: 1.35,
            ),
      ),
    );
  }
}

class _NextStepSection extends ConsumerWidget {
  const _NextStepSection({required this.item});

  final ChapterNextStep item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(editorProvider.notifier);
    return _SectionCard(
      title: 'Siguiente paso',
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MusaTheme.tokensOf(context).textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (item.exampleText != null) ...[
            const SizedBox(height: 6),
            Text(
              item.exampleText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MusaTheme.tokensOf(context).textSecondary,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              final handlesDirectAction =
                  item.type == NextStepType.createCharacter ||
                      item.type == NextStepType.enrichCharacter ||
                      item.type == NextStepType.createScenario ||
                      item.type == NextStepType.enrichScenario;
              if (handlesDirectAction) {
                controller.performChapterNextStep(item);
                return;
              }
              if (item.type == NextStepType.expandMoment) {
                final analysis = ref.read(editorProvider).currentChapterAnalysis;
                if (analysis != null) {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _ExpandMomentSheet(analysis: analysis),
                  );
                }
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_nextStepHint(item)),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: MusaTheme.tokensOf(context).textPrimary,
              side: BorderSide(color: MusaTheme.tokensOf(context).borderSoft),
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(item.actionLabel),
          ),
        ],
      ),
    );
  }

  String _nextStepHint(ChapterNextStep item) {
    return switch (item.type) {
      NextStepType.strengthenConflict =>
        'Sugerencia editorial: empuja el conflicto del capítulo en la siguiente reescritura.',
      NextStepType.connectToPlot =>
        'Sugerencia editorial: conecta este capítulo con la trama principal en la siguiente pasada.',
      NextStepType.expandMoment =>
        'Sugerencia editorial: desarrolla este momento con más peso en la siguiente revisión.',
      NextStepType.createCharacter =>
        'Aquí podrás crear este personaje desde el análisis del capítulo.',
      NextStepType.enrichCharacter =>
        'Aquí podrás enriquecer este personaje desde el análisis del capítulo.',
      NextStepType.createScenario =>
        'Aquí podrás fijar este lugar como escenario.',
      NextStepType.enrichScenario =>
        'Aquí podrás enriquecer este escenario desde el análisis del capítulo.',
    };
  }
}

class _ExpandMomentSheet extends ConsumerStatefulWidget {
  const _ExpandMomentSheet({required this.analysis});

  final ChapterAnalysis analysis;

  @override
  ConsumerState<_ExpandMomentSheet> createState() => _ExpandMomentSheetState();
}

class _ExpandMomentSheetState extends ConsumerState<_ExpandMomentSheet> {
  int _selectedIndex = 0;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    final controller = ref.read(editorProvider.notifier);
    final aid = controller.buildExpandMomentEditorialAid(widget.analysis);
    final directions = aid.directions;
    if (directions.isEmpty) {
      return const SizedBox.shrink();
    }
    final clampedIndex = _selectedIndex.clamp(0, directions.length - 1);
    final selected = directions[clampedIndex];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(18),
              decoration: MusaTheme.panelDecoration(
                context,
                backgroundColor: tokens.canvasBackground,
                radius: 22,
                elevated: true,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Desarrollar este momento',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    aid.problem,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Elige una dirección. La idea es empujar la escena, no cerrarla.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(directions.length, (index) {
                    final item = directions[index];
                    final selectedTile = index == clampedIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _selectedIndex = index),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: MusaTheme.panelDecoration(
                            context,
                            accent: selectedTile,
                            radius: 14,
                            backgroundColor: selectedTile
                                ? tokens.warningBackground
                                : tokens.subtleBackground,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: tokens.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.summary,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: tokens.textSecondary,
                                      height: 1.35,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  _SectionCard(
                    title: 'Empuje posible',
                    accent: true,
                    child: Text(
                      selected.example,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textPrimary,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  setState(() => _isSaving = true);
                                  final ok = await controller
                                      .useExpandMomentDirection(selected);
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? 'Dirección guardada como nota editorial.'
                                            : 'No se pudo guardar la dirección editorial.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                          child: Text(
                            _isSaving
                                ? 'Guardando…'
                                : 'Usar esta dirección',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: directions.length <= 1
                            ? null
                            : () => setState(() {
                                  _selectedIndex =
                                      (_selectedIndex + 1) % directions.length;
                                }),
                        child: const Text('Ver otra'),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangesSection extends StatelessWidget {
  const _ChangesSection({required this.analysis});

  final ChapterAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Qué cambia aquí',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...analysis.characterDevelopments.take(2).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ChangeRow(
                    icon: Icons.person_outline,
                    label: item.label,
                    summary: item.summary,
                  ),
                ),
              ),
          ...analysis.scenarioDevelopments.take(1).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ChangeRow(
                    icon: Icons.place_outlined,
                    label: item.label,
                    summary: item.summary,
                  ),
                ),
              ),
          if (analysis.trajectory != null)
            _ChangeRow(
              icon: Icons.trending_flat_outlined,
              label: 'Trayectoria',
              summary: analysis.trajectory!.summary,
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.accent = false,
  });

  final String title;
  final Widget child;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: MusaTheme.panelDecoration(
        context,
        accent: accent,
        radius: 16,
        backgroundColor: accent
            ? MusaTheme.tokensOf(context).warningBackground
            : MusaTheme.tokensOf(context).subtleBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: MusaTheme.sectionEyebrow(context),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _EntityRow extends StatelessWidget {
  const _EntityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 16,
            color: MusaTheme.tokensOf(context).textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: MusaTheme.tokensOf(context).textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MusaTheme.tokensOf(context).textSecondary,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.icon,
    required this.label,
    required this.summary,
  });

  final IconData icon;
  final String label;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 15,
            color: MusaTheme.tokensOf(context).textMuted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MusaTheme.tokensOf(context).textSecondary,
                    height: 1.35,
                  ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MusaTheme.tokensOf(context).textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                ),
                TextSpan(text: summary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
