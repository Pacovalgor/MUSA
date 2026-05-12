import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/creative/models/creative_card.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';
import 'package:musa/ui/inbox/window/widgets/capture_actions.dart';

class CaptureDetailPanel extends ConsumerStatefulWidget {
  const CaptureDetailPanel({super.key, required this.record});
  final InboxCaptureRecord record;

  @override
  ConsumerState<CaptureDetailPanel> createState() => _CaptureDetailPanelState();
}

class _CaptureDetailPanelState extends ConsumerState<CaptureDetailPanel> {
  late TextEditingController _editController;
  bool _editing = false;
  CreativeCardType _creativeType = CreativeCardType.idea;

  @override
  void initState() {
    super.initState();
    _editController =
        TextEditingController(text: widget.record.capture?.body ?? '');
    _creativeType = _typeFromCapture();
  }

  @override
  void didUpdateWidget(CaptureDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.path != widget.record.path) {
      _editController.text = widget.record.capture?.body ?? '';
      _editing = false;
      _creativeType = _typeFromCapture();
    }
  }

  CreativeCardType _typeFromCapture() {
    final raw = widget.record.capture?.creativeTypeHint;
    for (final type in CreativeCardType.values) {
      if (type.name == raw) return type;
    }
    return CreativeCardType.idea;
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.record.capture;
    if (c == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ Captura ilegible',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.red)),
            const SizedBox(height: 12),
            if (widget.record.parseError != null)
              Text(widget.record.parseError!,
                  style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            if (widget.record.rawContent != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade100,
                child: SelectableText(widget.record.rawContent!,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => CaptureActions.discard(ref.read, widget.record),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(c.deviceLabel,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(width: 8),
            Text('· ${c.capturedAt.toLocal()}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          if (c.url != null) ...[
            SelectableText(c.url!,
                style: TextStyle(color: Colors.blue.shade800)),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: _editing
                ? TextField(
                    controller: _editController,
                    maxLines: null,
                    expands: true,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  )
                : SelectableText(
                    c.body.isEmpty ? '(sin texto adicional)' : c.body,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TypeChip(
                key: const Key('capture-detail-type-idea'),
                label: 'Idea',
                selected: _creativeType == CreativeCardType.idea,
                onTap: () =>
                    setState(() => _creativeType = CreativeCardType.idea),
              ),
              _TypeChip(
                key: const Key('capture-detail-type-sketch'),
                label: 'Boceto',
                selected: _creativeType == CreativeCardType.sketch,
                onTap: () =>
                    setState(() => _creativeType = CreativeCardType.sketch),
              ),
              _TypeChip(
                key: const Key('capture-detail-type-question'),
                label: 'Pregunta',
                selected: _creativeType == CreativeCardType.question,
                onTap: () =>
                    setState(() => _creativeType = CreativeCardType.question),
              ),
              _TypeChip(
                key: const Key('capture-detail-type-research'),
                label: 'Research',
                selected: _creativeType == CreativeCardType.research,
                onTap: () =>
                    setState(() => _creativeType = CreativeCardType.research),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailActionsHook(
            record: widget.record,
            editing: _editing,
            editController: _editController,
            creativeType: _creativeType,
            onToggleEdit: () => setState(() => _editing = !_editing),
            onCancelEdit: () => setState(() {
              _editController.text = c.body;
              _editing = false;
            }),
          ),
        ],
      ),
    );
  }
}

class _DetailActionsHook extends ConsumerWidget {
  const _DetailActionsHook({
    required this.record,
    required this.editing,
    required this.editController,
    required this.creativeType,
    required this.onToggleEdit,
    required this.onCancelEdit,
  });
  final InboxCaptureRecord record;
  final bool editing;
  final TextEditingController editController;
  final CreativeCardType creativeType;
  final VoidCallback onToggleEdit;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      children: [
        if (!editing) ...[
          FilledButton(
            key: const Key('capture-detail-create-card'),
            onPressed: () => CaptureActions.acceptAsCreativeCard(
              ref.read,
              record,
              creativeTypeHint: creativeType.name,
            ),
            child: const Text('Crear tarjeta'),
          ),
          OutlinedButton(
            onPressed: () => CaptureActions.accept(ref.read, record),
            child: const Text('Aceptar como nota'),
          ),
          OutlinedButton(
            onPressed: onToggleEdit,
            child: const Text('Expandir y editar'),
          ),
          TextButton(
            onPressed: () => CaptureActions.discard(ref.read, record),
            child: const Text('Descartar'),
          ),
        ] else ...[
          OutlinedButton(
            onPressed: onCancelEdit,
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await CaptureActions.accept(
                ref.read,
                record,
                editedBody: editController.text,
              );
              onCancelEdit();
            },
            child: const Text('Guardar y aceptar'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              await CaptureActions.acceptAsCreativeCard(
                ref.read,
                record,
                editedBody: editController.text,
                creativeTypeHint: creativeType.name,
              );
              onCancelEdit();
            },
            child: const Text('Guardar y crear tarjeta'),
          ),
        ],
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
