import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/books/providers/workspace_providers.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';

typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

class CaptureActions {
  static Future<bool> accept(
    ProviderReader read,
    InboxCaptureRecord record, {
    String? editedBody,
  }) async {
    final c = record.capture;
    if (c == null) return false;
    final storage = read(inboxStorageProvider);
    if (storage == null) return false;

    final body = (editedBody ?? c.body);
    await read(narrativeWorkspaceProvider.notifier).addNoteFromInbox(
      body: body,
      url: c.url,
      capturedAt: c.capturedAt,
      deviceLabel: c.deviceLabel,
    );
    await storage.markProcessed(File(record.path));
    read(inboxRefreshTickProvider.notifier).state++;
    return true;
  }

  static Future<bool> acceptAsCreativeCard(
    ProviderReader read,
    InboxCaptureRecord record, {
    String? editedBody,
    String? creativeTypeHint,
  }) async {
    final c = record.capture;
    if (c == null) return false;
    final storage = read(inboxStorageProvider);
    if (storage == null) return false;

    final body = editedBody ?? c.body;
    final card = await read(narrativeWorkspaceProvider.notifier)
        .addCreativeCardFromInbox(
      body: body,
      url: c.url,
      capturedAt: c.capturedAt,
      deviceLabel: c.deviceLabel,
      creativeTypeHint: creativeTypeHint ?? c.creativeTypeHint,
      attachmentUri: c.attachmentUri,
      attachmentKind: c.attachmentKind,
    );
    if (card == null) return false;
    await storage.markProcessed(File(record.path));
    read(inboxRefreshTickProvider.notifier).state++;
    return true;
  }

  static Future<bool> discard(
    ProviderReader read,
    InboxCaptureRecord record,
  ) async {
    final storage = read(inboxStorageProvider);
    if (storage == null) return false;
    await storage.markDiscarded(File(record.path));
    read(inboxRefreshTickProvider.notifier).state++;
    return true;
  }
}
