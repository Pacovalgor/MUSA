import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../../modules/scenarios/models/scenario_autofill_draft.dart';
import '../ia/embedded/management/model_catalog.dart';
import '../ia/embedded/management/model_manager.dart';
import '../ia/embedded/management/model_persistence.dart';
import '../ia/embedded/ffi/llama_processor.dart';
import 'scenario_autofill_prompt_builder.dart';
import 'scenario_autofill_service.dart';

class EmbeddedScenarioAutofillService implements ScenarioAutofillService {
  EmbeddedScenarioAutofillService({
    required this.activeModelPath,
  });

  final String? activeModelPath;

  @override
  Future<ScenarioAutofillDraft?> buildDraft(
    ScenarioAutofillRequest request,
  ) async {
    try {
      final modelPath = await _resolveActiveModelPath();
      if (modelPath == null ||
          modelPath.isEmpty ||
          !await File(modelPath).exists()) {
        return null;
      }

      final prompt =
          ScenarioAutofillPromptBuilder.buildEmbeddedChatPrompt(request);
      debugPrint('[MUSA] SCENARIO PROMPT START');
      debugPrint(prompt);
      debugPrint('[MUSA] SCENARIO PROMPT END');
      final processor = LlamaProcessor(
        modelPath: modelPath,
        dylibPath: _bundledDylibPath(),
        maxGeneratedTokens: 256,
      );

      final buffer = StringBuffer();
      await for (final token in processor.generate(prompt)) {
        buffer.write(token);
      }

      final raw = buffer.toString();
      debugPrint('[MUSA] SCENARIO RESPONSE START');
      debugPrint(raw);
      debugPrint('[MUSA] SCENARIO RESPONSE END');

      final parsed = _parseDraft(raw) ?? _buildFallbackDraft(request);
      return _sanitizeDraft(request, parsed);
    } catch (_) {
      return _sanitizeDraft(request, _buildFallbackDraft(request));
    }
  }

  ScenarioAutofillDraft? _parseDraft(String raw) {
    final normalized = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('’', "'")
        .trim();
    final start = normalized.indexOf('{');
    final end = normalized.lastIndexOf('}');
    if (start != -1 && end > start) {
      final jsonBlock = normalized.substring(start, end + 1).trim();
      try {
        final decoded = jsonDecode(jsonBlock);
        if (decoded is Map<String, dynamic>) {
          return ScenarioAutofillDraft.fromJson(decoded);
        }
        if (decoded is Map) {
          return ScenarioAutofillDraft.fromJson(
              decoded.cast<String, dynamic>());
        }
      } catch (_) {}
    }
    return null;
  }

  ScenarioAutofillDraft _buildFallbackDraft(ScenarioAutofillRequest request) {
    final source = '${request.selection} ${request.nearbyContext}'
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final sentences = source
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    String shorten(String value, int maxLength) {
      final trimmed = value.trim();
      if (trimmed.length <= maxLength) return trimmed;
      return '${trimmed.substring(0, maxLength - 1)}…';
    }

    String findMatch(List<String> cues) {
      for (final sentence in sentences) {
        final lowered = sentence.toLowerCase();
        for (final cue in cues) {
          if (lowered.contains(cue)) return sentence;
        }
      }
      return '';
    }

    final weakEvidence = _hasWeakScenarioEvidence(request);
    final summary = weakEvidence || sentences.isEmpty
        ? ''
        : shorten(sentences.first, 150);
    final atmosphere = findMatch([
      'oscur',
      'frío',
      'vacío',
      'humedad',
      'ruido',
      'silencio',
      'luz',
      'olor',
    ]);
    final importance = findMatch([
      'aquí',
      'allí',
      'es donde',
      'volver',
      'entra',
      'salida',
      'espera',
    ]);
    final currentState = findMatch([
      'ahora',
      'todavía',
      'está',
      'queda',
      'parece',
      'sigue',
    ]);

    return ScenarioAutofillDraft(
      summary: summary,
      atmosphere: weakEvidence ? '' : shorten(atmosphere, 120),
      importance: weakEvidence ? '' : shorten(importance, 120),
      whatItHides: '',
      currentState: weakEvidence ? '' : shorten(currentState, 120),
      role: '',
      notes: request.mode == ScenarioAutofillMode.enrich
          ? 'Matiz editorial extraído de un fragmento reciente del manuscrito.'
          : 'Propuesta inicial a partir del manuscrito.',
    );
  }

  ScenarioAutofillDraft _sanitizeDraft(
    ScenarioAutofillRequest request,
    ScenarioAutofillDraft draft,
  ) {
    final languageSanitized = _sanitizeLanguage(request, draft);
    if (!_hasWeakScenarioEvidence(request)) {
      return languageSanitized;
    }

    return ScenarioAutofillDraft(
      summary: '',
      atmosphere: '',
      importance: '',
      whatItHides: '',
      currentState: '',
      role: '',
      notes: languageSanitized.notes.trim().isNotEmpty
          ? languageSanitized.notes.trim()
          : 'La evidencia del fragmento es débil; conviene no fijar todavía este escenario.',
    );
  }

  ScenarioAutofillDraft _sanitizeLanguage(
    ScenarioAutofillRequest request,
    ScenarioAutofillDraft draft,
  ) {
    if (request.sourceLanguage.toLowerCase() != 'spanish') {
      return draft;
    }

    String clean(String value) {
      if (!_looksEnglish(value)) return value;
      return '';
    }

    return ScenarioAutofillDraft(
      summary: clean(draft.summary),
      atmosphere: clean(draft.atmosphere),
      importance: clean(draft.importance),
      whatItHides: clean(draft.whatItHides),
      currentState: clean(draft.currentState),
      role: clean(draft.role),
      notes: clean(draft.notes),
    );
  }

  bool _hasWeakScenarioEvidence(ScenarioAutofillRequest request) {
    final selection = ' ${request.selection.toLowerCase()} ';
    final nearbyContext = ' ${request.nearbyContext.toLowerCase()} ';
    final target = request.provisionalName.trim().toLowerCase();
    final targetMentioned = target.isNotEmpty &&
        RegExp('\\b${RegExp.escape(target)}\\b', caseSensitive: false)
            .hasMatch(request.selection);
    final concreteSignals = _containsAny(selection, const [
      ' apartamento ',
      ' estudio ',
      ' redacción ',
      ' oficina ',
      ' callejón ',
      ' hospital ',
      ' taller ',
      ' almacén ',
      ' cafetería ',
      ' bar ',
      ' restaurante ',
      ' biblioteca ',
      ' laboratorio ',
      ' casa ',
      ' habitación ',
      ' portal ',
      ' parque ',
    ]);
    final transitSignals = _containsAny(selection, const [
      ' calle ',
      ' avenida ',
      ' carretera ',
      ' esquina ',
      ' portal ',
      ' barrio ',
    ]);
    final nearbyOnly =
        selection.trim().isEmpty || (!concreteSignals && !transitSignals);
    final broadNearbyContext = _containsAny(nearbyContext, const [
      ' san francisco ',
      ' mission district ',
      ' bernal heights ',
      ' barrio ',
      ' ciudad ',
    ]);

    return !targetMentioned && nearbyOnly && broadNearbyContext;
  }

  bool _containsAny(String text, List<String> cues) {
    for (final cue in cues) {
      if (text.contains(cue)) {
        return true;
      }
    }
    return false;
  }

  bool _looksEnglish(String value) {
    final normalized = ' ${value.trim().toLowerCase()} ';
    if (normalized.trim().isEmpty) return false;
    const englishSignals = <String>[
      ' setting ',
      ' atmosphere ',
      ' nearby ',
      ' draft ',
      ' place ',
      ' chapter ',
      ' evidence ',
      ' fragment ',
      ' location ',
    ];
    for (final signal in englishSignals) {
      if (normalized.contains(signal)) {
        return true;
      }
    }
    return false;
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

  String _bundledDylibPath() {
    if (!Platform.isMacOS) {
      throw UnsupportedError(
          'El runtime actual solo está preparado para macOS.');
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

  ModelDefinition? _findModelById(String modelId) {
    for (final model in ModelCatalog.availableModels) {
      if (model.id == modelId) {
        return model;
      }
    }
    return null;
  }
}
