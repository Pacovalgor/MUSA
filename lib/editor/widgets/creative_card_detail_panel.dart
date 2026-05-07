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
  final _attachmentTitleController = TextEditingController();
  final _attachmentUriController = TextEditingController();

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
    _attachmentTitleController.dispose();
    _attachmentUriController.dispose();
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

  Future<void> _addLinkAttachment(CreativeCard card) async {
    final uri = _attachmentUriController.text.trim();
    if (uri.isEmpty) return;
    final title = _attachmentTitleController.text.trim();
    final attachment = CreativeCardAttachment(
      id: 'creative_attachment_${DateTime.now().microsecondsSinceEpoch}',
      kind: CreativeCardAttachmentKind.link,
      uri: uri,
      title: title,
      createdAt: DateTime.now(),
    );

    await ref.read(narrativeWorkspaceProvider.notifier).updateCreativeCard(
          card.copyWith(attachments: [...card.attachments, attachment]),
        );
    if (!mounted) return;
    _attachmentTitleController.clear();
    _attachmentUriController.clear();
  }

  Future<void> _removeAttachment(
    CreativeCard card,
    CreativeCardAttachment attachment,
  ) async {
    await ref.read(narrativeWorkspaceProvider.notifier).updateCreativeCard(
          card.copyWith(
            attachments: card.attachments
                .where((item) => item.id != attachment.id)
                .toList(),
          ),
        );
  }

  Future<void> _toggleLink(
    CreativeCard card, {
    String? characterId,
    String? scenarioId,
    String? documentId,
    String? noteId,
  }) async {
    List<String> toggled(List<String> ids, String? id) {
      if (id == null) return ids;
      if (ids.contains(id)) {
        return ids.where((item) => item != id).toList(growable: false);
      }
      return [...ids, id];
    }

    await ref.read(narrativeWorkspaceProvider.notifier).setCreativeCardLinks(
          cardId: card.id,
          characterIds: toggled(card.linkedCharacterIds, characterId),
          scenarioIds: toggled(card.linkedScenarioIds, scenarioId),
          documentIds: toggled(card.linkedDocumentIds, documentId),
          noteIds: toggled(card.linkedNoteIds, noteId),
        );
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(narrativeWorkspaceProvider).valueOrNull;
    final tokens = MusaTheme.tokensOf(context);
    final widgetCard = widget.card;
    final selectedCard = widgetCard == null
        ? null
        : workspace?.creativeCards.cast<CreativeCard?>().firstWhere(
                  (card) => card?.id == widgetCard.id,
                  orElse: () => widgetCard,
                ) ??
            widgetCard;
    final activeBookCharacters = workspace?.activeBookCharacters ?? const [];
    final activeBookScenarios = workspace?.activeBookScenarios ?? const [];
    final activeBookDocuments = workspace?.activeBookDocuments ?? const [];
    final activeBookNotes = workspace?.activeBookNotes ?? const [];
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
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalle de tarjeta',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
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
                          const SizedBox(height: 14),
                          Text(
                            'Adjuntos',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: tokens.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          for (final attachment in selectedCard.attachments)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                attachment.title.isEmpty
                                    ? _attachmentKindLabel(attachment.kind)
                                    : attachment.title,
                              ),
                              subtitle: Text(attachment.uri),
                              trailing: IconButton(
                                key: Key(
                                  'creative-card-remove-attachment-${attachment.id}',
                                ),
                                tooltip: 'Quitar adjunto',
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  _removeAttachment(selectedCard, attachment);
                                },
                              ),
                            ),
                          TextField(
                            key: const Key(
                                'creative-card-attachment-title-field'),
                            controller: _attachmentTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Título del enlace',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            key:
                                const Key('creative-card-attachment-uri-field'),
                            controller: _attachmentUriController,
                            decoration: const InputDecoration(
                              labelText: 'URL o ruta',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            key: const Key('creative-card-add-link-button'),
                            onPressed: () => _addLinkAttachment(selectedCard),
                            icon: const Icon(Icons.link, size: 16),
                            label: const Text('Añadir enlace'),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Enlaces',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: tokens.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final character in activeBookCharacters)
                                FilterChip(
                                  key: Key(
                                    'creative-link-character-${character.id}',
                                  ),
                                  label: Text(character.displayName),
                                  selected: selectedCard.linkedCharacterIds
                                      .contains(character.id),
                                  onSelected: (_) => _toggleLink(
                                    selectedCard,
                                    characterId: character.id,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              for (final scenario in activeBookScenarios)
                                FilterChip(
                                  key: Key(
                                    'creative-link-scenario-${scenario.id}',
                                  ),
                                  label: Text(scenario.name),
                                  selected: selectedCard.linkedScenarioIds
                                      .contains(scenario.id),
                                  onSelected: (_) => _toggleLink(
                                    selectedCard,
                                    scenarioId: scenario.id,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              for (final document in activeBookDocuments)
                                FilterChip(
                                  key: Key(
                                    'creative-link-document-${document.id}',
                                  ),
                                  label: Text(document.title),
                                  selected: selectedCard.linkedDocumentIds
                                      .contains(document.id),
                                  onSelected: (_) => _toggleLink(
                                    selectedCard,
                                    documentId: document.id,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              for (final note in activeBookNotes)
                                FilterChip(
                                  key: Key('creative-link-note-${note.id}'),
                                  label: Text(note.title ?? ''),
                                  selected: selectedCard.linkedNoteIds
                                      .contains(note.id),
                                  onSelected: (_) => _toggleLink(
                                    selectedCard,
                                    noteId: note.id,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
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
                                        child: Text(
                                            _typeLabels[type] ?? type.name),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: tokens.successText,
                                    fontWeight: FontWeight.w700,
                                  ),
                            )
                          else
                            InputDecorator(
                              key: const Key(
                                  'creative-card-detail-status-field'),
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
                                            _statusLabels[status] ??
                                                status.name,
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
                        ],
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
    );
  }
}

String _attachmentKindLabel(CreativeCardAttachmentKind kind) {
  return switch (kind) {
    CreativeCardAttachmentKind.link => 'Enlace',
    CreativeCardAttachmentKind.image => 'Imagen',
  };
}
