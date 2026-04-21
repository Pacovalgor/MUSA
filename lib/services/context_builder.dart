import '../domain/musa/musa_objects.dart';
import '../muses/musa.dart';
import '../modules/books/models/musa_settings.dart';

class ContextBuilder {
  static const String _embeddedSystemPrompt = """
You are MUSA, a literary revision assistant for fiction manuscripts.
You receive a selected passage, project context, and a named editorial Musa.
You must answer with one surgical rewrite only.
Never explain your reasoning.
Never add labels, headings, markdown, quotation marks around the answer, or commentary.
Never mention the prompt, the rules, or the Musa.
Preserve meaning, continuity, tone, and narrative voice unless the task explicitly asks for a tonal adjustment.
You MUST ONLY rewrite the selected text.
You MUST NOT continue the story.
You MUST NOT expand beyond the semantic scope of the selected fragment.
You MUST NOT introduce new narrative events, dialogue, or scene progression.
Context is for tone and coherence only, not for expansion.
If the output includes content not contained or directly implied by the selected fragment, it is incorrect.
""";

  /// Builds a comprehensive summary using the decoupled NarrativeContext DTO.
  static String buildGlobalContext(NarrativeContext context) {
    final continuity = context.knownFacts.isNotEmpty
        ? context.knownFacts.join("\n- ")
        : "No established facts yet.";
    final characterSummary =
        (context.metadata['charactersSummary'] as List?)?.cast<String>() ??
            const <String>[];
    final scenarioSummary =
        (context.metadata['scenariosSummary'] as List?)?.cast<String>() ??
            const <String>[];
    final characterBlock = characterSummary.isEmpty
        ? 'No character notes registered yet.'
        : characterSummary.join('\n- ');
    final scenarioBlock = scenarioSummary.isEmpty
        ? 'No scenario notes registered yet.'
        : scenarioSummary.join('\n- ');

    return """
# PROJECT NARRATIVE CONTEXT
BOOK: ${context.bookTitle}
DOCUMENT: ${context.documentTitle}
SUMMARY: ${context.projectSummary}

### CURRENT STATE: 
Tension Level: ${context.tensionLevel}

### ESTABLISHED LORE & CONTINUITY:
- $continuity

### CHARACTERS IN PLAY:
- $characterBlock

### SCENARIOS IN PLAY:
- $scenarioBlock

### OPEN QUESTIONS:
- ${context.openQuestions.isEmpty ? "No open questions yet." : context.openQuestions.join("\n- ")}

### MOTIFS:
- ${context.motifs.isEmpty ? "No motifs registered yet." : context.motifs.join("\n- ")}
"""
        .trim();
  }

  /// Constructs the final prompt using the NarrativeContext and specific chapter context.
  static String buildFullPrompt({
    required NarrativeContext narrativeContext,
    required String documentTitle,
    required String documentContent,
    required String selection,
    required Musa musa,
    required MusaSettings settings,
  }) {
    final globalContext = buildGlobalContext(narrativeContext);
    final inferredLanguage = _inferLanguage(selection);
    final outputLanguage = _resolveOutputLanguage(
      inferredLanguage,
      settings.outputLanguageMode,
    );
    final expansionRatio = settings.expansionRatioFor(musa);

    return """
$globalContext

# CURRENT DOCUMENT CONTEXT (${narrativeContext.documentTitle.isEmpty ? documentTitle : narrativeContext.documentTitle}):
${_getDocumentGlimpse(documentContent)}

# AUTHOR SELECTION (TEXT TO INTERVENE):
>>> $selection <<<

# ACTIVE MUSA:
${musa.name}

# USER EDITORIAL PREFERENCES:
${settings.editorialIntensityInstruction}
${settings.fragmentFidelityInstruction}
${settings.scopeProtectionInstruction}
${settings.preferredToneInstruction}
${settings.musaIntensityInstruction(musa)}

# LANGUAGE LOCK:
Return the rewrite in ${outputLanguage.displayName}. Keep the selected language preference exactly. Do not translate unless explicitly asked.

# SCOPE LOCK:
Rewrite ONLY the selected fragment.
Do NOT continue the surrounding scene.
Do NOT add new events, dialogue, actions, or narrative progression.
Context is for tone and coherence only.
Output length must remain close to input length, with a maximum expansion ratio of ${expansionRatio.toStringAsFixed(1)}x.

# EDITORIAL CONTRACT:
${musa.refinedContract(selection)}

# MUSA-SPECIFIC SCOPE:
${musa.scopeReminder}

# RULES:
1. Maintain total coherence with lore, tone, and character voices defined in the context.
2. SURGICAL OUTPUT: Return ONLY the suggested rewrite.
3. NO PREAMBLES: Do not say "Here is your rewrite", "Revised version:" or "Sure thing".
4. NO EXPLANATIONS: Do not explain your stylistic choices.
5. NO FORMATTING: Return raw text. Do not wrap in markdown code blocks.
6. LANGUAGE LOCK: The output must remain in ${outputLanguage.displayName}.
7. SCOPE LOCK: Rewrite only the selected fragment, without narrative expansion.
8. LENGTH LOCK: Keep the output close to input length.
9. PERSISTENCE: Balance literary impact with the original author's intent.
"""
        .trim();
  }

  static String buildEmbeddedChatPrompt({
    required NarrativeContext narrativeContext,
    required String documentTitle,
    required String documentContent,
    required String selection,
    required Musa musa,
    required MusaSettings settings,
  }) {
    final globalContext = _buildCompactEmbeddedContext(narrativeContext);
    final inferredLanguage = _inferLanguage(selection);
    final outputLanguage = _resolveOutputLanguage(
      inferredLanguage,
      settings.outputLanguageMode,
    );
    final expansionRatio = settings.expansionRatioFor(musa);

    final userPayload = """
$globalContext

CURRENT DOCUMENT CONTEXT (${narrativeContext.documentTitle.isEmpty ? documentTitle : narrativeContext.documentTitle}):
${_getDocumentGlimpse(documentContent, maxChars: 500)}

SELECTED PASSAGE:
$selection

ACTIVE MUSA:
${musa.name}

USER EDITORIAL PREFERENCES:
${settings.editorialIntensityInstruction}
${settings.fragmentFidelityInstruction}
${settings.scopeProtectionInstruction}
${settings.preferredToneInstruction}
${settings.musaIntensityInstruction(musa)}

LANGUAGE LOCK:
The selected passage is in ${inferredLanguage.displayName}. Rewrite in ${outputLanguage.displayName} only. Do not translate unless explicitly asked.

SCOPE LOCK:
Rewrite only the selected fragment.
Do not continue the scene or add new events.
Keep the output close to the original length, with a maximum expansion ratio of ${expansionRatio.toStringAsFixed(1)}x.

EDITORIAL CONTRACT:
${musa.promptContract}

MUSA-SPECIFIC SCOPE:
${musa.scopeReminder}

Return one rewritten version of the selected passage only, with no explanation.
"""
        .trim();

    return """
<|begin_of_text|><|start_header_id|>system<|end_header_id|>

${_embeddedSystemPrompt.trim()}
${settings.editorialIntensityInstruction}
${settings.fragmentFidelityInstruction}
${settings.scopeProtectionInstruction}
${settings.preferredToneInstruction}
The output language must be ${outputLanguage.displayName}.
Respect the user-selected language mode exactly.
If language mode is "same as fragment", follow the language of the selected passage.
If language mode is fixed to Spanish, answer in Spanish.
If language mode is fixed to English, answer in English.
Never switch languages because of the prompt language.
<|eot_id|><|start_header_id|>user<|end_header_id|>

$userPayload
<|eot_id|><|start_header_id|>assistant<|end_header_id|>

"""
        .trimRight();
  }

  static String _buildCompactEmbeddedContext(NarrativeContext context) {
    final characterSummary = _compactList(
      (context.metadata['charactersSummary'] as List?)?.cast<String>() ??
          const <String>[],
      emptyText: 'Sin notas de personajes.',
      maxItems: 3,
      maxItemLength: 140,
    );
    final scenarioSummary = _compactList(
      (context.metadata['scenariosSummary'] as List?)?.cast<String>() ??
          const <String>[],
      emptyText: 'Sin notas de escenarios.',
      maxItems: 2,
      maxItemLength: 140,
    );
    final continuity = _compactList(
      context.knownFacts,
      emptyText: 'Sin hechos fijados.',
      maxItems: 4,
      maxItemLength: 140,
    );

    return """
# PROJECT NARRATIVE CONTEXT
BOOK: ${_trimInline(context.bookTitle, 80)}
DOCUMENT: ${_trimInline(context.documentTitle, 80)}
SUMMARY: ${_trimInline(context.projectSummary, 180)}
TENSION: ${_trimInline(context.tensionLevel, 32)}
CHARACTERS:
$characterSummary
SCENARIOS:
$scenarioSummary
CONTINUITY:
$continuity
"""
        .trim();
  }

  static String _getDocumentGlimpse(String content, {int maxChars = 1000}) {
    if (content.length <= maxChars) return content;
    return "...\n${content.substring(content.length - maxChars)}";
  }

  static String _compactList(
    List<String> items, {
    required String emptyText,
    required int maxItems,
    required int maxItemLength,
  }) {
    if (items.isEmpty) {
      return '- $emptyText';
    }

    return items
        .take(maxItems)
        .map((item) => '- ${_trimInline(item, maxItemLength)}')
        .join('\n');
  }

  static String _trimInline(String value, int maxChars) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return '';
    }
    if (normalized.length <= maxChars) {
      return normalized;
    }
    return '${normalized.substring(0, maxChars - 1)}…';
  }

  static _SelectionLanguage _inferLanguage(String selection) {
    final normalized = selection.trim().toLowerCase();
    final spanishSignals = <String>[
      ' el ',
      ' la ',
      ' de ',
      ' que ',
      ' y ',
      ' en ',
      ' un ',
      ' una ',
      ' pero ',
      ' no ',
      '¿',
      '¡',
      'á',
      'é',
      'í',
      'ó',
      'ú',
      'ñ',
    ];

    var spanishScore = 0;
    for (final signal in spanishSignals) {
      if (normalized.contains(signal)) {
        spanishScore += 1;
      }
    }

    return spanishScore > 0
        ? _SelectionLanguage.spanish
        : _SelectionLanguage.english;
  }

  static _SelectionLanguage _resolveOutputLanguage(
    _SelectionLanguage inferredLanguage,
    OutputLanguageMode mode,
  ) {
    return switch (mode) {
      OutputLanguageMode.matchSelection => inferredLanguage,
      OutputLanguageMode.spanish => _SelectionLanguage.spanish,
      OutputLanguageMode.english => _SelectionLanguage.english,
    };
  }
}

enum _SelectionLanguage {
  spanish('Spanish'),
  english('English');

  const _SelectionLanguage(this.displayName);
  final String displayName;
}
