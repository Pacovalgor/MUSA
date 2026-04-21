import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/books/services/narrative_document_classifier.dart';
import '../../modules/characters/models/character.dart';
import '../../modules/scenarios/models/scenario.dart';
import '../models/chapter_analysis.dart';
import '../models/fragment_analysis.dart';
import 'fragment_analysis_service.dart';
import 'fragment_inference_utils.dart';

final chapterAnalysisServiceProvider = Provider<ChapterAnalysisService>((ref) {
  return const ChapterAnalysisService();
});

class ChapterAnalysisService {
  const ChapterAnalysisService({
    this.fragmentAnalysisService = const FragmentAnalysisService(),
    this.documentClassifier = const NarrativeDocumentClassifier(),
  });

  final FragmentAnalysisService fragmentAnalysisService;
  final NarrativeDocumentClassifier documentClassifier;

  Future<ChapterAnalysis> analyzeAsync({
    required String chapterText,
    required List<Character> characters,
    required List<Scenario> scenarios,
    required List<String> linkedCharacterIds,
    required List<String> linkedScenarioIds,
  }) async {
    final classification = documentClassifier.classifyRaw(chapterText);

    if (classification.kind != NarrativeDocumentKind.scene &&
        classification.kind != NarrativeDocumentKind.unknown) {
      return _buildNonNarrativeAnalysis(classification);
    }

    final payload = <String, dynamic>{
      'chapterText': chapterText,
      'characters': characters.map((item) => item.toJson()).toList(),
      'scenarios': scenarios.map((item) => item.toJson()).toList(),
      'linkedCharacterIds': linkedCharacterIds,
      'linkedScenarioIds': linkedScenarioIds,
    };

    final result = await Isolate.run<Map<String, dynamic>>(
      () => _analyzeChapterPayload(payload),
    );

    return _chapterAnalysisFromJson(result);
  }

  ChapterAnalysis _buildNonNarrativeAnalysis(
      NarrativeDocumentClassification classification) {
    final message = switch (classification.kind) {
      NarrativeDocumentKind.research =>
        'Este documento se identifica como material de investigación. El Copiloto ignorará la estructura dramática para centrarse en la claridad de los datos.',
      NarrativeDocumentKind.technical =>
        'Documento técnico detectado. No se aplicarán métricas de tensión o ritmo narrativo.',
      NarrativeDocumentKind.worldbuilding =>
        'Material de construcción de mundo. Se prioriza la coherencia de hechos sobre la trayectoria emocional.',
      _ => 'Material de apoyo detectado.',
    };

    return ChapterAnalysis(
      dominantNarrativeMoment: const NarrativeMoment(
        title: 'Informativo',
        summary: 'El contenido es de naturaleza documental o técnica.',
      ),
      chapterFunction: ChapterFunction.setup,
      recommendation: ChapterRecommendation(
        message: message,
      ),
    );
  }

  ChapterAnalysis analyze({
    required String chapterText,
    required List<Character> characters,
    required List<Scenario> scenarios,
    required List<String> linkedCharacterIds,
    required List<String> linkedScenarioIds,
  }) {
    final fragments = _fragmentChapter(chapterText)
        .map(
          (fragment) => fragmentAnalysisService.analyze(
            selection: fragment,
            characters: characters,
            scenarios: scenarios,
            linkedCharacterIds: linkedCharacterIds,
            linkedScenarioIds: linkedScenarioIds,
          ),
        )
        .toList();

    final mainCharacters = _resolveMainCharacters(
      chapterText: chapterText,
      fragments: fragments,
      characters: characters,
      linkedCharacterIds: linkedCharacterIds,
    );
    final mainScenario = _resolveMainScenario(
      fragments: fragments,
      scenarios: scenarios,
      linkedScenarioIds: linkedScenarioIds,
    );
    final momentResolution = _resolveNarrativeMoments(
      chapterText: chapterText,
      fragments: fragments,
    );
    final chapterFunction = _resolveChapterFunction(
      chapterText: chapterText,
      fragments: fragments,
      mainCharacters: mainCharacters,
      mainScenario: mainScenario,
      dominantMoment: momentResolution.dominant,
    );
    final characterDevelopments = _resolveCharacterDevelopments(
      chapterText: chapterText,
      fragments: fragments,
      characters: characters,
      mainCharacters: mainCharacters,
      dominantMoment: momentResolution.dominant,
    );
    final scenarioDevelopments = _resolveScenarioDevelopments(
      chapterText: chapterText,
      fragments: fragments,
      mainScenario: mainScenario,
    );
    final trajectory = _resolveTrajectory(fragments);
    final recommendation = _buildRecommendation(
      chapterText: chapterText,
      fragments: fragments,
      mainCharacters: mainCharacters,
      mainScenario: mainScenario,
      chapterFunction: chapterFunction,
      characterDevelopments: characterDevelopments,
      scenarioDevelopments: scenarioDevelopments,
      trajectory: trajectory,
    );
    final draftAnalysis = ChapterAnalysis(
      mainCharacters: mainCharacters,
      mainScenario: mainScenario,
      narrativeMoments: momentResolution.moments,
      dominantNarrativeMoment: momentResolution.dominant,
      chapterFunction: chapterFunction,
      characterDevelopments: characterDevelopments,
      scenarioDevelopments: scenarioDevelopments,
      trajectory: trajectory,
      recommendation: recommendation,
    );
    final nextStep = _resolveNextStep(
      chapterText: chapterText,
      analysis: draftAnalysis,
    );

    return ChapterAnalysis(
      mainCharacters: mainCharacters,
      mainScenario: mainScenario,
      narrativeMoments: momentResolution.moments,
      dominantNarrativeMoment: momentResolution.dominant,
      chapterFunction: chapterFunction,
      characterDevelopments: characterDevelopments,
      scenarioDevelopments: scenarioDevelopments,
      trajectory: trajectory,
      nextStep: nextStep,
      recommendation: recommendation,
    );
  }

  int computeChapterCharacterScore({
    required String name,
    required List<FragmentAnalysis> fragments,
  }) {
    var score = 0;
    for (var index = 0; index < fragments.length; index++) {
      final fragment = fragments[index];
      final candidate =
          fragment.characters.cast<DetectedCharacter?>().firstWhere(
                (item) =>
                    item != null &&
                    FragmentInferenceUtils.isSameCharacter(item.name, name),
                orElse: () => null,
              );
      if (candidate == null) {
        continue;
      }

      score += candidate.strengthScore + 2;
      if (index == 0 || index == fragments.length - 1) {
        score += 2;
      }
    }
    return score;
  }

  List<String> _fragmentChapter(String chapterText) {
    final cleaned = chapterText.trim();
    if (cleaned.isEmpty) return const [];

    final paragraphs = cleaned
        .split(RegExp(r'\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (paragraphs.isEmpty) {
      return <String>[cleaned];
    }

    const targetSize = 900;
    final fragments = <String>[];
    final buffer = StringBuffer();

    for (final paragraph in paragraphs) {
      final current = buffer.toString();
      final nextLength = current.isEmpty
          ? paragraph.length
          : current.length + 2 + paragraph.length;
      if (current.isNotEmpty && nextLength > targetSize) {
        fragments.add(current.trim());
        buffer.clear();
      }
      if (buffer.isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
      }
      buffer.write(paragraph);
    }

    final trailing = buffer.toString().trim();
    if (trailing.isNotEmpty) {
      fragments.add(trailing);
    }

    return fragments.isEmpty ? <String>[cleaned] : fragments;
  }

  List<DetectedCharacter> _resolveMainCharacters({
    required String chapterText,
    required List<FragmentAnalysis> fragments,
    required List<Character> characters,
    required List<String> linkedCharacterIds,
  }) {
    final clusters = <_CharacterCluster>[];
    final charactersById = {for (final item in characters) item.id: item};
    final chapterCharacterScores = <String, int>{};
    final normalizedChapter = ' ${chapterText.toLowerCase()} ';

    for (final character in characters) {
      chapterCharacterScores[character.id] = computeChapterCharacterScore(
        name: character.displayName,
        fragments: fragments,
      );
    }

    for (var index = 0; index < fragments.length; index++) {
      final fragment = fragments[index];

      for (final candidate in fragment.characters) {
        _addCharacterCandidate(
          clusters: clusters,
          candidate: candidate,
          fragmentIndex: index,
          isBoundary: index == 0 || index == fragments.length - 1,
          chapterBoost: candidate.existingCharacterId == null
              ? computeChapterCharacterScore(
                  name: candidate.name,
                  fragments: fragments,
                )
              : (chapterCharacterScores[candidate.existingCharacterId] ?? 0),
        );
      }

      final narratorCharacterId = fragment.narrator?.protagonistCharacterId;
      if (narratorCharacterId == null) {
        continue;
      }

      final protagonist = charactersById[narratorCharacterId];
      if (protagonist == null) {
        continue;
      }

      _addCharacterCandidate(
        clusters: clusters,
        candidate: DetectedCharacter(
          name: protagonist.displayName,
          summary: 'Sostiene la mirada del capítulo',
          existingCharacterId: protagonist.id,
          isAlreadyLinked: linkedCharacterIds.contains(protagonist.id),
          relevanceScore: 4,
          strengthScore: 5,
        ),
        fragmentIndex: index,
        isBoundary: index == 0 || index == fragments.length - 1,
        narratorBoost: 3,
        chapterBoost: chapterCharacterScores[protagonist.id] ?? 0,
      );
    }

    for (final character in characters) {
      if (character.isProtagonist) {
        continue;
      }

      final alreadyClustered = clusters.any(
        (item) => item.existingCharacterId == character.id,
      );
      if (alreadyClustered) {
        continue;
      }

      final occurrences = _countCharacterMentionsInChapter(
        normalizedChapter,
        character.displayName,
      );
      final hasHumanContext = FragmentInferenceUtils.hasHumanContext(
            chapterText,
            character.displayName,
          ) ||
          FragmentInferenceUtils.hasDirectPresentationContext(
            chapterText,
            character.displayName,
          );

      if (occurrences < 2 && !hasHumanContext) {
        continue;
      }

      final chapterStrength = FragmentInferenceUtils.computeCharacterStrength(
        name: character.displayName,
        context: chapterText,
      );
      if (chapterStrength < 3) {
        continue;
      }

      _addCharacterCandidate(
        clusters: clusters,
        candidate: DetectedCharacter(
          name: character.displayName,
          summary: hasHumanContext
              ? 'Gana presencia clara en el capítulo'
              : 'Reaparece con peso suficiente en el capítulo',
          existingCharacterId: character.id,
          isAlreadyLinked: linkedCharacterIds.contains(character.id),
          relevanceScore: occurrences + chapterStrength,
          strengthScore: chapterStrength,
        ),
        fragmentIndex: occurrences >= 2 ? 1 : 0,
        isBoundary: false,
        chapterBoost: (chapterCharacterScores[character.id] ?? 0) +
            occurrences +
            (hasHumanContext ? 2 : 0),
      );
    }

    final inferredChapterCharacters = <DetectedCharacter>[];
    final properNameRegex = RegExp(
      r'\b[A-ZÁÉÍÓÚÑ][a-záéíóúñ]{2,}(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]{2,})?\b',
    );
    final blockedNames = <String>{
      'San Francisco',
      'Mission District',
      'Los Ángeles',
      'Los Angeles',
      'WhatsApp',
      'Instagram',
      'Google',
      'Twitter',
      'Mission',
      'District',
      'Policía',
      'Ambulancia',
      'Callejón',
      'Crimen',
      'Norte',
      'Sur',
      'Este',
      'Oeste',
    };

    for (final match in properNameRegex.allMatches(chapterText)) {
      final candidate = match.group(0)?.trim() ?? '';
      if (candidate.isEmpty || blockedNames.contains(candidate)) {
        continue;
      }
      if (FragmentInferenceUtils.isBlockedCapitalizedWord(candidate) ||
          FragmentInferenceUtils.isCommonNonEntityWord(candidate)) {
        continue;
      }
      if (FragmentInferenceUtils.looksLikeGeographicName(candidate) ||
          FragmentInferenceUtils.appearsInGeographicContext(
            chapterText,
            candidate,
          )) {
        continue;
      }
      if (_looksLikeChapterOrganization(chapterText, candidate)) {
        continue;
      }
      if (characters.any((item) =>
          item.displayName.toLowerCase() == candidate.toLowerCase())) {
        continue;
      }
      if (FragmentInferenceUtils.appearsOnlyAtSentenceStart(
            chapterText,
            candidate,
          ) &&
          !FragmentInferenceUtils.hasDirectPresentationContext(
            chapterText,
            candidate,
          )) {
        continue;
      }

      final occurrences =
          _countCharacterMentionsInChapter(normalizedChapter, candidate);
      final hasHumanContext =
          FragmentInferenceUtils.hasHumanContext(chapterText, candidate) ||
              FragmentInferenceUtils.hasDirectPresentationContext(
                chapterText,
                candidate,
              );
      if (occurrences < 2 && !hasHumanContext) {
        continue;
      }

      final chapterStrength = FragmentInferenceUtils.computeCharacterStrength(
        name: candidate,
        context: chapterText,
      );
      if (chapterStrength < 4) {
        continue;
      }
      final isSingleWord = !candidate.contains(' ');
      if (isSingleWord && !hasHumanContext) {
        continue;
      }
      if (isSingleWord && chapterStrength < 6) {
        continue;
      }

      inferredChapterCharacters.add(
        DetectedCharacter(
          name: candidate,
          summary: hasHumanContext
              ? 'Gana presencia clara en el capítulo'
              : 'Reaparece con peso suficiente en el capítulo',
          relevanceScore:
              occurrences + chapterStrength + (hasHumanContext ? 2 : 0),
          strengthScore: chapterStrength,
        ),
      );
    }

    for (final candidate in inferredChapterCharacters) {
      _addCharacterCandidate(
        clusters: clusters,
        candidate: candidate,
        fragmentIndex: 1,
        isBoundary: false,
        chapterBoost: candidate.relevanceScore,
      );
    }

    final resolved = clusters
        .map(
          (cluster) => DetectedCharacter(
            name: cluster.bestName,
            summary: _buildCharacterSummary(cluster, charactersById),
            existingCharacterId: cluster.existingCharacterId,
            isAlreadyLinked: cluster.existingCharacterId != null &&
                linkedCharacterIds.contains(cluster.existingCharacterId),
            relevanceScore: cluster.maxRelevanceScore,
            strengthScore: cluster.maxStrengthScore,
            aggregateScore: cluster.totalScore,
            isIdentityUpgrade: cluster.hasIdentityUpgrade,
          ),
        )
        .where(
          (candidate) => _shouldSurfaceChapterCharacter(
            candidate: candidate,
            cluster: clusters.firstWhere(
              (item) => FragmentInferenceUtils.isSameCharacter(
                item.bestName,
                candidate.name,
              ),
            ),
          ),
        )
        .toList();

    resolved.sort((a, b) {
      final aggregateCompare = b.aggregateScore.compareTo(a.aggregateScore);
      if (aggregateCompare != 0) return aggregateCompare;
      return b.name.length.compareTo(a.name.length);
    });

    return fragmentAnalysisService
        .resolveCharacterDuplicates(resolved)
        .take(3)
        .toList();
  }

  bool _looksLikeChapterOrganization(String chapterText, String name) {
    return FragmentInferenceUtils.looksLikeOrganizationName(name) ||
        FragmentInferenceUtils.appearsInOrganizationContext(chapterText, name);
  }

  void _addCharacterCandidate({
    required List<_CharacterCluster> clusters,
    required DetectedCharacter candidate,
    required int fragmentIndex,
    required bool isBoundary,
    int narratorBoost = 0,
    int chapterBoost = 0,
  }) {
    final cluster = clusters.cast<_CharacterCluster?>().firstWhere(
          (item) =>
              item != null &&
              FragmentInferenceUtils.isSameCharacter(
                  item.bestName, candidate.name),
          orElse: () => null,
        );

    final chapterWeight = (chapterBoost / 2).round().clamp(0, 6);
    final score = candidate.strengthScore +
        candidate.relevanceScore +
        1 +
        narratorBoost +
        chapterWeight;
    if (cluster == null) {
      clusters.add(
        _CharacterCluster(
          bestName: candidate.name,
          existingCharacterId: candidate.existingCharacterId,
          totalScore: score + (isBoundary ? 2 : 0),
          fragments: 1,
          firstFragmentIndex: fragmentIndex,
          lastFragmentIndex: fragmentIndex,
          hasIdentityUpgrade: candidate.isIdentityUpgrade,
          wasLinked: candidate.isAlreadyLinked,
          hasNarratorSupport: narratorBoost > 0,
          maxStrengthScore: candidate.strengthScore,
          maxRelevanceScore: candidate.relevanceScore,
          chapterScore: chapterBoost,
        ),
      );
      return;
    }

    if (candidate.name.length > cluster.bestName.length ||
        candidate.strengthScore > cluster.maxStrengthScore) {
      cluster.bestName = candidate.name;
    }
    cluster.existingCharacterId ??= candidate.existingCharacterId;
    cluster.totalScore += score + (isBoundary ? 2 : 0);
    cluster.fragments += 1;
    cluster.lastFragmentIndex = fragmentIndex;
    cluster.hasIdentityUpgrade =
        cluster.hasIdentityUpgrade || candidate.isIdentityUpgrade;
    cluster.wasLinked = cluster.wasLinked || candidate.isAlreadyLinked;
    cluster.hasNarratorSupport =
        cluster.hasNarratorSupport || narratorBoost > 0;
    if (chapterBoost > cluster.chapterScore) {
      cluster.chapterScore = chapterBoost;
    }
    if (candidate.strengthScore > cluster.maxStrengthScore) {
      cluster.maxStrengthScore = candidate.strengthScore;
    }
    if (candidate.relevanceScore > cluster.maxRelevanceScore) {
      cluster.maxRelevanceScore = candidate.relevanceScore;
    }
  }

  String _buildCharacterSummary(
    _CharacterCluster cluster,
    Map<String, Character> charactersById,
  ) {
    final parts = <String>[];
    if (cluster.hasNarratorSupport) {
      parts.add('Sostiene la mirada del capítulo');
    } else if (cluster.fragments >= 3) {
      parts.add('Presencia sostenida en el capítulo');
    } else {
      parts.add('Figura relevante en varios momentos');
    }
    if (cluster.firstFragmentIndex == 0 || cluster.lastFragmentIndex > 0) {
      if (cluster.firstFragmentIndex == 0 && cluster.lastFragmentIndex > 0) {
        parts.add('entra pronto y sigue presente');
      } else if (cluster.lastFragmentIndex > cluster.firstFragmentIndex) {
        parts.add('gana peso hacia el final');
      }
    }

    final existing = cluster.existingCharacterId == null
        ? null
        : charactersById[cluster.existingCharacterId!];
    if (existing?.isProtagonist == true &&
        !parts.contains('Sostiene la mirada del capítulo')) {
      parts.insert(0, 'La protagonista ordena el capítulo');
    } else if (cluster.fragments >= 3 && cluster.maxStrengthScore >= 4) {
      parts.insert(0, 'Acompaña el capítulo con peso propio');
    } else if (cluster.fragments >= 2 && cluster.maxStrengthScore >= 3) {
      parts.insert(0, 'Gana presencia clara en el capítulo');
    }

    return parts.take(2).join(' · ');
  }

  bool _shouldSurfaceChapterCharacter({
    required DetectedCharacter candidate,
    required _CharacterCluster cluster,
  }) {
    if (fragmentAnalysisService.shouldSurfaceCharacter(candidate)) {
      return true;
    }

    if (cluster.hasNarratorSupport) {
      return true;
    }

    if (cluster.fragments >= 2 && cluster.chapterScore >= 4) {
      return true;
    }

    if (candidate.existingCharacterId != null &&
        cluster.fragments >= 2 &&
        cluster.maxStrengthScore >= 3) {
      return true;
    }

    if (candidate.existingCharacterId != null &&
        cluster.chapterScore >= 6 &&
        cluster.maxStrengthScore >= 3) {
      return true;
    }

    if (cluster.chapterScore >= 6 && candidate.aggregateScore >= 7) {
      return true;
    }

    return false;
  }

  List<CharacterDevelopment> _resolveCharacterDevelopments({
    required String chapterText,
    required List<FragmentAnalysis> fragments,
    required List<Character> characters,
    required List<DetectedCharacter> mainCharacters,
    required NarrativeMoment dominantMoment,
  }) {
    final normalized = ' ${chapterText.toLowerCase()} ';
    final charactersById = {for (final item in characters) item.id: item};
    final developments = <CharacterDevelopment>[];

    for (final character in mainCharacters) {
      final metrics = _collectCharacterMetrics(
        name: character.name,
        fragments: fragments,
      );
      final existing = character.existingCharacterId == null
          ? null
          : charactersById[character.existingCharacterId!];
      final isProtagonist =
          existing?.isProtagonist == true || metrics.narratorHits > 0;
      final introspectionSignals = _countSignals(normalized, <String>[
        ' pensé ',
        ' sentí ',
        ' no podía concentrarme ',
        ' procesando ',
        ' no sabía ',
        ' no tenía ganas ',
        ' me acompaña ',
        ' me está esperando ',
      ]);
      final conflictSignals = _countSignals(normalized, <String>[
        ' ansiedad ',
        ' insomnio ',
        ' no podía ',
        ' sombra ',
        ' símbolo ',
        ' miedo ',
        ' tensión ',
      ]);

      if (isProtagonist &&
          introspectionSignals >= 2 &&
          dominantMoment.title != 'Rutina de redacción') {
        developments.add(
          CharacterDevelopment(
            characterIdOrName: character.existingCharacterId ?? character.name,
            label: character.name,
            summary: 'La protagonista refuerza su voz interior aquí.',
            type: CharacterDevelopmentType.voice_definition,
            score: 10 + introspectionSignals,
          ),
        );
      }

      if (metrics.maxStrength >= metrics.firstStrength + 3 ||
          metrics.hasIdentityUpgrade ||
          (character.existingCharacterId == null &&
              metrics.fragmentHits >= 2 &&
              metrics.maxStrength >= 5)) {
        developments.add(
          CharacterDevelopment(
            characterIdOrName: character.existingCharacterId ?? character.name,
            label: character.name,
            summary: existing == null
                ? '${character.name} deja de ser lateral y gana relevancia.'
                : '${character.name} gana una definición más clara aquí.',
            type: existing == null
                ? CharacterDevelopmentType.new_relevance
                : CharacterDevelopmentType.identity_gain,
            score: 9 + metrics.maxStrength,
          ),
        );
      }

      if (!isProtagonist &&
          existing != null &&
          metrics.fragmentHits >= 2 &&
          metrics.maxStrength >= 3) {
        developments.add(
          CharacterDevelopment(
            characterIdOrName: existing.id,
            label: existing.displayName,
            summary:
                '${existing.displayName} aparece aquí con una función más nítida.',
            type: CharacterDevelopmentType.role_reinforcement,
            score: 7 + metrics.fragmentHits + metrics.maxStrength,
          ),
        );
      }

      if (isProtagonist && conflictSignals >= 3) {
        developments.add(
          CharacterDevelopment(
            characterIdOrName: character.existingCharacterId ?? character.name,
            label: character.name,
            summary:
                'Aquí se marca mejor la presión interna de la protagonista.',
            type: CharacterDevelopmentType.conflict_signal,
            score: 8 + conflictSignals,
          ),
        );
      }
    }

    final deduped = <CharacterDevelopment>[];
    for (final item in developments
      ..sort((a, b) => b.score.compareTo(a.score))) {
      final existing = deduped.cast<CharacterDevelopment?>().firstWhere(
            (candidate) =>
                candidate?.characterIdOrName == item.characterIdOrName,
            orElse: () => null,
          );
      if (existing == null) {
        deduped.add(item);
        continue;
      }
      if (item.score > existing.score) {
        deduped
          ..remove(existing)
          ..add(item);
      }
    }

    deduped.sort((a, b) => b.score.compareTo(a.score));
    return deduped.take(3).toList();
  }

  List<ScenarioDevelopment> _resolveScenarioDevelopments({
    required String chapterText,
    required List<FragmentAnalysis> fragments,
    required DetectedScenario? mainScenario,
  }) {
    if (mainScenario == null) {
      return const [];
    }

    final normalized = ' ${chapterText.toLowerCase()} ';
    final atmosphereSignals = _countSignals(normalized, <String>[
      ' frío ',
      ' gris',
      ' ruido ',
      ' tenso ',
      ' silencio ',
      ' sombra ',
      ' oscuro ',
      ' recalentado ',
    ]);
    final functionSignals = _countSignals(normalized, <String>[
      ' oficina ',
      ' redacción ',
      ' escena de crimen ',
      ' apartamento ',
      ' estudio ',
      ' refugio ',
      ' investigación ',
      ' presión ',
    ]);
    final scenarioHits =
        fragments.where((item) => item.scenario != null).length;

    if (mainScenario.isIdentityUpgrade ||
        mainScenario.aggregateScore >= 10 ||
        (scenarioHits >= 2 &&
            (atmosphereSignals >= 2 || functionSignals >= 2))) {
      return <ScenarioDevelopment>[
        ScenarioDevelopment(
          scenarioIdOrName:
              mainScenario.existingScenarioId ?? mainScenario.name,
          label: mainScenario.name,
          summary: _inferScenarioDevelopmentSummary(
            scenario: mainScenario,
            atmosphereSignals: atmosphereSignals,
            functionSignals: functionSignals,
            scenarioHits: scenarioHits,
          ),
          type: _inferScenarioDevelopmentType(
            scenario: mainScenario,
            atmosphereSignals: atmosphereSignals,
            functionSignals: functionSignals,
            scenarioHits: scenarioHits,
          ),
          score:
              mainScenario.aggregateScore + atmosphereSignals + functionSignals,
        ),
      ];
    }

    return const [];
  }

  ScenarioDevelopmentType _inferScenarioDevelopmentType({
    required DetectedScenario scenario,
    required int atmosphereSignals,
    required int functionSignals,
    required int scenarioHits,
  }) {
    if (scenario.isIdentityUpgrade) {
      return ScenarioDevelopmentType.identity_gain;
    }
    if (functionSignals >= atmosphereSignals && scenarioHits >= 2) {
      return ScenarioDevelopmentType.function_definition;
    }
    if (atmosphereSignals >= 2) {
      return ScenarioDevelopmentType.atmosphere_gain;
    }
    return ScenarioDevelopmentType.narrative_relevance_increase;
  }

  String _inferScenarioDevelopmentSummary({
    required DetectedScenario scenario,
    required int atmosphereSignals,
    required int functionSignals,
    required int scenarioHits,
  }) {
    final lower = scenario.name.toLowerCase();
    if (lower.contains('apartamento') || lower.contains('estudio')) {
      return 'Aquí el lugar gana forma de refugio precario e íntimo.';
    }
    if (lower.contains('redacción') || lower.contains('oficina')) {
      return 'Aquí el espacio de trabajo se define como presión y rutina.';
    }
    if (lower.contains('callejón') || lower.contains('crimen')) {
      return 'Aquí el lugar se consolida como foco de investigación.';
    }
    if (functionSignals >= atmosphereSignals && scenarioHits >= 2) {
      return 'Aquí el escenario deja de ser fondo y gana función narrativa.';
    }
    return 'Aquí el escenario se vuelve más importante y reconocible.';
  }

  ChapterTrajectory? _resolveTrajectory(List<FragmentAnalysis> fragments) {
    if (fragments.length < 2) {
      return null;
    }

    final startLabel = _trajectoryLabelForMoment(fragments.first.moment.title);
    final middleLabel = _trajectoryLabelForMoment(
        fragments[fragments.length ~/ 2].moment.title);
    final endLabel = _trajectoryLabelForMoment(fragments.last.moment.title);

    final distinct = <String>{startLabel, middleLabel, endLabel};
    if (distinct.length < 2) {
      return null;
    }

    if (distinct.length == 2 && startLabel == endLabel) {
      return null;
    }

    return ChapterTrajectory(
      startLabel: startLabel,
      middleLabel: middleLabel,
      endLabel: endLabel,
      summary: '$startLabel > $middleLabel > $endLabel',
    );
  }

  String _trajectoryLabelForMoment(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('rutina') || normalized.contains('redacción')) {
      return 'rutina';
    }
    if (normalized.contains('íntima') || normalized.contains('soledad')) {
      return 'intimidad';
    }
    if (normalized.contains('tensión')) {
      return 'inquietud';
    }
    if (normalized.contains('crimen')) {
      return 'presión';
    }
    if (normalized.contains('investigación') ||
        normalized.contains('indicios')) {
      return 'investigación';
    }
    return 'observación';
  }

  DetectedScenario? _resolveMainScenario({
    required List<FragmentAnalysis> fragments,
    required List<Scenario> scenarios,
    required List<String> linkedScenarioIds,
  }) {
    final clusters = <_ScenarioCluster>[];
    for (var index = 0; index < fragments.length; index++) {
      final candidate = fragments[index].scenario;
      if (candidate == null) {
        continue;
      }

      final existing = clusters.cast<_ScenarioCluster?>().firstWhere(
            (item) =>
                item != null &&
                FragmentInferenceUtils.isSameScenario(
                    item.bestName, candidate.name),
            orElse: () => null,
          );
      final score = candidate.strengthScore + candidate.priorityScore + 1;
      if (existing == null) {
        clusters.add(
          _ScenarioCluster(
            bestName: candidate.name,
            summarySeed: candidate.summary,
            existingScenarioId: candidate.existingScenarioId,
            totalScore:
                score + (index == 0 || index == fragments.length - 1 ? 2 : 0),
            fragments: 1,
            firstFragmentIndex: index,
            lastFragmentIndex: index,
            isBroad:
                FragmentInferenceUtils.isBroadGeographicContext(candidate.name),
            hasIdentityUpgrade: candidate.isIdentityUpgrade,
            maxStrengthScore: candidate.strengthScore,
          ),
        );
        continue;
      }

      if (!FragmentInferenceUtils.isBroadGeographicContext(candidate.name) &&
          (existing.isBroad ||
              candidate.name.length > existing.bestName.length)) {
        existing.bestName = candidate.name;
        existing.isBroad = false;
        existing.summarySeed = candidate.summary;
      }
      existing.existingScenarioId ??= candidate.existingScenarioId;
      existing.totalScore +=
          score + (index == 0 || index == fragments.length - 1 ? 2 : 0);
      existing.fragments += 1;
      existing.lastFragmentIndex = index;
      existing.hasIdentityUpgrade =
          existing.hasIdentityUpgrade || candidate.isIdentityUpgrade;
      if (candidate.strengthScore > existing.maxStrengthScore) {
        existing.maxStrengthScore = candidate.strengthScore;
      }
    }

    if (clusters.isEmpty) {
      return null;
    }

    clusters.sort((a, b) {
      final fragmentCompare = b.fragments.compareTo(a.fragments);
      if (fragmentCompare != 0) return fragmentCompare;
      final scoreCompare = b.totalScore.compareTo(a.totalScore);
      if (scoreCompare != 0) return scoreCompare;
      return b.lastFragmentIndex.compareTo(a.lastFragmentIndex);
    });
    var best = clusters.first;
    if (best.isBroad) {
      final concreteAlternative = clusters.firstWhere(
        (item) => !item.isBroad && item.totalScore >= best.totalScore - 3,
        orElse: () => best,
      );
      best = concreteAlternative;
    }

    final sustainedAlternative = clusters.firstWhere(
      (item) =>
          item != best &&
          !item.isBroad &&
          item.fragments >= best.fragments &&
          item.lastFragmentIndex > best.lastFragmentIndex &&
          item.totalScore >= best.totalScore - 2,
      orElse: () => best,
    );
    best = sustainedAlternative;

    final scenario = DetectedScenario(
      name: best.bestName,
      summary: best.fragments >= 3
          ? 'Sostiene la atmósfera del capítulo'
          : 'Marca el espacio dominante del capítulo',
      existingScenarioId: best.existingScenarioId,
      isAlreadyLinked: best.existingScenarioId != null &&
          linkedScenarioIds.contains(best.existingScenarioId),
      priorityScore: best.totalScore,
      strengthScore: best.maxStrengthScore,
      aggregateScore: best.totalScore,
      isIdentityUpgrade: best.hasIdentityUpgrade,
    );

    if (!fragmentAnalysisService.shouldSurfaceScenario(scenario)) {
      return null;
    }

    final exactMatch = scenarios.cast<Scenario?>().firstWhere(
          (item) =>
              item != null &&
              FragmentInferenceUtils.isSameScenario(
                  item.displayName, scenario.name),
          orElse: () => null,
        );

    if (exactMatch == null) {
      return scenario;
    }

    return DetectedScenario(
      name: FragmentInferenceUtils.isBroadGeographicContext(scenario.name)
          ? exactMatch.displayName
          : scenario.name,
      summary: scenario.summary,
      existingScenarioId: exactMatch.id,
      isAlreadyLinked: linkedScenarioIds.contains(exactMatch.id),
      priorityScore: scenario.priorityScore,
      strengthScore: scenario.strengthScore,
      aggregateScore: scenario.aggregateScore,
      isIdentityUpgrade:
          scenario.name.toLowerCase() != exactMatch.displayName.toLowerCase(),
    );
  }

  _MomentResolution _resolveNarrativeMoments({
    required String chapterText,
    required List<FragmentAnalysis> fragments,
  }) {
    final moments = <_MomentCluster>[];
    final normalized = ' ${chapterText.toLowerCase()} ';
    final subtextSignals = _countSignals(normalized, <String>[
      ' símbolo ',
      ' sombra ',
      ' no todavía ',
      ' no aún ',
      ' procesando ',
      ' no podía concentrarme ',
      ' me acompaña ',
      ' me está esperando ',
    ]);
    for (var index = 0; index < fragments.length; index++) {
      final moment = fragments[index].moment;
      final existing = moments.cast<_MomentCluster?>().firstWhere(
            (item) => item != null && item.title == moment.title,
            orElse: () => null,
          );
      final score = 2 +
          (index == 0 || index == fragments.length - 1 ? 1 : 0) +
          _momentPriorityBoost(
            title: moment.title,
            subtextSignals: subtextSignals,
          );
      if (existing == null) {
        moments.add(
          _MomentCluster(
            title: moment.title,
            summary: moment.summary,
            score: score,
            hits: 1,
          ),
        );
        continue;
      }
      existing.score += score;
      existing.hits += 1;
    }

    moments.sort((a, b) => b.score.compareTo(a.score));
    if (moments.isNotEmpty &&
        moments.first.title == 'Rutina de redacción' &&
        subtextSignals >= 2) {
      final subtextAlternative = moments.cast<_MomentCluster?>().firstWhere(
            (item) =>
                item != null &&
                _isSubtextMoment(item.title) &&
                item.score >= moments.first.score - 2,
            orElse: () => null,
          );
      if (subtextAlternative != null) {
        moments
          ..remove(subtextAlternative)
          ..insert(0, subtextAlternative);
      }
    }

    final resolved = moments
        .take(3)
        .map(
          (item) => NarrativeMoment(
            title: item.title,
            summary: item.summary,
          ),
        )
        .toList();

    final dominant = resolved.isNotEmpty
        ? resolved.first
        : const NarrativeMoment(
            title: 'Recogida de indicios',
            summary: 'El capítulo ordena señales antes de avanzar.',
          );

    return _MomentResolution(
      dominant: dominant,
      moments: resolved.isEmpty ? <NarrativeMoment>[dominant] : resolved,
    );
  }

  int _momentPriorityBoost({
    required String title,
    required int subtextSignals,
  }) {
    if (_isSubtextMoment(title)) {
      return subtextSignals >= 2 ? 2 : 1;
    }
    if (title == 'Inicio de investigación' || title == 'Tensión contenida') {
      return 1;
    }
    return 0;
  }

  bool _isSubtextMoment(String title) {
    return title == 'Procesamiento en soledad' ||
        title == 'Rutina con tensión de fondo' ||
        title == 'Pausa con subtexto' ||
        title == 'Tensión contenida';
  }

  ChapterFunction _resolveChapterFunction({
    required String chapterText,
    required List<FragmentAnalysis> fragments,
    required List<DetectedCharacter> mainCharacters,
    required DetectedScenario? mainScenario,
    required NarrativeMoment dominantMoment,
  }) {
    final normalized = ' ${chapterText.toLowerCase()} ';
    final protagonistPresence = _countProtagonistPresence(
      fragments: fragments,
      mainCharacters: mainCharacters,
    );
    final reflectionSignals = _countSignals(normalized, <String>[
      ' pensé ',
      ' sentí ',
      ' recordé ',
      ' me pregunté ',
      ' quería ',
      ' sabía ',
      ' silencio ',
      ' sola ',
      ' observé ',
      ' dudé ',
    ]);
    final actionSignals = _countSignals(normalized, <String>[
      ' investigar ',
      ' busqué ',
      ' buscar ',
      ' pista ',
      ' indicio ',
      ' seguí ',
      ' corrí ',
      ' abrí ',
      ' entré ',
      ' policía ',
      ' sangre ',
      ' grito ',
    ]);
    final discoverySignals = _countSignals(normalized, <String>[
      ' descubr',
      ' encontr',
      ' revel',
      ' entend',
      ' confirmé ',
      ' por fin ',
    ]);
    final conflictSignals = _countSignals(normalized, <String>[
      ' miedo ',
      ' amenaza ',
      ' sangre ',
      ' policía ',
      ' tensión ',
      ' grito ',
      ' cuerpo ',
      ' crimen ',
    ]);
    final questionSignals = RegExp(r'[?¿]').allMatches(chapterText).length;
    final transitionSignals = _countSignals(normalized, <String>[
      ' luego ',
      ' después ',
      ' al salir ',
      ' de vuelta ',
      ' más tarde ',
      ' crucé ',
      ' camino por ',
    ]);
    final newStrongCharacters = mainCharacters
        .where(
            (item) => item.existingCharacterId == null || !item.isAlreadyLinked)
        .length;
    final momentTitle = dominantMoment.title.toLowerCase();

    if ((momentTitle.contains('procesamiento') ||
            momentTitle.contains('rutina íntima') ||
            momentTitle.contains('rutina con tensión')) &&
        protagonistPresence >= 2 &&
        reflectionSignals >= actionSignals) {
      return ChapterFunction.character_building;
    }

    if ((momentTitle.contains('tensión') ||
            momentTitle.contains('escena de crimen')) &&
        conflictSignals >= 2) {
      return ChapterFunction.escalation;
    }

    if (discoverySignals >= 2 ||
        (momentTitle.contains('investigación') && questionSignals >= 3)) {
      return ChapterFunction.discovery;
    }

    if (transitionSignals >= 2 && mainScenario != null && actionSignals > 0) {
      return ChapterFunction.transition;
    }

    if (newStrongCharacters > 0 ||
        (momentTitle.contains('investigación') && questionSignals >= 1)) {
      return ChapterFunction.setup;
    }

    if (mainCharacters.length <= 1 &&
        protagonistPresence >= 2 &&
        reflectionSignals > 0 &&
        actionSignals == 0) {
      return ChapterFunction.introduction;
    }

    return ChapterFunction.development;
  }

  int _countProtagonistPresence({
    required List<FragmentAnalysis> fragments,
    required List<DetectedCharacter> mainCharacters,
  }) {
    final protagonist = mainCharacters.cast<DetectedCharacter?>().firstWhere(
          (item) =>
              item?.existingCharacterId != null &&
              item!.summary.contains('protagonista'),
          orElse: () => null,
        );
    final narratorHits =
        fragments.where((item) => item.narrator != null).length;
    return (protagonist != null ? 2 : 0) + narratorHits;
  }

  int _countSignals(String normalized, List<String> signals) {
    var total = 0;
    for (final signal in signals) {
      total += RegExp(RegExp.escape(signal.trim()), caseSensitive: false)
          .allMatches(normalized)
          .length;
    }
    return total;
  }

  int _countCharacterMentionsInChapter(String normalized, String value) {
    final escaped = RegExp.escape(value.toLowerCase());
    final pattern = RegExp('(^|[^a-záéíóúñü])$escaped([^a-záéíóúñü]|\$)');
    return pattern.allMatches(normalized).length;
  }

  ChapterRecommendation? _buildRecommendation({
    required String chapterText,
    required List<FragmentAnalysis> fragments,
    required List<DetectedCharacter> mainCharacters,
    required DetectedScenario? mainScenario,
    required ChapterFunction chapterFunction,
    required List<CharacterDevelopment> characterDevelopments,
    required List<ScenarioDevelopment> scenarioDevelopments,
    required ChapterTrajectory? trajectory,
  }) {
    final topCharacterDevelopment =
        characterDevelopments.isEmpty ? null : characterDevelopments.first;
    final topScenarioDevelopment =
        scenarioDevelopments.isEmpty ? null : scenarioDevelopments.first;
    final signals = _buildChapterDecisionSignals(
      chapterText: chapterText,
      analysis: ChapterAnalysis(
        mainCharacters: mainCharacters,
        mainScenario: mainScenario,
        narrativeMoments: const [],
        dominantNarrativeMoment: fragments.isEmpty
            ? const NarrativeMoment(
                title: 'Recogida de indicios',
                summary: 'El capítulo ordena señales antes de avanzar.',
              )
            : fragments.first.moment,
        chapterFunction: chapterFunction,
        characterDevelopments: characterDevelopments,
        scenarioDevelopments: scenarioDevelopments,
        trajectory: trajectory,
      ),
    );

    if (topCharacterDevelopment != null &&
        topCharacterDevelopment.type ==
            CharacterDevelopmentType.new_relevance) {
      return ChapterRecommendation(
        message:
            'Aquí merece la pena consolidar a ${topCharacterDevelopment.label} como figura clave.',
      );
    }

    if (topCharacterDevelopment != null &&
        (topCharacterDevelopment.type ==
                CharacterDevelopmentType.role_reinforcement ||
            topCharacterDevelopment.type ==
                CharacterDevelopmentType.identity_gain) &&
        topCharacterDevelopment.score >= 10) {
      return ChapterRecommendation(
        message:
            '${topCharacterDevelopment.label} gana relieve suficiente como para trabajarla mejor en este capítulo.',
      );
    }

    if (topScenarioDevelopment != null &&
        (topScenarioDevelopment.type == ScenarioDevelopmentType.identity_gain ||
            topScenarioDevelopment.type ==
                ScenarioDevelopmentType.function_definition)) {
      return ChapterRecommendation(
        message:
            'Este capítulo define bien ${_withArticle(topScenarioDevelopment.label)}; conviene fijarlo como escenario importante.',
      );
    }

    if (chapterFunction == ChapterFunction.character_building &&
        topCharacterDevelopment != null &&
        signals.actionSignals < 2) {
      return const ChapterRecommendation(
        message:
            'La protagonista gana peso interior, pero el conflicto aún avanza poco.',
      );
    }

    if (trajectory != null &&
        trajectory.endLabel == 'investigación' &&
        chapterFunction != ChapterFunction.discovery) {
      return const ChapterRecommendation(
        message:
            'Conviene conectar este capítulo un poco más con la línea de investigación.',
      );
    }

    if (topCharacterDevelopment != null &&
        topCharacterDevelopment.type ==
            CharacterDevelopmentType.voice_definition &&
        signals.actionSignals < 2) {
      return const ChapterRecommendation(
        message:
            'La protagonista gana peso interior, pero el conflicto aún avanza poco.',
      );
    }

    return null;
  }

  ChapterNextStep? _resolveNextStep({
    required String chapterText,
    required ChapterAnalysis analysis,
  }) {
    final sourceLanguage = _inferSourceLanguage(chapterText);
    final topCharacterDevelopment = analysis.characterDevelopments.isEmpty
        ? null
        : analysis.characterDevelopments.first;
    final topScenarioDevelopment = analysis.scenarioDevelopments.isEmpty
        ? null
        : analysis.scenarioDevelopments.first;
    final signals = _buildChapterDecisionSignals(
      chapterText: chapterText,
      analysis: analysis,
    );
    final structuralCharacterDevelopment = topCharacterDevelopment != null &&
        (topCharacterDevelopment.type ==
                CharacterDevelopmentType.identity_gain ||
            topCharacterDevelopment.type ==
                CharacterDevelopmentType.new_relevance ||
            topCharacterDevelopment.type ==
                CharacterDevelopmentType.role_reinforcement) &&
        topCharacterDevelopment.score >= 10;
    final strongestNewCharacter =
        analysis.mainCharacters.cast<DetectedCharacter?>().firstWhere(
              (item) =>
                  item != null &&
                  item.existingCharacterId == null &&
                  item.aggregateScore >= 10,
              orElse: () => null,
            );
    final existingMainScenario =
        analysis.mainScenario?.existingScenarioId != null;
    final repeatedAtmosphereScenarioPush = existingMainScenario &&
        topScenarioDevelopment?.type ==
            ScenarioDevelopmentType.atmosphere_gain &&
        (analysis.chapterFunction == ChapterFunction.character_building ||
            analysis.chapterFunction == ChapterFunction.introduction ||
            analysis.chapterFunction == ChapterFunction.development);
    final structuralScenarioDevelopment = topScenarioDevelopment != null &&
        topScenarioDevelopment.score >= 14 &&
        !repeatedAtmosphereScenarioPush &&
        topScenarioDevelopment.type !=
            ScenarioDevelopmentType.narrative_relevance_increase;

    if (structuralCharacterDevelopment) {
      final characterDevelopment = topCharacterDevelopment;
      final existingCharacter =
          analysis.mainCharacters.cast<DetectedCharacter?>().firstWhere(
                (item) =>
                    item != null &&
                    (item.existingCharacterId ==
                            characterDevelopment.characterIdOrName ||
                        item.name == characterDevelopment.label),
                orElse: () => null,
              );
      final isExisting = existingCharacter?.existingCharacterId != null;
      return ChapterNextStep(
        label: isExisting
            ? 'Da más forma a ${characterDevelopment.label}'
            : 'Consolida a ${characterDevelopment.label} como personaje',
        actionLabel: isExisting ? 'Enriquecer personaje' : 'Crear personaje',
        type: isExisting
            ? NextStepType.enrichCharacter
            : NextStepType.createCharacter,
        targetId: existingCharacter?.existingCharacterId,
        entityName: characterDevelopment.label,
      );
    }

    if (strongestNewCharacter != null) {
      return ChapterNextStep(
        label: 'Consolida a ${strongestNewCharacter.name} como personaje',
        actionLabel: 'Crear personaje',
        type: NextStepType.createCharacter,
        entityName: strongestNewCharacter.name,
      );
    }

    final scenarioDevelopmentScore = topScenarioDevelopment?.score ?? 0;
    final characterDevelopmentScore = topCharacterDevelopment?.score ?? 0;
    final dominantMomentTitle =
        analysis.dominantNarrativeMoment.title.toLowerCase();
    final dominantMomentSummary =
        analysis.dominantNarrativeMoment.summary.toLowerCase();
    final hasCrimeSceneSignals = dominantMomentTitle.contains('crimen') ||
        dominantMomentTitle.contains('escena de crimen') ||
        dominantMomentSummary.contains('observación e inquietud') ||
        dominantMomentSummary.contains('vacío de respuestas') ||
        dominantMomentSummary.contains('investigación');
    final hasExpandMomentSignals = (dominantMomentTitle.contains('investig') ||
            dominantMomentTitle.contains('indicios') ||
            dominantMomentTitle.contains('tensión') ||
            dominantMomentTitle.contains('crimen') ||
            dominantMomentSummary.contains('observación') ||
            dominantMomentSummary.contains('inquietud') ||
            hasCrimeSceneSignals ||
            analysis.chapterFunction == ChapterFunction.discovery ||
            analysis.chapterFunction == ChapterFunction.escalation) &&
        !structuralCharacterDevelopment &&
        !signals.needsPlotConnection;
    final shouldPrioritizeExpandMoment = hasExpandMomentSignals &&
        (hasCrimeSceneSignals ||
            dominantMomentTitle.contains('indicios') ||
            analysis.chapterFunction == ChapterFunction.escalation);

    if (shouldPrioritizeExpandMoment) {
      final step = ChapterNextStep(
        label: sourceLanguage == 'Spanish'
            ? 'Desarrolla este momento'
            : 'Develop this moment',
        actionLabel:
            sourceLanguage == 'Spanish' ? 'Ver sugerencia' : 'View suggestion',
        type: NextStepType.expandMoment,
      );
      return ChapterNextStep(
        label: step.label,
        actionLabel: step.actionLabel,
        type: step.type,
        entityName: step.entityName,
        exampleText: buildNextStepExample(
          type: step.type,
          analysis: analysis,
          sourceLanguage: sourceLanguage,
        ),
      );
    }

    if (structuralScenarioDevelopment &&
        (!structuralCharacterDevelopment ||
            scenarioDevelopmentScore >= characterDevelopmentScore + 2) &&
        analysis.mainScenario != null) {
      final isExisting = analysis.mainScenario!.existingScenarioId != null;
      final candidate = ChapterNextStep(
        label: isExisting
            ? 'Da más forma a ${analysis.mainScenario!.name}'
            : 'Fija ${analysis.mainScenario!.name} como escenario',
        actionLabel: isExisting ? 'Enriquecer escenario' : 'Crear escenario',
        type: isExisting
            ? NextStepType.enrichScenario
            : NextStepType.createScenario,
        targetId: analysis.mainScenario!.existingScenarioId,
        entityName: analysis.mainScenario!.name,
      );
      final exampleText = candidate.type == NextStepType.enrichScenario &&
              topScenarioDevelopment.type ==
                  ScenarioDevelopmentType.atmosphere_gain
          ? buildNextStepExample(
              type: candidate.type,
              analysis: analysis,
              sourceLanguage: sourceLanguage,
            )
          : null;
      return ChapterNextStep(
        label: candidate.label,
        actionLabel: candidate.actionLabel,
        type: candidate.type,
        targetId: candidate.targetId,
        entityName: candidate.entityName,
        exampleText: exampleText,
      );
    }

    final shouldPreferEmergingPattern = signals.hasEmergingPattern &&
        !signals.hasStrongConflict &&
        !structuralCharacterDevelopment &&
        !structuralScenarioDevelopment;
    if (shouldPreferEmergingPattern) {
      final step = ChapterNextStep(
        label: sourceLanguage == 'Spanish'
            ? 'Desarrolla este momento'
            : 'Develop this moment',
        actionLabel:
            sourceLanguage == 'Spanish' ? 'Ver sugerencia' : 'View suggestion',
        type: NextStepType.expandMoment,
      );
      return ChapterNextStep(
        label: step.label,
        actionLabel: step.actionLabel,
        type: step.type,
        entityName: step.entityName,
        exampleText: buildNextStepExample(
          type: step.type,
          analysis: analysis,
          sourceLanguage: sourceLanguage,
        ),
      );
    }

    final needsConflictPush =
        (analysis.chapterFunction == ChapterFunction.character_building ||
                analysis.chapterFunction == ChapterFunction.introduction) &&
            topCharacterDevelopment != null &&
            (topCharacterDevelopment.type ==
                    CharacterDevelopmentType.voice_definition ||
                topCharacterDevelopment.type ==
                    CharacterDevelopmentType.conflict_signal) &&
            signals.needsConflictPush &&
            !structuralCharacterDevelopment &&
            !structuralScenarioDevelopment;
    if (needsConflictPush) {
      final step = ChapterNextStep(
        label: sourceLanguage == 'Spanish'
            ? 'Refuerza el conflicto del capítulo'
            : 'Strengthen the chapter conflict',
        actionLabel:
            sourceLanguage == 'Spanish' ? 'Ver sugerencia' : 'View suggestion',
        type: NextStepType.strengthenConflict,
      );
      return ChapterNextStep(
        label: step.label,
        actionLabel: step.actionLabel,
        type: step.type,
        entityName: step.entityName,
        exampleText: buildNextStepExample(
          type: step.type,
          analysis: analysis,
          sourceLanguage: sourceLanguage,
        ),
      );
    }

    final needsPlotConnection = signals.needsPlotConnection;
    if (needsPlotConnection) {
      final step = ChapterNextStep(
        label: sourceLanguage == 'Spanish'
            ? 'Conecta este capítulo con la trama principal'
            : 'Connect this chapter to the main plot',
        actionLabel:
            sourceLanguage == 'Spanish' ? 'Ver sugerencia' : 'View suggestion',
        type: NextStepType.connectToPlot,
      );
      return ChapterNextStep(
        label: step.label,
        actionLabel: step.actionLabel,
        type: step.type,
        entityName: step.entityName,
        exampleText: buildNextStepExample(
          type: step.type,
          analysis: analysis,
          sourceLanguage: sourceLanguage,
        ),
      );
    }

    final canExpandMoment =
        hasExpandMomentSignals && !structuralScenarioDevelopment;
    if (canExpandMoment) {
      final step = ChapterNextStep(
        label: sourceLanguage == 'Spanish'
            ? 'Desarrolla este momento'
            : 'Develop this moment',
        actionLabel:
            sourceLanguage == 'Spanish' ? 'Ver sugerencia' : 'View suggestion',
        type: NextStepType.expandMoment,
      );
      return ChapterNextStep(
        label: step.label,
        actionLabel: step.actionLabel,
        type: step.type,
        entityName: step.entityName,
        exampleText: buildNextStepExample(
          type: step.type,
          analysis: analysis,
          sourceLanguage: sourceLanguage,
        ),
      );
    }

    return null;
  }

  _ChapterDecisionSignals _buildChapterDecisionSignals({
    required String chapterText,
    required ChapterAnalysis analysis,
  }) {
    final normalized = ' ${chapterText.toLowerCase()} ';
    final actionSignals = _countSignals(normalized, <String>[
      ' investigar ',
      ' pista ',
      ' indicio ',
      ' policía ',
      ' sangre ',
      ' descubr',
      ' encontr',
      ' conflicto ',
    ]);
    final plotSignals = _countSignals(normalized, <String>[
      ' símbolo ',
      ' pista ',
      ' investigación ',
      ' aquella noche ',
      ' patrón ',
      ' detalle aislado ',
      ' hilo suelto ',
    ]);
    final conflictSignals = _countSignals(normalized, <String>[
      ' conflicto ',
      ' pelea ',
      ' discusión ',
      ' amenaza ',
      ' grit',
      ' miedo ',
      ' peligro ',
      ' persec',
      ' violencia ',
      ' arma ',
      ' herida ',
      ' sangre ',
    ]);
    final repeatedElementSignals = _countSignals(normalized, <String>[
      ' símbolo ',
      ' patrón ',
      ' marca ',
      ' ojo ',
      ' triángulo ',
      ' pista ',
      ' detalle ',
      ' vídeo ',
      ' captura ',
      ' mapa ',
      ' blog ',
    ]);
    final searchSignals = _countSignals(normalized, <String>[
      ' buscar ',
      ' busco ',
      ' busqué ',
      ' revis',
      ' anal',
      ' ampli',
      ' cuadro por cuadro ',
      ' rastre',
      ' compar',
      ' guard',
      ' mapa ',
      ' blog ',
      ' reddit ',
      ' foro ',
    ]);
    final unresolvedSignals = _countSignals(normalized, <String>[
      ' no sé ',
      ' no sabia ',
      ' no sabía ',
      ' nada concreto ',
      ' nada nuevo ',
      ' nada fuera de lo común ',
      ' no hubo respuesta ',
      ' desapareció ',
      ' silencio ',
      ' no cuadr',
      ' no encaj',
      ' no parece ',
      ' no parecía ',
      ' no hay patrón ',
      ' sin explicación ',
    ]);
    final topCharacterDevelopment = analysis.characterDevelopments.isEmpty
        ? null
        : analysis.characterDevelopments.first;
    final dominantMomentTitle =
        analysis.dominantNarrativeMoment.title.toLowerCase();
    final dominantMomentSummary =
        analysis.dominantNarrativeMoment.summary.toLowerCase();
    final observationDrivenMoment = dominantMomentTitle.contains('observ') ||
        dominantMomentTitle.contains('proces') ||
        dominantMomentTitle.contains('indicios') ||
        dominantMomentTitle.contains('rutina con tensión') ||
        dominantMomentSummary.contains('observación') ||
        dominantMomentSummary.contains('procesamiento') ||
        dominantMomentSummary.contains('inquietud') ||
        dominantMomentSummary.contains('silencio');
    final trajectoryReinforcesPattern = analysis.trajectory != null &&
        analysis.trajectory!.endLabel == 'investigación';

    final needsConflictPush =
        (analysis.chapterFunction == ChapterFunction.character_building ||
                analysis.chapterFunction == ChapterFunction.introduction) &&
            topCharacterDevelopment != null &&
            (topCharacterDevelopment.type ==
                    CharacterDevelopmentType.voice_definition ||
                topCharacterDevelopment.type ==
                    CharacterDevelopmentType.conflict_signal) &&
            actionSignals <= 1;
    final hasEmergingPattern = repeatedElementSignals >= 2 &&
        searchSignals >= 2 &&
        unresolvedSignals >= 1 &&
        (observationDrivenMoment || trajectoryReinforcesPattern);
    final hasStrongConflict =
        analysis.chapterFunction == ChapterFunction.escalation ||
            conflictSignals >= 2;

    final needsPlotConnection = analysis.trajectory != null &&
        analysis.trajectory!.endLabel == 'investigación' &&
        plotSignals >= 3 &&
        actionSignals <= 2 &&
        analysis.chapterFunction != ChapterFunction.discovery &&
        analysis.chapterFunction != ChapterFunction.escalation;

    return _ChapterDecisionSignals(
      actionSignals: actionSignals,
      plotSignals: plotSignals,
      needsConflictPush: needsConflictPush,
      needsPlotConnection: needsPlotConnection,
      hasEmergingPattern: hasEmergingPattern,
      hasStrongConflict: hasStrongConflict,
    );
  }

  String? buildNextStepExample({
    required NextStepType type,
    required ChapterAnalysis analysis,
    required String sourceLanguage,
  }) {
    final isSpanish = sourceLanguage == 'Spanish';
    return switch (type) {
      NextStepType.strengthenConflict => isSpanish
          ? _buildSpanishConflictExample(analysis)
          : _buildEnglishConflictExample(analysis),
      NextStepType.connectToPlot => isSpanish
          ? _buildSpanishPlotExample(analysis)
          : _buildEnglishPlotExample(analysis),
      NextStepType.expandMoment => isSpanish
          ? _buildSpanishMomentExample(analysis)
          : _buildEnglishMomentExample(analysis),
      NextStepType.enrichCharacter => null,
      NextStepType.enrichScenario => isSpanish
          ? _buildSpanishScenarioExample(analysis)
          : _buildEnglishScenarioExample(analysis),
      _ => null,
    };
  }

  String _inferSourceLanguage(String selection) {
    final normalized = ' ${selection.trim().toLowerCase()} ';
    const spanishSignals = <String>[
      ' el ',
      ' la ',
      ' de ',
      ' que ',
      ' y ',
      ' en ',
      ' un ',
      ' una ',
      ' no ',
      ' pero ',
      '¿',
      '¡',
      'á',
      'é',
      'í',
      'ó',
      'ú',
      'ñ',
    ];

    for (final signal in spanishSignals) {
      if (normalized.contains(signal)) {
        return 'Spanish';
      }
    }

    return 'English';
  }

  String _buildSpanishConflictExample(ChapterAnalysis analysis) {
    final dominant = analysis.dominantNarrativeMoment.title.toLowerCase();
    if (dominant.contains('tensión')) {
      return 'No era solo cansancio. Era la sensación de que algo estaba a punto de romperse.';
    }
    if (analysis.trajectory?.startLabel == 'intimidad') {
      return 'Podía seguir como si nada. Pero ya no me creía capaz.';
    }
    return 'Algo en ese momento no encajaba. Y cuanto más lo pensaba, menos podía ignorarlo.';
  }

  String _buildEnglishConflictExample(ChapterAnalysis analysis) {
    final dominant = analysis.dominantNarrativeMoment.title.toLowerCase();
    if (dominant.contains('tensión')) {
      return 'It was not just exhaustion. It felt like something was about to break.';
    }
    if (analysis.trajectory?.startLabel == 'intimidad') {
      return 'I could keep going as if nothing had changed. But I no longer believed I could.';
    }
    return 'Something about that moment did not fit. And the more I thought about it, the harder it was to ignore.';
  }

  String _buildSpanishPlotExample(ChapterAnalysis analysis) {
    if (analysis.trajectory?.endLabel == 'investigación') {
      return 'Entonces recordé el símbolo. El mismo patrón. La misma incomodidad.';
    }
    return 'Hasta entonces parecía un hilo suelto. De pronto ya no lo era.';
  }

  String _buildEnglishPlotExample(ChapterAnalysis analysis) {
    if (analysis.trajectory?.endLabel == 'investigación') {
      return 'Then I remembered the symbol. The same pattern. The same unease.';
    }
    return 'Until then it had felt like a loose thread. Suddenly it did not.';
  }

  String _buildSpanishMomentExample(ChapterAnalysis analysis) {
    final dominant = analysis.dominantNarrativeMoment.title.toLowerCase();
    if (dominant.contains('indicios')) {
      return 'La pista seguía siendo pequeña, pero ya no parecía casual.';
    }
    if (dominant.contains('tensión')) {
      return 'Durante un segundo todo se detuvo, como si la escena estuviera esperando algo más.';
    }
    return 'No era solo lo que había visto. Era la forma en que seguía pesándome.';
  }

  String _buildEnglishMomentExample(ChapterAnalysis analysis) {
    final dominant = analysis.dominantNarrativeMoment.title.toLowerCase();
    if (dominant.contains('indicios')) {
      return 'The clue was still small, but it no longer felt accidental.';
    }
    if (dominant.contains('tensión')) {
      return 'For a second everything stopped, as if the scene were waiting for something more.';
    }
    return 'It was not only what I had seen. It was the way it kept weighing on me.';
  }

  String _buildSpanishScenarioExample(ChapterAnalysis analysis) {
    final name = analysis.mainScenario?.name.toLowerCase() ?? '';
    if (name.contains('apartamento') || name.contains('estudio')) {
      return 'No era solo un refugio. Empezaba a parecer una forma de encierro.';
    }
    return 'El lugar no estaba vacío. Estaba cargado de todo lo que nadie decía.';
  }

  String _buildEnglishScenarioExample(ChapterAnalysis analysis) {
    final name = analysis.mainScenario?.name.toLowerCase() ?? '';
    if (name.contains('apartment') || name.contains('studio')) {
      return 'It was not just a refuge. It was starting to feel like a trap.';
    }
    return 'The place was not empty. It was charged with everything no one was saying.';
  }

  String _withArticle(String label) {
    final lower = label.toLowerCase();
    if (lower.startsWith('el ') ||
        lower.startsWith('la ') ||
        lower.startsWith('los ') ||
        lower.startsWith('las ')) {
      return label;
    }
    return lower.endsWith('a') ? 'la $label' : 'el $label';
  }

  _CharacterMetrics _collectCharacterMetrics({
    required String name,
    required List<FragmentAnalysis> fragments,
  }) {
    var fragmentHits = 0;
    var firstStrength = 0;
    var maxStrength = 0;
    var narratorHits = 0;
    var hasIdentityUpgrade = false;

    for (final fragment in fragments) {
      final match = fragment.characters.cast<DetectedCharacter?>().firstWhere(
            (item) =>
                item != null &&
                FragmentInferenceUtils.isSameCharacter(item.name, name),
            orElse: () => null,
          );
      if (match != null) {
        fragmentHits += 1;
        if (firstStrength == 0) {
          firstStrength = match.strengthScore;
        }
        if (match.strengthScore > maxStrength) {
          maxStrength = match.strengthScore;
        }
        hasIdentityUpgrade = hasIdentityUpgrade || match.isIdentityUpgrade;
      }

      final narratorId = fragment.narrator?.protagonistCharacterId;
      if (narratorId != null) {
        narratorHits += 1;
      }
    }

    return _CharacterMetrics(
      fragmentHits: fragmentHits,
      firstStrength: firstStrength,
      maxStrength: maxStrength,
      narratorHits: narratorHits,
      hasIdentityUpgrade: hasIdentityUpgrade,
    );
  }
}

Map<String, dynamic> _analyzeChapterPayload(Map<String, dynamic> payload) {
  const service = ChapterAnalysisService();
  final analysis = service.analyze(
    chapterText: payload['chapterText'] as String,
    characters: (payload['characters'] as List<dynamic>)
        .map((item) =>
            Character.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(),
    scenarios: (payload['scenarios'] as List<dynamic>)
        .map(
            (item) => Scenario.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(),
    linkedCharacterIds:
        (payload['linkedCharacterIds'] as List<dynamic>).cast<String>(),
    linkedScenarioIds:
        (payload['linkedScenarioIds'] as List<dynamic>).cast<String>(),
  );

  return _chapterAnalysisToJson(analysis);
}

Map<String, dynamic> _chapterAnalysisToJson(ChapterAnalysis analysis) => {
      'mainCharacters': analysis.mainCharacters
          .map(
            (item) => {
              'name': item.name,
              'summary': item.summary,
              'existingCharacterId': item.existingCharacterId,
              'isAlreadyLinked': item.isAlreadyLinked,
              'relevanceScore': item.relevanceScore,
              'strengthScore': item.strengthScore,
              'aggregateScore': item.aggregateScore,
              'isIdentityUpgrade': item.isIdentityUpgrade,
            },
          )
          .toList(),
      'mainScenario': analysis.mainScenario == null
          ? null
          : {
              'name': analysis.mainScenario!.name,
              'summary': analysis.mainScenario!.summary,
              'existingScenarioId': analysis.mainScenario!.existingScenarioId,
              'isAlreadyLinked': analysis.mainScenario!.isAlreadyLinked,
              'priorityScore': analysis.mainScenario!.priorityScore,
              'strengthScore': analysis.mainScenario!.strengthScore,
              'aggregateScore': analysis.mainScenario!.aggregateScore,
              'isIdentityUpgrade': analysis.mainScenario!.isIdentityUpgrade,
            },
      'narrativeMoments': analysis.narrativeMoments
          .map((item) => {'title': item.title, 'summary': item.summary})
          .toList(),
      'dominantNarrativeMoment': {
        'title': analysis.dominantNarrativeMoment.title,
        'summary': analysis.dominantNarrativeMoment.summary,
      },
      'chapterFunction': analysis.chapterFunction.name,
      'characterDevelopments': analysis.characterDevelopments
          .map(
            (item) => {
              'characterIdOrName': item.characterIdOrName,
              'label': item.label,
              'summary': item.summary,
              'type': item.type.name,
              'score': item.score,
            },
          )
          .toList(),
      'scenarioDevelopments': analysis.scenarioDevelopments
          .map(
            (item) => {
              'scenarioIdOrName': item.scenarioIdOrName,
              'label': item.label,
              'summary': item.summary,
              'type': item.type.name,
              'score': item.score,
            },
          )
          .toList(),
      'trajectory': analysis.trajectory == null
          ? null
          : {
              'startLabel': analysis.trajectory!.startLabel,
              'middleLabel': analysis.trajectory!.middleLabel,
              'endLabel': analysis.trajectory!.endLabel,
              'summary': analysis.trajectory!.summary,
            },
      'nextStep': analysis.nextStep == null
          ? null
          : {
              'label': analysis.nextStep!.label,
              'actionLabel': analysis.nextStep!.actionLabel,
              'type': analysis.nextStep!.type.name,
              'targetId': analysis.nextStep!.targetId,
              'entityName': analysis.nextStep!.entityName,
              'exampleText': analysis.nextStep!.exampleText,
            },
      'recommendation': analysis.recommendation == null
          ? null
          : {
              'message': analysis.recommendation!.message,
            },
    };

ChapterAnalysis _chapterAnalysisFromJson(Map<String, dynamic> json) {
  final mainScenarioJson = json['mainScenario'] as Map<String, dynamic>?;
  final trajectoryJson = json['trajectory'] as Map<String, dynamic>?;
  final nextStepJson = json['nextStep'] as Map<String, dynamic>?;
  final recommendationJson = json['recommendation'] as Map<String, dynamic>?;
  final dominantMomentJson =
      Map<String, dynamic>.from(json['dominantNarrativeMoment'] as Map);

  return ChapterAnalysis(
    mainCharacters: (json['mainCharacters'] as List<dynamic>).map(
      (item) {
        final map = Map<String, dynamic>.from(item as Map);
        return DetectedCharacter(
          name: map['name'] as String,
          summary: map['summary'] as String,
          existingCharacterId: map['existingCharacterId'] as String?,
          isAlreadyLinked: map['isAlreadyLinked'] as bool? ?? false,
          relevanceScore: map['relevanceScore'] as int? ?? 0,
          strengthScore: map['strengthScore'] as int? ?? 0,
          aggregateScore: map['aggregateScore'] as int? ?? 0,
          isIdentityUpgrade: map['isIdentityUpgrade'] as bool? ?? false,
        );
      },
    ).toList(),
    mainScenario: mainScenarioJson == null
        ? null
        : DetectedScenario(
            name: mainScenarioJson['name'] as String,
            summary: mainScenarioJson['summary'] as String,
            existingScenarioId:
                mainScenarioJson['existingScenarioId'] as String?,
            isAlreadyLinked:
                mainScenarioJson['isAlreadyLinked'] as bool? ?? false,
            priorityScore: mainScenarioJson['priorityScore'] as int? ?? 0,
            strengthScore: mainScenarioJson['strengthScore'] as int? ?? 0,
            aggregateScore: mainScenarioJson['aggregateScore'] as int? ?? 0,
            isIdentityUpgrade:
                mainScenarioJson['isIdentityUpgrade'] as bool? ?? false,
          ),
    narrativeMoments: (json['narrativeMoments'] as List<dynamic>).map(
      (item) {
        final map = Map<String, dynamic>.from(item as Map);
        return NarrativeMoment(
          title: map['title'] as String,
          summary: map['summary'] as String,
        );
      },
    ).toList(),
    dominantNarrativeMoment: NarrativeMoment(
      title: dominantMomentJson['title'] as String,
      summary: dominantMomentJson['summary'] as String,
    ),
    chapterFunction: ChapterFunction.values.byName(
      json['chapterFunction'] as String,
    ),
    characterDevelopments: (json['characterDevelopments'] as List<dynamic>).map(
      (item) {
        final map = Map<String, dynamic>.from(item as Map);
        return CharacterDevelopment(
          characterIdOrName: map['characterIdOrName'] as String,
          label: map['label'] as String,
          summary: map['summary'] as String,
          type: CharacterDevelopmentType.values.byName(
            map['type'] as String,
          ),
          score: map['score'] as int,
        );
      },
    ).toList(),
    scenarioDevelopments: (json['scenarioDevelopments'] as List<dynamic>).map(
      (item) {
        final map = Map<String, dynamic>.from(item as Map);
        return ScenarioDevelopment(
          scenarioIdOrName: map['scenarioIdOrName'] as String,
          label: map['label'] as String,
          summary: map['summary'] as String,
          type: ScenarioDevelopmentType.values.byName(
            map['type'] as String,
          ),
          score: map['score'] as int,
        );
      },
    ).toList(),
    trajectory: trajectoryJson == null
        ? null
        : ChapterTrajectory(
            startLabel: trajectoryJson['startLabel'] as String,
            middleLabel: trajectoryJson['middleLabel'] as String,
            endLabel: trajectoryJson['endLabel'] as String,
            summary: trajectoryJson['summary'] as String,
          ),
    nextStep: nextStepJson == null
        ? null
        : ChapterNextStep(
            label: nextStepJson['label'] as String,
            actionLabel: nextStepJson['actionLabel'] as String,
            type: NextStepType.values.byName(nextStepJson['type'] as String),
            targetId: nextStepJson['targetId'] as String?,
            entityName: nextStepJson['entityName'] as String?,
            exampleText: nextStepJson['exampleText'] as String?,
          ),
    recommendation: recommendationJson == null
        ? null
        : ChapterRecommendation(
            message: recommendationJson['message'] as String,
          ),
  );
}

class _CharacterCluster {
  _CharacterCluster({
    required this.bestName,
    required this.totalScore,
    required this.fragments,
    required this.firstFragmentIndex,
    required this.lastFragmentIndex,
    required this.hasIdentityUpgrade,
    required this.wasLinked,
    required this.hasNarratorSupport,
    required this.maxStrengthScore,
    required this.maxRelevanceScore,
    required this.chapterScore,
    this.existingCharacterId,
  });

  String bestName;
  String? existingCharacterId;
  int totalScore;
  int fragments;
  int firstFragmentIndex;
  int lastFragmentIndex;
  bool hasIdentityUpgrade;
  bool wasLinked;
  bool hasNarratorSupport;
  int maxStrengthScore;
  int maxRelevanceScore;
  int chapterScore;
}

class _ScenarioCluster {
  _ScenarioCluster({
    required this.bestName,
    required this.summarySeed,
    required this.totalScore,
    required this.fragments,
    required this.firstFragmentIndex,
    required this.lastFragmentIndex,
    required this.isBroad,
    required this.hasIdentityUpgrade,
    required this.maxStrengthScore,
    this.existingScenarioId,
  });

  String bestName;
  String summarySeed;
  String? existingScenarioId;
  int totalScore;
  int fragments;
  int firstFragmentIndex;
  int lastFragmentIndex;
  bool isBroad;
  bool hasIdentityUpgrade;
  int maxStrengthScore;
}

class _MomentCluster {
  _MomentCluster({
    required this.title,
    required this.summary,
    required this.score,
    required this.hits,
  });

  final String title;
  final String summary;
  int score;
  int hits;
}

class _MomentResolution {
  final NarrativeMoment dominant;
  final List<NarrativeMoment> moments;

  const _MomentResolution({
    required this.dominant,
    required this.moments,
  });
}

class _ChapterDecisionSignals {
  final int actionSignals;
  final int plotSignals;
  final bool needsConflictPush;
  final bool needsPlotConnection;
  final bool hasEmergingPattern;
  final bool hasStrongConflict;

  const _ChapterDecisionSignals({
    required this.actionSignals,
    required this.plotSignals,
    required this.needsConflictPush,
    required this.needsPlotConnection,
    required this.hasEmergingPattern,
    required this.hasStrongConflict,
  });
}

class _CharacterMetrics {
  final int fragmentHits;
  final int firstStrength;
  final int maxStrength;
  final int narratorHits;
  final bool hasIdentityUpgrade;

  const _CharacterMetrics({
    required this.fragmentHits,
    required this.firstStrength,
    required this.maxStrength,
    required this.narratorHits,
    required this.hasIdentityUpgrade,
  });
}
