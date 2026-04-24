import 'package:musa/modules/characters/models/character.dart';
import 'package:musa/editor/services/semantic_pattern_analyzer.dart';

/// Injects character context into narrative analysis.
/// Uses character voice, motivation, and internal conflict to calibrate editorial signals.
/// Allows dialogue-heavy scenes for chatty characters, expects tension for conflicted ones, etc.
class CharacterContextInjector {
  CharacterContextInjector();

  /// Creates a voice profile from character data.
  /// Used to calibrate editorial signal expectations.
  CharacterVoiceProfile buildVoiceProfile(Character character) {
    final voiceScore = _analyzeVoice(character.voice);
    final motivationScore = _analyzeMotivation(character.motivation);
    final conflictScore = _analyzeInternalConflict(character.internalConflict);
    final secretScore = _analyzeSecrets(character.whatTheyHide);

    return CharacterVoiceProfile(
      characterId: character.id,
      characterName: character.name,
      isProtagonist: character.isProtagonist,
      voicePatterns: voiceScore,
      motivationPattern: motivationScore,
      conflictIntensity: conflictScore,
      secretBurden: secretScore,
      expectedDialogueFrequency: _computeDialogueExpectation(voiceScore),
      expectedActionDensity: _computeActionExpectation(
        motivationScore,
        conflictScore,
      ),
      expectedTonePatterns: _computeToneExpectations(
        voiceScore,
        conflictScore,
      ),
    );
  }

  /// Applies character context to editorial signal scoring.
  /// Returns multipliers that adjust thresholds based on character expectations.
  SignalMultipliers applyCharacterContext(
    CharacterVoiceProfile profile,
    AtmosphereAnalysis atmosphere,
  ) {
    var clarityMultiplier = 1.0;
    var rhythmMultiplier = 1.0;
    var styleMultiplier = 1.0;
    var tensionMultiplier = 1.0;

    // Verbose/chatty characters: allow more dialogue without clarity penalty
    if (profile.voicePatterns.isVerbose) {
      clarityMultiplier *= 0.9; // Relax clarity threshold
      rhythmMultiplier *= 1.1; // More tolerance for varied rhythm
    }

    // Taciturn characters: expect sparse dialogue, more internal action
    if (profile.voicePatterns.isTaciturn) {
      clarityMultiplier *= 1.1; // Tighten clarity
      rhythmMultiplier *= 0.9; // Accept more staccato
    }

    // Formal/educated characters: style bar higher
    if (profile.voicePatterns.isFormal) {
      styleMultiplier *= 1.2; // Expect sophisticated vocabulary
    }

    // Casual characters: style bar lower
    if (profile.voicePatterns.isCasual) {
      styleMultiplier *= 0.8; // Accept colloquialisms
    }

    // Emotionally conflicted: expect tension/atmosphere
    if (profile.conflictIntensity > 0.6) {
      tensionMultiplier *= 1.3; // Should have emotional weight
      if (atmosphere.tension < 0.3 && atmosphere.mystery < 0.2) {
        tensionMultiplier *= 1.5; // Missing expected tension = big gap
      }
    }

    // Action-motivated character: expect physical action density
    if (profile.expectedActionDensity > 0.7) {
      rhythmMultiplier *= 1.2; // Accept faster pacing
    }

    // Secret-burdened character: expect introspection
    if (profile.secretBurden > 0.6) {
      // Allow more internal monologue
      clarityMultiplier *= 0.85;
    }

    return SignalMultipliers(
      clarity: clarityMultiplier.clamp(0.6, 1.5),
      rhythm: rhythmMultiplier.clamp(0.6, 1.5),
      style: styleMultiplier.clamp(0.6, 1.5),
      tension: tensionMultiplier.clamp(0.6, 1.5),
    );
  }

  /// Generates character-aware editorial feedback.
  /// Suggests improvements that fit the character's voice and motivations.
  List<String> generateCharacterAwareFeedback(
    CharacterVoiceProfile profile,
    AtmosphereAnalysis atmosphere,
    String fragmentContext,
  ) {
    final feedback = <String>[];

    // Dialogue frequency feedback
    if (profile.voicePatterns.isVerbose && fragmentContext.contains('—')) {
      feedback.add(
        '${profile.characterName} habla mucho. La cantidad de diálogo refleja su naturaleza comunicativa.',
      );
    }

    if (profile.voicePatterns.isTaciturn && fragmentContext.contains('—')) {
      feedback.add(
        'Advertencia: ${profile.characterName} tiende a ser poco hablador. '
        'Considera más acción/introspección que diálogo.',
      );
    }

    // Atmosphere feedback
    if (profile.conflictIntensity > 0.6 && atmosphere.tension < 0.2) {
      feedback.add(
        '${profile.characterName} tiene conflicto interno importante. '
        'La escena podría reflejar más tensión o angustia.',
      );
    }

    if (profile.expectedActionDensity > 0.7 &&
        !fragmentContext.contains(RegExp(r'entré|salí|corrí|saltó|movió'))) {
      feedback.add(
        '${profile.characterName} es orientado a la acción. '
        'Considera incluir más movimiento físico.',
      );
    }

    // Tone feedback
    if (profile.voicePatterns.isFormal &&
        fragmentContext.contains(RegExp(r'oye|tío|vale|jaja'))) {
      feedback.add(
        '${profile.characterName} es formal/educado. '
        'El tono casual actual no coincide con su voz.',
      );
    }

    // Secret/hiding feedback
    if (profile.secretBurden > 0.5) {
      feedback.add(
        '${profile.characterName} está ocultando algo. '
        'Considera subrayar evasión, evasivas o revelaciones parciales.',
      );
    }

    return feedback;
  }

  // === Private Helpers ===

  VoicePatterns _analyzeVoice(String voice) {
    final lowerVoice = voice.toLowerCase();

    final verboseMarkers = const [
      'hablador', 'locuaz', 'comunicativo',
      'conversador', 'elocuente', 'parlanchín',
      'expresivo', 'detallista',
    ];

    final taciturnMarkers = const [
      'callado', 'silencioso', 'reservado',
      'lacónico', 'parco', 'introvertido',
      'mudo', 'cerrado',
    ];

    final formalMarkers = const [
      'formal', 'educado', 'profesional',
      'académico', 'culto', 'refinado',
      'erudito', 'cortés',
    ];

    const casualMarkers = const [
      'casual', 'informal', 'relajado',
      'coloquial', 'desenfadado', 'natural',
      'despreocupado', 'llano',
    ];

    var isVerbose = false;
    var isTaciturn = false;
    var isFormal = false;
    var isCasual = false;

    for (final marker in verboseMarkers) {
      if (lowerVoice.contains(marker)) {
        isVerbose = true;
        break;
      }
    }

    for (final marker in taciturnMarkers) {
      if (lowerVoice.contains(marker)) {
        isTaciturn = true;
        break;
      }
    }

    for (final marker in formalMarkers) {
      if (lowerVoice.contains(marker)) {
        isFormal = true;
        break;
      }
    }

    for (final marker in casualMarkers) {
      if (lowerVoice.contains(marker)) {
        isCasual = true;
        break;
      }
    }

    return VoicePatterns(
      isVerbose: isVerbose,
      isTaciturn: isTaciturn,
      isFormal: isFormal,
      isCasual: isCasual,
    );
  }

  MotivationScore _analyzeMotivation(String motivation) {
    final lowerMot = motivation.toLowerCase();

    final actionMarkers = const [
      'actuar', 'luchar', 'competir', 'conquistar',
      'ganar', 'dominar', 'controlar', 'defender',
    ];

    final intellectualMarkers = const [
      'comprender', 'descubrir', 'aprender', 'resolver',
      'investigar', 'analizar', 'buscar verdad',
    ];

    final emotionalMarkers = const [
      'amar', 'proteger', 'sacrificar', 'redención',
      'venganza', 'perdón', 'conexión', 'pertenencia',
    ];

    var actionScore = 0;
    var intellectualScore = 0;
    var emotionalScore = 0;

    for (final marker in actionMarkers) {
      if (lowerMot.contains(marker)) actionScore++;
    }
    for (final marker in intellectualMarkers) {
      if (lowerMot.contains(marker)) intellectualScore++;
    }
    for (final marker in emotionalMarkers) {
      if (lowerMot.contains(marker)) emotionalScore++;
    }

    return MotivationScore(
      actionOriented: (actionScore / actionMarkers.length).clamp(0.0, 1.0),
      intellectualOriented:
          (intellectualScore / intellectualMarkers.length).clamp(0.0, 1.0),
      emotionalOriented:
          (emotionalScore / emotionalMarkers.length).clamp(0.0, 1.0),
    );
  }

  double _analyzeInternalConflict(String conflict) {
    if (conflict.isEmpty) return 0.0;

    final conflictMarkers = const [
      'duda', 'indeciso', 'dilema', 'conflicto',
      'contradicción', 'tensión', 'lucha interna',
      'ambivalencia', 'culpa', 'miedo',
    ];

    var score = 0;
    for (final marker in conflictMarkers) {
      if (conflict.toLowerCase().contains(marker)) score++;
    }

    return (score / conflictMarkers.length).clamp(0.0, 1.0);
  }

  double _analyzeSecrets(String secrets) {
    if (secrets.isEmpty) return 0.0;

    final secretMarkers = const [
      'secreto', 'oculto', 'escondido', 'mentira',
      'pasado', 'verdad oculta', 'ocultando',
      'no sabe', 'ignora', 'desconoce',
    ];

    var score = 0;
    for (final marker in secretMarkers) {
      if (secrets.toLowerCase().contains(marker)) score++;
    }

    return (score / secretMarkers.length).clamp(0.0, 1.0);
  }

  double _computeDialogueExpectation(VoicePatterns voice) {
    if (voice.isVerbose) return 0.8; // Lots of dialogue expected
    if (voice.isTaciturn) return 0.2; // Little dialogue expected
    return 0.5; // Average dialogue
  }

  double _computeActionExpectation(
    MotivationScore motivation,
    double conflictIntensity,
  ) {
    var expectation = motivation.actionOriented * 0.6;
    expectation += conflictIntensity * 0.4; // Conflict drives action

    return expectation.clamp(0.0, 1.0);
  }

  List<String> _computeToneExpectations(
    VoicePatterns voice,
    double conflictIntensity,
  ) {
    final tones = <String>[];

    if (voice.isFormal) tones.add('formal');
    if (voice.isCasual) tones.add('casual');
    if (conflictIntensity > 0.6) tones.add('serious');

    if (tones.isEmpty) tones.add('balanced');

    return tones;
  }
}

/// Voice profile built from character data
class CharacterVoiceProfile {
  final String characterId;
  final String characterName;
  final bool isProtagonist;
  final VoicePatterns voicePatterns;
  final MotivationScore motivationPattern;
  final double conflictIntensity;
  final double secretBurden;
  final double expectedDialogueFrequency;
  final double expectedActionDensity;
  final List<String> expectedTonePatterns;

  CharacterVoiceProfile({
    required this.characterId,
    required this.characterName,
    required this.isProtagonist,
    required this.voicePatterns,
    required this.motivationPattern,
    required this.conflictIntensity,
    required this.secretBurden,
    required this.expectedDialogueFrequency,
    required this.expectedActionDensity,
    required this.expectedTonePatterns,
  });
}

/// Voice pattern classification
class VoicePatterns {
  final bool isVerbose;
  final bool isTaciturn;
  final bool isFormal;
  final bool isCasual;

  VoicePatterns({
    required this.isVerbose,
    required this.isTaciturn,
    required this.isFormal,
    required this.isCasual,
  });
}

/// Motivation analysis results
class MotivationScore {
  final double actionOriented;
  final double intellectualOriented;
  final double emotionalOriented;

  MotivationScore({
    required this.actionOriented,
    required this.intellectualOriented,
    required this.emotionalOriented,
  });
}

/// Signal multipliers based on character context
class SignalMultipliers {
  final double clarity;
  final double rhythm;
  final double style;
  final double tension;

  SignalMultipliers({
    required this.clarity,
    required this.rhythm,
    required this.style,
    required this.tension,
  });

  double getMultiplier(String musaType) {
    switch (musaType.toLowerCase()) {
      case 'clarity':
        return clarity;
      case 'rhythm':
        return rhythm;
      case 'style':
        return style;
      case 'tension':
        return tension;
      default:
        return 1.0;
    }
  }
}
