import '../models/book.dart';
import '../models/narrative_copilot.dart';

class NextBestMoveRecommendation {
  final String focus;
  final String reason;
  final String suggestedAction;
  final String riskIfIgnored;
  final String contextTrace;
  final NextBestMoveStrategy strategy;

  const NextBestMoveRecommendation({
    required this.focus,
    required this.reason,
    required this.suggestedAction,
    required this.riskIfIgnored,
    this.contextTrace = '',
    required this.strategy,
  });

  String get move => suggestedAction;

  NextBestMoveRecommendation copyWith({
    String? contextTrace,
  }) {
    return NextBestMoveRecommendation(
      focus: focus,
      reason: reason,
      suggestedAction: suggestedAction,
      riskIfIgnored: riskIfIgnored,
      contextTrace: contextTrace ?? this.contextTrace,
      strategy: strategy,
    );
  }
}

enum NextBestMoveStrategy {
  setup,
  pressure,
  decision,
  consequence,
  information,
  character,
  support,
}

class NextBestMoveService {
  const NextBestMoveService();

  String recommend({
    required Book book,
    required StoryAct act,
    required int globalTension,
    required bool realProgress,
    required bool hasInvestigationLoop,
    required NarrativeMemory memory,
    required List<String> diagnostics,
    String? currentText,
    String? previousMove,
  }) {
    return recommendDetailed(
      book: book,
      act: act,
      globalTension: globalTension,
      realProgress: realProgress,
      hasInvestigationLoop: hasInvestigationLoop,
      memory: memory,
      diagnostics: diagnostics,
      currentText: currentText,
      previousMove: previousMove,
    ).move;
  }

  NextBestMoveRecommendation recommendDetailed({
    required Book book,
    required StoryAct act,
    required int globalTension,
    required bool realProgress,
    required bool hasInvestigationLoop,
    required NarrativeMemory memory,
    required List<String> diagnostics,
    String? currentText,
    String? previousMove,
  }) {
    final genre = book.narrativeProfile.primaryGenre;
    final previousStrategy = _inferStrategy(previousMove);

    if (book.narrativeProfile.readerPromise?.trim().isEmpty ?? true) {
      return const NextBestMoveRecommendation(
        focus: 'promesa narrativa',
        reason:
            'El ADN narrativo todavía no dice qué experiencia debe sostener el libro.',
        suggestedAction:
            'Define una promesa de lectura concreta antes de pedirle más a la próxima escena.',
        riskIfIgnored:
            'La escena seguirá sin dirección clara y el libro quedará sin tensión de lectura.',
        strategy: NextBestMoveStrategy.setup,
      );
    }

    var contextTrace = '';
    final contextualResolution = _contextualSceneRecommendation(
      currentText,
      memory,
    );
    if (contextualResolution.recommendation != null) {
      return contextualResolution.recommendation!;
    }
    if (contextualResolution.rejectionTrace != null) {
      contextTrace = contextualResolution.rejectionTrace!;
    }

    if (hasInvestigationLoop) {
      if (previousStrategy == NextBestMoveStrategy.information) {
        return _withContextTrace(
          const NextBestMoveRecommendation(
            focus: 'consecuencia',
            reason:
                'La última recomendación ya empujaba información; ahora conviene variar hacia consecuencia.',
            suggestedAction:
                'No abras otra pista: convierte lo ya encontrado en una consecuencia visible.',
            riskIfIgnored:
                'La investigación puede quedarse en bucle y perder presión narrativa.',
            strategy: NextBestMoveStrategy.consequence,
          ),
          contextTrace,
        );
      }
      return _withContextTrace(
        const NextBestMoveRecommendation(
          focus: 'información con coste',
          reason:
              'Detecto varias búsquedas y pistas seguidas sin una consecuencia proporcional.',
          suggestedAction:
              'Rompe la cadena de investigación: la próxima pista debe obligar a elegir, perder algo o exponerse.',
          riskIfIgnored:
              'La escena repetirá búsqueda sin cambio y el hallazgo perderá valor dramático.',
          strategy: NextBestMoveStrategy.information,
        ),
        contextTrace,
      );
    }

    if (previousStrategy == NextBestMoveStrategy.information &&
        memory.openQuestions.length > 4) {
      final question = _specificOpenQuestion(memory);
      return _withContextTrace(
        NextBestMoveRecommendation(
          focus: 'decisión',
          reason: question == null
              ? 'La última recomendación ya iba hacia información; ahora conviene variar hacia decisión.'
              : 'La pregunta pendiente “$question” necesita afectar una elección concreta.',
          suggestedAction:
              'Convierte una pregunta abierta en una decisión de escena antes de sumar otra línea.',
          riskIfIgnored:
              'La escena acumulará incertidumbre sin convertirla en movimiento.',
          strategy: NextBestMoveStrategy.decision,
        ),
        contextTrace,
      );
    }

    if (!realProgress) {
      return _withContextTrace(
        switch (genre) {
          BookPrimaryGenre.thriller => const NextBestMoveRecommendation(
              focus: 'presión directa',
              reason:
                  'El tramo no cambia bastante la amenaza, la información o la posición emocional.',
              suggestedAction:
                  'Falta presión directa: haz que alguien actúe contra la protagonista o que el tiempo se cierre.',
              riskIfIgnored:
                  'La escena se quedará plana y el thriller perderá urgencia.',
              strategy: NextBestMoveStrategy.pressure,
            ),
          BookPrimaryGenre.scienceFiction => const NextBestMoveRecommendation(
              focus: 'consecuencia de la idea',
              reason:
                  'La escena explica, pero todavía no altera el sistema ni el margen de acción.',
              suggestedAction:
                  'La idea necesita consecuencia: convierte la explicación en una regla que obligue a decidir.',
              riskIfIgnored:
                  'La explicación quedará decorativa y no moverá el sistema.',
              strategy: NextBestMoveStrategy.consequence,
            ),
          BookPrimaryGenre.fantasy => const NextBestMoveRecommendation(
              focus: 'atmósfera con peso',
              reason:
                  'La pausa de mundo funciona mejor si deja una presión narrativa debajo.',
              suggestedAction:
                  'Conserva la atmósfera, pero ata la próxima imagen a una deuda, destino o conflicto latente.',
              riskIfIgnored:
                  'La atmósfera se quedará flotando sin fricción ni destino.',
              strategy: NextBestMoveStrategy.pressure,
            ),
          _ => const NextBestMoveRecommendation(
              focus: 'cambio visible',
              reason:
                  'No detecto un avance claro que modifique la situación de la escena.',
              suggestedAction:
                  'Añade un cambio visible: información nueva, amenaza concreta o giro emocional.',
              riskIfIgnored:
                  'La escena puede quedarse en una meseta sin diferencia perceptible.',
              strategy: NextBestMoveStrategy.consequence,
            ),
        },
        contextTrace,
      );
    }

    if (memory.openQuestions.length > 4) {
      final question = _specificOpenQuestion(memory);
      if (previousStrategy == NextBestMoveStrategy.information) {
        return _withContextTrace(
          NextBestMoveRecommendation(
            focus: 'decisión',
            reason: question == null
                ? 'La última recomendación ya iba hacia información; ahora conviene variar hacia decisión.'
                : 'La pregunta pendiente “$question” necesita afectar una elección concreta.',
            suggestedAction:
                'Convierte una pregunta abierta en una decisión de escena antes de sumar otra línea.',
            riskIfIgnored:
                'La escena seguirá sumando dudas sin convertirlas en acción.',
            strategy: NextBestMoveStrategy.decision,
          ),
          contextTrace,
        );
      }
      return _withContextTrace(
        NextBestMoveRecommendation(
          focus: 'incertidumbre',
          reason: question == null
              ? 'Hay demasiadas preguntas abiertas compitiendo por la atención.'
              : 'Esa pregunta ya concentra la incertidumbre; añadir más puede dispersar la escena.',
          suggestedAction: question == null
              ? 'Cierra o transforma una pregunta abierta antes de plantar otra.'
              : 'Cierra o transforma esta pregunta antes de plantar otra: “$question”.',
          riskIfIgnored:
              'La escena se llenará de preguntas sin jerarquía ni avance.',
          strategy: NextBestMoveStrategy.information,
        ),
        contextTrace,
      );
    }

    if (globalTension < 30 && genre == BookPrimaryGenre.thriller) {
      return _withContextTrace(
        const NextBestMoveRecommendation(
          focus: 'urgencia',
          reason:
              'Para thriller, la tensión global sigue baja frente a la promesa del género.',
          suggestedAction:
              'Antes de abrir más contexto, sube la urgencia con amenaza, reloj o persecución.',
          riskIfIgnored:
              'El capítulo puede perder la presión que sostiene el género.',
          strategy: NextBestMoveStrategy.pressure,
        ),
        contextTrace,
      );
    }

    return _withContextTrace(
      switch (act) {
        StoryAct.actI => const NextBestMoveRecommendation(
            focus: 'promesa inicial',
            reason:
                'El Acto I debe introducir el libro y dejar clara su primera tensión.',
            suggestedAction:
                'Afila la promesa inicial: presenta una fractura que obligue a seguir leyendo.',
            riskIfIgnored:
                'La apertura puede quedar sin dirección ni incentivo de lectura.',
            strategy: NextBestMoveStrategy.pressure,
          ),
        StoryAct.actII => const NextBestMoveRecommendation(
            focus: 'coste narrativo',
            reason:
                'El Acto II debe convertir lo abierto en presión y consecuencia.',
            suggestedAction:
                'Complica la línea principal con una elección que tenga coste narrativo.',
            riskIfIgnored:
                'La trama se puede quedar en desarrollo sin fricción suficiente.',
            strategy: NextBestMoveStrategy.decision,
          ),
        StoryAct.actIII => const NextBestMoveRecommendation(
            focus: 'confrontación',
            reason: 'El Acto III debe llevar lo acumulado a confrontación.',
            suggestedAction:
                'Confronta la amenaza central y paga una pista o herida plantada antes.',
            riskIfIgnored:
                'El cierre puede llegar sin resolver el peso acumulado.',
            strategy: NextBestMoveStrategy.consequence,
          ),
      },
      contextTrace,
    );
  }

  _ContextResolution _contextualSceneRecommendation(
    String? currentText,
    NarrativeMemory memory,
  ) {
    final sceneTokens = _tokenSet(currentText);
    if (sceneTokens.isEmpty) return const _ContextResolution();

    final prioritizedBuckets = [
      _ContextBucket(
        focus: 'restricción del sistema',
        items: memory.systemConstraints,
        traceSuffix: 'SystemConstraints',
        requiresQualityGate: true,
        suggestedAction: (context) =>
            'Usa la restricción “$context” para obligar una decisión en la escena.',
        reason: (context) =>
            'La escena comparte vocabulario con una restricción ya guardada.',
        riskIfIgnored: (context) =>
            'La restricción “$context” quedará como fondo y no moverá la escena.',
        strategy: NextBestMoveStrategy.decision,
      ),
      _ContextBucket(
        focus: 'regla del mundo',
        items: memory.worldRules,
        traceSuffix: 'WorldRules',
        requiresQualityGate: true,
        suggestedAction: (context) =>
            'Usa la regla “$context” para generar consecuencia visible.',
        reason: (context) =>
            'La escena toca una regla persistente ya establecida en el libro.',
        riskIfIgnored: (context) =>
            'La regla “$context” se quedará decorativa en lugar de pesar en la escena.',
        strategy: NextBestMoveStrategy.consequence,
      ),
      _ContextBucket(
        focus: 'hallazgo de investigación',
        items: memory.researchFindings,
        traceSuffix: 'ResearchFindings',
        suggestedAction: (context) =>
            'Convierte el hallazgo “$context” en un efecto observable ahora.',
        reason: (context) =>
            'La escena retoma un hallazgo previo y puede volverlo operativo.',
        riskIfIgnored: (context) =>
            'El hallazgo “$context” se quedará en exposición sin efecto.',
        strategy: NextBestMoveStrategy.information,
      ),
      _ContextBucket(
        focus: 'concepto persistente',
        items: memory.persistentConcepts,
        traceSuffix: 'PersistentConcepts',
        suggestedAction: (context) =>
            'Haz que el concepto “$context” cambie la elección o el coste de la escena.',
        reason: (context) =>
            'La escena comparte un concepto persistente con la memoria del libro.',
        riskIfIgnored: (context) =>
            'El concepto “$context” no dejará huella práctica en la escena.',
        strategy: NextBestMoveStrategy.character,
      ),
    ];

    String? rejectionTrace;
    for (final bucket in prioritizedBuckets) {
      final match = _bestContextMatch(sceneTokens, bucket.items);
      if (match == null) continue;
      if (bucket.requiresQualityGate) {
        final gate = _evaluateContextConfidence(match);
        if (!gate.accepted) {
          rejectionTrace ??= gate.trace;
          continue;
        }
      }
      return _ContextResolution(
        recommendation: NextBestMoveRecommendation(
          focus: bucket.focus,
          reason: bucket.reason(match),
          suggestedAction: bucket.suggestedAction(match),
          riskIfIgnored: bucket.riskIfIgnored(match),
          contextTrace: 'contextAccepted${bucket.traceSuffix}',
          strategy: bucket.strategy,
        ),
      );
    }

    return _ContextResolution(rejectionTrace: rejectionTrace);
  }

  String? _bestContextMatch(Set<String> sceneTokens, List<String> items) {
    String? bestItem;
    var bestScore = 0;
    var bestIndex = -1;

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final itemTokens = _tokenSet(item);
      if (itemTokens.isEmpty) continue;
      final shared = sceneTokens.intersection(itemTokens);
      final score = shared.length;
      if (score < 1) continue;
      if (score > bestScore || (score == bestScore && index > bestIndex)) {
        bestItem = item;
        bestScore = score;
        bestIndex = index;
      }
    }

    return bestItem;
  }

  Set<String> _tokenSet(String? text) {
    if (text == null || text.trim().isEmpty) return const <String>{};
    final tokens = RegExp(r'[a-záéíóúñü]{3,}', caseSensitive: false)
        .allMatches(text.toLowerCase())
        .map((match) => match.group(0)!)
        .where((token) => !_stopWords.contains(token))
        .toSet();
    return tokens;
  }

  _ContextGateResult _evaluateContextConfidence(String value) {
    final lowered = value.toLowerCase();
    final hasStructuralMarker = _containsAny(lowered, _structuralMarkers);
    final hasOperationalVerb = _containsAny(lowered, _operationalVerbs);
    final isDialogLike = _isDialogLike(value);
    final isGeneric = _containsAny(lowered, _genericSignals);
    final isTooShort =
        lowered.replaceAll(RegExp(r'\s+'), ' ').trim().length < 28;
    final hasEnoughLength =
        lowered.replaceAll(RegExp(r'\s+'), ' ').trim().length >= 45;

    var score = 0;
    if (hasStructuralMarker) score += 1;
    if (hasEnoughLength) score += 1;
    if (hasOperationalVerb) score += 1;
    if (isDialogLike) score -= 1;
    if (isGeneric) score -= 1;
    if (isTooShort) score -= 1;

    if (!hasStructuralMarker) {
      return const _ContextGateResult(
        accepted: false,
        trace: 'contextRejectedNoStructuralMarkers',
      );
    }
    if (isDialogLike) {
      return const _ContextGateResult(
        accepted: false,
        trace: 'contextRejectedDialogLike',
      );
    }
    if (score < 2 || !hasOperationalVerb) {
      return const _ContextGateResult(
        accepted: false,
        trace: 'contextRejectedLowConfidence',
      );
    }

    return const _ContextGateResult(
      accepted: true,
      trace: 'contextAcceptedByGate',
    );
  }

  bool _isDialogLike(String value) {
    final trimmed = value.trim();
    final compactLength = trimmed.replaceAll(RegExp(r'\s+'), ' ').length;
    final hasDialogPunctuation = trimmed.startsWith('—') ||
        trimmed.startsWith('-') ||
        trimmed.startsWith('"') ||
        trimmed.startsWith('“') ||
        trimmed.endsWith('"') ||
        trimmed.endsWith('”');
    final hasConversationCue = _containsAny(trimmed.toLowerCase(), const [
      'dijo',
      'preguntó',
      'respondió',
      'murmuró',
      'contestó',
      'dime',
      'mira',
    ]);
    return hasDialogPunctuation || (compactLength < 45 && hasConversationCue);
  }

  bool _containsAny(String value, List<String> tokens) {
    for (final token in tokens) {
      if (value.contains(token)) return true;
    }
    return false;
  }

  NextBestMoveRecommendation _withContextTrace(
    NextBestMoveRecommendation recommendation,
    String contextTrace,
  ) {
    if (contextTrace.isEmpty) return recommendation;
    if (recommendation.contextTrace.isNotEmpty) return recommendation;
    return recommendation.copyWith(contextTrace: contextTrace);
  }

  NextBestMoveStrategy? _inferStrategy(String? move) {
    final lowered = move?.toLowerCase();
    if (lowered == null || lowered.isEmpty) return null;
    if (lowered.contains('pista') ||
        lowered.contains('pregunta') ||
        lowered.contains('información')) {
      return NextBestMoveStrategy.information;
    }
    if (lowered.contains('presión') ||
        lowered.contains('urgencia') ||
        lowered.contains('amenaza')) {
      return NextBestMoveStrategy.pressure;
    }
    if (lowered.contains('decisión') || lowered.contains('eleg')) {
      return NextBestMoveStrategy.decision;
    }
    if (lowered.contains('consecuencia') ||
        lowered.contains('perder') ||
        lowered.contains('coste')) {
      return NextBestMoveStrategy.consequence;
    }
    return null;
  }

  String? _specificOpenQuestion(NarrativeMemory memory) {
    if (memory.openQuestions.isEmpty) return null;
    final question = memory.openQuestions.first.trim();
    if (question.isEmpty) return null;
    if (question.length <= 90) return question;
    return '${question.substring(0, 87).trimRight()}...';
  }

  static const Set<String> _stopWords = {
    'una',
    'uno',
    'unos',
    'unas',
    'que',
    'por',
    'para',
    'con',
    'sin',
    'sobre',
    'entre',
    'esta',
    'este',
    'esto',
    'como',
    'cuando',
    'donde',
    'porque',
    'pero',
    'tambien',
    'también',
    'cada',
    'todo',
    'toda',
    'todas',
    'todos',
    'puede',
    'pueden',
    'debe',
    'deben',
    'hay',
    'ser',
    'está',
    'están',
    'estan',
    'hace',
    'hacer',
    'más',
    'mas',
    'muy',
    'del',
    'los',
    'las',
    'al',
    'el',
    'la',
    'lo',
    'y',
    'o',
  };

  static const List<String> _structuralMarkers = [
    'regla',
    'límite',
    'limite',
    'coste',
    'costo',
    'obliga',
    'obligado',
    'obligación',
    'obligacion',
    'prohíbe',
    'prohibe',
    'prohibido',
    'restricción',
    'restriccion',
    'impide',
    'requiere',
    'solo puede',
    'no puede',
    'depende de',
    'a cambio de',
    'bajo condición',
    'bajo condicion',
  ];

  static const List<String> _operationalVerbs = [
    'obliga',
    'requiere',
    'impide',
    'limita',
    'prohíbe',
    'prohibe',
    'prohibido',
    'cuesta',
    'coste',
    'costo',
    'depende de',
    'solo puede',
    'no puede',
    'a cambio de',
  ];

  static const List<String> _genericSignals = [
    'depende de quien',
    'ya veremos',
    'puede ser',
    'tal vez',
    'quizá',
    'quizas',
    'quien lo mire',
  ];
}

class _ContextBucket {
  final String focus;
  final List<String> items;
  final String Function(String context) suggestedAction;
  final String Function(String context) reason;
  final String Function(String context) riskIfIgnored;
  final bool requiresQualityGate;
  final String traceSuffix;
  final NextBestMoveStrategy strategy;

  const _ContextBucket({
    required this.focus,
    required this.items,
    required this.suggestedAction,
    required this.reason,
    required this.riskIfIgnored,
    this.requiresQualityGate = false,
    required this.traceSuffix,
    required this.strategy,
  });
}

class _ContextGateResult {
  final bool accepted;
  final String trace;

  const _ContextGateResult({
    required this.accepted,
    required this.trace,
  });
}

class _ContextResolution {
  final NextBestMoveRecommendation? recommendation;
  final String? rejectionTrace;

  const _ContextResolution({
    this.recommendation,
    this.rejectionTrace,
  });
}
