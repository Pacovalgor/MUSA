import 'dart:io';

import 'package:path/path.dart' as path;

import '../../../services/ia/embedded/ffi/llama_processor.dart';
import 'guided_rewrite_generation_service.dart';

/// [GuidedRewriteModelClient] backed by the local llama.cpp runtime.
///
/// Requires a valid [modelPath] (.gguf on disk) and [dylibPath]
/// (libllama.0.dylib inside the app bundle). Both are resolved by
/// [guidedRewriteGenerationServiceProvider] before constructing this client.
class LlamaGuidedRewriteModelClient implements GuidedRewriteModelClient {
  const LlamaGuidedRewriteModelClient({
    required this.modelPath,
    required this.dylibPath,
  });

  final String modelPath;
  final String dylibPath;

  @override
  bool get isReady =>
      File(modelPath).existsSync() && File(dylibPath).existsSync();

  @override
  Future<String> rewrite(GuidedRewriteModelRequest request) async {
    final processor = LlamaProcessor(
      modelPath: modelPath,
      dylibPath: dylibPath,
    );
    final buffer = StringBuffer();
    await for (final token in processor.generate(request.prompt)) {
      buffer.write(token);
    }
    return buffer.toString();
  }

  /// Resolves the path to libllama.0.dylib inside the macOS app bundle.
  /// Returns null if the file is not found (e.g. during tests or dev runs).
  static String? resolveDylibPath() {
    if (!Platform.isMacOS) return null;
    try {
      final executablePath = File(Platform.resolvedExecutable).absolute.path;
      final macOsDirectory = File(executablePath).parent;
      final contentsDirectory = macOsDirectory.parent;
      final dylibPath = path.join(
        contentsDirectory.path,
        'Frameworks',
        'libllama.0.dylib',
      );
      return File(dylibPath).existsSync() ? dylibPath : null;
    } catch (_) {
      return null;
    }
  }
}
