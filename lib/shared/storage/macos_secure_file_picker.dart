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
