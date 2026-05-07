import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    _editController =
        TextEditingController(text: widget.record.capture?.body ?? '');
  }

  @override
  void didUpdateWidget(CaptureDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.path != widget.record.path) {
      _editController.text = widget.record.capture?.body ?? '';
      _editing = false;
    }
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
              onPressed: () => CaptureActions.discard(ref, widget.record),
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
          _DetailActionsHook(
            record: widget.record,
            editing: _editing,
            editController: _editController,
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
    required this.onToggleEdit,
    required this.onCancelEdit,
  });
  final InboxCaptureRecord record;
  final bool editing;
  final TextEditingController editController;
  final VoidCallback onToggleEdit;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      children: [
        if (!editing) ...[
          FilledButton(
            onPressed: () => CaptureActions.accept(ref, record),
            child: const Text('Aceptar como nota'),
          ),
          OutlinedButton(
            onPressed: () => CaptureActions.acceptAsCreativeCard(ref, record),
            child: const Text('Enviar a mesa'),
          ),
          OutlinedButton(
            onPressed: onToggleEdit,
            child: const Text('Expandir y editar'),
          ),
          TextButton(
            onPressed: () => CaptureActions.discard(ref, record),
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
                ref,
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
                ref,
                record,
                editedBody: editController.text,
              );
              onCancelEdit();
            },
            child: const Text('Enviar a mesa'),
          ),
        ],
      ],
    );
  }
}
