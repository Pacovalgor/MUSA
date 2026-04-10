import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/providers/workspace_providers.dart';
import '../../manuscript/models/document.dart';
import '../models/scenario.dart';

/// Progress states for AI-assisted scenario autofill.
enum ScenarioAutofillPhase { idle, drafting, completed, failed }

/// Whether the autofill flow is creating or enriching a scenario sheet.
enum ScenarioAutofillKind { create, enrich }

/// UI state for scenario autofill banners and progress indicators.
class ScenarioAutofillState {
  final String? scenarioId;
  final ScenarioAutofillPhase phase;
  final ScenarioAutofillKind kind;
  final String message;

  const ScenarioAutofillState({
    this.scenarioId,
    this.phase = ScenarioAutofillPhase.idle,
    this.kind = ScenarioAutofillKind.create,
    this.message = 'MUSA está dando forma al escenario…',
  });

  bool appliesTo(String? id) => id != null && id == scenarioId;
}

/// Drives the transient UI state around scenario autofill operations.
class ScenarioAutofillNotifier extends StateNotifier<ScenarioAutofillState> {
  ScenarioAutofillNotifier() : super(const ScenarioAutofillState());

  void start(String scenarioId) {
    state = ScenarioAutofillState(
      scenarioId: scenarioId,
      phase: ScenarioAutofillPhase.drafting,
      kind: ScenarioAutofillKind.create,
      message: 'MUSA está dando forma al escenario…',
    );
  }

  void startEnrichment(String scenarioId, String displayName) {
    state = ScenarioAutofillState(
      scenarioId: scenarioId,
      phase: ScenarioAutofillPhase.drafting,
      kind: ScenarioAutofillKind.enrich,
      message: 'MUSA está afinando "$displayName"…',
    );
  }

  void updateMessage(String scenarioId, String message) {
    if (!state.appliesTo(scenarioId) ||
        state.phase != ScenarioAutofillPhase.drafting) {
      return;
    }
    state = ScenarioAutofillState(
      scenarioId: scenarioId,
      phase: state.phase,
      kind: state.kind,
      message: message,
    );
  }

  void complete(String scenarioId) {
    if (!state.appliesTo(scenarioId)) return;
    state = ScenarioAutofillState(
      scenarioId: scenarioId,
      phase: ScenarioAutofillPhase.completed,
      kind: state.kind,
      message: state.kind == ScenarioAutofillKind.enrich
          ? 'El escenario acaba de matizarse con un nuevo fragmento.'
          : 'La ficha inicial del escenario ya está lista.',
    );
  }

  void fail(String scenarioId) {
    if (!state.appliesTo(scenarioId)) return;
    state = ScenarioAutofillState(
      scenarioId: scenarioId,
      phase: ScenarioAutofillPhase.failed,
      kind: state.kind,
      message: state.kind == ScenarioAutofillKind.enrich
          ? 'No se pudo enriquecer el escenario con este fragmento.'
          : 'No se pudo completar la primera ficha del escenario.',
    );
  }

  void clear(String scenarioId) {
    if (!state.appliesTo(scenarioId)) return;
    state = const ScenarioAutofillState();
  }
}

/// Scenarios available in the active book.
final scenariosProvider = Provider<List<Scenario>>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.activeBookScenarios ??
      const [];
});

/// Scenario currently selected in the workspace.
final selectedScenarioProvider = Provider<Scenario?>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.selectedScenario;
});

/// Documents in which the selected scenario is explicitly referenced.
final selectedScenarioDocumentsProvider = Provider<List<Document>>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  final scenario = ref.watch(selectedScenarioProvider);
  if (workspace == null || scenario == null) return const [];

  return workspace.documents
      .where((document) =>
          document.bookId == scenario.bookId &&
          document.scenarioIds.contains(scenario.id))
      .toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
});

/// Notifier that exposes the live scenario autofill status to the UI.
final scenarioAutofillProvider =
    StateNotifierProvider<ScenarioAutofillNotifier, ScenarioAutofillState>(
  (ref) => ScenarioAutofillNotifier(),
);
