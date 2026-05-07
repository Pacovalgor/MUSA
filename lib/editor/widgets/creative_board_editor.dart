import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../modules/books/providers/workspace_providers.dart';
import '../../modules/creative/models/creative_card.dart';
import '../../modules/creative/providers/creative_providers.dart';
import 'creative_card_detail_panel.dart';

class CreativeBoardEditor extends ConsumerStatefulWidget {
  const CreativeBoardEditor({super.key});

  @override
  ConsumerState<CreativeBoardEditor> createState() =>
      _CreativeBoardEditorState();
}

class _CreativeBoardEditorState extends ConsumerState<CreativeBoardEditor> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  CreativeCardType _type = CreativeCardType.idea;
  String? _selectedCardId;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    final workspace = ref.watch(narrativeWorkspaceProvider).value;
    final activeBook = workspace?.activeBook;
    final cards = ref.watch(visibleCreativeCardsProvider);
    final selectedCard = cards.cast<CreativeCard?>().firstWhere(
          (card) => card?.id == _selectedCardId,
          orElse: () => null,
        );
    if (_selectedCardId != null && selectedCard == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedCardId = null);
      });
    }

    return ColoredBox(
      color: tokens.canvasBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BoardHeader(activeBookTitle: activeBook?.title),
              const SizedBox(height: 18),
              _CreateCardForm(
                titleController: _titleController,
                bodyController: _bodyController,
                type: _type,
                isEnabled: activeBook != null && !_isCreating,
                onTypeChanged: (value) {
                  if (value == null) return;
                  setState(() => _type = value);
                },
                onCreate: _createCard,
              ),
              const SizedBox(height: 18),
              Expanded(
                child: activeBook == null
                    ? const _BoardMessage(
                        icon: Icons.menu_book_outlined,
                        title: 'No hay libro activo',
                        body:
                            'Selecciona o crea un libro para usar la mesa creativa.',
                      )
                    : cards.isEmpty
                        ? const _BoardMessage(
                            icon: Icons.dashboard_customize_outlined,
                            title: 'No hay tarjetas visibles',
                            body:
                                'Crea una tarjeta para capturar ideas, bocetos o preguntas sin llevarlas a memoria narrativa.',
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _BoardColumns(
                                  cards: cards,
                                  selectedCardId: _selectedCardId,
                                  onSelectCard: (cardId) {
                                    setState(() => _selectedCardId = cardId);
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              SizedBox(
                                width: 360,
                                child:
                                    CreativeCardDetailPanel(card: selectedCard),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createCard() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty && body.isEmpty) return;

    setState(() => _isCreating = true);
    await ref.read(narrativeWorkspaceProvider.notifier).createCreativeCard(
          title: title.isEmpty ? 'Idea sin título' : title,
          body: body,
          type: _type,
        );
    if (!mounted) return;
    _titleController.clear();
    _bodyController.clear();
    setState(() {
      _type = CreativeCardType.idea;
      _isCreating = false;
    });
  }
}

class _BoardHeader extends StatelessWidget {
  const _BoardHeader({required this.activeBookTitle});

  final String? activeBookTitle;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mesa creativa',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          activeBookTitle == null
              ? 'Sin libro activo'
              : 'Libro: $activeBookTitle',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _CreateCardForm extends StatelessWidget {
  const _CreateCardForm({
    required this.titleController,
    required this.bodyController,
    required this.type,
    required this.isEnabled,
    required this.onTypeChanged,
    required this.onCreate,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final CreativeCardType type;
  final bool isEnabled;
  final ValueChanged<CreativeCardType?> onTypeChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.subtleBackground,
        border: Border.all(color: tokens.borderSoft),
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                key: const Key('creative-card-title-field'),
                controller: titleController,
                enabled: isEnabled,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: TextField(
                key: const Key('creative-card-body-field'),
                controller: bodyController,
                enabled: isEnabled,
                minLines: 1,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Cuerpo',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<CreativeCardType>(
                key: ValueKey(type),
                initialValue: type,
                onChanged: isEnabled ? onTypeChanged : null,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: CreativeCardType.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_typeLabel(value)),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              key: const Key('creative-card-create-button'),
              onPressed: isEnabled ? onCreate : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardColumns extends StatelessWidget {
  const _BoardColumns({
    required this.cards,
    required this.selectedCardId,
    required this.onSelectCard,
  });

  final List<CreativeCard> cards;
  final String? selectedCardId;
  final ValueChanged<String> onSelectCard;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      primary: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _visibleStatuses
            .map(
              (status) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _BoardColumn(
                  status: status,
                  cards: cards
                      .where((card) => card.status == status)
                      .toList(growable: false),
                  selectedCardId: selectedCardId,
                  onSelectCard: onSelectCard,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
    required this.status,
    required this.cards,
    required this.selectedCardId,
    required this.onSelectCard,
  });

  final CreativeCardStatus status;
  final List<CreativeCard> cards;
  final String? selectedCardId;
  final ValueChanged<String> onSelectCard;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return SizedBox(
      width: 260,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.panelBackground,
          border: Border.all(color: tokens.borderSoft),
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusDot(status: status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusLabel(status),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    '${cards.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textMuted,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (cards.isEmpty)
                Text(
                  'Vacío',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textMuted,
                      ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    primary: false,
                    itemCount: cards.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return _CreativeCardTile(
                        card: card,
                        isSelected: card.id == selectedCardId,
                        onSelect: () => onSelectCard(card.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreativeCardTile extends ConsumerWidget {
  const _CreativeCardTile({
    required this.card,
    required this.isSelected,
    required this.onSelect,
  });

  final CreativeCard card;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = MusaTheme.tokensOf(context);
    final borderColor =
        isSelected ? tokens.editorCaret : _statusColor(card.status, tokens);
    return Material(
      color: tokens.canvasBackground,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: isSelected ? 2 : 1),
        borderRadius: BorderRadius.circular(tokens.radiusSm),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: Key('creative-card-tile-${card.id}'),
            onTap: onSelect,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title.trim().isEmpty ? 'Idea sin título' : card.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (card.body.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      card.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                            height: 1.35,
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MetaChip(label: _typeLabel(card.type)),
                      _MetaChip(label: _sourceLabel(card.source)),
                      _MetaChip(label: _statusLabel(card.status)),
                      ...card.tags.map((tag) => _MetaChip(label: '#$tag')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (card.status != CreativeCardStatus.converted)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _moveTargetStatuses(card.status)
                    .map(
                      (status) => OutlinedButton(
                        key: Key('creative-card-${card.id}-${status.name}'),
                        onPressed: () => ref
                            .read(narrativeWorkspaceProvider.notifier)
                            .moveCreativeCard(cardId: card.id, status: status),
                        child: Text(_shortStatusLabel(status)),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (card.status != CreativeCardStatus.converted) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Wrap(
                spacing: 4,
                runSpacing: 0,
                children: [
                  _ConversionButton(
                    label: 'Nota',
                    onPressed: () => _convert(
                      ref,
                      () => ref
                          .read(narrativeWorkspaceProvider.notifier)
                          .convertCreativeCardToNote(card.id),
                    ),
                  ),
                  _ConversionButton(
                    label: 'Personaje',
                    onPressed: () => _convert(
                      ref,
                      () => ref
                          .read(narrativeWorkspaceProvider.notifier)
                          .convertCreativeCardToCharacter(card.id),
                    ),
                  ),
                  _ConversionButton(
                    label: 'Escenario',
                    onPressed: () => _convert(
                      ref,
                      () => ref
                          .read(narrativeWorkspaceProvider.notifier)
                          .convertCreativeCardToScenario(card.id),
                    ),
                  ),
                  _ConversionButton(
                    label: 'Documento',
                    onPressed: () => _convert(
                      ref,
                      () => ref
                          .read(narrativeWorkspaceProvider.notifier)
                          .convertCreativeCardToDocument(card.id),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _convert(
    WidgetRef ref,
    Future<Object?> Function() convert,
  ) async {
    await convert();
    await ref.read(narrativeWorkspaceProvider.notifier).openCreativeBoard();
  }
}

class _ConversionButton extends StatelessWidget {
  const _ConversionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 30),
      ),
      child: Text(label),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.hoverBackground,
        borderRadius: BorderRadius.circular(tokens.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final CreativeCardStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: _statusColor(status, tokens),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BoardMessage extends StatelessWidget {
  const _BoardMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: tokens.textMuted),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

const _visibleStatuses = [
  CreativeCardStatus.inbox,
  CreativeCardStatus.exploring,
  CreativeCardStatus.promising,
  CreativeCardStatus.readyToUse,
  CreativeCardStatus.converted,
];

List<CreativeCardStatus> _moveTargetStatuses(CreativeCardStatus current) {
  return _visibleStatuses
      .where((status) =>
          status != current && status != CreativeCardStatus.converted)
      .toList(growable: false);
}

String _statusLabel(CreativeCardStatus status) => switch (status) {
      CreativeCardStatus.inbox => 'Inbox',
      CreativeCardStatus.exploring => 'Explorando',
      CreativeCardStatus.promising => 'Prometedoras',
      CreativeCardStatus.readyToUse => 'Listas',
      CreativeCardStatus.converted => 'Convertidas',
      CreativeCardStatus.archived => 'Archivadas',
    };

String _shortStatusLabel(CreativeCardStatus status) => switch (status) {
      CreativeCardStatus.inbox => 'Inbox',
      CreativeCardStatus.exploring => 'Explorar',
      CreativeCardStatus.promising => 'Prometer',
      CreativeCardStatus.readyToUse => 'Lista',
      CreativeCardStatus.converted => 'Convertida',
      CreativeCardStatus.archived => 'Archivar',
    };

String _typeLabel(CreativeCardType type) => switch (type) {
      CreativeCardType.idea => 'Idea',
      CreativeCardType.sketch => 'Boceto',
      CreativeCardType.character => 'Personaje',
      CreativeCardType.scenario => 'Escenario',
      CreativeCardType.image => 'Imagen',
      CreativeCardType.research => 'Research',
      CreativeCardType.question => 'Pregunta',
    };

String _sourceLabel(CreativeCardSource source) => switch (source) {
      CreativeCardSource.manual => 'Manual',
      CreativeCardSource.inbox => 'Inbox',
      CreativeCardSource.iphone => 'iPhone',
      CreativeCardSource.ipad => 'iPad',
      CreativeCardSource.imported => 'Importada',
    };

Color _statusColor(CreativeCardStatus status, MusaThemeTokens tokens) {
  return switch (status) {
    CreativeCardStatus.inbox => tokens.borderStrong,
    CreativeCardStatus.exploring => tokens.warningText,
    CreativeCardStatus.promising => tokens.editorCaret,
    CreativeCardStatus.readyToUse => tokens.successText,
    CreativeCardStatus.converted => tokens.successBorder,
    CreativeCardStatus.archived => tokens.textDisabled,
  };
}
