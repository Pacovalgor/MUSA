import '../../modules/scenarios/models/scenario_autofill_draft.dart';

enum ScenarioAutofillMode { create, enrich }

class ScenarioAutofillRequest {
  final ScenarioAutofillMode mode;
  final String selection;
  final String nearbyContext;
  final String documentTitle;
  final String bookTitle;
  final String bookSummary;
  final List<String> knownScenarios;
  final String provisionalName;
  final String sourceLanguage;
  final String existingScenarioProfile;

  const ScenarioAutofillRequest({
    required this.mode,
    required this.selection,
    required this.nearbyContext,
    required this.documentTitle,
    required this.bookTitle,
    required this.bookSummary,
    required this.knownScenarios,
    required this.provisionalName,
    required this.sourceLanguage,
    this.existingScenarioProfile = '',
  });
}

abstract class ScenarioAutofillService {
  Future<ScenarioAutofillDraft?> buildDraft(ScenarioAutofillRequest request);
}
