import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/ui/inbox/popover/inbox_popover.dart';

/// Botón de la bandeja en la toolbar del Studio Shell. Abre el popover.
class InboxToolbarButton extends ConsumerWidget {
  const InboxToolbarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folder = ref.watch(inboxFolderProvider);
    final asyncCaps = ref.watch(inboxPendingCapturesProvider);
    final unreachable = folder.health == InboxFolderHealth.unreachable;
    final unconfigured = folder.health == InboxFolderHealth.unconfigured;

    return MenuAnchor(
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 18,
                      color: unreachable
                          ? Colors.red.shade700
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    if (unreachable)
                      const Positioned(
                        right: -4, top: -2,
                        child: Icon(Icons.error, size: 12, color: Colors.red),
                      )
                    else
                      asyncCaps.maybeWhen(
                        orElse: () => const SizedBox.shrink(),
                        data: (caps) => caps.isEmpty
                            ? const SizedBox.shrink()
                            : Positioned(
                                right: -6, top: -4,
                                child: _Badge(text: caps.length.toString()),
                              ),
                      ),
                  ],
                ),
                if (unconfigured) ...[
                  const SizedBox(width: 6),
                  const Text('Configurar bandeja',
                      style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
        );
      },
      menuChildren: const [
        SizedBox(
          width: 320,
          child: InboxPopover(),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}
