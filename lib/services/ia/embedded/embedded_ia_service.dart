import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../../../domain/ia/ia_interfaces.dart';
import '../../../domain/ia/engine_status.dart';
import '../../../domain/musa/musa_objects.dart';
import '../../context_builder.dart';
import '../common/scope_guard.dart';
import 'management/model_catalog.dart';
import 'management/model_manager.dart';
import 'management/model_persistence.dart';
import 'ffi/llama_processor.dart';

/// In-process AI service using llama.cpp FFI (zero external dependencies).
class EmbeddedIAService implements IAService {
  @override
  final ValueNotifier<EngineStatus> status = ValueNotifier(EngineStatus.ready);

  /// The real, verified path to the active .gguf model file.
  /// null = no model installed yet → mock fallback will be used.
  final String? activeModelPath;

  EmbeddedIAService({this.activeModelPath});

  @override
  Stream<MusaResponse> processRequest(MusaRequest request) async* {
    if (status.value != EngineStatus.ready) {
      return;
    }

    status.value = EngineStatus.processing;

    final fullPrompt = ContextBuilder.buildEmbeddedChatPrompt(
      narrativeContext: request.narrativeContext,
      documentTitle: request.documentTitle,
      documentContent: request.documentContext,
      selection: request.selection,
      musa: request.musa,
      settings: request.settings,
    );
    _logPrompt(request, fullPrompt);

    try {
      // Determine model availability
      final modelPath = await _resolveActiveModelPath();
      final modelExists = modelPath != null && await File(modelPath).exists();
      final modelSize = modelExists ? await File(modelPath).length() : 0;

      if (!modelExists || modelSize < 1000) {
        yield MusaSuggestion(
          id: 'error-model-missing',
          originalText: request.selection,
          suggestedText:
              'No hay inferencia real disponible: el modelo embebido no está instalado o es inválido.',
          editorComment:
              'El sistema bloqueó la respuesta placeholder para evitar resultados falsos.',
        );
        return;
      }

      // ─── REAL INFERENCE PATH ──────────────────────────────────────────────
      final dylibPath = _bundledDylibPath();

      String accumulatedText = '';
      final processor = LlamaProcessor(
        modelPath: modelPath,
        dylibPath: dylibPath,
      );

      try {
        await Future<void>.delayed(Duration.zero);
        await for (final token in processor.generate(fullPrompt)) {
          accumulatedText += token;
          yield MusaChunk(token);
        }
      } catch (ffiError) {
        yield MusaSuggestion(
          id: 'error-ffi',
          originalText: request.selection,
          suggestedText:
              'La inferencia embebida falló durante la generación real.',
          editorComment:
              'No se devolvió ningún placeholder. Revisa el error FFI real en los logs.',
        );
        return;
      }

      final scopeResult = ScopeGuard.validate(
        original: request.selection,
        candidate: accumulatedText,
        musa: request.musa,
        settings: request.settings,
      );

      if (!scopeResult.isValid && request.settings.shouldBlockScopeViolation) {
        yield MusaSuggestion(
          id: 'error-scope',
          originalText: request.selection,
          suggestedText: 'La Musa se ha salido del fragmento seleccionado.',
          editorComment: scopeResult.reason,
        );
        return;
      }

      yield MusaSuggestion(
        id: _buildSuggestionId(scopeResult, request),
        originalText: request.selection,
        suggestedText: accumulatedText,
        editorComment: _buildEditorComment(scopeResult, request),
      );
      _logResponse(accumulatedText);
    } catch (e) {
      yield MusaSuggestion(
        id: 'error',
        originalText: request.selection,
        suggestedText: 'Error en el motor embebido: $e',
        editorComment: 'Revisa los logs del sistema para más detalles.',
      );
    } finally {
      status.value = EngineStatus.ready;
    }
  }

  void _logPrompt(MusaRequest request, String fullPrompt) {
    debugPrint('[MUSA] PROMPT MUSA=${request.musa.name}');
    debugPrint('[MUSA] PROMPT START');
    debugPrint(fullPrompt);
    debugPrint('[MUSA] PROMPT END');
  }

  void _logResponse(String responseText) {
    debugPrint('[MUSA] RESPONSE START');
    debugPrint(responseText);
    debugPrint('[MUSA] RESPONSE END');
  }

  String _buildSuggestionId(ScopeGuardResult scopeResult, MusaRequest request) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (!scopeResult.isValid && request.settings.shouldShowScopeWarning) {
      return 'warning-scope-$timestamp';
    }

    return 'musa-ffi-$timestamp';
  }

  String _buildEditorComment(
      ScopeGuardResult scopeResult, MusaRequest request) {
    const baseComment = 'Generado vía FFI (llama.cpp) con aceleración Metal.';
    if (scopeResult.isValid || scopeResult.reason == null) {
      return baseComment;
    }

    if (request.settings.shouldMuteScopeWarning) {
      return baseComment;
    }

    return '$baseComment Aviso editorial: ${scopeResult.reason}';
  }

  @override
  void dispose() {
    status.dispose();
  }

  String _bundledDylibPath() {
    if (!Platform.isMacOS) {
      throw UnsupportedError(
          'El runtime embebido actual solo está preparado para macOS.');
    }

    final executablePath = File(Platform.resolvedExecutable).absolute.path;
    final macOsDirectory = File(executablePath).parent;
    final contentsDirectory = macOsDirectory.parent;
    final dylibPath = path.join(
      contentsDirectory.path,
      'Frameworks',
      'libllama.0.dylib',
    );

    if (!File(dylibPath).existsSync()) {
      throw FileSystemException(
        'No se encontró libllama.0.dylib dentro del bundle de la app.',
        dylibPath,
      );
    }

    return dylibPath;
  }

  Future<String?> _resolveActiveModelPath() async {
    if (activeModelPath != null && activeModelPath!.isNotEmpty) {
      return activeModelPath;
    }

    final persistence = ModelPersistence();
    final activeId = await persistence.getActiveModelId();
    final installedIds = await persistence.getInstalledModels();

    final candidateIds = <String>[
      if (activeId != null) activeId,
      ...installedIds.where((id) => id != activeId),
    ];

    for (final modelId in candidateIds) {
      final model = _findModelById(modelId);
      if (model == null) {
        continue;
      }

      final resolvedPath = await ModelManager.resolveModelPath(model);
      if (await File(resolvedPath).exists()) {
        return resolvedPath;
      }
    }

    return null;
  }

  ModelDefinition? _findModelById(String modelId) {
    for (final model in ModelCatalog.availableModels) {
      if (model.id == modelId) {
        return model;
      }
    }
    return null;
  }
}
