import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InboxBookmarkResult {
  const InboxBookmarkResult({required this.path, required this.bookmark});
  final String path;
  final Uint8List bookmark;
}

class InboxBookmarkResolution {
  const InboxBookmarkResolution({required this.path, required this.stale});
  final String path;
  final bool stale;
}

/// Servicio cross-platform para abrir un picker de carpeta y persistir el
/// security-scoped bookmark.
class InboxBookmarkService {
  InboxBookmarkService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('musa/inbox_bookmark');

  final MethodChannel _channel;

  static const String _prefsKey = 'inbox.bookmark.v1';
  static const String _prefsPathKey = 'inbox.bookmark.path.v1';

  bool get isPlatformSupported => Platform.isMacOS || Platform.isIOS;

  /// Lanza el picker nativo. Devuelve null si el usuario cancela.
  Future<InboxBookmarkResult?> pickFolder() async {
    if (!isPlatformSupported) return null;
    final raw = await _channel.invokeMethod<dynamic>('pickFolder');
    if (raw == null) return null;
    final m = Map<String, dynamic>.from(raw as Map);
    final blob = m['bookmark'];
    final path = m['path'] as String;
    final bytes = blob is Uint8List
        ? blob
        : Uint8List.fromList((blob as List).cast<int>());
    return InboxBookmarkResult(path: path, bookmark: bytes);
  }

  /// Resuelve un blob persistido y comienza el acceso security-scoped.
  Future<InboxBookmarkResolution> resolve(Uint8List bookmark) async {
    final raw = await _channel.invokeMethod<dynamic>(
      'resolveBookmark',
      {'bookmark': bookmark},
    );
    final m = Map<String, dynamic>.from(raw as Map);
    return InboxBookmarkResolution(
      path: m['path'] as String,
      stale: m['stale'] as bool,
    );
  }

  Future<void> persist(InboxBookmarkResult bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    // SharedPreferences no soporta Uint8List nativo: serializamos a base64.
    await prefs.setString(_prefsKey, base64Encode(bookmark.bookmark));
    await prefs.setString(_prefsPathKey, bookmark.path);
  }

  Future<InboxBookmarkResolution?> loadAndResolve() async {
    if (!isPlatformSupported) return null;
    final prefs = await SharedPreferences.getInstance();
    final blobB64 = prefs.getString(_prefsKey);
    if (blobB64 == null) return null;
    final bytes = Uint8List.fromList(base64Decode(blobB64));
    try {
      return await resolve(bytes);
    } on PlatformException {
      // Bookmark inválido. Lo dejamos en prefs por si se quiere mostrar el
      // path antiguo, pero no resolvemos.
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_prefsPathKey);
  }

  Future<String?> lastKnownPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsPathKey);
  }
}
