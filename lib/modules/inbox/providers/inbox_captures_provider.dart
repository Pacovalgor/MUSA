import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';

/// Tick que fuerza recarga; se incrementa al pull-to-refresh, al detectar
/// FSEvent en Mac, o tras una acción (aceptar/descartar).
final inboxRefreshTickProvider = StateProvider<int>((_) => 0);

void bumpInboxRefreshTick(WidgetRef ref) {
  ref.read(inboxRefreshTickProvider.notifier).state++;
}

/// Capturas pendientes (sólo `MUSA-Inbox/<fecha>/`), ordenadas por
/// `capturedAt` desc. Sólo poblado cuando la carpeta es healthy.
final inboxPendingCapturesProvider =
    FutureProvider<List<InboxCaptureRecord>>((ref) async {
  ref.watch(inboxRefreshTickProvider);
  final storage = ref.watch(inboxStorageProvider);
  if (storage == null) return const [];
  final list = await storage.readPending();
  list.sort((a, b) {
    final ac = a.capture?.capturedAt;
    final bc = b.capture?.capturedAt;
    if (ac == null || bc == null) return 0;
    return bc.compareTo(ac);
  });
  return list;
});
