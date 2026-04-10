import 'scenario_autofill_service.dart';

class ScenarioAutofillPromptBuilder {
  static String buildEmbeddedChatPrompt(ScenarioAutofillRequest request) {
    final taskDescription = request.mode == ScenarioAutofillMode.enrich
        ? 'Enrich the existing scenario sheet using only what this fragment adds or clarifies.'
        : 'Create a concise editorial first draft for this scenario using only the fragment and nearby context.';
    final modeRules = request.mode == ScenarioAutofillMode.enrich
        ? '''
EXISTING SCENARIO SHEET:
${request.existingScenarioProfile.isEmpty ? 'No previous sheet available.' : request.existingScenarioProfile}

ENRICHMENT RULES:
- Preserve established information.
- Fill gaps first.
- If a field already has useful content, only propose a concise addition if the fragment clearly adds something new.
- If the fragment adds nuance but not a clean replacement, keep it brief and editorial.
'''
        : '';

    final userPayload = """
BOOK: ${request.bookTitle}
DOCUMENT: ${request.documentTitle}
BOOK SUMMARY:
${request.bookSummary.isEmpty ? 'No summary available.' : request.bookSummary}

TARGET SCENARIO:
- Working name: ${request.provisionalName.isEmpty ? 'Escenario nuevo' : request.provisionalName}
- Source language: ${request.sourceLanguage}

KNOWN SCENARIOS:
${request.knownScenarios.isEmpty ? '- None yet.' : request.knownScenarios.map((item) => '- $item').join('\n')}

SELECTED FRAGMENT:
${request.selection}

NEARBY MANUSCRIPT CONTEXT:
${request.nearbyContext}

TASK:
$taskDescription
If the context is weak, be prudent and keep fields short.
Do not turn the place into technical geography.
Do not inflate the lore.
Do not invent history or symbolism without support.
Never use nearby context to override a weak selected fragment.
$modeRules

TARGETING RULES:
- Describe only the place, environment, or setting implied by the fragment.
- Keep the sheet focused on the target scenario named above, not on the whole chapter.
- If the selected fragment mainly follows a character emotion and the place is only background, infer very little.
- If the setting is mentioned only in passing, leave atmosphere, importance, role, and whatItHides empty.
- Do not upgrade a broad area into a specific scenario unless the fragment supports it clearly.
- If the fragment mainly reveals a mood rather than a concrete place, keep the sheet cautious and editorial.
- If the setting is barely mentioned, leave most fields empty.
- It is better to return several empty fields than to invent worldbuilding.

LANGUAGE LOCK:
- Every string value inside the JSON must be written in the source language.
- If the source language is Spanish, every non-empty value must be in Spanish.
- Never answer in English when the source fragment is in Spanish.
- Return JSON only. No preambles. No follow-up comments. No text before or after the JSON object.

OUTPUT:
Return ONLY one valid JSON object with these exact keys:
summary, atmosphere, importance, whatItHides, currentState, role, notes

JSON TEMPLATE:
{
  "summary": "",
  "atmosphere": "",
  "importance": "",
  "whatItHides": "",
  "currentState": "",
  "role": "",
  "notes": ""
}

RULES:
- Use the same language as the source fragment.
- Keep each field brief and useful.
- Leave fields as an empty string when the context is insufficient.
- No markdown.
- No explanations.
- No extra keys.
"""
        .trim();

    return """
<|begin_of_text|><|start_header_id|>system<|end_header_id|>

You are MUSA, an editorial assistant for fiction scenarios and places.
You help draft concise, editable scenario sheets from manuscript evidence.
You are proposing a useful editorial draft, not definitive canon.
Be prudent, grounded, and brief.
Preserve existing scenario information when the task is enrichment.
You must never confuse setting mood with setting identity.
Return only valid JSON.
<|eot_id|><|start_header_id|>user<|end_header_id|>

$userPayload
<|eot_id|><|start_header_id|>assistant<|end_header_id|>

"""
        .trimRight();
  }
}
