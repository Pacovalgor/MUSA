import 'text_analysis_lexicons.dart';

class FragmentInferenceUtils {
  static bool isBlockedCapitalizedWord(String value) {
    return TextAnalysisLexicons.blockedCharacterWords.contains(value) ||
        TextAnalysisLexicons.narrativeVerbNonEntities.contains(value) ||
        TextAnalysisLexicons.narrativeNounNonEntities.contains(value);
  }

  static bool isCommonNonEntityWord(String value) {
    final lowered = value.toLowerCase();
    return TextAnalysisLexicons.commonNonEntityWords.contains(lowered) ||
        TextAnalysisLexicons.narrativeVerbNonEntities
            .any((item) => item.toLowerCase() == lowered) ||
        TextAnalysisLexicons.narrativeNounNonEntities
            .any((item) => item.toLowerCase() == lowered);
  }

  static bool looksLikeOrganizationName(String name) {
    final lowered = name.trim().toLowerCase();
    if (lowered.isEmpty) return false;

    for (final signal in TextAnalysisLexicons.organizationSignals) {
      if (RegExp(r'(^|\\s)' + RegExp.escape(signal) + r'(\\s|$)')
          .hasMatch(lowered)) {
        return true;
      }
    }
    return false;
  }

  static bool looksLikeGeographicName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (TextAnalysisLexicons.topLevelGeography.contains(trimmed)) return true;

    final lowered = trimmed.toLowerCase();
    if (TextAnalysisLexicons.monthWords.contains(lowered)) return true;
    if (RegExp(r'\b\d{1,4}\b').hasMatch(lowered)) return true;

    final parts = lowered.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.any(TextAnalysisLexicons.geographyDescriptorWords.contains);
  }

  static bool appearsInGeographicContext(String text, String name) {
    final escaped = RegExp.escape(name);
    final patterns = <RegExp>[
      RegExp(
        r'\b(calle|avenida|carretera|camino|barrio|distrito|callejón|muelle|parque|plaza|portal|bar|cafetería|oficina|redacción|apartamento|estudio)\s+(de|del|en)\s+' +
            escaped +
            r'\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(en|desde|hasta|hacia|por|rumbo a|camino a|frente a|cerca de|junto a|dos manzanas de)\s+' +
            escaped +
            r'\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b' + escaped + r'\s+(street|st|avenue|ave|road|rd|boulevard|blvd|district|heights|city|park|harbor|pier)\b',
        caseSensitive: false,
      ),
    ];
    return patterns.any((pattern) => pattern.hasMatch(text));
  }

  static bool appearsInOrganizationContext(String text, String name) {
    final escaped = RegExp.escape(name);
    final patterns = <RegExp>[
      RegExp(
        r'\b(redacción|diario|medio|revista|periódico|editorial|newsroom|portal)\s+(de|del|en)\s+' +
            escaped +
            r'\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(beca|trabajo|prácticas|pasantía|puesto|empleo)\s+(en|de)\s+' +
            escaped +
            r'\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b' + escaped + r'\s+(está|era|tiene|publicó|encargó)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b' +
            escaped +
            r'\b.{0,48}\b(edificio|ventanas|suelos|oficina|fotocopiadora|escritorio|gestor de contenidos)\b',
        caseSensitive: false,
      ),
    ];
    return patterns.any((pattern) => pattern.hasMatch(text));
  }

  static bool appearsOnlyAtSentenceStart(String selection, String candidate) {
    final escaped = RegExp.escape(candidate);
    final total = RegExp(r'\b' + escaped + r'\b').allMatches(selection).length;
    if (total == 0) return false;
    final atStart = RegExp(
      r'(^|[.!?…\n"“”])\s*' + escaped + r'\b',
      multiLine: true,
    ).allMatches(selection).length;
    return atStart == total;
  }

  static bool hasLikelyHumanContext(String selection, String candidate) {
    final escaped = RegExp.escape(candidate);
    final patterns = <RegExp>[
      RegExp(
        r'\b' +
            escaped +
            r'\b.{0,40}\b(dijo|preguntó|miró|escribió|llamó|respondió|vio|pensó|sonrió|admitió|ordenó)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(dijo|preguntó|miró|escribió|llamó|respondió|vio|pensó|sonrió|ordenó)\b.{0,40}\b' +
            escaped +
            r'\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b' +
            escaped +
            r'\b.{0,40}\b(madre|padre|hermana|hermano|jefa|jefe|vecina|vecino|abogada|abogado|profesora|profesor|periodista|reportera|reportero|detective)\b',
        caseSensitive: false,
      ),
    ];
    return patterns.any((pattern) => pattern.hasMatch(selection));
  }

  static bool hasHumanContext(String selection, String name) {
    final escaped = RegExp.escape(name);
    final patterns = <RegExp>[
      RegExp(
        r'\b' +
            escaped +
            r'\s+(dijo|preguntó|respondió|escribió|miró|llamó|vio|pensó|sonrió|admitió|ordenó)\b',
      ),
      RegExp(r'\b' + escaped + r'\s+me\b'),
      RegExp(r'—[^—\n]{0,60}\b' + escaped + r'\b'),
      RegExp(
        r'\b(dijo|preguntó|respondió|escribió|miró|llamó|vio|pensó|sonrió|admitió|ordenó)\b.{0,40}\b' +
            escaped +
            r'\b',
      ),
      RegExp(
        r'\b' +
            escaped +
            r'\s+(estaba|estuvo|seguía|discutía|tecleaba|trabajaba|sonreía|se\s+giró|se\s+volvió|salió|entró|llevaba|cubría|acompañó)\b',
        caseSensitive: false,
      ),
    ];
    return patterns.any((pattern) => pattern.hasMatch(selection));
  }

  static bool hasDirectPresentationContext(String selection, String name) {
    final escaped = RegExp.escape(name);
    final patterns = <RegExp>[
      RegExp(
        r'\b' +
            escaped +
            r'\b.{0,40}\b(' +
            (TextAnalysisLexicons.professionCues +
                    TextAnalysisLexicons.relationshipCues)
                .join('|') +
            r')\b',
        caseSensitive: false,
      ),
      RegExp(r'mensaje de\s+' + escaped, caseSensitive: false),
      RegExp(r'\b' + escaped + r'\s*:\s*[“"]'),
    ];
    return patterns.any((pattern) => pattern.hasMatch(selection));
  }

  static bool isFullName(String candidate) {
    final parts = candidate
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length < 2) return false;
    for (final part in parts) {
      if (isBlockedCapitalizedWord(part) || isCommonNonEntityWord(part)) {
        return false;
      }
    }
    final lowered = candidate.toLowerCase();
    if (lowered.contains('san francisco') ||
        lowered.contains('mission district')) {
      return false;
    }
    return true;
  }

  static bool isSameCharacter(String a, String b) {
    final normalizedA = a.trim().toLowerCase();
    final normalizedB = b.trim().toLowerCase();
    if (normalizedA.isEmpty || normalizedB.isEmpty) return false;
    if (normalizedA == normalizedB) return true;
    if (normalizedA.contains(normalizedB) ||
        normalizedB.contains(normalizedA)) {
      return true;
    }
    final firstA = normalizedA.split(RegExp(r'\s+')).first;
    final firstB = normalizedB.split(RegExp(r'\s+')).first;
    final hasFullName =
        isFullName(a) || isFullName(b) || a.contains(' ') || b.contains(' ');
    return hasFullName && firstA.length > 2 && firstA == firstB;
  }

  static int computeCharacterStrength({
    required String name,
    required String context,
  }) {
    var score = 0;
    if (isFullName(name)) score += 3;
    if (inferProfession(context, name).isNotEmpty) score += 2;

    final escaped = RegExp.escape(name);
    final localContextMatch = RegExp(
      r'\b' + escaped + r'\b([^.!?\n]{0,120})',
      caseSensitive: false,
    ).firstMatch(context);
    final localContext =
        '${context.toLowerCase()} ${(localContextMatch?.group(1) ?? '').toLowerCase()}';

    if (RegExp(r'\b\d{1,3}\b').hasMatch(localContext) ||
        RegExp(
          r'\b(veinte|treinta|cuarenta|cincuenta|sesenta|setenta|ochenta|noventa)\b',
          caseSensitive: false,
        ).hasMatch(localContext)) {
      score += 2;
    }

    if (RegExp(
      r'\b(trabajaba como|era|se dedicaba a)\b',
      caseSensitive: false,
    ).hasMatch(localContext)) {
      score += 2;
    }

    if (hasDirectPresentationContext(context, name)) {
      score += 2;
    }

    if (TextAnalysisLexicons.relationshipCues
        .any((cue) => mentionsRelationshipCue(localContext, cue))) {
      score += 2;
    }

    if (RegExp(
      r'\b' +
          escaped +
          r'\s+(estaba|estuvo|seguía|discutía|tecleaba|trabajaba|sonreía|se\s+giró|se\s+volvió|salió|entró|llevaba|cubría|acompañó)\b',
      caseSensitive: false,
    ).hasMatch(context)) {
      score += 2;
    }

    if (hasHumanContext(context, name) ||
        RegExp(r'—[^—\n]{0,80}\b' + escaped + r'\b', caseSensitive: false)
            .hasMatch(context)) {
      score += 1;
    }

    return score;
  }

  static bool mentionsRelationshipCue(String normalized, String cue) {
    final pattern = RegExp(
      r'(^|[^a-záéíóúñ])(?:mi|su)\s+' +
          RegExp.escape(cue) +
          r'([^a-záéíóúñ]|$)|(^|[^a-záéíóúñ])' +
          RegExp.escape(cue) +
          r'\s+de\s+la\s+protagonista([^a-záéíóúñ]|$)|(^|[^a-záéíóúñ])' +
          RegExp.escape(cue) +
          r'\s+del\s+protagonista([^a-záéíóúñ]|$)',
      caseSensitive: false,
    );
    return pattern.hasMatch(normalized);
  }

  static String inferProfession(String selection, String name) {
    final escaped = RegExp.escape(name);
    final match = RegExp(
      r'\b' + escaped + r'\.\s*([A-ZÁÉÍÓÚÑa-záéíóúñ][^.!?\n]{3,80})[.!?\n]',
      caseSensitive: false,
    ).firstMatch(selection);
    if (match == null) return '';

    final sentence = match.group(1)!.trim();
    final lowered = sentence.toLowerCase();
    for (final cue in TextAnalysisLexicons.professionCues) {
      if (lowered.contains(cue)) {
        return sentence;
      }
    }
    return '';
  }

  static bool isLikelyFirstPersonNarrator(String selection) {
    final normalized = ' ${selection.trim().toLowerCase()} ';
    var score = 0;
    for (final cue in TextAnalysisLexicons.firstPersonCues) {
      if (normalized.contains(cue)) {
        score += 1;
      }
    }

    final hasMe = normalized.contains(' me ') || normalized.contains(' mi ');
    final hasFirstPersonVerb =
        RegExp(r'\b[a-záéíóúñ]+é\b', caseSensitive: false)
                .hasMatch(normalized) ||
            normalized.contains(' era ') ||
            normalized.contains(' estaba ') ||
            normalized.contains(' tenía ') ||
            normalized.contains(' quería ') ||
            normalized.contains(' sabía ') ||
            normalized.contains(' debía ');
    if (hasMe && hasFirstPersonVerb) {
      score += 2;
    }

    return score >= 2;
  }

  static bool isBroadGeographicContext(String candidate) {
    final normalized = candidate.trim();
    return TextAnalysisLexicons.topLevelGeography.contains(normalized);
  }

  static String? inferScenarioFunction(String context) {
    final normalized = ' ${context.toLowerCase()} ';
    if (_containsAny(
        normalized, TextAnalysisLexicons.scenarioFunctionCrimeSignals)) {
      return 'Escena de crimen';
    }
    if (_containsAny(
        normalized, TextAnalysisLexicons.scenarioFunctionIntimacySignals)) {
      return 'Espacio de intimidad';
    }
    if (_containsAny(
        normalized, TextAnalysisLexicons.scenarioFunctionWorkSignals)) {
      return 'Lugar de trabajo';
    }
    if (_containsAny(
        normalized, TextAnalysisLexicons.scenarioFunctionTransitSignals)) {
      return 'Zona de tránsito';
    }
    if (_containsAny(
        normalized, TextAnalysisLexicons.scenarioFunctionWaitingSignals)) {
      return 'Espacio de espera';
    }
    if (_containsAny(
        normalized, TextAnalysisLexicons.scenarioFunctionObservationSignals)) {
      return 'Lugar de observación';
    }
    return null;
  }

  static int computeScenarioStrength({
    required String name,
    required String context,
  }) {
    final normalized = ' ${context.toLowerCase()} ';
    var score = 0;

    if (!isBroadGeographicContext(name) &&
        TextAnalysisLexicons.scenarioCoreWords
            .any((word) => name.toLowerCase().contains(word))) {
      score += 3;
    } else if (!isBroadGeographicContext(name) && name.trim().isNotEmpty) {
      score += 2;
    }

    if (_containsAny(normalized, TextAnalysisLexicons.scenarioAtmosphereTerms)) {
      score += 2;
    }

    if (_containsAny(normalized, TextAnalysisLexicons.scenarioObjectTerms)) {
      score += 2;
    }

    if (inferScenarioFunction(context) != null) {
      score += 2;
    }

    final nameLower = name.toLowerCase();
    if (nameLower.isNotEmpty &&
        RegExp(RegExp.escape(nameLower))
                .allMatches(context.toLowerCase())
                .length >
            1) {
      score += 1;
    }

    if (isBroadGeographicContext(name) && score <= 2) {
      score = 1;
    }

    return score;
  }

  static bool isSameScenario(String a, String b) {
    final normalizedA = a.trim().toLowerCase();
    final normalizedB = b.trim().toLowerCase();
    if (normalizedA.isEmpty || normalizedB.isEmpty) return false;
    if (normalizedA == normalizedB) return true;
    if (normalizedA.contains(normalizedB) ||
        normalizedB.contains(normalizedA)) {
      return true;
    }
    for (final core in TextAnalysisLexicons.scenarioCoreWords) {
      if (normalizedA.contains(core) && normalizedB.contains(core)) {
        return true;
      }
    }
    return false;
  }

  static bool _containsAny(String normalized, List<String> terms) {
    for (final term in terms) {
      if (normalized.contains(term)) return true;
    }
    return false;
  }
}
