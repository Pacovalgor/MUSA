import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/fragment_analysis.dart';
import '../../services/ia/embedded/ffi/llama_processor.dart';
import '../../services/ia/embedded/management/model_catalog.dart';
import '../../services/ia/embedded/management/model_manager.dart';
import '../../services/ia/embedded/management/model_persistence.dart';

abstract class ChapterCharacterValidationService {
  bool get isReady;

  Future<Set<String>> confirmPersonNames({
    required String chapterText,
    required List<DetectedCharacter> candidates,
  });
}

class UnavailableChapterCharacterValidationService
    implements ChapterCharacterValidationService {
  const UnavailableChapterCharacterValidationService();

  @override
  bool get isReady => false;

  @override
  Future<Set<String>> confirmPersonNames({
    required String chapterText,
    required List<DetectedCharacter> candidates,
  }) async {
    return candidates.map((item) => item.name).toSet();
  }
}

class EmbeddedChapterCharacterValidationService
    implements ChapterCharacterValidationService {
  const EmbeddedChapterCharacterValidationService({
    required this.activeModelPath,
  });

  final String? activeModelPath;

  @override
  bool get isReady => Platform.isMacOS;

  @override
  Future<Set<String>> confirmPersonNames({
    required String chapterText,
    required List<DetectedCharacter> candidates,
  }) async {
    if (candidates.isEmpty) return const <String>{};

    try {
      final modelPath = await _resolveActiveModelPath();
      if (modelPath == null ||
          modelPath.isEmpty ||
          !await File(modelPath).exists()) {
        return candidates.map((item) => item.name).toSet();
      }

      final prompt = _buildPrompt(
        chapterText: chapterText,
        candidates: candidates,
      );
      final processor = LlamaProcessor(
        modelPath: modelPath,
        dylibPath: _bundledDylibPath(),
        maxGeneratedTokens: 96,
      );

      final buffer = StringBuffer();
      await for (final token in processor.generate(prompt)) {
        buffer.write(token);
      }

      final confirmed = _parseConfirmedNames(buffer.toString(), candidates);
      return confirmed ?? candidates.map((item) => item.name).toSet();
    } catch (error) {
      debugPrint('[MUSA] Chapter character validation skipped: $error');
      return candidates.map((item) => item.name).toSet();
    }
  }

  String _buildPrompt({
    required String chapterText,
    required List<DetectedCharacter> candidates,
  }) {
    final compactText = chapterText.trim().replaceAll(RegExp(r'\s+'), ' ');
    final clippedText = compactText.length <= 1800
        ? compactText
        : compactText.substring(0, 1800);
    final names = candidates.map((item) => item.name).join(', ');

    return '''
<|begin_of_text|><|start_header_id|>system<|end_header_id|>

Eres un clasificador local de entidades narrativas. No reescribas. No expliques.
Devuelve solo JSON valido.
<|eot_id|><|start_header_id|>user<|end_header_id|>

Texto del capitulo:
$clippedText

Candidatos detectados:
$names

Tarea:
Devuelve {"people":[...]} solo con candidatos que sean personajes/personas reales en la escena.
Excluye verbos, acciones, objetos, lugares, distritos, ciudades, marcas, estados mentales y palabras capitalizadas por inicio de frase.
No agregues nombres que no esten en la lista de candidatos.
<|eot_id|><|start_header_id|>assistant<|end_header_id|>

''';
  }

  Set<String>? _parseConfirmedNames(
    String raw,
    List<DetectedCharacter> candidates,
  ) {
    final allowed = {
      for (final candidate in candidates)
        candidate.name.toLowerCase(): candidate.name,
    };
    final jsonBlock = _extractJsonBlock(raw);
    if (jsonBlock == null) return null;

    try {
      final decoded = jsonDecode(jsonBlock);
      final people = decoded is Map ? decoded['people'] : null;
      if (people is! List) return null;

      final confirmed = <String>{};
      for (final item in people) {
        final name = item.toString().trim();
        final canonical = allowed[name.toLowerCase()];
        if (canonical != null) {
          confirmed.add(canonical);
        }
      }
      return confirmed;
    } catch (_) {
      return null;
    }
  }

  String? _extractJsonBlock(String raw) {
    final normalized = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .trim();
    final start = normalized.indexOf('{');
    final end = normalized.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      return null;
    }
    return normalized.substring(start, end + 1);
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
      if (model == null) continue;
      final resolvedPath = await ModelManager.resolveModelPath(model);
      if (await File(resolvedPath).exists()) {
        return resolvedPath;
      }
    }

    return null;
  }

  ModelDefinition? _findModelById(String modelId) {
    for (final model in ModelCatalog.availableModels) {
      if (model.id == modelId) return model;
    }
    return null;
  }

  String _bundledDylibPath() {
    final executablePath = File(Platform.resolvedExecutable).absolute.path;
    final macOsDirectory = File(executablePath).parent;
    final contentsDirectory = macOsDirectory.parent;
    return path.join(
      contentsDirectory.path,
      'Frameworks',
      'libllama.0.dylib',
    );
  }
}
