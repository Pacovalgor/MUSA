import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../modules/creative/models/creative_card.dart';

class CreativeCardDetailPanel extends ConsumerWidget {
  const CreativeCardDetailPanel({super.key, required this.card});

  final CreativeCard? card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = MusaTheme.tokensOf(context);
    final selectedCard = card;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.panelBackground,
        border: Border.all(color: tokens.borderSoft),
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: selectedCard == null
            ? Center(
                child: Text(
                  'Selecciona una tarjeta',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: tokens.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalle de tarjeta',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('creative-card-detail-title-field'),
                      controller: TextEditingController(
                        text: selectedCard.title.trim().isEmpty
                            ? 'Idea sin título'
                            : selectedCard.title,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
