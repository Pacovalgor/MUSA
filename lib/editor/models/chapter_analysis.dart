// ignore_for_file: constant_identifier_names

import 'fragment_analysis.dart';

enum ChapterFunction {
  introduction,
  development,
  escalation,
  discovery,
  transition,
  character_building,
  setup,
}

class ChapterAnalysis {
  final List<DetectedCharacter> mainCharacters;
  final DetectedScenario? mainScenario;
  final List<NarrativeMoment> narrativeMoments;
  final NarrativeMoment dominantNarrativeMoment;
  final ChapterFunction chapterFunction;
  final List<CharacterDevelopment> characterDevelopments;
  final List<ScenarioDevelopment> scenarioDevelopments;
  final ChapterTrajectory? trajectory;
  final ChapterNextStep? nextStep;
  final ChapterRecommendation? recommendation;

  const ChapterAnalysis({
    this.mainCharacters = const [],
    this.mainScenario,
    this.narrativeMoments = const [],
    required this.dominantNarrativeMoment,
    required this.chapterFunction,
    this.characterDevelopments = const [],
    this.scenarioDevelopments = const [],
    this.trajectory,
    this.nextStep,
    this.recommendation,
  });
}

enum NextStepType {
  strengthenConflict,
  createCharacter,
  enrichCharacter,
  createScenario,
  enrichScenario,
  connectToPlot,
  expandMoment,
}

class ChapterNextStep {
  final String label;
  final String actionLabel;
  final NextStepType type;
  final String? targetId;
  final String? entityName;
  final String? exampleText;

  const ChapterNextStep({
    required this.label,
    required this.actionLabel,
    required this.type,
    this.targetId,
    this.entityName,
    this.exampleText,
  });
}

enum CharacterDevelopmentType {
  identity_gain,
  voice_definition,
  role_reinforcement,
  conflict_signal,
  new_relevance,
}

class CharacterDevelopment {
  final String characterIdOrName;
  final String label;
  final String summary;
  final CharacterDevelopmentType type;
  final int score;

  const CharacterDevelopment({
    required this.characterIdOrName,
    required this.label,
    required this.summary,
    required this.type,
    required this.score,
  });
}

enum ScenarioDevelopmentType {
  identity_gain,
  atmosphere_gain,
  function_definition,
  narrative_relevance_increase,
}

class ScenarioDevelopment {
  final String scenarioIdOrName;
  final String label;
  final String summary;
  final ScenarioDevelopmentType type;
  final int score;

  const ScenarioDevelopment({
    required this.scenarioIdOrName,
    required this.label,
    required this.summary,
    required this.type,
    required this.score,
  });
}

class ChapterTrajectory {
  final String startLabel;
  final String middleLabel;
  final String endLabel;
  final String summary;

  const ChapterTrajectory({
    required this.startLabel,
    required this.middleLabel,
    required this.endLabel,
    required this.summary,
  });
}

class ChapterRecommendation {
  final String message;

  const ChapterRecommendation({
    required this.message,
  });
}

enum ExpandMomentDirectionType {
  add_consequence,
  raise_tension,
  clarify_clue,
  extend_observation,
  link_emotion_to_action,
}

class ExpandMomentDirection {
  final ExpandMomentDirectionType type;
  final String title;
  final String summary;
  final String example;

  const ExpandMomentDirection({
    required this.type,
    required this.title,
    required this.summary,
    required this.example,
  });
}

class ExpandMomentEditorialAid {
  final String problem;
  final List<ExpandMomentDirection> directions;

  const ExpandMomentEditorialAid({
    required this.problem,
    required this.directions,
  });
}

extension ChapterFunctionCopy on ChapterFunction {
  String get label {
    return switch (this) {
      ChapterFunction.introduction => 'Introducción',
      ChapterFunction.development => 'Desarrollo',
      ChapterFunction.escalation => 'Escalada',
      ChapterFunction.discovery => 'Descubrimiento',
      ChapterFunction.transition => 'Transición',
      ChapterFunction.character_building => 'Construcción de personaje',
      ChapterFunction.setup => 'Preparación',
    };
  }

  String get summary {
    return switch (this) {
      ChapterFunction.introduction =>
        'El capítulo presenta piezas centrales y fija el tono.',
      ChapterFunction.development =>
        'El capítulo hace avanzar lo ya abierto sin cambiar de eje.',
      ChapterFunction.escalation => 'La tensión sube y el conflicto gana peso.',
      ChapterFunction.discovery =>
        'El capítulo revela algo que reordena la lectura.',
      ChapterFunction.transition =>
        'El capítulo conecta espacios, ritmos o líneas de acción.',
      ChapterFunction.character_building =>
        'El foco está en la interioridad y el relieve de la protagonista.',
      ChapterFunction.setup =>
        'El capítulo coloca indicios y piezas que preparan lo siguiente.',
    };
  }
}
