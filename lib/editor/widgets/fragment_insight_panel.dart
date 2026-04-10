import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/editor_controller.dart';
import '../models/fragment_analysis.dart';
import '../../core/theme.dart';

class FragmentInsightPanel extends ConsumerStatefulWidget {
  const FragmentInsightPanel({super.key});

  @override
  ConsumerState<FragmentInsightPanel> createState() =>
      _FragmentInsightPanelState();
}

class _FragmentInsightPanelState extends ConsumerState<FragmentInsightPanel> {
  static const double _panelWidth = 440;
  static const double _bottomInset = 36;
  static const double _sideInset = 16;
  static const double _topInset = 16;

  Offset _dragOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    final analysis = ref.watch(editorProvider).currentFragmentAnalysis;
    if (analysis == null) {
      if (_dragOffset != Offset.zero) {
        _dragOffset = Offset.zero;
      }
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHorizontal =
            ((constraints.maxWidth - _panelWidth) / 2) - _sideInset;
        final clampedDx = _dragOffset.dx.clamp(
          availableHorizontal > 0 ? -availableHorizontal : 0,
          availableHorizontal > 0 ? availableHorizontal : 0,
        );
        final maxUpwardTravel =
            (constraints.maxHeight - 260).clamp(_topInset, 1000).toDouble();
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
                            .dismissFragmentAnalysis(),
                        onDragUpdate: (delta) {
                          setState(() {
                            _dragOffset = Offset(
                              _dragOffset.dx + delta.dx,
                              _dragOffset.dy + delta.dy,
                            );
                          });
                        },
                      ),
                      if (analysis.narrator != null) ...[
                        const SizedBox(height: 10),
                        _NarratorSection(item: analysis.narrator!),
                      ],
                      if (analysis.characters.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _CharactersSection(items: analysis.characters),
                      ],
                      if (analysis.scenario != null) ...[
                        const SizedBox(height: 10),
                        _ScenarioSection(item: analysis.scenario!),
                      ],
                      const SizedBox(height: 10),
                      _MomentSection(moment: analysis.moment),
                      if (analysis.recommendation != null) ...[
                        const SizedBox(height: 10),
                        _RecommendationSection(item: analysis.recommendation!),
                      ],
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
              'Entendiendo el fragmento',
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

class _NarratorSection extends ConsumerWidget {
  const _NarratorSection({required this.item});

  final NarratorInsight item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(editorProvider.notifier);
    final actionLabel = item.protagonistExists
        ? 'Enriquecer protagonista'
        : 'Crear protagonista';

    return _SectionCard(
      title: 'Narradora',
      child: _EntityRow(
        icon: Icons.visibility_outlined,
        title: item.title,
        subtitle: item.summary,
        actionLabel: actionLabel,
        onAction: item.action == null
            ? null
            : () => controller.performInsightAction(item.action!),
      ),
    );
  }
}

class _CharactersSection extends ConsumerWidget {
  const _CharactersSection({required this.items});

  final List<DetectedCharacter> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(editorProvider.notifier);

    return _SectionCard(
      title: 'Personajes en escena',
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _EntityRow(
                  icon: Icons.person_outline,
                  title: item.name,
                  subtitle: item.summary,
                  actionLabel: item.action?.label,
                  onAction: item.action == null
                      ? null
                      : () => controller.performInsightAction(item.action!),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ScenarioSection extends ConsumerWidget {
  const _ScenarioSection({required this.item});

  final DetectedScenario item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(editorProvider.notifier);

    return _SectionCard(
      title: 'Escenario',
      child: _EntityRow(
        icon: Icons.place_outlined,
        title: item.name,
        subtitle: item.summary,
        actionLabel: item.action?.label,
        onAction: item.action == null
            ? null
            : () => controller.performInsightAction(item.action!),
      ),
    );
  }
}

class _MomentSection extends StatelessWidget {
  const _MomentSection({required this.moment});

  final NarrativeMoment moment;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Momento narrativo',
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            moment.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MusaTheme.tokensOf(context).textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            moment.summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MusaTheme.tokensOf(context).textSecondary,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationSection extends ConsumerWidget {
  const _RecommendationSection({required this.item});

  final FragmentRecommendation item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(editorProvider.notifier);
    return _SectionCard(
      title: 'Recomendación de MUSA',
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.reason,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MusaTheme.tokensOf(context).textPrimary,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 8),
          _ActionChip(
            label: item.action.label,
            onTap: () => controller.performInsightAction(item.action),
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
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

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
              const SizedBox(height: 8),
              if (actionLabel != null && onAction != null)
                _ActionChip(
                  label: actionLabel!,
                  onTap: onAction!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: MusaTheme.tokensOf(context).textPrimary,
        side: BorderSide(color: MusaTheme.tokensOf(context).borderSubtle),
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}
