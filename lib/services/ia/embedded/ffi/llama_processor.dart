import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'llama_bindings.dart';

class LlamaProcessor {
  static const int _contextWindowTokens = 2048;
  static const int _promptBatchSize = 512;
  static const int _promptSafetyMargin = 32;

  LlamaProcessor({
    required this.modelPath,
    required this.dylibPath,
    this.maxGeneratedTokens = 192,
  });

  final String modelPath;
  final String dylibPath;
  final int maxGeneratedTokens;

  static const int _llamaTokenNull = -1;
  static final ffi.Pointer<ffi.NativeFunction<LlamaLogCallbackNative>>
      _noopLogCallbackPtr =
      ffi.Pointer.fromFunction<LlamaLogCallbackNative>(_noopLogCallback);

  Stream<String> generate(String prompt) {
    final streamController = StreamController<String>();
    final receivePort = ReceivePort();
    Isolate? worker;

    receivePort.listen((dynamic message) {
      if (message is Map) {
        final type = message['type'];
        if (type == 'token') {
          final token = message['value'];
          if (token is String) {
            streamController.add(token);
          }
          return;
        }

        if (type == 'error') {
          final error = message['value'];
          streamController.addError('Error en el puente FFI: $error');
          receivePort.close();
          worker?.kill(priority: Isolate.immediate);
          unawaited(streamController.close());
          return;
        }

        if (type == 'done') {
          receivePort.close();
          worker?.kill(priority: Isolate.immediate);
          unawaited(streamController.close());
        }
      }
    });

    streamController.onCancel = () {
      receivePort.close();
      worker?.kill(priority: Isolate.immediate);
    };

    unawaited(() async {
      try {
        worker = await Isolate.spawn<Map<String, Object?>>(
          _generationIsolateMain,
          <String, Object?>{
            'sendPort': receivePort.sendPort,
            'prompt': prompt,
            'modelPath': modelPath,
            'dylibPath': dylibPath,
            'maxGeneratedTokens': maxGeneratedTokens,
          },
        );
      } catch (e) {
        streamController.addError('Error en el puente FFI: $e');
        receivePort.close();
        await streamController.close();
      }
    }());

    return streamController.stream;
  }

  static void _generationIsolateMain(Map<String, Object?> args) {
    final sendPort = args['sendPort'] as SendPort;
    final prompt = args['prompt'] as String;
    final modelPath = args['modelPath'] as String;
    final dylibPath = args['dylibPath'] as String;
    final maxGeneratedTokens = args['maxGeneratedTokens'] as int? ?? 192;

    final processor = LlamaProcessor(
      modelPath: modelPath,
      dylibPath: dylibPath,
      maxGeneratedTokens: maxGeneratedTokens,
    );
    processor._runInference(prompt, sendPort, maxGeneratedTokens);
  }

  void _runInference(String prompt, SendPort sendPort, int maxGeneratedTokens) {
    LlamaBindings? bindings;
    ffi.Pointer<LlamaModel> model = ffi.nullptr;
    ffi.Pointer<LlamaContext> context = ffi.nullptr;
    ffi.Pointer<LlamaVocab> vocab = ffi.nullptr;
    ffi.Pointer<LlamaSampler> sampler = ffi.nullptr;
    LlamaBatch? promptBatch;
    LlamaBatch? generationBatch;
    bool backendInitialized = false;

    try {
      final resolvedDylibPath = _resolveDylibPath();
      bindings = LlamaBindings(resolvedDylibPath);
      bindings.llamaLogSet(_noopLogCallbackPtr, ffi.nullptr);

      bindings.llamaBackendInit();
      backendInitialized = true;

      final modelPathUtf8 = modelPath.toNativeUtf8();
      try {
        final modelParams = bindings.llamaModelDefaultParams();
        modelParams.nGpuLayers = -1;
        modelParams.useMmap = true;
        modelParams.useMlock = false;

        model = bindings.llamaModelLoadFromFile(modelPathUtf8, modelParams);
      } finally {
        calloc.free(modelPathUtf8);
      }

      if (model == ffi.nullptr) {
        throw StateError('No se pudo cargar el modelo GGUF en memoria.');
      }

      final contextParams = bindings.llamaContextDefaultParams();
      contextParams.nCtx = _contextWindowTokens;
      contextParams.nBatch = _promptBatchSize;
      contextParams.nUbatch = 512;
      contextParams.nSeqMax = 1;
      contextParams.nThreads = 4;
      contextParams.nThreadsBatch = 4;
      contextParams.offloadKqv = true;

      context = bindings.llamaInitFromModel(model, contextParams);
      if (context == ffi.nullptr) {
        throw StateError('No se pudo crear el contexto de inferencia.');
      }

      vocab = bindings.llamaModelGetVocab(model);
      if (vocab == ffi.nullptr) {
        throw StateError('No se pudo resolver el vocabulario del modelo.');
      }

      final promptTokens = _tokenize(bindings, vocab, prompt);
      if (promptTokens.isEmpty) {
        throw StateError('La tokenización devolvió cero tokens.');
      }

      final maxPromptTokens =
          (_contextWindowTokens - maxGeneratedTokens - _promptSafetyMargin)
              .clamp(1, _contextWindowTokens);
      if (promptTokens.length > maxPromptTokens) {
        throw StateError(
          'El prompt tokenizado (${promptTokens.length}) excede el contexto disponible ($maxPromptTokens). Reduce el contexto o las instrucciones.',
        );
      }

      promptBatch = bindings.llamaBatchInit(_promptBatchSize, 0, 1);
      _decodePromptInChunks(
        bindings: bindings,
        context: context,
        batch: promptBatch,
        promptTokens: promptTokens,
      );

      sampler = bindings.llamaSamplerInitGreedy();
      if (sampler == ffi.nullptr) {
        throw StateError('No se pudo crear el sampler greedy.');
      }

      generationBatch = bindings.llamaBatchInit(1, 0, 1);

      var generatedCount = 0;
      while (generatedCount < maxGeneratedTokens) {
        final token = bindings.llamaSamplerSample(sampler, context, -1);
        if (token == _llamaTokenNull) {
          throw StateError('El sampler devolvió LLAMA_TOKEN_NULL.');
        }

        if (bindings.llamaVocabIsEog(vocab, token)) {
          break;
        }

        final piece = _tokenToPiece(bindings, vocab, token);

        sendPort.send(<String, Object?>{
          'type': 'token',
          'value': piece,
        });
        generatedCount += 1;

        _fillBatch(
          batch: generationBatch,
          tokens: <int>[token],
          startPos: promptTokens.length + generatedCount - 1,
          emitLogitsOnLast: true,
        );

        final decodeResult = bindings.llamaDecode(context, generationBatch);
        if (decodeResult != 0) {
          throw StateError(
            'llama_decode(generation step $generatedCount) devolvió $decodeResult.',
          );
        }
      }

      if (generatedCount == 0) {
        throw StateError('El modelo no devolvió tokens visibles antes de EOG.');
      }
    } catch (e) {
      sendPort.send(<String, Object?>{
        'type': 'error',
        'value': '$e',
      });
    } finally {
      if (generationBatch != null) {
        bindings?.llamaBatchFree(generationBatch);
      }
      if (promptBatch != null) {
        bindings?.llamaBatchFree(promptBatch);
      }
      if (sampler != ffi.nullptr) {
        bindings?.llamaSamplerFree(sampler);
      }
      if (context != ffi.nullptr) {
        bindings?.llamaFree(context);
      }
      if (model != ffi.nullptr) {
        bindings?.llamaModelFree(model);
      }
      if (backendInitialized) {
        bindings?.llamaBackendFree();
      }
      sendPort.send(<String, Object?>{
        'type': 'done',
      });
    }
  }

  static void _noopLogCallback(
    int level,
    ffi.Pointer<ffi.Char> text,
    ffi.Pointer<ffi.Void> userData,
  ) {}

  List<int> _tokenize(
    LlamaBindings bindings,
    ffi.Pointer<LlamaVocab> vocab,
    String prompt,
  ) {
    final encodedPrompt = utf8.encode(prompt);
    final promptUtf8 = prompt.toNativeUtf8();
    ffi.Pointer<ffi.Int32> tokenBuffer = ffi.nullptr;

    try {
      var bufferSize = encodedPrompt.length + 32;
      tokenBuffer = calloc<ffi.Int32>(bufferSize);
      final addSpecial = !_containsExplicitChatMarkers(prompt);

      var tokenCount = bindings.llamaTokenize(
        vocab,
        promptUtf8.cast<ffi.Char>(),
        encodedPrompt.length,
        tokenBuffer,
        bufferSize,
        addSpecial,
        true,
      );

      if (tokenCount < 0) {
        calloc.free(tokenBuffer);
        bufferSize = -tokenCount;
        tokenBuffer = calloc<ffi.Int32>(bufferSize);
        tokenCount = bindings.llamaTokenize(
          vocab,
          promptUtf8.cast<ffi.Char>(),
          encodedPrompt.length,
          tokenBuffer,
          bufferSize,
          addSpecial,
          true,
        );
      }

      if (tokenCount <= 0) {
        throw StateError('llama_tokenize devolvió $tokenCount.');
      }

      return List<int>.generate(
        tokenCount,
        (index) => tokenBuffer[index],
      );
    } finally {
      if (tokenBuffer != ffi.nullptr) {
        calloc.free(tokenBuffer);
      }
      calloc.free(promptUtf8);
    }
  }

  String _tokenToPiece(
    LlamaBindings bindings,
    ffi.Pointer<LlamaVocab> vocab,
    int token,
  ) {
    ffi.Pointer<ffi.Char> pieceBuffer = ffi.nullptr;

    try {
      var bufferSize = 64;
      pieceBuffer = calloc<ffi.Char>(bufferSize);

      var pieceLength = bindings.llamaTokenToPiece(
        vocab,
        token,
        pieceBuffer,
        bufferSize,
        0,
        false,
      );

      if (pieceLength < 0) {
        calloc.free(pieceBuffer);
        bufferSize = -pieceLength + 1;
        pieceBuffer = calloc<ffi.Char>(bufferSize);
        pieceLength = bindings.llamaTokenToPiece(
          vocab,
          token,
          pieceBuffer,
          bufferSize,
          0,
          false,
        );
      }

      if (pieceLength <= 0) {
        return '';
      }

      final bytes = pieceBuffer.cast<ffi.Uint8>().asTypedList(pieceLength);
      return const Utf8Decoder(allowMalformed: true).convert(bytes);
    } finally {
      if (pieceBuffer != ffi.nullptr) {
        calloc.free(pieceBuffer);
      }
    }
  }

  void _fillBatch({
    required LlamaBatch batch,
    required List<int> tokens,
    required int startPos,
    required bool emitLogitsOnLast,
  }) {
    batch.nTokens = tokens.length;

    for (var index = 0; index < tokens.length; index += 1) {
      batch.token[index] = tokens[index];
      batch.pos[index] = startPos + index;
      batch.nSeqId[index] = 1;

      final seqPointer = batch.seqId[index];
      if (seqPointer == ffi.nullptr) {
        throw StateError('llama_batch_init devolvió seq_id[$index] nulo.');
      }
      seqPointer[0] = 0;

      batch.logits[index] =
          emitLogitsOnLast && index == tokens.length - 1 ? 1 : 0;
    }
  }

  void _decodePromptInChunks({
    required LlamaBindings bindings,
    required ffi.Pointer<LlamaContext> context,
    required LlamaBatch batch,
    required List<int> promptTokens,
  }) {
    for (var start = 0;
        start < promptTokens.length;
        start += _promptBatchSize) {
      final end = (start + _promptBatchSize < promptTokens.length)
          ? start + _promptBatchSize
          : promptTokens.length;
      final chunk = promptTokens.sublist(start, end);
      _fillBatch(
        batch: batch,
        tokens: chunk,
        startPos: start,
        emitLogitsOnLast: end == promptTokens.length,
      );

      final decodeResult = bindings.llamaDecode(context, batch);
      if (decodeResult != 0) {
        throw StateError(
          'llama_decode(prompt chunk ${start ~/ _promptBatchSize}) devolvió $decodeResult.',
        );
      }
    }
  }

  String _resolveDylibPath() {
    final cwd = Directory.current.path;
    final candidates = <String>{
      dylibPath,
      '$cwd/$dylibPath',
      '/tmp/llama.cpp/build/bin/libllama.dylib',
      '/tmp/llama.cpp/build/bin/libllama.0.dylib',
      '$cwd/build/bin/libllama.dylib',
      '$cwd/build/bin/libllama.0.dylib',
      '$cwd/build/macos/Build/Products/Debug/libllama.dylib',
      '$cwd/macos/libllama.dylib',
    };

    for (final candidate in candidates) {
      if (candidate.isEmpty) {
        continue;
      }

      final file = File(candidate);
      if (file.existsSync()) {
        return file.absolute.path;
      }
    }

    throw FileSystemException(
      'No se encontró libllama.dylib en ninguna ruta candidata.',
      candidates.join('\n'),
    );
  }

  bool _containsExplicitChatMarkers(String prompt) {
    return prompt.contains('<|begin_of_text|>') &&
        prompt.contains('<|start_header_id|>') &&
        prompt.contains('<|end_header_id|>');
  }
}
