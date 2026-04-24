import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/suggestion_history.dart';
import '../../core/theme.dart';

/// Widget para navegar por el historial de sugerencias (últimas 5)
class SuggestionHistoryNavigator extends ConsumerWidget {
  final SuggestionHistoryManager historyManager;
  final VoidCallback onPreviousSelected;
  final ValueChanged<HistoricalSuggestion> onSuggestionSelected;

  const SuggestionHistoryNavigator({
    required this.historyManager,
    required this.onPreviousSelected,
    required this.onSuggestionSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = MusaTheme.tokensOf(context);
    final history = historyManager.getAll();

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: tokens.colors.surfaceSecondary,
        border: Border(
          top: BorderSide(color: tokens.colors.divider, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Historial (últimas ${history.length})',
            style: tokens.textStyles.captionSmall.copyWith(
              color: tokens.colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Timeline horizontal de historial
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Botón "Anterior" principal
                _buildPreviousButton(context, tokens),
                const SizedBox(width: 12),
                // Items del historial
                ...List.generate(
                  history.length,
                  (index) => _buildHistoryItem(
                    context,
                    tokens,
                    history[index],
                    index,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousButton(BuildContext context, MusaTheme tokens) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPreviousSelected,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: tokens.colors.divider),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back,
                size: 14,
                color: tokens.colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Anterior',
                style: tokens.textStyles.captionSmall.copyWith(
                  color: tokens.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    MusaTheme tokens,
    HistoricalSuggestion suggestion,
    int index,
  ) {
    final isFirst = index == 0;
    final timestamp = _formatTime(suggestion.timestamp);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSuggestionSelected(suggestion),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isFirst ? tokens.colors.primary.withAlpha(20) : null,
            border: Border.all(
              color: isFirst ? tokens.colors.primary : tokens.colors.divider,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícono de musa + nombre
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getMusaIcon(suggestion.musaId),
                  const SizedBox(width: 4),
                  Text(
                    suggestion.musaName.substring(0, 1).toUpperCase(),
                    style: tokens.textStyles.captionSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isFirst
                          ? tokens.colors.primary
                          : tokens.colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Hora
              Text(
                timestamp,
                style: tokens.textStyles.captionSmall.copyWith(
                  fontSize: 10,
                  color: tokens.colors.textTertiary,
                ),
              ),
              if (suggestion.wasAccepted)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle,
                    size: 12,
                    color: tokens.colors.success,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getMusaIcon(String musaId) {
    return switch (musaId) {
      'clarity' => const Text('📝', style: TextStyle(fontSize: 12)),
      'rhythm' => const Text('🎵', style: TextStyle(fontSize: 12)),
      'style' => const Text('✨', style: TextStyle(fontSize: 12)),
      'tension' => const Text('⚡', style: TextStyle(fontSize: 12)),
      _ => const Text('◆', style: TextStyle(fontSize: 12)),
    };
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

/// Panel desplegable para seleccionar qué pasos del pipeline mantener/descartar
class PipelineStepSelector extends ConsumerWidget {
  final List<String> executedMusas;
  final ValueChanged<List<String>> onStepsSelected;

  const PipelineStepSelector({
    required this.executedMusas,
    required this.onStepsSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = MusaTheme.tokensOf(context);
    final selectedSteps = List.from(executedMusas);

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona pasos a mantener',
              style: tokens.textStyles.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...executedMusas.map((musaId) {
              final name = _getMusaName(musaId);
              return StatefulBuilder(
                builder: (context, setState) {
                  final isSelected = selectedSteps.contains(musaId);
                  return CheckboxListTile(
                    title: Text(name),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedSteps.add(musaId);
                        } else {
                          selectedSteps.remove(musaId);
                        }
                      });
                    },
                  );
                },
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    onStepsSelected(selectedSteps);
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMusaName(String musaId) {
    return switch (musaId) {
      'clarity' => 'Musa de Claridad',
      'rhythm' => 'Musa de Ritmo',
      'style' => 'Musa de Estilo',
      'tension' => 'Musa de Tensión',
      _ => 'Musa desconocida',
    };
  }
}
