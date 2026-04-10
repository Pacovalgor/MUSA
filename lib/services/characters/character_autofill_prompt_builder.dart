import 'character_autofill_service.dart';

class CharacterAutofillPromptBuilder {
  static String buildEmbeddedChatPrompt(CharacterAutofillRequest request) {
    final taskDescription = request.mode == CharacterAutofillMode.enrich
        ? 'Enrich the existing character sheet using only what this fragment adds or clarifies.'
        : 'Create a brief editorial first draft for this character based only on the fragment and nearby context.';
    final modeRules = request.mode == CharacterAutofillMode.enrich
        ? '''
EXISTING CHARACTER SHEET:
${request.existingCharacterProfile.isEmpty ? 'No previous sheet available.' : request.existingCharacterProfile}

ENRICHMENT RULES:
- Preserve established information.
- Fill gaps first.
- If a field already has useful content, only propose a concise addition if the fragment clearly adds something new.
- If the fragment adds nuance but not a clean replacement, keep it brief and editorial.
'''
        : '''
INITIAL CHARACTER SEED:
${request.existingCharacterProfile.isEmpty ? 'No initial seed available.' : request.existingCharacterProfile}

CREATE RULES:
- Use the initial seed when it is directly supported by the fragment.
- If the fragment gives an explicit family or relational cue, prioritize that in summary or role.
- Prefer relationship and narrative function over profession alone when both are clearly present.
''';
    final userPayload = """
BOOK: ${request.bookTitle}
DOCUMENT: ${request.documentTitle}
BOOK SUMMARY:
${request.bookSummary.isEmpty ? 'No summary available.' : request.bookSummary}

TARGET CHARACTER:
- Working name: ${request.provisionalName.isEmpty ? 'none' : request.provisionalName}
- Implicit protagonist: ${request.isProtagonist ? 'yes' : 'no'}
- Source language: ${request.sourceLanguage}

KNOWN CHARACTERS:
${request.knownCharacters.isEmpty ? '- None yet.' : request.knownCharacters.map((item) => '- $item').join('\n')}

SELECTED FRAGMENT:
${request.selection}

NEARBY MANUSCRIPT CONTEXT:
${request.nearbyContext}

TASK:
$taskDescription
If the context is weak, be prudent and keep fields short.
If the character is an implicit first-person narrator, treat the voice as the narrator voice and do not invent a proper name.
Never write a biography.
Never add information that is unsupported by the fragment.
$modeRules

TARGETING RULES:
- The sheet must describe ONLY the target character named above.
- If the fragment mainly describes another person or the first-person narrator, do not transfer those traits to the target character.
- If the target character is not the first-person narrator, never attribute the narrator's voice, emotions, role, or situation to the target.
- If the fragment explicitly identifies a relationship like mother, father, sister, boss, or neighbour, treat that as core evidence for the target.
- If the target character is only briefly mentioned, keep most fields empty.
- If the fragment gives only an instruction, message, or indirect mention from the target, infer very little.
- It is better to return several empty fields than to assign the narrator's traits to the wrong character.

LANGUAGE LOCK:
- Every string value inside the JSON must be written in the source language.
- If the source language is Spanish, every non-empty value must be in Spanish.
- Never answer in English when the source fragment is in Spanish.
- Return JSON only. No preambles. No follow-up comments. No text before or after the JSON object.

OUTPUT:
Return ONLY one valid JSON object with these exact keys:
summary, voice, motivation, internalConflict, whatTheyHide, currentState, role, notes

JSON TEMPLATE:
{
  "summary": "",
  "voice": "",
  "motivation": "",
  "internalConflict": "",
  "whatTheyHide": "",
  "currentState": "",
  "role": "",
  "notes": ""
}

RULES:
- Use the same language as the source fragment.
- Keep each field brief and useful.
- Leave fields as an empty string when the context is insufficient.
- Do not include markdown.
- Do not include explanations.
- Do not include extra keys.
"""
        .trim();

    return """
<|begin_of_text|><|start_header_id|>system<|end_header_id|>

You are MUSA, an editorial assistant for fiction characters.
You help draft concise, editable character sheets from manuscript evidence.
You are proposing a first useful draft, not a definitive truth.
Be prudent, grounded, and brief.
Do not invent a name for an unnamed first-person narrator.
Preserve existing character information when the task is enrichment.
You must never confuse the target character with the narrator or another nearby character.
Return only valid JSON.
<|eot_id|><|start_header_id|>user<|end_header_id|>

$userPayload
<|eot_id|><|start_header_id|>assistant<|end_header_id|>

"""
        .trimRight();
  }

  static String buildPlainPrompt(CharacterAutofillRequest request) {
    final taskDescription = request.mode == CharacterAutofillMode.enrich
        ? 'Enrich the existing character sheet using only what this fragment adds or clarifies.'
        : 'Create a brief editorial first draft for this character based only on the fragment and nearby context.';
    final modeRules = request.mode == CharacterAutofillMode.enrich
        ? '''
EXISTING CHARACTER SHEET:
${request.existingCharacterProfile.isEmpty ? 'No previous sheet available.' : request.existingCharacterProfile}

ENRICHMENT RULES:
- Preserve established information.
- Fill gaps first.
- If a field already has useful content, only propose a concise addition if the fragment clearly adds something new.
- If the fragment adds nuance but not a clean replacement, keep it brief and editorial.
'''
        : '''
INITIAL CHARACTER SEED:
${request.existingCharacterProfile.isEmpty ? 'No initial seed available.' : request.existingCharacterProfile}

CREATE RULES:
- Use the initial seed when it is directly supported by the fragment.
- If the fragment gives an explicit family or relational cue, prioritize that in summary or role.
- Prefer relationship and narrative function over profession alone when both are clearly present.
''';
    return """
You are MUSA, an editorial assistant for fiction characters.
You help draft concise, editable character sheets from manuscript evidence.
You are proposing a first useful draft, not a definitive truth.
Be prudent, grounded, and brief.
Do not invent a name for an unnamed first-person narrator.
Preserve existing character information when the task is enrichment.
Return only valid JSON.

BOOK: ${request.bookTitle}
DOCUMENT: ${request.documentTitle}
BOOK SUMMARY:
${request.bookSummary.isEmpty ? 'No summary available.' : request.bookSummary}

TARGET CHARACTER:
- Working name: ${request.provisionalName.isEmpty ? 'none' : request.provisionalName}
- Implicit protagonist: ${request.isProtagonist ? 'yes' : 'no'}
- Source language: ${request.sourceLanguage}

KNOWN CHARACTERS:
${request.knownCharacters.isEmpty ? '- None yet.' : request.knownCharacters.map((item) => '- $item').join('\n')}

SELECTED FRAGMENT:
${request.selection}

NEARBY MANUSCRIPT CONTEXT:
${request.nearbyContext}

TASK:
$taskDescription
If the context is weak, be prudent and keep fields short.
If the character is an implicit first-person narrator, treat the voice as the narrator voice and do not invent a proper name.
Never write a biography.
Never add information that is unsupported by the fragment.
$modeRules

TARGETING RULES:
- The sheet must describe ONLY the target character named above.
- If the fragment mainly describes another person or the first-person narrator, do not transfer those traits to the target character.
- If the target character is not the first-person narrator, never attribute the narrator's voice, emotions, role, or situation to the target.
- If the target character is only briefly mentioned, keep most fields empty.
- If the fragment gives only an instruction, message, or indirect mention from the target, infer very little.
- It is better to return several empty fields than to assign the narrator's traits to the wrong character.

LANGUAGE LOCK:
- Every string value inside the JSON must be written in the source language.
- If the source language is Spanish, every non-empty value must be in Spanish.
- Never answer in English when the source fragment is in Spanish.
- Return JSON only. No preambles. No follow-up comments. No text before or after the JSON object.

OUTPUT:
Return ONLY one valid JSON object with these exact keys:
summary, voice, motivation, internalConflict, whatTheyHide, currentState, role, notes

JSON TEMPLATE:
{
  "summary": "",
  "voice": "",
  "motivation": "",
  "internalConflict": "",
  "whatTheyHide": "",
  "currentState": "",
  "role": "",
  "notes": ""
}

RULES:
- Use the same language as the source fragment.
- Keep each field brief and useful.
- Leave fields as an empty string when the context is insufficient.
- Do not include markdown.
- Do not include explanations.
- Do not include extra keys.
"""
        .trim();
  }
}
