import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../modules/books/providers/workspace_providers.dart';
import '../../modules/creative/models/creative_card.dart';

const _editableStatuses = [
  CreativeCardStatus.inbox,
  CreativeCardStatus.exploring,
  CreativeCardStatus.promising,
  CreativeCardStatus.readyToUse,
];

const _typeLabels = {
  CreativeCardType.idea: 'Idea',
  CreativeCardType.sketch: 'Boceto',
  CreativeCardType.character: 'Personaje',
  CreativeCardType.scenario: 'Escenario',
  CreativeCardType.image: 'Imagen',
  CreativeCardType.research: 'Research',
  CreativeCardType.question: 'Pregunta',
};

const _statusLabels = {
  CreativeCardStatus.inbox: 'Inbox',
  CreativeCardStatus.exploring: 'Explorando',
  CreativeCardStatus.promising: 'Prometedora',
  CreativeCardStatus.readyToUse: 'Lista',
  CreativeCardStatus.converted: 'Convertida',
  CreativeCardStatus.archived: 'Archivada',
};

class CreativeCardDetailPanel extends ConsumerStatefulWidget {
  const CreativeCardDetailPanel({super.key, required this.card});

  final CreativeCard? card;

  @override
  ConsumerState<CreativeCardDetailPanel> createState() =>
      _CreativeCardDetailPanelState();
}

class _CreativeCardDetailPanelState
    extends ConsumerState<CreativeCardDetailPanel> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagsController = TextEditingController();

  CreativeCardType _type = CreativeCardType.idea;
  CreativeCardStatus _status = CreativeCardStatus.inbox;
  String? _syncedCardId;
  CreativeCardType? _syncedType;
  CreativeCardStatus? _syncedStatus;

  @override
  void initState() {
    super.initState();
    _syncCard(widget.card);
  }

  @override
  void didUpdateWidget(covariant CreativeCardDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCard(widget.card);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _syncCard(CreativeCard? card) {
    final cardId = card?.id;
    final cardType = card?.type ?? CreativeCardType.idea;
    final cardStatus = card?.status ?? CreativeCardStatus.inbox;
    final editableStatus = _editableStatuses.contains(cardStatus)
        ? cardStatus
        : CreativeCardStatus.inbox;

    if (cardId != _syncedCardId) {
      _syncedCardId = cardId;
      _titleController.text = card?.title ?? '';
      _bodyController.text = card?.body ?? '';
      _tagsController.text = card?.tags.join(', ') ?? '';
      _type = cardType;
      _status = editableStatus;
      _syncedType = cardType;
      _syncedStatus = cardStatus;
      return;
    }

    if (cardType != _syncedType) {
      _type = cardType;
      _syncedType = cardType;
    }
    if (cardStatus != _syncedStatus) {
      _status = editableStatus;
      _syncedStatus = cardStatus;
    }
  }

  Future<void> _save(CreativeCard card) async {
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
    final isConverted = card.status == CreativeCardStatus.converted;

    await ref.read(narrativeWorkspaceProvider.notifier).updateCreativeCard(
          card.copyWith(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            tags: tags,
            type: isConverted ? card.type : _type,
            status: isConverted ? card.status : _status,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(narrativeWorkspaceProvider);
    final tokens = MusaTheme.tokensOf(context);
    final selectedCard = widget.card;
    final isConverted = selectedCard?.status == CreativeCardStatus.converted;

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
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('creative-card-detail-body-field'),
                      controller: _bodyController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Cuerpo',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('creative-card-detail-tags-field'),
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Etiquetas',
                        hintText: 'Separadas por coma',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InputDecorator(
                      key: const Key('creative-card-detail-type-field'),
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CreativeCardType>(
                          value: _type,
                          isDense: true,
                          isExpanded: true,
                          items: CreativeCardType.values
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(_typeLabels[type] ?? type.name),
                                ),
                              )
                              .toList(),
                          onChanged: isConverted
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() => _type = value);
                                },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isConverted)
                      Text(
                        _statusLabels[CreativeCardStatus.converted]!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: tokens.successText,
                              fontWeight: FontWeight.w700,
                            ),
                      )
                    else
                      InputDecorator(
                        key: const Key('creative-card-detail-status-field'),
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<CreativeCardStatus>(
                            value: _status,
                            isDense: true,
                            isExpanded: true,
                            items: _editableStatuses
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      _statusLabels[status] ?? status.name,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _status = value);
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('creative-card-detail-save-button'),
                        onPressed: () => _save(selectedCard),
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
