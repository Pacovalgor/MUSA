import 'package:flutter/material.dart';
import 'package:musa/modules/inbox/models/inbox_capture.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';

class CaptureListItem extends StatelessWidget {
  const CaptureListItem({
    super.key,
    required this.record,
    required this.selected,
    required this.onTap,
  });
  final InboxCaptureRecord record;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = record.capture;
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primary.withValues(alpha: 0.08) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: c == null
              ? const Text('⚠️ Captura ilegible')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(_kindLabel(c.kind),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(_when(c.capturedAt),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700)),
                    ]),
                    const SizedBox(height: 6),
                    Text(_preview(c),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(c.deviceLabel,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600)),
                  ],
                ),
        ),
      ),
    );
  }

  String _kindLabel(InboxCaptureKind k) =>
      k == InboxCaptureKind.link ? '🔗 link' : '📝 texto';

  String _preview(InboxCapture c) =>
      c.body.isEmpty && c.url != null ? c.url! : c.body;

  String _when(DateTime utc) {
    final l = utc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}
