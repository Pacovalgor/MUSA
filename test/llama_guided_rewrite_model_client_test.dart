import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/musa/services/llama_guided_rewrite_model_client.dart';

void main() {
  group('LlamaGuidedRewriteModelClient', () {
    test('isReady returns false when neither path exists', () {
      const client = LlamaGuidedRewriteModelClient(
        modelPath: '/nonexistent/model.gguf',
        dylibPath: '/nonexistent/libllama.0.dylib',
      );
      expect(client.isReady, isFalse);
    });

    test('isReady returns false when only model path exists', () async {
      final tempModel = File(
        '${Directory.systemTemp.path}/musa_test_model.gguf',
      );
      await tempModel.writeAsString('GGUF');
      addTearDown(() {
        if (tempModel.existsSync()) tempModel.deleteSync();
      });

      const client = LlamaGuidedRewriteModelClient(
        modelPath: '/tmp/musa_test_model.gguf',
        dylibPath: '/nonexistent/libllama.0.dylib',
      );
      expect(client.isReady, isFalse);
    });

    test('resolveDylibPath does not throw outside app bundle', () {
      // En flutter test no hay bundle de app. Verificamos que devuelve
      // null sin lanzar excepción.
      expect(
        () => LlamaGuidedRewriteModelClient.resolveDylibPath(),
        returnsNormally,
      );
    });
  });
}
