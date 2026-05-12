import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';
import 'package:musa/ui/inbox/window/inbox_management_screen.dart';
import 'package:musa/ui/inbox/window/widgets/capture_actions.dart';

class InboxPopover extends ConsumerWidget {
  const InboxPopover({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folder = ref.watch(inboxFolderProvider);
    final asyncCaps = ref.watch(inboxPendingCapturesProvider);

    if (folder.health == InboxFolderHealth.unconfigured) {
      return _ConfigurePrompt(ref: ref);
    }
    if (folder.health == InboxFolderHealth.unreachable) {
      return _UnreachablePrompt(ref: ref, lastPath: folder.path);
    }

    return asyncCaps.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: SizedBox(
          height: 24,
          width: 24,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Error: $e'),
      ),
      data: (caps) {
        if (caps.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Text('No hay capturas pendientes.',
                textAlign: TextAlign.center),
          );
        }
        final visible = caps.take(5).toList();
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Text('Capturas pendientes (${caps.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              for (final r in visible) _CapturePopoverRow(record: r),
              const Divider(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => const InboxManagementScreen(),
                    ),
                  );
                },
                child: Text('Ver todas (${caps.length}) →'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CapturePopoverRow extends ConsumerWidget {
  const _CapturePopoverRow({required this.record});
  final InboxCaptureRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = record.capture;
    if (c == null) {
      return const ListTile(title: Text('⚠️ Captura ilegible'));
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_kindEmoji(c.kind)} ${_short(c.body, c.url, 80)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => CaptureActions.accept(ref.read, record),
                style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: const Text('Aceptar', style: TextStyle(fontSize: 11)),
              ),
              TextButton(
                onPressed: () => CaptureActions.discard(ref.read, record),
                style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: const Text('Descartar', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _kindEmoji(k) => k.toString().endsWith('link') ? '🔗' : '📝';
  String _short(String body, String? url, int max) {
    final s = body.isEmpty && url != null ? url : body;
    return s.length <= max ? s : '${s.substring(0, max - 1)}…';
  }
}

class _ConfigurePrompt extends StatelessWidget {
  const _ConfigurePrompt({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Configura la carpeta de la bandeja para empezar.',
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                ref.read(inboxFolderProvider.notifier).chooseNewFolder(),
            child: const Text('Elegir carpeta…'),
          ),
        ],
      ),
    );
  }
}

class _UnreachablePrompt extends StatelessWidget {
  const _UnreachablePrompt({required this.ref, this.lastPath});
  final WidgetRef ref;
  final String? lastPath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 28),
          const SizedBox(height: 8),
          const Text('Bandeja desconectada',
              style: TextStyle(fontWeight: FontWeight.w700)),
          if (lastPath != null) ...[
            const SizedBox(height: 4),
            Text(lastPath!,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ref.read(inboxFolderProvider.notifier).recheck(),
            child: const Text('Reintentar'),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () =>
                ref.read(inboxFolderProvider.notifier).chooseNewFolder(),
            child: const Text('Reconfigurar carpeta…'),
          ),
        ],
      ),
    );
  }
}
