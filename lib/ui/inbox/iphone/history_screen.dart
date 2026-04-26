import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/models/inbox_capture.dart';
import 'package:musa/modules/inbox/models/inbox_capture_status.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_history_provider.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(inboxHistoryProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Historial',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  bumpInboxRefreshTick(ref);
                  await ref.read(inboxHistoryProvider.future);
                },
                child: asyncHistory.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _Error(error: e.toString()),
                  data: (records) => records.isEmpty
                      ? const _Empty()
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: records.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _HistoryItem(record: records[i]),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.record});
  final InboxCaptureRecord record;

  @override
  Widget build(BuildContext context) {
    final c = record.capture;
    if (c == null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('⚠️ Captura ilegible',
            style: TextStyle(color: Colors.red)),
      );
    }
    final (statusColor, statusText) = switch (record.status) {
      InboxCaptureStatus.pending => (Colors.orange, 'Pendiente'),
      InboxCaptureStatus.processed => (Colors.green, 'Procesada'),
      InboxCaptureStatus.discarded => (Colors.grey, 'Descartada'),
      InboxCaptureStatus.unreadable => (Colors.red, 'Ilegible'),
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _formatLocal(c.capturedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 8),
              _KindLabel(kind: c.kind),
              const Spacer(),
              Text(statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            c.body.isEmpty && c.url != null ? c.url! : c.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatLocal(DateTime utc) {
    final l = utc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}

class _KindLabel extends StatelessWidget {
  const _KindLabel({required this.kind});
  final InboxCaptureKind kind;

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (kind) {
      InboxCaptureKind.text => ('📝', 'texto'),
      InboxCaptureKind.link => ('🔗', 'link'),
    };
    return Text('$icon $text',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600));
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return ListView(
      // necesario para RefreshIndicator
      children: const [
        SizedBox(height: 96),
        Center(child: Text('Aún no hay capturas en este dispositivo.')),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('No se pudo cargar el historial:\n$error',
            textAlign: TextAlign.center),
      ),
    );
  }
}
