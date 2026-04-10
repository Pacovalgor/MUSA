import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

final class LlamaModel extends ffi.Opaque {}

final class LlamaContext extends ffi.Opaque {}

final class LlamaVocab extends ffi.Opaque {}

final class LlamaSampler extends ffi.Opaque {}

final class LlamaSamplerSeqConfig extends ffi.Struct {
  @ffi.Int32()
  external int seqId;

  external ffi.Pointer<LlamaSampler> sampler;
}

final class LlamaModelParams extends ffi.Struct {
  external ffi.Pointer<ffi.Void> devices;
  external ffi.Pointer<ffi.Void> tensorBuftOverrides;

  @ffi.Int32()
  external int nGpuLayers;

  @ffi.Int32()
  external int splitMode;

  @ffi.Int32()
  external int mainGpu;

  external ffi.Pointer<ffi.Float> tensorSplit;
  external ffi.Pointer<ffi.Void> progressCallback;
  external ffi.Pointer<ffi.Void> progressCallbackUserData;
  external ffi.Pointer<ffi.Void> kvOverrides;

  @ffi.Bool()
  external bool vocabOnly;

  @ffi.Bool()
  external bool useMmap;

  @ffi.Bool()
  external bool useDirectIo;

  @ffi.Bool()
  external bool useMlock;

  @ffi.Bool()
  external bool checkTensors;

  @ffi.Bool()
  external bool useExtraBufts;

  @ffi.Bool()
  external bool noHost;

  @ffi.Bool()
  external bool noAlloc;
}

final class LlamaContextParams extends ffi.Struct {
  @ffi.Uint32()
  external int nCtx;

  @ffi.Uint32()
  external int nBatch;

  @ffi.Uint32()
  external int nUbatch;

  @ffi.Uint32()
  external int nSeqMax;

  @ffi.Int32()
  external int nThreads;

  @ffi.Int32()
  external int nThreadsBatch;

  @ffi.Int32()
  external int ropeScalingType;

  @ffi.Int32()
  external int poolingType;

  @ffi.Int32()
  external int attentionType;

  @ffi.Int32()
  external int flashAttnType;

  @ffi.Float()
  external double ropeFreqBase;

  @ffi.Float()
  external double ropeFreqScale;

  @ffi.Float()
  external double yarnExtFactor;

  @ffi.Float()
  external double yarnAttnFactor;

  @ffi.Float()
  external double yarnBetaFast;

  @ffi.Float()
  external double yarnBetaSlow;

  @ffi.Uint32()
  external int yarnOrigCtx;

  @ffi.Float()
  external double defragThold;

  external ffi.Pointer<ffi.Void> cbEval;
  external ffi.Pointer<ffi.Void> cbEvalUserData;

  @ffi.Int32()
  external int typeK;

  @ffi.Int32()
  external int typeV;

  external ffi.Pointer<ffi.Void> abortCallback;
  external ffi.Pointer<ffi.Void> abortCallbackData;

  @ffi.Bool()
  external bool embeddings;

  @ffi.Bool()
  external bool offloadKqv;

  @ffi.Bool()
  external bool noPerf;

  @ffi.Bool()
  external bool opOffload;

  @ffi.Bool()
  external bool swaFull;

  @ffi.Bool()
  external bool kvUnified;

  external ffi.Pointer<LlamaSamplerSeqConfig> samplers;

  @ffi.Size()
  external int nSamplers;
}

final class LlamaSamplerChainParams extends ffi.Struct {
  @ffi.Bool()
  external bool noPerf;
}

final class LlamaBatch extends ffi.Struct {
  @ffi.Int32()
  external int nTokens;

  external ffi.Pointer<ffi.Int32> token;
  external ffi.Pointer<ffi.Float> embd;
  external ffi.Pointer<ffi.Int32> pos;
  external ffi.Pointer<ffi.Int32> nSeqId;
  external ffi.Pointer<ffi.Pointer<ffi.Int32>> seqId;
  external ffi.Pointer<ffi.Int8> logits;
}

typedef LlamaBackendInitNative = ffi.Void Function();
typedef LlamaBackendInit = void Function();

typedef LlamaBackendFreeNative = ffi.Void Function();
typedef LlamaBackendFree = void Function();

typedef LlamaModelDefaultParamsNative = LlamaModelParams Function();
typedef LlamaModelDefaultParams = LlamaModelParams Function();

typedef LlamaContextDefaultParamsNative = LlamaContextParams Function();
typedef LlamaContextDefaultParams = LlamaContextParams Function();

typedef LlamaSamplerChainDefaultParamsNative = LlamaSamplerChainParams
    Function();
typedef LlamaSamplerChainDefaultParams = LlamaSamplerChainParams Function();

typedef LlamaModelLoadFromFileNative = ffi.Pointer<LlamaModel> Function(
  ffi.Pointer<Utf8>,
  LlamaModelParams,
);
typedef LlamaModelLoadFromFile = ffi.Pointer<LlamaModel> Function(
  ffi.Pointer<Utf8>,
  LlamaModelParams,
);

typedef LlamaInitFromModelNative = ffi.Pointer<LlamaContext> Function(
  ffi.Pointer<LlamaModel>,
  LlamaContextParams,
);
typedef LlamaInitFromModel = ffi.Pointer<LlamaContext> Function(
  ffi.Pointer<LlamaModel>,
  LlamaContextParams,
);

typedef LlamaFreeNative = ffi.Void Function(ffi.Pointer<LlamaContext>);
typedef LlamaFree = void Function(ffi.Pointer<LlamaContext>);

typedef LlamaModelFreeNative = ffi.Void Function(ffi.Pointer<LlamaModel>);
typedef LlamaModelFree = void Function(ffi.Pointer<LlamaModel>);

typedef LlamaModelGetVocabNative = ffi.Pointer<LlamaVocab> Function(
  ffi.Pointer<LlamaModel>,
);
typedef LlamaModelGetVocab = ffi.Pointer<LlamaVocab> Function(
  ffi.Pointer<LlamaModel>,
);

typedef LlamaTokenizeNative = ffi.Int32 Function(
  ffi.Pointer<LlamaVocab>,
  ffi.Pointer<ffi.Char>,
  ffi.Int32,
  ffi.Pointer<ffi.Int32>,
  ffi.Int32,
  ffi.Bool,
  ffi.Bool,
);
typedef LlamaTokenize = int Function(
  ffi.Pointer<LlamaVocab>,
  ffi.Pointer<ffi.Char>,
  int,
  ffi.Pointer<ffi.Int32>,
  int,
  bool,
  bool,
);

typedef LlamaBatchInitNative = LlamaBatch Function(
  ffi.Int32,
  ffi.Int32,
  ffi.Int32,
);
typedef LlamaBatchInit = LlamaBatch Function(
  int,
  int,
  int,
);

typedef LlamaBatchFreeNative = ffi.Void Function(LlamaBatch);
typedef LlamaBatchFree = void Function(LlamaBatch);

typedef LlamaDecodeNative = ffi.Int32 Function(
  ffi.Pointer<LlamaContext>,
  LlamaBatch,
);
typedef LlamaDecode = int Function(
  ffi.Pointer<LlamaContext>,
  LlamaBatch,
);

typedef LlamaSamplerInitGreedyNative = ffi.Pointer<LlamaSampler> Function();
typedef LlamaSamplerInitGreedy = ffi.Pointer<LlamaSampler> Function();

typedef LlamaSamplerFreeNative = ffi.Void Function(ffi.Pointer<LlamaSampler>);
typedef LlamaSamplerFree = void Function(ffi.Pointer<LlamaSampler>);

typedef LlamaSamplerSampleNative = ffi.Int32 Function(
  ffi.Pointer<LlamaSampler>,
  ffi.Pointer<LlamaContext>,
  ffi.Int32,
);
typedef LlamaSamplerSample = int Function(
  ffi.Pointer<LlamaSampler>,
  ffi.Pointer<LlamaContext>,
  int,
);

typedef LlamaTokenToPieceNative = ffi.Int32 Function(
  ffi.Pointer<LlamaVocab>,
  ffi.Int32,
  ffi.Pointer<ffi.Char>,
  ffi.Int32,
  ffi.Int32,
  ffi.Bool,
);
typedef LlamaTokenToPiece = int Function(
  ffi.Pointer<LlamaVocab>,
  int,
  ffi.Pointer<ffi.Char>,
  int,
  int,
  bool,
);

typedef LlamaVocabIsEogNative = ffi.Bool Function(
  ffi.Pointer<LlamaVocab>,
  ffi.Int32,
);
typedef LlamaVocabIsEog = bool Function(
  ffi.Pointer<LlamaVocab>,
  int,
);

typedef LlamaLogCallbackNative = ffi.Void Function(
  ffi.Int32,
  ffi.Pointer<ffi.Char>,
  ffi.Pointer<ffi.Void>,
);
typedef LlamaLogSetNative = ffi.Void Function(
  ffi.Pointer<ffi.NativeFunction<LlamaLogCallbackNative>>,
  ffi.Pointer<ffi.Void>,
);
typedef LlamaLogSet = void Function(
  ffi.Pointer<ffi.NativeFunction<LlamaLogCallbackNative>>,
  ffi.Pointer<ffi.Void>,
);

class LlamaBindings {
  LlamaBindings(String path) : nativeLib = ffi.DynamicLibrary.open(path) {
    llamaBackendInit = nativeLib
        .lookup<ffi.NativeFunction<LlamaBackendInitNative>>(
          'llama_backend_init',
        )
        .asFunction();
    llamaBackendFree = nativeLib
        .lookup<ffi.NativeFunction<LlamaBackendFreeNative>>(
          'llama_backend_free',
        )
        .asFunction();
    llamaModelDefaultParams = nativeLib
        .lookup<ffi.NativeFunction<LlamaModelDefaultParamsNative>>(
          'llama_model_default_params',
        )
        .asFunction();
    llamaContextDefaultParams = nativeLib
        .lookup<ffi.NativeFunction<LlamaContextDefaultParamsNative>>(
          'llama_context_default_params',
        )
        .asFunction();
    llamaSamplerChainDefaultParams = nativeLib
        .lookup<ffi.NativeFunction<LlamaSamplerChainDefaultParamsNative>>(
          'llama_sampler_chain_default_params',
        )
        .asFunction();
    llamaModelLoadFromFile = nativeLib
        .lookup<ffi.NativeFunction<LlamaModelLoadFromFileNative>>(
          'llama_model_load_from_file',
        )
        .asFunction();
    llamaInitFromModel = nativeLib
        .lookup<ffi.NativeFunction<LlamaInitFromModelNative>>(
          'llama_init_from_model',
        )
        .asFunction();
    llamaFree = nativeLib
        .lookup<ffi.NativeFunction<LlamaFreeNative>>('llama_free')
        .asFunction();
    llamaModelFree = nativeLib
        .lookup<ffi.NativeFunction<LlamaModelFreeNative>>('llama_model_free')
        .asFunction();
    llamaModelGetVocab = nativeLib
        .lookup<ffi.NativeFunction<LlamaModelGetVocabNative>>(
          'llama_model_get_vocab',
        )
        .asFunction();
    llamaTokenize = nativeLib
        .lookup<ffi.NativeFunction<LlamaTokenizeNative>>('llama_tokenize')
        .asFunction();
    llamaBatchInit = nativeLib
        .lookup<ffi.NativeFunction<LlamaBatchInitNative>>('llama_batch_init')
        .asFunction();
    llamaBatchFree = nativeLib
        .lookup<ffi.NativeFunction<LlamaBatchFreeNative>>('llama_batch_free')
        .asFunction();
    llamaDecode = nativeLib
        .lookup<ffi.NativeFunction<LlamaDecodeNative>>('llama_decode')
        .asFunction();
    llamaSamplerInitGreedy = nativeLib
        .lookup<ffi.NativeFunction<LlamaSamplerInitGreedyNative>>(
          'llama_sampler_init_greedy',
        )
        .asFunction();
    llamaSamplerFree = nativeLib
        .lookup<ffi.NativeFunction<LlamaSamplerFreeNative>>(
            'llama_sampler_free')
        .asFunction();
    llamaSamplerSample = nativeLib
        .lookup<ffi.NativeFunction<LlamaSamplerSampleNative>>(
          'llama_sampler_sample',
        )
        .asFunction();
    llamaTokenToPiece = nativeLib
        .lookup<ffi.NativeFunction<LlamaTokenToPieceNative>>(
          'llama_token_to_piece',
        )
        .asFunction();
    llamaVocabIsEog = nativeLib
        .lookup<ffi.NativeFunction<LlamaVocabIsEogNative>>(
          'llama_vocab_is_eog',
        )
        .asFunction();
    llamaLogSet = nativeLib
        .lookup<ffi.NativeFunction<LlamaLogSetNative>>('llama_log_set')
        .asFunction();
  }

  final ffi.DynamicLibrary nativeLib;

  late final LlamaBackendInit llamaBackendInit;
  late final LlamaBackendFree llamaBackendFree;
  late final LlamaModelDefaultParams llamaModelDefaultParams;
  late final LlamaContextDefaultParams llamaContextDefaultParams;
  late final LlamaSamplerChainDefaultParams llamaSamplerChainDefaultParams;
  late final LlamaModelLoadFromFile llamaModelLoadFromFile;
  late final LlamaInitFromModel llamaInitFromModel;
  late final LlamaFree llamaFree;
  late final LlamaModelFree llamaModelFree;
  late final LlamaModelGetVocab llamaModelGetVocab;
  late final LlamaTokenize llamaTokenize;
  late final LlamaBatchInit llamaBatchInit;
  late final LlamaBatchFree llamaBatchFree;
  late final LlamaDecode llamaDecode;
  late final LlamaSamplerInitGreedy llamaSamplerInitGreedy;
  late final LlamaSamplerFree llamaSamplerFree;
  late final LlamaSamplerSample llamaSamplerSample;
  late final LlamaTokenToPiece llamaTokenToPiece;
  late final LlamaVocabIsEog llamaVocabIsEog;
  late final LlamaLogSet llamaLogSet;
}
