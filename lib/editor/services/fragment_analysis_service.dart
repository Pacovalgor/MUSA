import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/characters/models/character.dart';
import '../../modules/scenarios/models/scenario.dart';
import '../models/fragment_analysis.dart';
import 'fragment_inference_utils.dart';
import 'text_analysis_lexicons.dart';

final fragmentAnalysisServiceProvider =
    Provider<FragmentAnalysisService>((ref) {
  return const FragmentAnalysisService();
});

class FragmentAnalysisService {
  const FragmentAnalysisService();

  FragmentAnalysis analyze({
    required String selection,
    required List<Character> characters,
    required List<Scenario> scenarios,
    required List<String> linkedCharacterIds,
    required List<String> linkedScenarioIds,
  }) {
    final normalized = ' ${selection.toLowerCase()} ';
    final narrator = _detectNarrator(
      normalized: normalized,
      characters: characters,
    );
    final detectedCharacters = _detectSceneCharacters(
      selection: selection,
      normalized: normalized,
      characters: characters,
      linkedCharacterIds: linkedCharacterIds,
      narrator: narrator,
    );
    final scenario = _detectScenario(
      selection: selection,
      normalized: normalized,
      scenarios: scenarios,
      linkedScenarioIds: linkedScenarioIds,
    );
    final resolvedCharacters = resolveCharacterDuplicates(detectedCharacters)
        .where(shouldSurfaceCharacter)
        .take(2)
        .toList();
    final resolvedScenario =
        scenario != null && shouldSurfaceScenario(scenario) ? scenario : null;
    final recommendation = _pickRecommendation(
      narrator: narrator,
      characters: resolvedCharacters,
      scenario: resolvedScenario,
    );

    return FragmentAnalysis(
      narrator: narrator,
      characters: resolvedCharacters,
      scenario: resolvedScenario,
      moment: _detectMoment(normalized),
      recommendation: recommendation,
    );
  }

  List<DetectedCharacter> resolveCharacterDuplicates(
    List<DetectedCharacter> candidates,
  ) {
    if (candidates.length < 2) return candidates;
    final sorted = [...candidates]..sort((a, b) {
        final scoreCompare = b.strengthScore.compareTo(a.strengthScore);
        if (scoreCompare != 0) return scoreCompare;
        return b.name.length.compareTo(a.name.length);
      });

    final resolved = <DetectedCharacter>[];
    for (final candidate in sorted) {
      final existingIndex = resolved.indexWhere(
        (item) =>
            FragmentInferenceUtils.isSameCharacter(item.name, candidate.name),
      );
      if (existingIndex == -1) {
        resolved.add(candidate);
        continue;
      }

      final current = resolved[existingIndex];
      final winner = _pickPreferredCharacter(current, candidate);
      resolved[existingIndex] = winner;
    }
    return resolved;
  }

  DetectedCharacter _pickPreferredCharacter(
    DetectedCharacter a,
    DetectedCharacter b,
  ) {
    if (a.isIdentityUpgrade && !b.isIdentityUpgrade) return a;
    if (b.isIdentityUpgrade && !a.isIdentityUpgrade) return b;
    if (a.strengthScore != b.strengthScore) {
      return a.strengthScore > b.strengthScore ? a : b;
    }
    if (FragmentInferenceUtils.isFullName(a.name) &&
        !FragmentInferenceUtils.isFullName(b.name)) {
      return a;
    }
    if (FragmentInferenceUtils.isFullName(b.name) &&
        !FragmentInferenceUtils.isFullName(a.name)) {
      return b;
    }
    return a.name.length >= b.name.length ? a : b;
  }

  bool shouldSurfaceCharacter(DetectedCharacter candidate) {
    if (candidate.strengthScore <= 2) return false;
    if (!_hasStrongSingleWordSupport(candidate)) {
      return false;
    }
    return true;
  }

  bool shouldOfferCharacterCTA(DetectedCharacter candidate) {
    if (candidate.action == null) return false;
    if (candidate.strengthScore < 6) return false;
    if (!_hasStrongSingleWordSupport(candidate)) return false;
    return true;
  }

  bool _hasStrongSingleWordSupport(DetectedCharacter candidate) {
    final isSingleWord = !candidate.name.trim().contains(' ');
    if (!isSingleWord) return true;
    return candidate.strengthScore >= 6;
  }

  bool shouldSurfaceScenario(DetectedScenario candidate) {
    if (candidate.strengthScore <= 2) return false;
    if (FragmentInferenceUtils.isBroadGeographicContext(candidate.name) &&
        candidate.strengthScore < 6) {
      return false;
    }
    return true;
  }

  bool shouldOfferScenarioCTA(DetectedScenario candidate) {
    if (candidate.action == null) return false;
    if (candidate.strengthScore < 6) return false;
    if (FragmentInferenceUtils.isBroadGeographicContext(candidate.name)) {
      return false;
    }
    return true;
  }

  NarratorInsight? _detectNarrator({
    required String normalized,
    required List<Character> characters,
  }) {
    final compactSelection = normalized.trim();
    final hitCount = TextAnalysisLexicons.firstPersonCues
        .where((signal) => normalized.contains(signal))
        .length;
    if (hitCount < 2 && !(normalized.contains('—') && hitCount >= 1)) {
      if (!FragmentInferenceUtils.isLikelyFirstPersonNarrator(
          compactSelection)) {
        return null;
      }
    }

    final protagonist = characters.cast<Character?>().firstWhere(
          (item) => item?.isProtagonist == true,
          orElse: () => null,
        );

    final priorityScore = protagonist == null ? 92 : 72;
    final action = protagonist == null
        ? const InsightAction(
            type: InsightActionType.createProtagonist,
            label: 'Crear protagonista',
            priorityScore: 92,
          )
        : InsightAction(
            type: InsightActionType.enrichProtagonist,
            label: 'Enriquecer protagonista',
            targetId: protagonist.id,
            entityName: protagonist.displayName,
            priorityScore: 72,
          );

    return NarratorInsight(
      title: protagonist == null ? 'Protagonista implícita' : 'Narradora',
      summary: protagonist == null
          ? 'Voz en primera persona'
          : 'La escena está contada desde dentro',
      protagonistCharacterId: protagonist?.id,
      protagonistExists: protagonist != null,
      priorityScore: priorityScore,
      action: action,
    );
  }

  List<DetectedCharacter> _detectSceneCharacters({
    required String selection,
    required String normalized,
    required List<Character> characters,
    required List<String> linkedCharacterIds,
    required NarratorInsight? narrator,
  }) {
    final existingMatches = <DetectedCharacter>[];
    for (final character in characters) {
      if (character.isProtagonist &&
          narrator != null &&
          character.id == narrator.protagonistCharacterId) {
        continue;
      }

      final occurrences =
          _countWholeWordOccurrences(normalized, character.displayName);
      if (occurrences == 0) {
        continue;
      }

      final hasHumanContext = FragmentInferenceUtils.hasHumanContext(
        selection,
        character.displayName,
      );
      final strengthScore = FragmentInferenceUtils.computeCharacterStrength(
        name: character.displayName,
        context: selection,
      );
      final relevanceScore = strengthScore + occurrences;
      final action = _buildCharacterAction(
        name: character.displayName,
        existingCharacterId: character.id,
        isAlreadyLinked: linkedCharacterIds.contains(character.id),
        strengthScore: strengthScore,
        hasHumanContext: hasHumanContext,
      );

      existingMatches.add(
        DetectedCharacter(
          name: character.displayName,
          summary: linkedCharacterIds.contains(character.id)
              ? 'Tiene presencia en la escena'
              : _genericCharacterSummary(
                  selection: selection,
                  name: character.displayName,
                ),
          existingCharacterId: character.id,
          isAlreadyLinked: linkedCharacterIds.contains(character.id),
          relevanceScore: relevanceScore,
          strengthScore: strengthScore,
          action: action,
        ),
      );
    }

    final inferred = <DetectedCharacter>[];
    final properNameRegex = RegExp(
        r'\b[A-ZÁÉÍÓÚÑ][a-záéíóúñ]{2,}(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]{2,})?\b');

    for (final match in properNameRegex.allMatches(selection)) {
      final candidate = match.group(0)?.trim() ?? '';
      if (candidate.isEmpty ||
          TextAnalysisLexicons.nonPersonProperNames.contains(candidate)) {
        continue;
      }
      if (FragmentInferenceUtils.isBlockedCapitalizedWord(candidate)) {
        continue;
      }
      if (FragmentInferenceUtils.isCommonNonEntityWord(candidate)) {
        continue;
      }
      if (FragmentInferenceUtils.looksLikeGeographicName(candidate) ||
          FragmentInferenceUtils.appearsInGeographicContext(
            selection,
            candidate,
          )) {
        continue;
      }
      if (FragmentInferenceUtils.appearsOnlyAtSentenceStart(
              selection, candidate) &&
          !FragmentInferenceUtils.hasDirectPresentationContext(
              selection, candidate)) {
        continue;
      }
      if (_looksLikeOrganization(selection, candidate)) {
        continue;
      }
      if (existingMatches
          .any((item) => item.name.toLowerCase() == candidate.toLowerCase())) {
        continue;
      }

      final occurrences = _countWholeWordOccurrences(normalized, candidate);
      final hasDirectPresentation =
          FragmentInferenceUtils.hasDirectPresentationContext(
        selection,
        candidate,
      );
      final hasHumanContext =
          FragmentInferenceUtils.hasHumanContext(selection, candidate) ||
              hasDirectPresentation;
      if (occurrences < 2 && !hasHumanContext) {
        continue;
      }
      final strengthScore = FragmentInferenceUtils.computeCharacterStrength(
        name: candidate,
        context: selection,
      );
      final boostedStrength =
          hasDirectPresentation && !FragmentInferenceUtils.isFullName(candidate)
              ? strengthScore + 2
              : strengthScore;
      if (boostedStrength <= 1) {
        continue;
      }
      final relevanceScore = boostedStrength + occurrences;

      inferred.add(
        DetectedCharacter(
          name: candidate,
          summary: hasHumanContext
              ? _genericCharacterSummary(
                  selection: selection,
                  name: candidate,
                )
              : 'Aparece en este fragmento',
          relevanceScore: relevanceScore,
          strengthScore: boostedStrength,
          action: _buildCharacterAction(
            name: candidate,
            existingCharacterId: null,
            isAlreadyLinked: false,
            strengthScore: boostedStrength,
            hasHumanContext: hasHumanContext,
          ),
        ),
      );
    }

    final upgradedExisting = <DetectedCharacter>[];
    final consumedInferred = <int>{};
    for (final existing in existingMatches) {
      DetectedCharacter best = existing;
      for (var i = 0; i < inferred.length; i++) {
        final candidate = inferred[i];
        if (!FragmentInferenceUtils.isSameCharacter(
            existing.name, candidate.name)) {
          continue;
        }
        if (candidate.strengthScore <= best.strengthScore) {
          continue;
        }
        best = DetectedCharacter(
          name: candidate.name,
          summary: 'Este personaje ahora tiene más definición.',
          existingCharacterId: existing.existingCharacterId,
          isAlreadyLinked: existing.isAlreadyLinked,
          relevanceScore: candidate.relevanceScore + 2,
          strengthScore: candidate.strengthScore,
          isIdentityUpgrade: true,
          action: InsightAction(
            type: InsightActionType.enrichCharacter,
            label: 'Enriquecer personaje',
            targetId: existing.existingCharacterId,
            entityName: candidate.name,
            priorityScore: _characterPriorityScore(
              candidate.strengthScore,
              isUpgrade: true,
            ),
          ),
        );
        consumedInferred.add(i);
      }
      upgradedExisting.add(best);
    }

    final merged = <DetectedCharacter>[
      ...upgradedExisting,
      for (var i = 0; i < inferred.length; i++)
        if (!consumedInferred.contains(i)) inferred[i],
    ]..sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    final unique = <DetectedCharacter>[];
    final seen = <String>{};
    for (final item in merged) {
      final key = item.existingCharacterId ?? item.name.toLowerCase();
      if (item.existingCharacterId == null && item.strengthScore < 3) {
        continue;
      }
      if (seen.add(key)) {
        unique.add(item);
      }
      if (unique.length >= 2) {
        break;
      }
    }
    return unique;
  }

  DetectedScenario? _detectScenario({
    required String selection,
    required String normalized,
    required List<Scenario> scenarios,
    required List<String> linkedScenarioIds,
  }) {
    final keyObjectSummary = _buildKeyObjectSummary(normalized);
    final scenarioFunction =
        FragmentInferenceUtils.inferScenarioFunction(selection);
    final hasNewsroom =
        _containsAny(normalized, TextAnalysisLexicons.newsroomSignals);
    final hasPressIdentity =
        _containsAny(normalized, TextAnalysisLexicons.pressIdentitySignals);
    final hasApartment =
        _containsAny(normalized, TextAnalysisLexicons.apartmentSignals);
    final hasCafe = _containsAny(normalized, TextAnalysisLexicons.cafeSignals);
    final hasWorkshop =
        _containsAny(normalized, TextAnalysisLexicons.workshopSignals);
    final hasWarehouse =
        _containsAny(normalized, TextAnalysisLexicons.warehouseSignals);
    final hasHospital =
        _containsAny(normalized, TextAnalysisLexicons.hospitalSignals);
    final hasSchool =
        _containsAny(normalized, TextAnalysisLexicons.schoolSignals);
    final hasStore =
        _containsAny(normalized, TextAnalysisLexicons.storeSignals);
    final hasBarRestaurant =
        _containsAny(normalized, TextAnalysisLexicons.barRestaurantSignals);
    final hasPark = _containsAny(normalized, TextAnalysisLexicons.parkSignals);
    final hasRoad = _containsAny(normalized, TextAnalysisLexicons.roadSignals);
    final hasTown = _containsAny(normalized, TextAnalysisLexicons.townSignals);
    final hasBeach =
        _containsAny(normalized, TextAnalysisLexicons.beachSignals);
    final hasForest =
        _containsAny(normalized, TextAnalysisLexicons.forestSignals);
    final hasStreetTransit =
        _containsAny(normalized, TextAnalysisLexicons.streetTransitSignals);
    final hasBayLens = normalized.contains(' the bay lens ');
    final hasSanFrancisco = normalized.contains(' san francisco ');
    final hasMissionDistrict = normalized.contains(' mission district ') ||
        normalized.contains(' district mission ') ||
        normalized.contains(' mission ');
    final hasTenderloin = RegExp(r'\btenderloin\b').hasMatch(normalized);
    final hasSoMa = RegExp(r'\bsoma\b').hasMatch(normalized) ||
        normalized.contains(' south of market ');
    final hasCivicCenter = normalized.contains(' civic center ');
    final hasEllis = normalized.contains(' ellis street ') ||
        RegExp(r'\bellis\b').hasMatch(normalized);
    final hasAlley = normalized.contains(' callejón ');
    final hasCrimeScene =
        _containsAny(normalized, TextAnalysisLexicons.crimeSceneSignals);
    final hasMoisture =
        _containsAny(normalized, TextAnalysisLexicons.moistureSignals);

    if (hasApartment) {
      final name = normalized.contains(' bernal heights ')
          ? 'Apartamento en Bernal Heights'
          : 'Apartamento o estudio';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ?? 'Espacio íntimo, pequeño y algo precario',
            if (keyObjectSummary != null) keyObjectSummary,
            'Ambiente reconocible en la escena',
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    if (hasCrimeScene || hasAlley) {
      final name = hasTenderloin
          ? 'Callejón en Tenderloin'
          : hasMissionDistrict
              ? 'Lugar del crimen en Mission'
              : hasSoMa
                  ? 'Callejón en SoMa'
                  : 'Lugar del crimen';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ?? 'Escena intervenida, observación e inquietud',
            if (keyObjectSummary != null) keyObjectSummary,
            if (hasMissionDistrict) 'Mission District',
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    if ((hasNewsroom || hasBayLens) && !hasPressIdentity) {
      final name = hasBayLens ? 'Redacción de The Bay Lens' : 'Redacción';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ??
                (hasBayLens ? 'Oficina y ritmo periodístico' : ''),
            if (keyObjectSummary != null) keyObjectSummary,
            'Ambiente reconocible en la escena',
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    // Si bar y café disparan a la vez, gana bar (libro 2: Christopher's
    // tenía 'barra' y 'café' pero era un bar de cócteles).
    if (hasCafe && !hasBarRestaurant) {
      const name = 'Cafetería de la esquina';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ?? 'Pausa breve, conversación y observación',
            if (keyObjectSummary != null) keyObjectSummary,
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    if (hasWorkshop) {
      const name = 'Taller';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ?? 'Espacio de trabajo manual',
            if (keyObjectSummary != null) keyObjectSummary,
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    if (hasWarehouse) {
      const name = 'Almacén o muelle';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ?? 'Espacio industrial con movimiento o restos',
            if (keyObjectSummary != null) keyObjectSummary,
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    if (hasHospital) {
      const name = 'Hospital';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ?? 'Entorno clínico y tenso',
            if (keyObjectSummary != null) keyObjectSummary,
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    if (hasSchool) {
      const name = 'Centro de estudio';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ?? 'Espacio de aprendizaje o archivo',
            if (keyObjectSummary != null) keyObjectSummary,
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    if (hasStore) {
      const name = 'Tienda o local';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ?? 'Espacio comercial reconocible',
            if (keyObjectSummary != null) keyObjectSummary,
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    if (hasBarRestaurant) {
      const name = 'Bar o restaurante';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ?? 'Encuentro, ruido y movimiento',
            if (keyObjectSummary != null) keyObjectSummary,
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    if (hasPark) {
      const name = 'Parque o jardín';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ?? 'Espacio abierto con pausa y observación',
            if (keyObjectSummary != null) keyObjectSummary,
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    if (hasTown) {
      const name = 'Pueblo o plaza';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ?? 'Centro urbano reconocible',
            if (keyObjectSummary != null) keyObjectSummary,
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    if (hasBeach) {
      const name = 'Playa o costa';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ?? 'Espacio abierto junto al agua',
            if (keyObjectSummary != null) keyObjectSummary,
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    if (hasForest) {
      const name = 'Bosque o sendero';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ?? 'Espacio natural con fricción o aislamiento',
            if (keyObjectSummary != null) keyObjectSummary,
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    if (hasStreetTransit) {
      final name = hasTenderloin
          ? 'Calles del Tenderloin'
          : hasSoMa
              ? 'Calles de SoMa'
              : hasCivicCenter || hasEllis
                  ? 'Calles de Civic Center'
                  : hasMissionDistrict
                      ? 'Calles de Mission'
                      : hasRoad
                          ? 'Calle o avenida'
                          : 'Calles de la ciudad';
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: name,
        context: selection,
      );
      final action = _buildStandaloneScenarioAction(
        name: name,
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: name,
          summary: _mergeSummaryParts(<String>[
            scenarioFunction ?? 'Desplazamiento urbano, ruido y cansancio',
            if (keyObjectSummary != null) keyObjectSummary,
          ]),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    for (final scenario in scenarios) {
      final scenarioName = scenario.displayName.toLowerCase();
      final matchesScenarioName =
          _countWholeWordOccurrences(normalized, scenario.displayName) > 0;
      final matchesGenericCrimeScene = scenarioName.contains('crimen') &&
          (hasCrimeScene || hasAlley || hasMissionDistrict);
      final matchesLocationAlias = hasMissionDistrict &&
          (scenarioName.contains('mission') ||
              scenarioName.contains('callejón') ||
              scenarioName.contains('lugar del crimen'));

      if (!matchesScenarioName &&
          !matchesGenericCrimeScene &&
          !matchesLocationAlias) {
        continue;
      }

      final summaryParts = <String>[
        if (hasSanFrancisco) 'San Francisco',
        if (hasMissionDistrict) 'Mission District',
        if (hasCrimeScene) 'escena de crimen',
        if (hasMoisture) 'ambiente húmedo',
      ];
      final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
        name: scenario.displayName,
        context: selection,
      );
      final action = _buildScenarioAction(
        scenarioId: scenario.id,
        isAlreadyLinked: linkedScenarioIds.contains(scenario.id),
        strengthScore: strengthScore,
      );
      return _resolveScenarioCandidate(
        candidate: DetectedScenario(
          name: scenario.displayName,
          summary: summaryParts.isEmpty
              ? (linkedScenarioIds.contains(scenario.id)
                  ? 'Lugar con peso narrativo'
                  : 'Ambiente reconocible en la escena')
              : _mergeSummaryParts(<String>[
                  _sentenceCase(summaryParts.join(', ')),
                  if (keyObjectSummary != null) keyObjectSummary,
                ]),
          existingScenarioId: scenario.id,
          isAlreadyLinked: linkedScenarioIds.contains(scenario.id),
          priorityScore: action?.priorityScore ?? 0,
          strengthScore: strengthScore,
          action: action,
        ),
        scenarios: scenarios,
        linkedScenarioIds: linkedScenarioIds,
        selection: selection,
      )!;
    }

    if (!hasSanFrancisco &&
        !hasMissionDistrict &&
        !hasAlley &&
        !hasCrimeScene) {
      return null;
    }

    final name = hasAlley && hasMissionDistrict
        ? 'Callejón en Mission District'
        : hasAlley && hasSanFrancisco
            ? 'Callejón en San Francisco'
            : hasAlley
                ? 'Callejón'
                : hasMissionDistrict
                    ? 'Mission District'
                    : hasSanFrancisco
                        ? 'San Francisco'
                        : 'Escena del crimen';

    final summaryParts = <String>[
      if (hasSanFrancisco && !name.contains('San Francisco')) 'San Francisco',
      if (hasMissionDistrict && !name.contains('Mission District'))
        'Mission District',
      if (hasCrimeScene) 'Escena de crimen',
      if (hasMoisture) 'ambiente húmedo',
      if (normalized.contains(' tenso ') || hasCrimeScene) 'tensión contenida',
    ];

    final strengthScore = FragmentInferenceUtils.computeScenarioStrength(
      name: name,
      context: selection,
    );
    final action = _buildStandaloneScenarioAction(
      name: name,
      strengthScore: strengthScore,
    );
    return _resolveScenarioCandidate(
      candidate: DetectedScenario(
        name: name,
        summary: summaryParts.isEmpty
            ? _mergeSummaryParts(<String>[
                'Espacio con identidad propia',
                if (keyObjectSummary != null) keyObjectSummary,
              ])
            : _mergeSummaryParts(<String>[
                _sentenceCase(summaryParts.join(', ')),
                if (keyObjectSummary != null) keyObjectSummary,
              ]),
        priorityScore: action?.priorityScore ?? 0,
        strengthScore: strengthScore,
        action: action,
      ),
      scenarios: scenarios,
      linkedScenarioIds: linkedScenarioIds,
      selection: selection,
    )!;
  }

  NarrativeMoment _detectMoment(String normalized) {
    if (_containsAny(normalized, TextAnalysisLexicons.workshopMomentTerms)) {
      return const NarrativeMoment(
        title: 'Trabajo bajo fricción',
        summary: 'La escena avanza entre tarea, materia y tensión.',
      );
    }

    if (_containsAny(normalized, TextAnalysisLexicons.newsroomMomentTerms)) {
      return const NarrativeMoment(
        title: 'Rutina de redacción',
        summary: 'Trabajo, presión y atención dividida.',
      );
    }

    if (_containsAny(
        normalized, TextAnalysisLexicons.intimateMorningMomentTerms)) {
      return const NarrativeMoment(
        title: 'Rutina íntima de mañana',
        summary: 'La escena presenta a la narradora a través de su espacio.',
      );
    }

    if (_containsAny(
        normalized, TextAnalysisLexicons.backgroundTensionMomentTerms)) {
      return const NarrativeMoment(
        title: 'Rutina con tensión de fondo',
        summary:
            'La escena perfila a la narradora desde su vínculo y su conflicto.',
      );
    }

    if (_containsAny(
        normalized, TextAnalysisLexicons.soloProcessingMomentTerms)) {
      return const NarrativeMoment(
        title: 'Procesamiento en soledad',
        summary: 'La escena se vuelve íntima y mental.',
      );
    }

    if (_containsAny(
        normalized, TextAnalysisLexicons.nightWalkHomeMomentTerms)) {
      return const NarrativeMoment(
        title: 'Vuelta a casa con inquietud',
        summary: 'La ciudad acompaña el pensamiento de fondo.',
      );
    }

    if (_containsAny(normalized, TextAnalysisLexicons.cafePauseMomentTerms)) {
      return const NarrativeMoment(
        title: 'Pausa con subtexto',
        summary: 'La escena baja el ritmo, pero mantiene tensión de fondo.',
      );
    }

    if (_containsAny(
        normalized, TextAnalysisLexicons.investigationStartMomentTerms)) {
      return const NarrativeMoment(
        title: 'Inicio de investigación',
        summary: 'La narradora observa, recoge y conecta.',
      );
    }

    if (_containsAny(
        normalized, TextAnalysisLexicons.crimeSceneEntryMomentTerms)) {
      return const NarrativeMoment(
        title: 'Entrada a una escena de crimen',
        summary: 'La escena se sostiene sobre observación e inquietud.',
      );
    }

    if (_containsAny(
        normalized, TextAnalysisLexicons.containedTensionMomentTerms)) {
      return const NarrativeMoment(
        title: 'Tensión contenida',
        summary: 'Hay amenaza cerca, pero todavía manda la observación.',
      );
    }

    // Fallback neutro: cuando ningún momento específico dispara, no
    // imponer "Recogida de indicios" (sesgo a thriller de investigación)
    // — lo que tenemos es ausencia de foco dominante.
    return const NarrativeMoment(
      title: 'Avance abierto',
      summary: 'El fragmento aún no fija un foco dominante.',
    );
  }

  bool _looksLikeOrganization(String selection, String name) {
    return FragmentInferenceUtils.looksLikeOrganizationName(name) ||
        FragmentInferenceUtils.appearsInOrganizationContext(selection, name);
  }

  String? _buildKeyObjectSummary(String normalized) {
    final objects = <String>[
      if (_containsAny(normalized, TextAnalysisLexicons.phoneTerms)) 'móvil',
      if (_containsAny(normalized, TextAnalysisLexicons.laptopTerms))
        'portátil',
      if (normalized.contains(' libreta ')) 'libreta',
      if (_containsAny(normalized, TextAnalysisLexicons.cameraTerms)) 'cámara',
      if (_containsAny(normalized, TextAnalysisLexicons.videoTerms)) 'vídeo',
      if (_containsAny(normalized, TextAnalysisLexicons.folderTerms))
        'expediente',
      if (_containsAny(normalized, TextAnalysisLexicons.keyTerms)) 'llaves',
      if (_containsAny(normalized, TextAnalysisLexicons.dangerousObjectTerms))
        'objeto peligroso',
      if (_containsAny(normalized, TextAnalysisLexicons.physicalTraceTerms))
        'rastro físico',
      if (_containsAny(normalized, TextAnalysisLexicons.containerTerms))
        'contenedores o cajas',
      if (_containsAny(normalized, TextAnalysisLexicons.coffeeTerms))
        'café o taza',
      if (_containsAny(normalized, TextAnalysisLexicons.workFurnitureTerms))
        'mobiliario de trabajo',
    ];

    if (objects.isEmpty) {
      return null;
    }

    return 'Claves: ${objects.take(2).join(', ')}';
  }

  String _mergeSummaryParts(List<String> parts) {
    final cleaned = parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) {
      return '';
    }
    return cleaned.join(' · ');
  }

  InsightAction? _buildCharacterAction({
    required String name,
    required String? existingCharacterId,
    required bool isAlreadyLinked,
    required int strengthScore,
    required bool hasHumanContext,
  }) {
    if (existingCharacterId == null) {
      if (strengthScore < 6) return null;
      return InsightAction(
        type: InsightActionType.createCharacter,
        label: 'Crear personaje',
        entityName: name,
        priorityScore: _characterPriorityScore(strengthScore),
      );
    }

    if (!isAlreadyLinked && strengthScore >= 6) {
      return InsightAction(
        type: InsightActionType.linkCharacter,
        label: 'Vincular personaje',
        targetId: existingCharacterId,
        entityName: name,
        priorityScore: _characterPriorityScore(strengthScore),
      );
    }

    if (strengthScore >= 6) {
      return InsightAction(
        type: InsightActionType.enrichCharacter,
        label: 'Enriquecer personaje',
        targetId: existingCharacterId,
        entityName: name,
        priorityScore: _characterPriorityScore(strengthScore),
      );
    }

    return null;
  }

  int _characterPriorityScore(int strengthScore, {bool isUpgrade = false}) {
    final base = switch (strengthScore) {
      >= 9 => 96,
      >= 6 => 90,
      >= 3 => 72,
      _ => 0,
    };
    return isUpgrade ? base + 2 : base;
  }

  InsightAction? _buildStandaloneScenarioAction({
    required String name,
    required int strengthScore,
  }) {
    if (FragmentInferenceUtils.isBroadGeographicContext(name)) {
      return null;
    }
    if (strengthScore < 6) {
      return null;
    }
    return InsightAction(
      type: InsightActionType.createScenario,
      label: 'Crear escenario',
      entityName: name,
      priorityScore: _scenarioPriorityScore(strengthScore),
    );
  }

  InsightAction? _buildScenarioAction({
    required String scenarioId,
    required bool isAlreadyLinked,
    required int strengthScore,
  }) {
    if (strengthScore < 6) {
      return null;
    }

    if (!isAlreadyLinked) {
      return InsightAction(
        type: InsightActionType.linkScenario,
        label: 'Vincular escenario',
        targetId: scenarioId,
        priorityScore: _scenarioPriorityScore(strengthScore),
      );
    }

    if (strengthScore >= 6) {
      return InsightAction(
        type: InsightActionType.enrichScenario,
        label: 'Enriquecer escenario',
        targetId: scenarioId,
        priorityScore: _scenarioPriorityScore(strengthScore, isUpgrade: true),
      );
    }

    return null;
  }

  int _scenarioPriorityScore(int strengthScore, {bool isUpgrade = false}) {
    final base = switch (strengthScore) {
      >= 9 => 94,
      >= 6 => 86,
      >= 3 => 64,
      _ => 0,
    };
    return isUpgrade ? base + 2 : base;
  }

  DetectedScenario? _resolveScenarioCandidate({
    required DetectedScenario candidate,
    required List<Scenario> scenarios,
    required List<String> linkedScenarioIds,
    required String selection,
  }) {
    Scenario? existingMatch;
    for (final scenario in scenarios) {
      if (FragmentInferenceUtils.isSameScenario(
        scenario.displayName,
        candidate.name,
      )) {
        existingMatch = scenario;
        break;
      }
    }

    if (existingMatch == null) {
      return candidate;
    }

    final action = _buildScenarioAction(
      scenarioId: existingMatch.id,
      isAlreadyLinked: linkedScenarioIds.contains(existingMatch.id),
      strengthScore: candidate.strengthScore,
    );

    return DetectedScenario(
      name: candidate.strengthScore >= 6
          ? candidate.name
          : existingMatch.displayName,
      summary: candidate.strengthScore >= 6
          ? 'Este escenario ahora tiene más forma.'
          : candidate.summary,
      existingScenarioId: existingMatch.id,
      isAlreadyLinked: linkedScenarioIds.contains(existingMatch.id),
      priorityScore: action?.priorityScore ?? 0,
      strengthScore: candidate.strengthScore,
      isIdentityUpgrade: candidate.name.toLowerCase() !=
          existingMatch.displayName.toLowerCase(),
      action: action,
    );
  }

  FragmentRecommendation? _pickRecommendation({
    required NarratorInsight? narrator,
    required List<DetectedCharacter> characters,
    required DetectedScenario? scenario,
  }) {
    final candidates = <MapEntry<InsightAction, String>>[];
    final strongestCharacterScore = characters.isEmpty
        ? 0
        : characters
            .map((item) => item.strengthScore)
            .reduce((a, b) => a > b ? a : b);
    final hasStrongExplicitCharacter = strongestCharacterScore >= 7;

    if (narrator?.action != null && !hasStrongExplicitCharacter) {
      candidates.add(MapEntry(
        narrator!.action!,
        narrator.protagonistExists
            ? 'Este fragmento perfila mejor a la narradora.'
            : 'Aquí merece la pena fijar primero a la protagonista.',
      ));
    }

    for (final character in characters) {
      if (!shouldOfferCharacterCTA(character)) continue;
      final reason = character.isIdentityUpgrade
          ? 'Este personaje ahora tiene más definición.'
          : switch (character.action!.type) {
              InsightActionType.createCharacter => character.strengthScore >= 6
                  ? 'Aquí aparece un personaje con identidad clara.'
                  : 'Aquí aparece un personaje con algo de definición.',
              InsightActionType.linkCharacter =>
                'Conviene vincular este personaje para no perder su presencia.',
              InsightActionType.enrichCharacter =>
                'Este personaje ahora tiene más definición.',
              _ => 'Aquí hay una acción útil sobre este personaje.',
            };
      candidates.add(MapEntry(character.action!, reason));
    }

    if (scenario?.action != null) {
      if (shouldOfferScenarioCTA(scenario!)) {
        final reason = scenario.isIdentityUpgrade
            ? 'Este escenario ahora tiene más forma.'
            : switch (scenario.action!.type) {
                InsightActionType.createScenario => scenario.strengthScore >= 6
                    ? 'Aquí merece la pena fijar el escenario.'
                    : 'Este lugar ya empieza a tomar forma.',
                InsightActionType.linkScenario =>
                  'Conviene vincular este lugar para ordenar mejor el capítulo.',
                InsightActionType.enrichScenario =>
                  'Aquí aparecen detalles útiles para enriquecer el lugar.',
                _ => 'Aquí hay una acción útil sobre el escenario.',
              };
        candidates.add(MapEntry(scenario.action!, reason));
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort(
      (a, b) => b.key.priorityScore.compareTo(a.key.priorityScore),
    );
    final best = candidates.first;
    return FragmentRecommendation(
      reason: best.value,
      action: best.key,
    );
  }

  String _genericCharacterSummary({
    required String selection,
    required String name,
  }) {
    final escaped = RegExp.escape(name);
    final lowerSelection = selection.toLowerCase();

    if (RegExp(
            r'\b' + escaped + r'\b.{0,40}\b(dijo|preguntó|respondió|ordenó)\b',
            caseSensitive: false)
        .hasMatch(selection)) {
      return 'Activa el intercambio en esta escena';
    }

    if (RegExp(r'\b' + escaped + r'\b.{0,40}\b(escribió|llamó|avisó|pidió)\b',
            caseSensitive: false)
        .hasMatch(selection)) {
      return 'Desencadena movimiento en este momento';
    }

    if (RegExp(
            r'\b' +
                escaped +
                r'\b.{0,50}\b(madre|padre|hermano|hermana|tía|tio|tío|prima|primo|hija|hijo|novia|novio|pareja|amiga|amigo|jefa|jefe|vecina|vecino|compañera|compañero|abogada|abogado|profesora|profesor|editora|editor|inspectora|inspector)\b',
            caseSensitive: false)
        .hasMatch(selection)) {
      return 'Aporta un vínculo claro en este momento';
    }

    if (RegExp(
            r'\b' +
                escaped +
                r'\b.{0,60}\b(se sienta|acompaña|ofrece|sonríe)\b',
            caseSensitive: false)
        .hasMatch(selection)) {
      return 'Tiene presencia cercana en la escena';
    }

    if (lowerSelection.contains(' no habló ') ||
        lowerSelection.contains(' no dijo nada ')) {
      return 'Aparece en este fragmento';
    }

    return 'Podría ser relevante en este momento';
  }

  int _countWholeWordOccurrences(String normalized, String value) {
    final escaped = RegExp.escape(value.toLowerCase());
    final pattern = RegExp('(^|[^a-záéíóúñü])$escaped([^a-záéíóúñü]|\$)');
    return pattern.allMatches(normalized).length;
  }

  bool _containsAny(String normalized, List<String> terms) {
    for (final term in terms) {
      if (normalized.contains(term)) {
        return true;
      }
    }
    return false;
  }

  String _sentenceCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
