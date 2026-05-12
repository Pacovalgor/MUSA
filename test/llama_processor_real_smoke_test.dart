import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musa/services/ia/embedded/ffi/llama_processor.dart';

@Tags(['real_ffi'])
void main() {
  test(
    'llama processor returns real tokens',
    () async {
      final modelPath = Platform.environment['MUSA_TEST_MODEL_PATH'];
      if (modelPath == null || !File(modelPath).existsSync()) {
        debugPrint(
            '[MUSA TEST] Skipping real FFI smoke test: model not found.');
        return;
      }

      final dylibPath = Platform.environment['MUSA_TEST_LLAMA_DYLIB_PATH'] ??
          'libllama.dylib';

      final processor = LlamaProcessor(
        modelPath: modelPath,
        dylibPath: dylibPath,
      );

      const prompt = 'Completa en español: La noche cayó sobre Madrid y';

      final tokens = <String>[];
      await for (final token in processor.generate(prompt)) {
        tokens.add(token);
        if (tokens.length >= 5) {
          break;
        }
      }

      debugPrint('[MUSA TEST] PROMPT=$prompt');
      debugPrint(
        '[MUSA TEST] TOKENS=${tokens.map(jsonEncode).join(', ')}',
      );

      expect(tokens, isNotEmpty);
      expect(tokens.join(), isNotEmpty);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
