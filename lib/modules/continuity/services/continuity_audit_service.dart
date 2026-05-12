import '../../books/models/book.dart';
import '../../books/models/narrative_copilot.dart';
import '../../characters/models/character.dart';
import '../../manuscript/models/document.dart';
import '../../scenarios/models/scenario.dart';
import '../models/continuity_audit.dart';
import '../models/continuity_state.dart';

class ContinuityAuditService {
  const ContinuityAuditService();

  List<ContinuityFinding> audit({
    required Book book,
    required List<Document> documents,
    required NarrativeMemory? memory,
    required StoryState? storyState,
    required ContinuityState? continuityState,
    required List<Character> characters,
    required List<Scenario> scenarios,
    required DateTime now,
  }) {
    final text = documents
        .where((document) => document.bookId == book.id)
        .map((document) => document.content)
        .join('\n\n');
    final findings = <ContinuityFinding>[
      ..._unresolvedPromiseFindings(memory),
      ..._contradictionFindings(text, continuityState),
      ..._untrackedCharacterFindings(text, characters),
      ..._untrackedScenarioFindings(text, scenarios),
      ..._repeatedPatternFindings(memory),
    ];
    return findings.take(8).toList();
  }

  List<ContinuityFinding> _unresolvedPromiseFindings(
    NarrativeMemory? memory,
  ) {
    final unresolved = memory?.unresolvedPromises ?? const [];
    if (unresolved.length < 3) return const [];
    final evidence = unresolved.take(3).join(' · ');
    return [
      ContinuityFinding(
        id: _makeId(ContinuityFindingType.unresolvedPromise, evidence),
        type: ContinuityFindingType.unresolvedPromise,
        severity: ContinuityFindingSeverity.warning,
        title: 'Promesas abiertas sin pago',
        detail:
            'La novela acumula promesas abiertas que pueden competir entre sí.',
        evidence: evidence,
        action:
            'Cierra, transforma o jerarquiza una promesa antes de abrir otra.',
      ),
    ];
  }

  List<ContinuityFinding> _contradictionFindings(
    String text,
    ContinuityState? continuityState,
  ) {
    final lowered = text.toLowerCase();
    final findings = <ContinuityFinding>[];
    for (final contradiction
        in continuityState?.forbiddenContradictions ?? const <String>[]) {
      final normalized = contradiction.trim();
      if (normalized.isEmpty) continue;
      if (!lowered.contains(normalized.toLowerCase())) continue;
      findings.add(
        ContinuityFinding(
          id: _makeId(ContinuityFindingType.contradiction, normalized),
          type: ContinuityFindingType.contradiction,
          severity: ContinuityFindingSeverity.critical,
          title: 'Contradicción prohibida detectada',
          detail:
              'El manuscrito contiene una afirmación marcada como contradicción.',
          evidence: normalized,
          action:
              'Revisa la escena y decide si corregir el hecho o actualizar la memoria de continuidad.',
        ),
      );
    }
    return findings;
  }

  List<ContinuityFinding> _untrackedCharacterFindings(
    String text,
    List<Character> characters,
  ) {
    final known =
        characters.map((item) => item.displayName.toLowerCase()).toSet();
    final results = <ContinuityFinding>[];
    for (final name in _capitalizedNames(text)) {
      if (known.contains(name.toLowerCase())) continue;
      if (_blockedNames.contains(name)) continue;
      results.add(
        ContinuityFinding(
          id: _makeId(ContinuityFindingType.untrackedCharacter, name),
          type: ContinuityFindingType.untrackedCharacter,
          severity: ContinuityFindingSeverity.info,
          title: 'Personaje sin ficha',
          detail:
              'Aparece un nombre relevante que no tiene ficha de personaje.',
          evidence: name,
          action:
              'Crea o vincula una ficha si este personaje seguirá importando.',
        ),
      );
      if (results.length == 2) break;
    }
    return results;
  }

  List<ContinuityFinding> _untrackedScenarioFindings(
    String text,
    List<Scenario> scenarios,
  ) {
    final known =
        scenarios.map((item) => item.displayName.toLowerCase()).toSet();
    final results = <ContinuityFinding>[];
    for (final place in _namedPlaces(text)) {
      if (known.any((knownPlace) => knownPlace.contains(place.toLowerCase()))) {
        continue;
      }
      results.add(
        ContinuityFinding(
          id: _makeId(ContinuityFindingType.untrackedScenario, place),
          type: ContinuityFindingType.untrackedScenario,
          severity: ContinuityFindingSeverity.info,
          title: 'Escenario sin ficha',
          detail: 'Aparece un lugar nombrado que no tiene ficha de escenario.',
          evidence: place,
          action: 'Crea o vincula una ficha si este lugar tendrá continuidad.',
        ),
      );
      if (results.length == 2) break;
    }
    return results;
  }

  List<ContinuityFinding> _repeatedPatternFindings(NarrativeMemory? memory) {
    final warnings = memory?.scenePatternWarnings ?? const [];
    if (warnings.isEmpty) return const [];
    final evidence = warnings.take(2).join(' · ');
    return [
      ContinuityFinding(
        id: _makeId(ContinuityFindingType.repeatedPattern, evidence),
        type: ContinuityFindingType.repeatedPattern,
        severity: ContinuityFindingSeverity.warning,
        title: 'Patrón de escena repetido',
        detail: warnings.first,
        evidence: evidence,
        action: 'Convierte la repetición en consecuencia visible.',
      ),
    ];
  }

  /// Genera un id estable a partir del tipo de hallazgo y una clave de evidencia.
  /// El id es reproducible entre sesiones siempre que el hallazgo subyacente
  /// no cambie, lo que permite persistir los descartados sin guardar los findings.
  static String _makeId(ContinuityFindingType type, String key) {
    final clean = key
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-záéíóúña-z0-9·]+'), '_');
    final truncated = clean.length > 48 ? clean.substring(0, 48) : clean;
    return 'cf_${type.name}_$truncated';
  }

  List<String> _capitalizedNames(String text) {
    final matches = RegExp(r'\b[A-ZÁÉÍÓÚÑ][a-záéíóúñ]{2,}\b')
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
    final results = <String>[];
    for (final match in matches) {
      if (results.contains(match)) continue;
      results.add(match);
    }
    return results;
  }

  List<String> _namedPlaces(String text) {
    final results = <String>[];
    final pattern = RegExp(
      r'\b(?:Observatorio|Callejón|Calle|Casa|Hotel|Hospital|Estación|Biblioteca|Puerto|Muelle|Torre|Templo)\s+[A-ZÁÉÍÓÚÑ][A-Za-zÁÉÍÓÚáéíóúÑñ ]{2,}',
    );
    for (final match in pattern.allMatches(text)) {
      final value = match.group(0)!.trim();
      if (!results.contains(value)) results.add(value);
    }
    return results;
  }

  static const _blockedNames = <String>{
    'Capítulo',
    'Diane',
    'Madrid',
    'San',
    'Francisco',
  };
}
