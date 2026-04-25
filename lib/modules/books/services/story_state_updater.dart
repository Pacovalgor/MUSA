import '../../../editor/services/text_analysis_lexicons.dart';
import '../../../editor/services/text_normalizer.dart';
import '../../manuscript/models/document.dart';
import '../models/book.dart';
import '../models/narrative_copilot.dart';
import 'narrative_document_classifier.dart';
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
    this.documentClassifier = const NarrativeDocumentClassifier(),
  });

  final NextBestMoveService nextBestMoveService;
  final NarrativeDocumentClassifier documentClassifier;

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
    final classified = [
      for (final document in ordered)
        _ClassifiedDocument(
          document: document,
          classification: documentClassifier.classify(document),
        ),
    ];
    final narrativeDocuments = classified
        .where((item) => item.classification.updatesStoryState)
        .map((item) => item.document)
        .toList();
    final latestClassification =
        classified.isEmpty ? null : classified.last.classification;

    if (latestClassification != null &&
        !latestClassification.updatesStoryState) {
      return _nonNarrativeState(
        book: book,
        previous: previous,
        now: now,
        memory: memory,
        classification: latestClassification,
      );
    }

    final effectiveDocuments =
        narrativeDocuments.isEmpty ? ordered : narrativeDocuments;
    final chapterCount = effectiveDocuments
        .where((item) => item.kind == DocumentKind.chapter)
        .length;
    final act = _inferAct(chapterCount);
    final recentText = effectiveDocuments.reversed
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
      documents: effectiveDocuments,
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
      documentKind: latestClassification?.kind,
      currentText: recentText,
      previousMove: previous?.nextBestMove,
    );

    return draft.copyWith(
      nextBestMove: recommendation.move,
      nextBestMoveReason: recommendation.reason,
    );
  }

  StoryState _nonNarrativeState({
    required Book book,
    required StoryState? previous,
    required DateTime now,
    required NarrativeMemory memory,
    required NarrativeDocumentClassification classification,
  }) {
    final base = previous ?? StoryState.empty(book.id, now);
    final move = switch (classification.kind) {
      NarrativeDocumentKind.research => memory.researchFindings.isEmpty
          ? 'Documento tratado como investigación; no altera el estado narrativo del libro.'
          : 'Documento tratado como investigación; suma contexto sin alterar el estado narrativo.',
      NarrativeDocumentKind.worldbuilding => memory.worldRules.isEmpty &&
              memory.systemConstraints.isEmpty
          ? 'Material de worldbuilding válido, pero sin impulso narrativo directo.'
          : 'Se detecta una regla persistente útil para el contexto del libro.',
      NarrativeDocumentKind.technical =>
        'Esto parece material técnico; no debe contaminar el estado narrativo del libro.',
      NarrativeDocumentKind.unknown =>
        'No lo trataría como escena hasta que haya acción narrativa más clara.',
      NarrativeDocumentKind.scene =>
        'Continúa la escena desde una decisión o consecuencia concreta.',
    };
    return base.copyWith(
      diagnostics: [
        'Documento no narrativo: ${_documentKindLabel(classification.kind)}.',
      ],
      nextBestMove: move,
      nextBestMoveReason: classification.reason,
      updatedAt: now,
    );
  }

  String _documentKindLabel(NarrativeDocumentKind kind) {
    return switch (kind) {
      NarrativeDocumentKind.scene => 'escena',
      NarrativeDocumentKind.research => 'investigación',
      NarrativeDocumentKind.worldbuilding => 'worldbuilding',
      NarrativeDocumentKind.technical => 'técnico',
      NarrativeDocumentKind.unknown => 'desconocido',
    };
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
    for (final token in TextAnalysisLexicons.tensionTokens) {
      if (lowered.contains(token)) score += 8;
    }
    if (genre == BookPrimaryGenre.thriller) score += 12;
    // Floor: la memoria acumulada marca un mínimo de tensión que los capítulos
    // de pausa no pueden borrar por completo.
    final memoryFloor = (memory.activeThreats.length * 6 +
            memory.openQuestions.length * 3 +
            (genre == BookPrimaryGenre.thriller ? 8 : 0))
        .clamp(0, 50);
    return score.clamp(memoryFloor, 100);
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
    return _hasAffirmedAny(lowered, TextAnalysisLexicons.progressDefaultTokens);
  }

  bool _hasMemoryProgressSignal(String lowered, NarrativeMemory memory) {
    final hasThreat = memory.activeThreats.isNotEmpty &&
        _hasAffirmedAny(lowered, TextAnalysisLexicons.progressThreatTokens);
    final hasFact = memory.importantFacts.isNotEmpty &&
        _hasAffirmedAny(lowered, TextAnalysisLexicons.progressFactTokens);
    final hasShift =
        memory.recentCharacterShifts.isNotEmpty && _hasStructuralShift(lowered);
    return hasThreat || hasFact || hasShift;
  }

  bool _hasSystemImplication(String lowered) {
    final hasSystem =
        _hasAffirmedAny(lowered, TextAnalysisLexicons.systemTokens);
    return hasSystem && _hasStructuralShift(lowered);
  }

  bool _hasStructuralShift(String lowered) {
    return _hasAffirmedAny(lowered, TextAnalysisLexicons.structuralShiftTokens);
  }

  bool _hasLatentFantasyConflict(String lowered) {
    final hasWorldTexture = _hasAffirmedAny(
        lowered, TextAnalysisLexicons.fantasyWorldTextureTokens);
    final hasPressure =
        _hasAffirmedAny(lowered, TextAnalysisLexicons.fantasyPressureTokens);
    return hasWorldTexture && hasPressure && _hasStructuralShift(lowered);
  }

  bool _hasAffirmedAny(String lowered, List<String> tokens) {
    for (final token in tokens) {
      if (_hasAffirmedToken(lowered, token)) return true;
      final synonyms = TextAnalysisLexicons.synonymMap[token.toLowerCase()];
      if (synonyms == null) continue;
      for (final synonym in synonyms) {
        if (_hasAffirmedToken(lowered, synonym)) return true;
      }
    }
    return false;
  }

  bool _hasAffirmedToken(String lowered, String token) {
    if (token.contains(' ')) {
      return _hasAffirmedSubstring(lowered, token);
    }

    final tokenStem = TextNormalizer.stem(token);
    if (tokenStem.isEmpty) return false;

    for (final match in TextNormalizer.wordPattern.allMatches(lowered)) {
      if (TextNormalizer.stem(match.group(0)!) != tokenStem) continue;

      final prefixStart = (match.start - 24).clamp(0, match.start);
      final prefix = lowered.substring(prefixStart, match.start);
      final suffixEnd = (match.end + 16).clamp(match.end, lowered.length);
      final suffix = lowered.substring(match.end, suffixEnd);
      if (!_isNegatedContext(prefix, suffix)) return true;
    }
    return false;
  }

  bool _hasAffirmedSubstring(String lowered, String token) {
    var start = 0;
    while (true) {
      final index = lowered.indexOf(token, start);
      if (index == -1) return false;
      final prefixStart = (index - 24).clamp(0, index);
      final prefix = lowered.substring(prefixStart, index);
      final suffixEnd =
          (index + token.length + 16).clamp(index, lowered.length);
      final suffix = lowered.substring(index + token.length, suffixEnd);
      if (!_isNegatedContext(prefix, suffix)) return true;
      start = index + token.length;
    }
  }

  bool _isNegatedContext(String prefix, String suffix) {
    return prefix.contains('sin ') ||
        prefix.contains(' ni ') ||
        prefix.contains('no ') ||
        prefix.contains('nadie ') ||
        suffix.contains(' nada');
  }

  bool _hasInvestigationLoop(String text) {
    final lowered = text.toLowerCase();
    // Verbos de acción investigadora (incluye búsquedas online: busqué, buscó...)
    final investigateCount =
        RegExp(r'investig|busc|pregunt|averigua').allMatches(lowered).length;
    // Indicios: tanto los clásicos como los del thriller moderno (símbolo, patrón,
    // captura, imagen) que sirven como pista aunque no se llamen así.
    final clueCount =
        RegExp(r'pista|indicio|rastro|huella|señal|símbolo|patrón|marca|captura|imagen|prueba|conexión')
            .allMatches(lowered)
            .length;
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

class _ClassifiedDocument {
  final Document document;
  final NarrativeDocumentClassification classification;

  const _ClassifiedDocument({
    required this.document,
    required this.classification,
  });
}
