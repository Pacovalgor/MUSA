import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/books/providers/workspace_providers.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';

class CaptureActions {
  static Future<void> accept(WidgetRef ref, InboxCaptureRecord record,
      {String? editedBody}) async {
    final c = record.capture;
    if (c == null) return;
    final storage = ref.read(inboxStorageProvider);
    if (storage == null) return;

    final body = (editedBody ?? c.body);
    await ref
        .read(narrativeWorkspaceProvider.notifier)
        .addNoteFromInbox(
          body: body,
          url: c.url,
          capturedAt: c.capturedAt,
          deviceLabel: c.deviceLabel,
        );
    await storage.markProcessed(File(record.path));
    bumpInboxRefreshTick(ref);
  }

  static Future<void> discard(WidgetRef ref, InboxCaptureRecord record) async {
    final storage = ref.read(inboxStorageProvider);
    if (storage == null) return;
    await storage.markDiscarded(File(record.path));
    bumpInboxRefreshTick(ref);
  }
}
