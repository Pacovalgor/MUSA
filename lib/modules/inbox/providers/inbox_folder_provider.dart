import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/services/inbox_bookmark_service.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';

enum InboxFolderHealth { unconfigured, healthy, unreachable }

class InboxFolderState {
  const InboxFolderState({
    required this.health,
    this.path,
  });
  final InboxFolderHealth health;
  final String? path;
}

final inboxBookmarkServiceProvider =
    Provider<InboxBookmarkService>((ref) => InboxBookmarkService());

class InboxFolderNotifier extends StateNotifier<InboxFolderState> {
  InboxFolderNotifier(this._bookmarks)
      : super(const InboxFolderState(health: InboxFolderHealth.unconfigured)) {
    _initialize();
  }

  final InboxBookmarkService _bookmarks;

  Future<void> _initialize() async {
    final resolved = await _bookmarks.loadAndResolve();
    if (resolved == null) {
      final lastPath = await _bookmarks.lastKnownPath();
      state = InboxFolderState(
        health: lastPath == null
            ? InboxFolderHealth.unconfigured
            : InboxFolderHealth.unreachable,
        path: lastPath,
      );
      return;
    }
    state = InboxFolderState(
      health: InboxFolderHealth.healthy,
      path: resolved.path,
    );
  }

  Future<bool> chooseNewFolder() async {
    final picked = await _bookmarks.pickFolder();
    if (picked == null) return false;
    await _bookmarks.persist(picked);
    state = InboxFolderState(
      health: InboxFolderHealth.healthy,
      path: picked.path,
    );
    return true;
  }

  Future<void> recheck() => _initialize();
}

final inboxFolderProvider =
    StateNotifierProvider<InboxFolderNotifier, InboxFolderState>(
  (ref) => InboxFolderNotifier(ref.watch(inboxBookmarkServiceProvider)),
);

/// Storage construido sobre la carpeta actual.
/// Devuelve null si la carpeta no es saludable.
final inboxStorageProvider = Provider<InboxStorageService?>((ref) {
  final folder = ref.watch(inboxFolderProvider);
  if (folder.health != InboxFolderHealth.healthy || folder.path == null) {
    return null;
  }
  return InboxStorageService(rootDirectory: Directory(folder.path!));
});
