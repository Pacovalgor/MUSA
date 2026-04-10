import '../../modules/characters/models/character_autofill_draft.dart';

enum CharacterAutofillMode { create, enrich }

class CharacterAutofillRequest {
  final CharacterAutofillMode mode;
  final String selection;
  final String nearbyContext;
  final String documentTitle;
  final String bookTitle;
  final String bookSummary;
  final List<String> knownCharacters;
  final String provisionalName;
  final bool isProtagonist;
  final String sourceLanguage;
  final String existingCharacterProfile;

  const CharacterAutofillRequest({
    required this.mode,
    required this.selection,
    required this.nearbyContext,
    required this.documentTitle,
    required this.bookTitle,
    required this.bookSummary,
    required this.knownCharacters,
    required this.provisionalName,
    required this.isProtagonist,
    required this.sourceLanguage,
    this.existingCharacterProfile = '',
  });
}

abstract class CharacterAutofillService {
  Future<CharacterAutofillDraft?> buildDraft(CharacterAutofillRequest request);
}
