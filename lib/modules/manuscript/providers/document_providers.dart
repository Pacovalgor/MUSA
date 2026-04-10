import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/providers/workspace_providers.dart';
import '../../characters/models/character.dart';
import '../../characters/providers/character_providers.dart';
import '../../scenarios/models/scenario.dart';
import '../../scenarios/providers/scenario_providers.dart';
import '../models/document.dart';

/// Documents belonging to the active book, already sorted for editor usage.
final documentsProvider = Provider<List<Document>>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.activeBookDocuments ??
      const [];
});

/// Currently selected manuscript document.
final currentDocumentProvider = Provider<Document?>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.selectedDocument;
});

/// Characters explicitly linked from the current document metadata.
final currentDocumentCharactersProvider = Provider<List<Character>>((ref) {
  final document = ref.watch(currentDocumentProvider);
  final characters = ref.watch(charactersProvider);
  if (document == null || document.characterIds.isEmpty) return const [];
  final byId = {for (final character in characters) character.id: character};
  return document.characterIds
      .map((id) => byId[id])
      .whereType<Character>()
      .toList();
});

/// Scenarios explicitly linked from the current document metadata.
final currentDocumentScenariosProvider = Provider<List<Scenario>>((ref) {
  final document = ref.watch(currentDocumentProvider);
  final scenarios = ref.watch(scenariosProvider);
  if (document == null || document.scenarioIds.isEmpty) return const [];
  final byId = {for (final scenario in scenarios) scenario.id: scenario};
  return document.scenarioIds
      .map((id) => byId[id])
      .whereType<Scenario>()
      .toList();
});
