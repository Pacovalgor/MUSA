import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/services/inbox_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kHistoryUuidsKey = 'inbox.history.uuids.v1';

/// Set de UUIDs que ESTE dispositivo escribió.
class HistoryCacheNotifier extends StateNotifier<Set<String>> {
  HistoryCacheNotifier() : super(const <String>{}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHistoryUuidsKey);
    if (raw == null) return;
    state = (jsonDecode(raw) as List).map((e) => e as String).toSet();
  }

  Future<void> add(String id) async {
    state = {...state, id};
    await _persist();
  }

  /// Purga: deja sólo los UUIDs cuyos archivos siguen existiendo en el FS.
  Future<void> reconcile(Iterable<String> aliveIds) async {
    final alive = aliveIds.toSet();
    final next = state.intersection(alive);
    if (next.length == state.length) return;
    state = next;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHistoryUuidsKey, jsonEncode(state.toList()));
  }
}

final inboxHistoryCacheProvider =
    StateNotifierProvider<HistoryCacheNotifier, Set<String>>(
  (_) => HistoryCacheNotifier(),
);

/// Capturas escritas por ESTE dispositivo, con su estado actual en el FS.
/// Ordenadas por `capturedAt` desc.
final inboxHistoryProvider =
    FutureProvider<List<InboxCaptureRecord>>((ref) async {
  ref.watch(inboxRefreshTickProvider);
  final storage = ref.watch(inboxStorageProvider);
  final cache = ref.watch(inboxHistoryCacheProvider);
  if (storage == null) return const [];
  final all = await storage.readAll();
  final aliveIds = all.map((r) => r.capture?.id).whereType<String>().toSet();
  // Purga del cache de UUIDs que ya no existen en el FS.
  ref.read(inboxHistoryCacheProvider.notifier).reconcile(aliveIds);
  final mine = all.where((r) {
    final id = r.capture?.id;
    return id != null && cache.contains(id);
  }).toList();
  mine.sort((a, b) =>
      b.capture!.capturedAt.compareTo(a.capture!.capturedAt));
  return mine;
});
