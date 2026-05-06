import '../../../shared/utils/enum_codec.dart';

enum BookPrimaryGenre {
  literary,
  thriller,
  scienceFiction,
  fantasy,
  mystery,
  romance,
  historical,
  other
}

enum NarrativeScale { intimate, ensemble, epic }

enum TargetPace { slow, measured, agile, urgent }

enum DominantPriority { character, plot, atmosphere, idea, tension }

enum EndingType { open, bittersweet, resolved, tragic, ambiguous }

enum StoryAct { actI, actII, actIII }

enum CurrentChapterFunction {
  introduce,
  complicate,
  confront,
  reveal,
  transition,
  deepenCharacter,
  setup
}

enum PerceivedRhythm { slow, steady, uneven, tense, rushed }

class BookNarrativeProfile {
  final BookPrimaryGenre primaryGenre;
  final String? subgenre;
  final String? tone;
  final NarrativeScale scale;
  final TargetPace targetPace;
  final DominantPriority dominantPriority;
  final String? readerPromise;
  final EndingType endingType;

  const BookNarrativeProfile({
    this.primaryGenre = BookPrimaryGenre.literary,
    this.subgenre,
    this.tone,
    this.scale = NarrativeScale.intimate,
    this.targetPace = TargetPace.measured,
    this.dominantPriority = DominantPriority.character,
    this.readerPromise,
    this.endingType = EndingType.open,
  });

  BookNarrativeProfile copyWith({
    BookPrimaryGenre? primaryGenre,
    String? subgenre,
    bool clearSubgenre = false,
    String? tone,
    bool clearTone = false,
    NarrativeScale? scale,
    TargetPace? targetPace,
    DominantPriority? dominantPriority,
    String? readerPromise,
    bool clearReaderPromise = false,
    EndingType? endingType,
  }) {
    return BookNarrativeProfile(
      primaryGenre: primaryGenre ?? this.primaryGenre,
      subgenre: clearSubgenre ? null : (subgenre ?? this.subgenre),
      tone: clearTone ? null : (tone ?? this.tone),
      scale: scale ?? this.scale,
      targetPace: targetPace ?? this.targetPace,
      dominantPriority: dominantPriority ?? this.dominantPriority,
      readerPromise:
          clearReaderPromise ? null : (readerPromise ?? this.readerPromise),
      endingType: endingType ?? this.endingType,
    );
  }

  Map<String, dynamic> toJson() => {
        'primaryGenre': primaryGenre.name,
        'subgenre': subgenre,
        'tone': tone,
        'scale': scale.name,
        'targetPace': targetPace.name,
        'dominantPriority': dominantPriority.name,
        'readerPromise': readerPromise,
        'endingType': endingType.name,
      };

  factory BookNarrativeProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BookNarrativeProfile();
    return BookNarrativeProfile(
      primaryGenre: enumFromName(
        BookPrimaryGenre.values,
        json['primaryGenre'] as String?,
        BookPrimaryGenre.literary,
      ),
      subgenre: json['subgenre'] as String?,
      tone: json['tone'] as String?,
      scale: enumFromName(
        NarrativeScale.values,
        json['scale'] as String?,
        NarrativeScale.intimate,
      ),
      targetPace: enumFromName(
        TargetPace.values,
        json['targetPace'] as String?,
        TargetPace.measured,
      ),
      dominantPriority: enumFromName(
        DominantPriority.values,
        json['dominantPriority'] as String?,
        DominantPriority.character,
      ),
      readerPromise: json['readerPromise'] as String?,
      endingType: enumFromName(
        EndingType.values,
        json['endingType'] as String?,
        EndingType.open,
      ),
    );
  }
}

class NarrativeMemory {
  final String bookId;
  final List<String> openQuestions;
  final List<String> plantedClues;
  final List<String> activeThreats;
  final List<String> importantFacts;
  final List<String> recentCharacterShifts;
  final List<String> worldRules;
  final List<String> systemConstraints;
  final List<String> researchFindings;
  final List<String> persistentConcepts;
  final List<String> readerPromises;
  final List<String> unresolvedPromises;
  final List<String> toneSignals;
  final List<String> scenePatternWarnings;
  final DateTime updatedAt;

  const NarrativeMemory({
    required this.bookId,
    this.openQuestions = const [],
    this.plantedClues = const [],
    this.activeThreats = const [],
    this.importantFacts = const [],
    this.recentCharacterShifts = const [],
    this.worldRules = const [],
    this.systemConstraints = const [],
    this.researchFindings = const [],
    this.persistentConcepts = const [],
    this.readerPromises = const [],
    this.unresolvedPromises = const [],
    this.toneSignals = const [],
    this.scenePatternWarnings = const [],
    required this.updatedAt,
  });

  factory NarrativeMemory.empty(String bookId, DateTime now) {
    return NarrativeMemory(bookId: bookId, updatedAt: now);
  }

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'openQuestions': openQuestions,
        'plantedClues': plantedClues,
        'activeThreats': activeThreats,
        'importantFacts': importantFacts,
        'recentCharacterShifts': recentCharacterShifts,
        'worldRules': worldRules,
        'systemConstraints': systemConstraints,
        'researchFindings': researchFindings,
        'persistentConcepts': persistentConcepts,
        'readerPromises': readerPromises,
        'unresolvedPromises': unresolvedPromises,
        'toneSignals': toneSignals,
        'scenePatternWarnings': scenePatternWarnings,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NarrativeMemory.fromJson(Map<String, dynamic> json) {
    return NarrativeMemory(
      bookId: json['bookId'] as String,
      openQuestions:
          List<String>.from(json['openQuestions'] as List? ?? const []),
      plantedClues:
          List<String>.from(json['plantedClues'] as List? ?? const []),
      activeThreats:
          List<String>.from(json['activeThreats'] as List? ?? const []),
      importantFacts:
          List<String>.from(json['importantFacts'] as List? ?? const []),
      recentCharacterShifts:
          List<String>.from(json['recentCharacterShifts'] as List? ?? const []),
      worldRules: List<String>.from(json['worldRules'] as List? ?? const []),
      systemConstraints:
          List<String>.from(json['systemConstraints'] as List? ?? const []),
      researchFindings:
          List<String>.from(json['researchFindings'] as List? ?? const []),
      persistentConcepts:
          List<String>.from(json['persistentConcepts'] as List? ?? const []),
      readerPromises:
          List<String>.from(json['readerPromises'] as List? ?? const []),
      unresolvedPromises:
          List<String>.from(json['unresolvedPromises'] as List? ?? const []),
      toneSignals: List<String>.from(json['toneSignals'] as List? ?? const []),
      scenePatternWarnings: List<String>.from(
        json['scenePatternWarnings'] as List? ?? const [],
      ),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class StoryState {
  final String bookId;
  final StoryAct currentAct;
  final CurrentChapterFunction currentChapterFunction;
  final int globalTension;
  final PerceivedRhythm perceivedRhythm;
  final String protagonistState;
  final List<String> activeThreats;
  final List<String> openQuestions;
  final List<String> plantedClues;
  final List<String> recentKeyEvents;
  final List<String> diagnostics;
  final String nextBestMove;
  final String nextBestMoveReason;
  final DateTime updatedAt;

  const StoryState({
    required this.bookId,
    this.currentAct = StoryAct.actI,
    this.currentChapterFunction = CurrentChapterFunction.introduce,
    this.globalTension = 0,
    this.perceivedRhythm = PerceivedRhythm.steady,
    this.protagonistState = '',
    this.activeThreats = const [],
    this.openQuestions = const [],
    this.plantedClues = const [],
    this.recentKeyEvents = const [],
    this.diagnostics = const [],
    this.nextBestMove = '',
    this.nextBestMoveReason = '',
    required this.updatedAt,
  });

  StoryState copyWith({
    StoryAct? currentAct,
    CurrentChapterFunction? currentChapterFunction,
    int? globalTension,
    PerceivedRhythm? perceivedRhythm,
    String? protagonistState,
    List<String>? activeThreats,
    List<String>? openQuestions,
    List<String>? plantedClues,
    List<String>? recentKeyEvents,
    List<String>? diagnostics,
    String? nextBestMove,
    String? nextBestMoveReason,
    DateTime? updatedAt,
  }) {
    return StoryState(
      bookId: bookId,
      currentAct: currentAct ?? this.currentAct,
      currentChapterFunction:
          currentChapterFunction ?? this.currentChapterFunction,
      globalTension: globalTension ?? this.globalTension,
      perceivedRhythm: perceivedRhythm ?? this.perceivedRhythm,
      protagonistState: protagonistState ?? this.protagonistState,
      activeThreats: activeThreats ?? this.activeThreats,
      openQuestions: openQuestions ?? this.openQuestions,
      plantedClues: plantedClues ?? this.plantedClues,
      recentKeyEvents: recentKeyEvents ?? this.recentKeyEvents,
      diagnostics: diagnostics ?? this.diagnostics,
      nextBestMove: nextBestMove ?? this.nextBestMove,
      nextBestMoveReason: nextBestMoveReason ?? this.nextBestMoveReason,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory StoryState.empty(String bookId, DateTime now) {
    return StoryState(bookId: bookId, updatedAt: now);
  }

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'currentAct': currentAct.name,
        'currentChapterFunction': currentChapterFunction.name,
        'globalTension': globalTension,
        'perceivedRhythm': perceivedRhythm.name,
        'protagonistState': protagonistState,
        'activeThreats': activeThreats,
        'openQuestions': openQuestions,
        'plantedClues': plantedClues,
        'recentKeyEvents': recentKeyEvents,
        'diagnostics': diagnostics,
        'nextBestMove': nextBestMove,
        'nextBestMoveReason': nextBestMoveReason,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory StoryState.fromJson(Map<String, dynamic> json) {
    return StoryState(
      bookId: json['bookId'] as String,
      currentAct: enumFromName(
        StoryAct.values,
        json['currentAct'] as String?,
        StoryAct.actI,
      ),
      currentChapterFunction: enumFromName(
        CurrentChapterFunction.values,
        json['currentChapterFunction'] as String?,
        CurrentChapterFunction.introduce,
      ),
      globalTension: (json['globalTension'] as int? ?? 0).clamp(0, 100),
      perceivedRhythm: enumFromName(
        PerceivedRhythm.values,
        json['perceivedRhythm'] as String?,
        PerceivedRhythm.steady,
      ),
      protagonistState: json['protagonistState'] as String? ?? '',
      activeThreats:
          List<String>.from(json['activeThreats'] as List? ?? const []),
      openQuestions:
          List<String>.from(json['openQuestions'] as List? ?? const []),
      plantedClues:
          List<String>.from(json['plantedClues'] as List? ?? const []),
      recentKeyEvents:
          List<String>.from(json['recentKeyEvents'] as List? ?? const []),
      diagnostics: List<String>.from(json['diagnostics'] as List? ?? const []),
      nextBestMove: json['nextBestMove'] as String? ?? '',
      nextBestMoveReason: json['nextBestMoveReason'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
