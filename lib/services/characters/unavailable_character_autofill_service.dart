import 'character_autofill_service.dart';
import '../../modules/characters/models/character_autofill_draft.dart';

class UnavailableCharacterAutofillService implements CharacterAutofillService {
  @override
  Future<CharacterAutofillDraft?> buildDraft(
    CharacterAutofillRequest request,
  ) async {
    return null;
  }
}
