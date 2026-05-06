import '../models/guided_rewrite.dart';
import 'guided_rewrite_safety_service.dart';
import 'guided_rewrite_service.dart';

class GuidedRewriteModelRequest {
  const GuidedRewriteModelRequest({
    required this.selection,
    required this.action,
    required this.prompt,
  });

  final String selection;
  final GuidedRewriteAction action;
  final String prompt;
}

abstract class GuidedRewriteModelClient {
  bool get isReady;

  Future<String> rewrite(GuidedRewriteModelRequest request);
}

class GuidedRewritePromptBuilder {
  const GuidedRewritePromptBuilder();

  String build({
    required String selection,
    required GuidedRewriteAction action,
  }) {
    return '''
Eres una editora literaria local dentro de MUSA.
Tarea: ${_instruction(action)}

Contrato:
- Devuelve solo el texto reescrito.
- No expliques.
- No añadas personajes, nombres, lugares, hechos ni revelaciones nuevas.
- No resuelvas promesas narrativas.
- Conserva la voz, el punto de vista y los datos del fragmento.
- Mantén una extensión similar al original.

Fragmento:
$selection
''';
  }

  String _instruction(GuidedRewriteAction action) {
    return switch (action) {
      GuidedRewriteAction.raiseTension =>
        'sube la tensión sin cambiar los hechos.',
      GuidedRewriteAction.clarify =>
        'aclara la lectura sin simplificar la intención narrativa.',
      GuidedRewriteAction.reduceExposition =>
        'reduce explicación y deja en primer plano la acción concreta.',
      GuidedRewriteAction.naturalizeDialogue =>
        'naturaliza el diálogo con respiración física sin cambiar las frases dichas.',
    };
  }
}

class GuidedRewriteGenerationService {
  const GuidedRewriteGenerationService({
    this.modelClient,
    this.promptBuilder = const GuidedRewritePromptBuilder(),
    this.deterministicService = const GuidedRewriteService(),
    this.safetyService = const GuidedRewriteSafetyService(),
  });

  final GuidedRewriteModelClient? modelClient;
  final GuidedRewritePromptBuilder promptBuilder;
  final GuidedRewriteService deterministicService;
  final GuidedRewriteSafetyService safetyService;

  Future<GuidedRewriteResult> rewrite({
    required String selection,
    required GuidedRewriteAction action,
  }) async {
    final client = modelClient;
    if (client == null || !client.isReady) {
      return deterministicService.rewrite(selection: selection, action: action);
    }

    final prompt = promptBuilder.build(selection: selection, action: action);
    final raw = await client.rewrite(
      GuidedRewriteModelRequest(
        selection: selection,
        action: action,
        prompt: prompt,
      ),
    );
    final candidate = _cleanModelOutput(raw);
    final audit = safetyService.audit(
      originalText: selection,
      suggestedText: candidate,
    );

    if (candidate.trim().isEmpty ||
        audit.level == GuidedRewriteSafetyLevel.warning) {
      final fallback = deterministicService.rewrite(
        selection: selection,
        action: action,
      );
      return GuidedRewriteResult(
        action: fallback.action,
        originalText: fallback.originalText,
        suggestedText: fallback.suggestedText,
        safetyNotes: fallback.safetyNotes,
        editorComment:
            '${fallback.editorComment} Se usó fallback determinista porque la salida del modelo no pasó la auditoría.',
        source: GuidedRewriteSource.deterministic,
        safetyAudit: fallback.safetyAudit,
      );
    }

    return GuidedRewriteResult(
      action: action,
      originalText: selection,
      suggestedText: candidate,
      safetyNotes: const [
        GuidedRewriteSafetyNote.preserveFacts,
        GuidedRewriteSafetyNote.preserveVoice,
        GuidedRewriteSafetyNote.noNewCharacters,
        GuidedRewriteSafetyNote.noPlotResolution,
      ],
      editorComment:
          'Reescritura generada por el modelo local y validada por auditoría determinista.',
      source: GuidedRewriteSource.localModel,
      safetyAudit: audit,
    );
  }

  String _cleanModelOutput(String raw) {
    return raw
        .trim()
        .replaceAll(RegExp(r'^```[a-zA-Z]*\s*'), '')
        .replaceAll(RegExp(r'\s*```$'), '')
        .trim();
  }
}
