import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../domain/ia/ia_interfaces.dart';
import '../../../domain/ia/engine_status.dart';
import '../../../domain/musa/musa_objects.dart';
import '../common/scope_guard.dart';
import '../../context_builder.dart';

/// A real implementation for macOS that connects to a local inference engine
/// (like Ollama or llama.cpp) via its internal HTTP server.
class LocalMacIAService implements IAService {
  @override
  final ValueNotifier<EngineStatus> status = ValueNotifier(EngineStatus.ready);

  final String _endpoint =
      "http://localhost:11434/api/generate"; // Ollama default
  final String _model =
      "mistral"; // Default recommended model for local writing

  LocalMacIAService();

  @override
  Stream<MusaResponse> processRequest(MusaRequest request) async* {
    if (status.value != EngineStatus.ready) return;

    status.value = EngineStatus.processing;

    final fullPrompt = ContextBuilder.buildFullPrompt(
      narrativeContext: request.narrativeContext,
      documentTitle: request.documentTitle,
      documentContent: request.documentContext,
      selection: request.selection,
      musa: request.musa,
      settings: request.settings,
    );
    _logPrompt(request, fullPrompt);

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final uri = Uri.parse(_endpoint);
      final req = await client.postUrl(uri);

      final body = {
        "model": _model,
        "prompt": fullPrompt,
        "stream": true,
      };

      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(body));

      final response = await req.close();
      if (response.statusCode != 200) {
        throw Exception("Local engine returned ${response.statusCode}");
      }

      String accumulatedText = "";

      // Handle the specialized Ollama stream format (JSON per line)
      await for (var chunk
          in response.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.isEmpty) continue;

        try {
          final json = jsonDecode(chunk);
          final delta = json['response'] as String?;
          final done = json['done'] as bool? ?? false;

          if (delta != null) {
            accumulatedText += delta;
            yield MusaChunk(delta);
          }

          if (done) break;
        } catch (e) {
          // Skip malformed lines if any
          continue;
        }
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

      // Finally, emit the frozen Suggestion object
      yield MusaSuggestion(
        id: _buildSuggestionId(scopeResult, request),
        originalText: request.selection,
        suggestedText: accumulatedText,
        editorComment: _buildEditorComment(scopeResult, request),
      );
      _logResponse(accumulatedText);
    } catch (e) {
      // Graceful fallback and debugging for local connection failures
      String userMessage = "No se pudo conectar con el motor local.";
      String advice = "Verifica que Ollama esté activo.";

      if (e.toString().contains('Connection refused') || e is SocketException) {
        userMessage = "Ollama no detectado en localhost:11434.";
        advice = "Abre Ollama antes de invocar a la Musa.";
      }

      yield MusaSuggestion(
        id: "error",
        originalText: request.selection,
        suggestedText: "$userMessage ($e)",
        editorComment: advice,
      );
    } finally {
      status.value = EngineStatus.ready;
    }
  }

  @override
  void dispose() {
    status.dispose();
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

    return 'mac-local-$timestamp';
  }

  String _buildEditorComment(
      ScopeGuardResult scopeResult, MusaRequest request) {
    const baseComment =
        'Refinado localmente para mejorar el ritmo y la coherencia.';
    if (scopeResult.isValid || scopeResult.reason == null) {
      return baseComment;
    }

    if (request.settings.shouldMuteScopeWarning) {
      return baseComment;
    }

    return '$baseComment Aviso editorial: ${scopeResult.reason}';
  }
}
