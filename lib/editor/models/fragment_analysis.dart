class FragmentAnalysis {
  final NarratorInsight? narrator;
  final List<DetectedCharacter> characters;
  final DetectedScenario? scenario;
  final NarrativeMoment moment;
  final FragmentRecommendation? recommendation;

  const FragmentAnalysis({
    this.narrator,
    this.characters = const [],
    this.scenario,
    required this.moment,
    this.recommendation,
  });

  bool get isEmpty =>
      narrator == null && characters.isEmpty && scenario == null;
}

class NarratorInsight {
  final String title;
  final String summary;
  final String? protagonistCharacterId;
  final bool protagonistExists;
  final int priorityScore;
  final InsightAction? action;

  const NarratorInsight({
    required this.title,
    required this.summary,
    this.protagonistCharacterId,
    this.protagonistExists = false,
    this.priorityScore = 0,
    this.action,
  });
}

class DetectedCharacter {
  final String name;
  final String summary;
  final String? existingCharacterId;
  final bool isAlreadyLinked;
  final int relevanceScore;
  final int strengthScore;
  final int aggregateScore;
  final bool isIdentityUpgrade;
  final InsightAction? action;

  const DetectedCharacter({
    required this.name,
    required this.summary,
    this.existingCharacterId,
    this.isAlreadyLinked = false,
    this.relevanceScore = 0,
    this.strengthScore = 0,
    this.aggregateScore = 0,
    this.isIdentityUpgrade = false,
    this.action,
  });
}

class DetectedScenario {
  final String name;
  final String summary;
  final String? existingScenarioId;
  final bool isAlreadyLinked;
  final int priorityScore;
  final int strengthScore;
  final int aggregateScore;
  final bool isIdentityUpgrade;
  final InsightAction? action;

  const DetectedScenario({
    required this.name,
    required this.summary,
    this.existingScenarioId,
    this.isAlreadyLinked = false,
    this.priorityScore = 0,
    this.strengthScore = 0,
    this.aggregateScore = 0,
    this.isIdentityUpgrade = false,
    this.action,
  });
}

class NarrativeMoment {
  final String title;
  final String summary;

  const NarrativeMoment({
    required this.title,
    required this.summary,
  });
}

class FragmentRecommendation {
  final String reason;
  final InsightAction action;

  const FragmentRecommendation({
    required this.reason,
    required this.action,
  });
}

class InsightAction {
  final InsightActionType type;
  final String label;
  final String? targetId;
  final String? entityName;
  final int priorityScore;

  const InsightAction({
    required this.type,
    required this.label,
    this.targetId,
    this.entityName,
    this.priorityScore = 0,
  });
}

enum InsightActionType {
  createProtagonist,
  enrichProtagonist,
  createCharacter,
  linkCharacter,
  enrichCharacter,
  createScenario,
  linkScenario,
  enrichScenario,
}
