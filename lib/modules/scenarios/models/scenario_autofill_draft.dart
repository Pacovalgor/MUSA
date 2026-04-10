import 'scenario.dart';

class ScenarioAutofillDraft {
  final String summary;
  final String atmosphere;
  final String importance;
  final String whatItHides;
  final String currentState;
  final String role;
  final String notes;

  const ScenarioAutofillDraft({
    this.summary = '',
    this.atmosphere = '',
    this.importance = '',
    this.whatItHides = '',
    this.currentState = '',
    this.role = '',
    this.notes = '',
  });

  bool get isEmpty =>
      summary.trim().isEmpty &&
      atmosphere.trim().isEmpty &&
      importance.trim().isEmpty &&
      whatItHides.trim().isEmpty &&
      currentState.trim().isEmpty &&
      role.trim().isEmpty &&
      notes.trim().isEmpty;

  factory ScenarioAutofillDraft.fromJson(Map<String, dynamic> json) {
    String read(String key) => (json[key] as String? ?? '').trim();

    return ScenarioAutofillDraft(
      summary: read('summary'),
      atmosphere: read('atmosphere'),
      importance: read('importance'),
      whatItHides: read('whatItHides'),
      currentState: read('currentState'),
      role: read('role'),
      notes: read('notes'),
    );
  }

  Scenario mergeInto(
    Scenario scenario, {
    bool onlyFillEmpty = true,
  }) {
    String pick(String current, String incoming) {
      if (!onlyFillEmpty) return incoming.trim().isEmpty ? current : incoming;
      return current.trim().isNotEmpty ? current : incoming;
    }

    return scenario.copyWith(
      summary: pick(scenario.summary, summary),
      atmosphere: pick(scenario.atmosphere, atmosphere),
      importance: pick(scenario.importance, importance),
      whatItHides: pick(scenario.whatItHides, whatItHides),
      currentState: pick(scenario.currentState, currentState),
      role: pick(scenario.role, role),
      notes: pick(scenario.notes, notes),
    );
  }

  Map<String, String> nonEmptyFields() {
    return <String, String>{
      if (summary.trim().isNotEmpty) 'Qué es este lugar': summary.trim(),
      if (atmosphere.trim().isNotEmpty) 'Qué ambiente tiene': atmosphere.trim(),
      if (importance.trim().isNotEmpty) 'Por qué importa': importance.trim(),
      if (whatItHides.trim().isNotEmpty) 'Qué oculta': whatItHides.trim(),
      if (currentState.trim().isNotEmpty) 'Estado actual': currentState.trim(),
      if (role.trim().isNotEmpty) 'Función en la historia': role.trim(),
      if (notes.trim().isNotEmpty) 'Notas': notes.trim(),
    };
  }
}
