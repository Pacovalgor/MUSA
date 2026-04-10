import 'character.dart';

class CharacterAutofillDraft {
  final String summary;
  final String voice;
  final String motivation;
  final String internalConflict;
  final String whatTheyHide;
  final String currentState;
  final String role;
  final String notes;

  const CharacterAutofillDraft({
    this.summary = '',
    this.voice = '',
    this.motivation = '',
    this.internalConflict = '',
    this.whatTheyHide = '',
    this.currentState = '',
    this.role = '',
    this.notes = '',
  });

  bool get isEmpty =>
      summary.trim().isEmpty &&
      voice.trim().isEmpty &&
      motivation.trim().isEmpty &&
      internalConflict.trim().isEmpty &&
      whatTheyHide.trim().isEmpty &&
      currentState.trim().isEmpty &&
      role.trim().isEmpty &&
      notes.trim().isEmpty;

  factory CharacterAutofillDraft.fromJson(Map<String, dynamic> json) {
    String read(String key) => (json[key] as String? ?? '').trim();

    return CharacterAutofillDraft(
      summary: read('summary'),
      voice: read('voice'),
      motivation: read('motivation'),
      internalConflict: read('internalConflict'),
      whatTheyHide: read('whatTheyHide'),
      currentState: read('currentState'),
      role: read('role'),
      notes: read('notes'),
    );
  }

  Character mergeInto(
    Character character, {
    bool onlyFillEmpty = true,
  }) {
    String pick(String current, String incoming) {
      if (!onlyFillEmpty) return incoming.trim().isEmpty ? current : incoming;
      return current.trim().isNotEmpty ? current : incoming;
    }

    return character.copyWith(
      summary: pick(character.summary, summary),
      voice: pick(character.voice, voice),
      motivation: pick(character.motivation, motivation),
      internalConflict: pick(character.internalConflict, internalConflict),
      whatTheyHide: pick(character.whatTheyHide, whatTheyHide),
      currentState: pick(character.currentState, currentState),
      role: pick(character.role, role),
      notes: pick(character.notes, notes),
    );
  }

  Map<String, String> nonEmptyFields() {
    return <String, String>{
      if (summary.trim().isNotEmpty) 'Quién es': summary.trim(),
      if (voice.trim().isNotEmpty) 'Cómo habla': voice.trim(),
      if (motivation.trim().isNotEmpty) 'Qué quiere': motivation.trim(),
      if (internalConflict.trim().isNotEmpty)
        'Qué lo fractura': internalConflict.trim(),
      if (whatTheyHide.trim().isNotEmpty) 'Qué oculta': whatTheyHide.trim(),
      if (currentState.trim().isNotEmpty) 'Estado actual': currentState.trim(),
      if (role.trim().isNotEmpty) 'Rol': role.trim(),
      if (notes.trim().isNotEmpty) 'Notas': notes.trim(),
    };
  }
}
