import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/ui/inbox/window/widgets/capture_detail_panel.dart';
import 'package:musa/ui/inbox/window/widgets/capture_list_item.dart';

final inboxSelectedRecordIndexProvider = StateProvider<int?>((_) => null);

class InboxManagementScreen extends ConsumerWidget {
  const InboxManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCaps = ref.watch(inboxPendingCapturesProvider);
    final selectedIdx = ref.watch(inboxSelectedRecordIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandeja de capturas'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: asyncCaps.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (caps) {
          if (caps.isEmpty) {
            return const Center(child: Text('No hay capturas pendientes.'));
          }
          final selected = (selectedIdx != null && selectedIdx < caps.length)
              ? caps[selectedIdx]
              : null;
          return Row(
            children: [
              SizedBox(
                width: 320,
                child: ListView.separated(
                  itemCount: caps.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => CaptureListItem(
                    record: caps[i],
                    selected: selectedIdx == i,
                    onTap: () => ref
                        .read(inboxSelectedRecordIndexProvider.notifier)
                        .state = i,
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: selected == null
                    ? const Center(child: Text('Selecciona una captura'))
                    : CaptureDetailPanel(record: selected),
              ),
            ],
          );
        },
      ),
    );
  }
}
