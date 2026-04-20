/// Native macOS secure file picker.
///
/// Calls the Swift SecureFilePickerHandler via MethodChannel.
/// The native code handles startAccessingSecurityScopedResource() automatically.
/// Returns the file bytes directly (Uint8List), bypassing the sandbox restriction.
library;

import 'package:flutter/services.dart';

const _channel = MethodChannel('musa/secure_file_picker');

/// Presents an NSOpenPanel for .musa files and returns the file bytes.
/// Returns null if the user cancels.
///
/// On non-macOS platforms, returns null immediately.
Future<Uint8List?> pickMusaFileNative() async {
  try {
    final result = await _channel.invokeMethod<Uint8List>('pickMusaFile');
    return result;
  } catch (e) {
    throw Exception('Secure file picker failed: $e');
  }
}

/// Presents an NSSavePanel for .musa files and writes [fileBytes] natively.
///
/// Returns the saved path, or null if the user cancels.
Future<String?> saveMusaFileNative(
  Uint8List fileBytes, {
  String suggestedName = 'Musa.musa',
}) async {
  try {
    return _channel.invokeMethod<String>('saveMusaFile', {
      'fileName': suggestedName,
      'bytes': fileBytes,
    });
  } catch (e) {
    throw Exception('Secure file save failed: $e');
  }
}
