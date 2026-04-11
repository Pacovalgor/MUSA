import '../../manuscript/models/document.dart';
import '../models/book.dart';
import '../models/narrative_copilot.dart';
import 'next_best_move_service.dart';

class StoryStateInput {
  final CurrentChapterFunction? chapterFunction;
  final bool? realProgress;
  final List<String> keyEvents;
  final List<String> diagnostics;

  const StoryStateInput({
    this.chapterFunction,
    this.realProgress,
    this.keyEvents = const [],
    this.diagnostics = const [],
  });
}

class StoryStateUpdater {
  const StoryStateUpdater({
    this.nextBestMoveService = const NextBestMoveService(),
  });

  final NextBestMoveService nextBestMoveService;

  StoryState update({
    required Book book,
    required List<Document> documents,
    required NarrativeMemory memory,
    required StoryState? previous,
    required DateTime now,
    StoryStateInput input = const StoryStateInput(),
  }) {
    final ordered = documents.toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final chapterCount =
        ordered.where((item) => item.kind == DocumentKind.chapter).length;
    final act = _inferAct(chapterCount);
    final recentText = ordered.reversed
        .take(3)
        .map((document) => document.content)
        .join('\n\n');
    final chapterFunction = input.chapterFunction ?? _inferChapterFunction(act);
    final globalTension = _inferTension(
      recentText: recentText,
      memory: memory,
      genre: book.narrativeProfile.primaryGenre,
    );
    final rhythm = _inferRhythm(
      documents: ordered,
      targetPace: book.narrativeProfile.targetPace,
      globalTension: globalTension,
    );
    final realProgress = input.realProgress ??
        _hasRealProgress(
          recentText,
          memory,
          book.narrativeProfile.primaryGenre,
        );
    final hasInvestigationLoop = _hasInvestigationLoop(recentText);
    final diagnostics = <String>[
      ...input.diagnostics,
      if (!realProgress)
        'No se detecta cambio claro de información, amenaza o estado emocional.',
      if (hasInvestigationLoop)
        'Se repite el patrón investigar-pista-investigar.',
      ..._genreDiagnostics(
          book.narrativeProfile.primaryGenre, recentText, globalTension),
    ];
    final recentKeyEvents = _dedupe([
      ...input.keyEvents,
      ...memory.importantFacts,
      ...memory.recentCharacterShifts,
    ]).take(5).toList();

    final draft = StoryState(
      bookId: book.id,
      currentAct: act,
      currentChapterFunction: chapterFunction,
      globalTension: globalTension,
      perceivedRhythm: rhythm,
      protagonistState: _inferProtagonistState(recentText),
      activeThreats: memory.activeThreats,
      openQuestions: memory.openQuestions,
      plantedClues: memory.plantedClues,
      recentKeyEvents: recentKeyEvents,
      diagnostics: diagnostics,
      updatedAt: now,
    );

    final recommendation = nextBestMoveService.recommendDetailed(
      book: book,
      act: act,
      globalTension: globalTension,
      realProgress: realProgress,
      hasInvestigationLoop: hasInvestigationLoop,
      memory: memory,
      diagnostics: diagnostics,
    );

    return draft.copyWith(
      nextBestMove: recommendation.move,
      nextBestMoveReason: recommendation.reason,
    );
  }

  StoryAct _inferAct(int chapterCount) {
    if (chapterCount <= 3) return StoryAct.actI;
    if (chapterCount <= 12) return StoryAct.actII;
    return StoryAct.actIII;
  }

  CurrentChapterFunction _inferChapterFunction(StoryAct act) {
    return switch (act) {
      StoryAct.actI => CurrentChapterFunction.introduce,
      StoryAct.actII => CurrentChapterFunction.complicate,
      StoryAct.actIII => CurrentChapterFunction.confront,
    };
  }

  int _inferTension({
    required String recentText,
    required NarrativeMemory memory,
    required BookPrimaryGenre genre,
  }) {
    final lowered = recentText.toLowerCase();
    var score =
        memory.activeThreats.length * 12 + memory.openQuestions.length * 4;
    for (final token in const [
      'amenaza',
      'peligro',
      'muerte',
      'huye',
      'arma',
      'sangre',
      'secreto'
    ]) {
      if (lowered.contains(token)) score += 8;
    }
    if (genre == BookPrimaryGenre.thriller) score += 12;
    return score.clamp(0, 100);
  }

  PerceivedRhythm _inferRhythm({
    required List<Document> documents,
    required TargetPace targetPace,
    required int globalTension,
  }) {
    final recent = documents.reversed.take(3).toList();
    final averageWords = recent.isEmpty
        ? 0
        : recent.map((item) => item.wordCount).fold<int>(0, (a, b) => a + b) ~/
            recent.length;
    if (globalTension > 70) return PerceivedRhythm.tense;
    if (averageWords > 3500 && targetPace == TargetPace.urgent) {
      return PerceivedRhythm.slow;
    }
    if (averageWords < 500 && documents.length > 2) {
      return PerceivedRhythm.rushed;
    }
    return PerceivedRhythm.steady;
  }

  bool _hasRealProgress(
    String text,
    NarrativeMemory memory,
    BookPrimaryGenre genre,
  ) {
    final lowered = text.toLowerCase();
    final hasSignal = _hasMemoryProgressSignal(lowered, memory);
    if (hasSignal) return true;
    if (genre == BookPrimaryGenre.scienceFiction &&
        _hasSystemImplication(lowered)) {
      return true;
    }
    if (genre == BookPrimaryGenre.fantasy &&
        _hasLatentFantasyConflict(lowered)) {
      return true;
    }
    return _hasAffirmedAny(lowered, const [
      'descubre',
      'decide',
      'revela',
      'amenaza',
      'confiesa',
      'pierde'
    ]);
  }

  bool _hasMemoryProgressSignal(String lowered, NarrativeMemory memory) {
    final hasThreat = memory.activeThreats.isNotEmpty &&
        _hasAffirmedAny(lowered, const [
          'amenaza',
          'peligro',
          'riesgo',
          'persecución',
          'muerte',
        ]);
    final hasFact = memory.importantFacts.isNotEmpty &&
        _hasAffirmedAny(lowered, const [
          'descubre',
          'revela',
          'sabe que',
          'comprende',
        ]);
    final hasShift =
        memory.recentCharacterShifts.isNotEmpty && _hasStructuralShift(lowered);
    return hasThreat || hasFact || hasShift;
  }

  bool _hasSystemImplication(String lowered) {
    final hasSystem = _hasAffirmedAny(lowered, const [
      'sistema',
      'tecnología',
      'algoritmo',
      'motor',
      'órbita',
      'colonia',
      'protocolo',
    ]);
    return hasSystem && _hasStructuralShift(lowered);
  }

  bool _hasStructuralShift(String lowered) {
    return _hasAffirmedAny(lowered, const [
      'obliga',
      'exige',
      'decide',
      'elige',
      'pierde',
      'cruza',
      'renuncia',
      'empuja',
      'marca',
      'implica',
      'cambia',
      'regla',
      'coste',
      'consecuencia',
      'prohíbe',
      'limita',
      'altera',
      'reduce',
      'aumenta',
      'impide',
    ]);
  }

  bool _hasLatentFantasyConflict(String lowered) {
    final hasWorldTexture = _hasAffirmedAny(lowered, const [
      'bosque',
      'reino',
      'magia',
      'templo',
      'dragón',
      'hechizo',
      'oráculo',
    ]);
    final hasPressure = _hasAffirmedAny(lowered, const [
      'deuda',
      'destino',
      'maldición',
      'juramento',
      'amenaza',
      'sombra',
      'guerra',
      'exilio',
    ]);
    return hasWorldTexture && hasPressure && _hasStructuralShift(lowered);
  }

  bool _hasAffirmedAny(String lowered, List<String> tokens) {
    for (final token in tokens) {
      if (_hasAffirmedToken(lowered, token)) return true;
    }
    return false;
  }

  bool _hasAffirmedToken(String lowered, String token) {
    var start = 0;
    while (true) {
      final index = lowered.indexOf(token, start);
      if (index == -1) return false;
      final prefixStart = (index - 24).clamp(0, index);
      final prefix = lowered.substring(prefixStart, index);
      final suffixEnd =
          (index + token.length + 16).clamp(index, lowered.length);
      final suffix = lowered.substring(index + token.length, suffixEnd);
      final isNegated = prefix.contains('sin ') ||
          prefix.contains(' ni ') ||
          prefix.contains('no ') ||
          prefix.contains('nadie ') ||
          suffix.contains(' nada');
      if (!isNegated) return true;
      start = index + token.length;
    }
  }

  bool _hasInvestigationLoop(String text) {
    final lowered = text.toLowerCase();
    final investigateCount =
        RegExp(r'investig|busca|pregunta|averigua').allMatches(lowered).length;
    final clueCount =
        RegExp(r'pista|indicio|rastro|huella|señal').allMatches(lowered).length;
    return investigateCount >= 2 && clueCount >= 2;
  }

  Iterable<String> _genreDiagnostics(
    BookPrimaryGenre genre,
    String text,
    int globalTension,
  ) sync* {
    final lowered = text.toLowerCase();
    switch (genre) {
      case BookPrimaryGenre.thriller:
        if (globalTension < 45) {
          yield 'Thriller: conviene reforzar tensión o urgencia.';
        }
        break;
      case BookPrimaryGenre.scienceFiction:
        if (_hasSystemImplication(lowered)) {
          yield 'Ciencia ficción: la explicación aporta porque cambia reglas o consecuencias.';
        } else if (lowered.contains('sistema') ||
            lowered.contains('tecnología')) {
          yield 'Ciencia ficción: la explicación necesita una consecuencia práctica.';
        }
        break;
      case BookPrimaryGenre.fantasy:
        if (_hasLatentFantasyConflict(lowered)) {
          yield 'Fantasía: la atmósfera queda sostenida por conflicto latente.';
        } else if (lowered.contains('reino') || lowered.contains('magia')) {
          yield 'Fantasía: la atmósfera necesita deuda, destino o conflicto debajo.';
        }
        break;
      default:
        break;
    }
  }

  String _inferProtagonistState(String text) {
    final lowered = text.toLowerCase();
    if (lowered.contains('miedo') || lowered.contains('teme')) {
      return 'En tensión';
    }
    if (lowered.contains('decide') || lowered.contains('elige')) {
      return 'Ante una decisión';
    }
    if (lowered.contains('duda')) return 'En duda';
    return '';
  }

  List<String> _dedupe(List<String> values) {
    final seen = <String>{};
    final results = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      results.add(trimmed);
    }
    return results;
  }
}
