import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../muses/musa_effectiveness_tracker.dart';
import '../../muses/providers/musa_providers.dart';
import '../../core/theme.dart';

/// Dashboard que muestra estadísticas de efectividad de las musas
class MusaEffectivenessDashboard extends ConsumerWidget {
  const MusaEffectivenessDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = MusaTheme.tokensOf(context);
    final tracker = ref.watch(musaEffectivenessTrackerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 12),
          child: Text(
            'Estadísticas de Musas',
            style: tokens.textStyles.labelMedium.copyWith(
              color: tokens.colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildMusaStats(context, tokens, 'clarity', 'Claridad', tracker),
        _buildMusaStats(context, tokens, 'rhythm', 'Ritmo', tracker),
        _buildMusaStats(context, tokens, 'style', 'Estilo', tracker),
        _buildMusaStats(context, tokens, 'tension', 'Tensión', tracker),
      ],
    );
  }

  Widget _buildMusaStats(
    BuildContext context,
    MusaTheme tokens,
    String musaId,
    String musaName,
    MusaEffectivenessTracker tracker,
  ) {
    final acceptanceRate = tracker.getAcceptanceRate(musaId);
    final totalShown = tracker.getTotalSuggestionsShown(musaId);
    final multiplier = tracker.getThresholdMultiplier(musaId);

    // Determinar tendencia
    final trend = _getTrend(multiplier);
    final trendColor = _getTrendColor(tokens, multiplier);
    final percentage = (acceptanceRate * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nombre + porcentaje + barra
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$musaName: ',
                      style: tokens.textStyles.labelSmall,
                    ),
                    Text(
                      '$percentage%',
                      style: tokens.textStyles.labelSmall.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      trend,
                      style: tokens.textStyles.labelSmall.copyWith(
                        color: trendColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: acceptanceRate,
                    minHeight: 4,
                    backgroundColor: tokens.colors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getBarColor(tokens, acceptanceRate),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Estadísticas
          Text(
            '($totalShown)',
            style: tokens.textStyles.captionSmall.copyWith(
              color: tokens.colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _getTrend(double multiplier) {
    if (multiplier > 1.15) return '↑↑';
    if (multiplier > 1.0) return '↑';
    if (multiplier < 0.85) return '↓↓';
    if (multiplier < 1.0) return '↓';
    return '→';
  }

  Color _getTrendColor(MusaTheme tokens, double multiplier) {
    if (multiplier > 1.1) return tokens.colors.success;
    if (multiplier < 0.9) return tokens.colors.warning;
    return tokens.colors.textSecondary;
  }

  Color _getBarColor(MusaTheme tokens, double value) {
    if (value >= 0.8) return tokens.colors.success;
    if (value >= 0.6) return tokens.colors.info;
    if (value >= 0.3) return tokens.colors.warning;
    return tokens.colors.error;
  }
}

/// Pequeño badge para mostrar efectividad en la configuración de musas
class EffectivenessIndicator extends ConsumerWidget {
  final String musaId;
  final String musaName;

  const EffectivenessIndicator({
    required this.musaId,
    required this.musaName,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = MusaTheme.tokensOf(context);
    final tracker = ref.watch(musaEffectivenessTrackerProvider);

    final acceptanceRate = tracker.getAcceptanceRate(musaId);
    final multiplier = tracker.getThresholdMultiplier(musaId);
    final percentage = (acceptanceRate * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(tokens, acceptanceRate),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            percentage,
            style: tokens.textStyles.captionSmall.copyWith(
              color: tokens.colors.textInverse,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _getTrendEmoji(multiplier),
            style: tokens.textStyles.captionSmall,
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(MusaTheme tokens, double value) {
    if (value >= 0.8) return tokens.colors.success;
    if (value >= 0.6) return tokens.colors.info;
    if (value >= 0.3) return tokens.colors.warning;
    return tokens.colors.error;
  }

  String _getTrendEmoji(double multiplier) {
    if (multiplier > 1.1) return '📈';
    if (multiplier < 0.9) return '📉';
    return '➡️';
  }
}
