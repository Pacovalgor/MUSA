import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../../modules/characters/models/character_autofill_draft.dart';
import '../ia/embedded/management/model_catalog.dart';
import '../ia/embedded/management/model_manager.dart';
import '../ia/embedded/management/model_persistence.dart';
import '../ia/embedded/ffi/llama_processor.dart';
import 'character_autofill_prompt_builder.dart';
import 'character_autofill_service.dart';

class EmbeddedCharacterAutofillService implements CharacterAutofillService {
  EmbeddedCharacterAutofillService({
    required this.activeModelPath,
  });

  final String? activeModelPath;

  @override
  Future<CharacterAutofillDraft?> buildDraft(
    CharacterAutofillRequest request,
  ) async {
    try {
      final modelPath = await _resolveActiveModelPath();
      if (modelPath == null ||
          modelPath.isEmpty ||
          !await File(modelPath).exists()) {
        return null;
      }

      final prompt =
          CharacterAutofillPromptBuilder.buildEmbeddedChatPrompt(request);
      debugPrint('[MUSA] CHARACTER PROMPT START');
      debugPrint(prompt);
      debugPrint('[MUSA] CHARACTER PROMPT END');
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
      debugPrint('[MUSA] CHARACTER RESPONSE START');
      debugPrint(raw);
      debugPrint('[MUSA] CHARACTER RESPONSE END');

      final parsed = _parseDraft(raw) ?? _buildFallbackDraft(request);
      return _sanitizeDraft(request, parsed);
    } catch (_) {
      return _sanitizeDraft(request, _buildFallbackDraft(request));
    }
  }

  CharacterAutofillDraft? _parseDraft(String raw) {
    final normalized = _normalizeRaw(raw);
    final jsonBlock = _extractJsonBlock(normalized);
    final fromJson = jsonBlock == null ? null : _decodeDraft(jsonBlock);
    if (fromJson != null) {
      return fromJson;
    }

    final repaired = jsonBlock == null ? null : _repairJson(jsonBlock);
    final fromRepaired = repaired == null ? null : _decodeDraft(repaired);
    if (fromRepaired != null) {
      return fromRepaired;
    }

    final looseMap = _parseLooseFields(normalized);
    if (looseMap.isNotEmpty) {
      return CharacterAutofillDraft.fromJson(looseMap);
    }

    return null;
  }

  CharacterAutofillDraft? _decodeDraft(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return CharacterAutofillDraft.fromJson(decoded);
      }
      if (decoded is Map) {
        return CharacterAutofillDraft.fromJson(decoded.cast<String, dynamic>());
      }
    } catch (_) {}
    return null;
  }

  String _normalizeRaw(String raw) {
    return raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('’', "'")
        .trim();
  }

  String _repairJson(String rawJson) {
    var repaired = rawJson;
    repaired = repaired.replaceAllMapped(
      RegExp(
        r'([{,]\s*)(summary|voice|motivation|internalConflict|whatTheyHide|currentState|role|notes)\s*:',
      ),
      (match) => '${match.group(1)}"${match.group(2)}":',
    );
    repaired = repaired.replaceAll(RegExp(r',\s*}'), '}');
    return repaired;
  }

  Map<String, dynamic> _parseLooseFields(String raw) {
    const keys = <String>[
      'summary',
      'voice',
      'motivation',
      'internalConflict',
      'whatTheyHide',
      'currentState',
      'role',
      'notes',
    ];

    final result = <String, dynamic>{};
    for (final key in keys) {
      final pattern =
          '"?${RegExp.escape(key)}"?\\s*[:=]\\s*"?(.*?)"?' r'(?=(?:\n|\r|$))';
      final match = RegExp(
        pattern,
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(raw);
      if (match == null) continue;
      result[key] = match.group(1)?.trim() ?? '';
    }
    return result;
  }

  String? _extractJsonBlock(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      return null;
    }

    return raw.substring(start, end + 1).trim();
  }

  CharacterAutofillDraft _buildFallbackDraft(CharacterAutofillRequest request) {
    final source = '${request.selection} ${request.nearbyContext}'.trim();
    final normalized = source.replaceAll(RegExp(r'\s+'), ' ').trim();
    final sentences = normalized
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    String shorten(String value, int maxLength) {
      final trimmed = value.trim();
      if (trimmed.length <= maxLength) return trimmed;
      return '${trimmed.substring(0, maxLength - 1)}…';
    }

    String firstWhereOrEmpty(bool Function(String) test) {
      for (final sentence in sentences) {
        if (test(sentence)) return sentence;
      }
      return '';
    }

    final role = request.isProtagonist
        ? firstWhereOrEmpty(
            (sentence) =>
                sentence.toLowerCase().contains('becaria') ||
                sentence.toLowerCase().contains('periodista') ||
                sentence.toLowerCase().contains('polic'),
          )
        : '';

    final summary = request.isProtagonist
        ? shorten(
            role.isNotEmpty
                ? role
                : 'Voz narradora en primera persona situada en el centro de la escena.',
            140,
          )
        : shorten(sentences.isNotEmpty ? sentences.first : normalized, 140);

    final voice = request.isProtagonist
        ? 'Narradora en primera persona, observadora y contenida.'
        : 'Se perfila a través de detalles concretos del manuscrito.';

    final motivation = firstWhereOrEmpty(
      (sentence) =>
          sentence.toLowerCase().contains('curiosidad') ||
          sentence.toLowerCase().contains('saber') ||
          sentence.toLowerCase().contains('buscar'),
    );

    final internalConflict = firstWhereOrEmpty(
      (sentence) =>
          sentence.toLowerCase().contains('incomod') ||
          sentence.toLowerCase().contains('duda') ||
          sentence.toLowerCase().contains('miedo'),
    );

    final currentState = firstWhereOrEmpty(
      (sentence) =>
          sentence.toLowerCase().contains('escena') ||
          sentence.toLowerCase().contains('polic') ||
          sentence.toLowerCase().contains('ambulancia') ||
          sentence.toLowerCase().contains('cinta amarilla'),
    );

    final whatTheyHide = request.isProtagonist
        ? 'No termina de admitir cuánto la arrastra la curiosidad.'
        : '';

    return CharacterAutofillDraft(
      summary: shorten(summary, 160),
      voice: shorten(voice, 120),
      motivation: shorten(motivation, 120),
      internalConflict: shorten(internalConflict, 120),
      whatTheyHide: shorten(whatTheyHide, 120),
      currentState: shorten(currentState, 120),
      role: shorten(role, 100),
      notes: request.mode == CharacterAutofillMode.enrich
          ? 'Matiz editorial extraído de un fragmento reciente del manuscrito.'
          : 'Propuesta inicial a partir del manuscrito.',
    );
  }

  CharacterAutofillDraft _sanitizeDraft(
    CharacterAutofillRequest request,
    CharacterAutofillDraft draft,
  ) {
    final languageSanitized = _sanitizeLanguage(request, draft);
    if (request.isProtagonist) {
      return languageSanitized;
    }

    final selection = ' ${request.selection.toLowerCase()} ';
    final nearbyContext = ' ${request.nearbyContext.toLowerCase()} ';
    final target = request.provisionalName.trim().toLowerCase();
    final mentionCount = target.isEmpty
        ? 0
        : RegExp('\\b${RegExp.escape(target)}\\b', caseSensitive: false)
            .allMatches(selection)
            .length;
    final firstPersonHeavy = _looksLikeFirstPersonContext(selection) ||
        _looksLikeFirstPersonContext(nearbyContext);
    final indirectPresence = mentionCount <= 1 && firstPersonHeavy;
    if (!indirectPresence) {
      return languageSanitized;
    }

    String note = languageSanitized.notes.trim();
    final quoteMatch =
        RegExp('“([^”]+)”|"([^"]+)"').firstMatch(request.selection);
    final quote = (quoteMatch?.group(1) ?? quoteMatch?.group(2) ?? '').trim();
    final hasWrittenCue = RegExp(
      '\\b${RegExp.escape(target)}\\b[^.?!]{0,40}\\b(escribi[oó]|llam[oó]|avis[oó]|dijo|mand[oó])\\b',
      caseSensitive: false,
    ).hasMatch(request.selection);

    if (hasWrittenCue) {
      note = quote.isEmpty
          ? 'Aparece de forma indirecta: envía un aviso breve a la narradora.'
          : 'Aparece de forma indirecta: envía un aviso breve a la narradora: "$quote".';
    } else if (note.isEmpty) {
      note = quote.isEmpty
          ? 'Solo aparece de forma indirecta en este fragmento.'
          : 'Solo aparece de forma indirecta en un mensaje breve: "$quote".';
    }

    return CharacterAutofillDraft(
      summary: '',
      voice: '',
      motivation: '',
      internalConflict: '',
      whatTheyHide: '',
      currentState: '',
      role: '',
      notes: note,
    );
  }

  CharacterAutofillDraft _sanitizeLanguage(
    CharacterAutofillRequest request,
    CharacterAutofillDraft draft,
  ) {
    if (request.sourceLanguage.toLowerCase() != 'spanish') {
      return draft;
    }

    String clean(String value) {
      if (!_looksEnglish(value)) return value;
      return '';
    }

    return CharacterAutofillDraft(
      summary: clean(draft.summary),
      voice: clean(draft.voice),
      motivation: clean(draft.motivation),
      internalConflict: clean(draft.internalConflict),
      whatTheyHide: clean(draft.whatTheyHide),
      currentState: clean(draft.currentState),
      role: clean(draft.role),
      notes: clean(draft.notes),
    );
  }

  bool _looksEnglish(String value) {
    final normalized = ' ${value.trim().toLowerCase()} ';
    if (normalized.trim().isEmpty) return false;
    const englishSignals = <String>[
      ' present ',
      ' briefly ',
      ' mentioned ',
      ' possibly ',
      ' near his ',
      ' near her ',
      ' home ',
      ' alleyway ',
      ' sheet ',
      ' draft ',
      ' based only ',
      ' let me know ',
    ];
    var score = 0;
    for (final signal in englishSignals) {
      if (normalized.contains(signal)) {
        score += 1;
      }
    }
    return score >= 1;
  }

  bool _looksLikeFirstPersonContext(String text) {
    const cues = <String>[
      ' yo ',
      ' me ',
      ' mi ',
      ' miré ',
      ' vi ',
      ' sentí ',
      ' dije ',
      ' pregunté ',
      ' abrí ',
      ' busqué ',
      ' subí ',
      ' detuve ',
      ' no era ',
      ' podía ',
    ];
    var score = 0;
    for (final cue in cues) {
      if (text.contains(cue)) {
        score += 1;
      }
    }
    return score >= 2;
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
