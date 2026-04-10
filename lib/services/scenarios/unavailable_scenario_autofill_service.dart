import '../../modules/scenarios/models/scenario_autofill_draft.dart';
import 'scenario_autofill_service.dart';

class UnavailableScenarioAutofillService implements ScenarioAutofillService {
  @override
  Future<ScenarioAutofillDraft?> buildDraft(
    ScenarioAutofillRequest request,
  ) async {
    return null;
  }
}
