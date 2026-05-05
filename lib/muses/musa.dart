import 'editorial_signals.dart';

abstract class Musa {
  final String id;
  final String name;
  final String shortName;
  final String icon;
  final String editorialIntent;
  final List<String> editorialRules;
  final String scopeReminder;
  final double maxLengthExpansionRatio;
  final List<String> thinkingMessages;
  final List<String> streamingMessages;

  const Musa({
    required this.id,
    required this.name,
    required this.shortName,
    required this.editorialIntent,
    required this.editorialRules,
    required this.scopeReminder,
    this.maxLengthExpansionRatio = 1.3,
    required this.thinkingMessages,
    required this.streamingMessages,
    this.icon = 'auto_awesome',
  });

  String get promptContract {
    final buffer = StringBuffer(editorialIntent.trim());
    for (final rule in editorialRules) {
      buffer.writeln();
      buffer.write('- ${rule.trim()}');
    }
    return buffer.toString().trim();
  }

  /// Refines the editorial contract based on the local context of the selection.
  String refinedContract(String? selection) {
    if (selection == null || selection.trim().isEmpty) return promptContract;

    final rules = _detectLocalRules(selection);
    if (rules.isEmpty) return promptContract;

    final buffer = StringBuffer(promptContract);
    for (final rule in rules) {
      buffer.writeln();
      buffer.write('- [LOCAL CONTEXT] $rule');
    }
    return buffer.toString().trim();
  }

  /// Hook for Musas to add dynamic rules based on the selection.
  List<String> _detectLocalRules(String selection) => const [];
}

class StyleMusa extends Musa {
  const StyleMusa()
      : super(
          id: 'style',
          name: 'Musa de Estilo',
          shortName: 'Estilo',
          icon: 'brush',
          editorialIntent:
              'Refina la prosa del pasaje seleccionado con una mejora literaria controlada.',
          editorialRules: const [
            'Prioriza cadencia, precisión léxica y elegancia verbal.',
            'Mantén el sentido original y evita expandir el contenido si no es necesario.',
            'Refina antes de reimaginar: mejora la frase sin invadirla.',
            'Evita metáforas genéricas, solemnidad vacía y ornamento gratuito.',
          ],
          scopeReminder:
              'Puede elevar el léxico o la imagen, pero no debe inventar escena ni contexto nuevo.',
          maxLengthExpansionRatio: 1.3,
          thinkingMessages: const [
            'Invocando Musa de Estilo…',
            'Leyendo la respiración del pasaje…',
            'Afinando léxico y cadencia…',
          ],
          streamingMessages: const [
            'Puliendo la frase…',
            'Afinando tono y textura…',
            'Reescribiendo con contención…',
          ],
        );

  @override
  List<String> _detectLocalRules(String selection) {
    final rules = <String>[];
    final lowered = selection.toLowerCase();
    
    // Simple tokenization: split by spaces and common punctuation
    final rawTokens = lowered.split(RegExp(r'[\s\.,;:\!\?¿¡\(\)"]+'));
    final tokens = rawTokens.where((t) => t.isNotEmpty).toList();

    // 1. Detect repeated adverbs ending in -mente
    final menteTokens = tokens.where((t) => t.endsWith('mente') && t.length > 7).toList();
    if (menteTokens.length >= 2) {
      rules.add(
          'He detectado varios adverbios en "-mente" cercanos; busca sustituirlos por imágenes concretas o formas verbales más precisas.');
    }

    // 2. Detect repeated substantial words (>5 chars)
    final substantialTokens = tokens.where((t) => t.length > 5 && !t.endsWith('mente')).toList();
    final counts = <String, int>{};
    for (final word in substantialTokens) {
      counts[word] = (counts[word] ?? 0) + 1;
    }

    final repeatedWords = counts.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .take(2)
        .toList();

    if (repeatedWords.isNotEmpty) {
      rules.add(
          'Se repiten términos como "${repeatedWords.join(', ')}"; busca variedad léxica para mejorar la textura literaria.');
    }

    return rules;
  }
}

class TensionMusa extends Musa {
  const TensionMusa()
      : super(
          id: 'tension',
          name: 'Musa de Tensión',
          shortName: 'Tensión',
          icon: 'bolt',
          editorialIntent:
              'Aumenta la fricción narrativa del pasaje con inquietud concreta y amenaza implícita.',
          editorialRules: const [
            'Incrementa la tensión mediante detalles sensoriales, ambigüedad y fricción dramática.',
            'Prefiere señales concretas y físicas frente a abstracciones atmosféricas.',
            'Evita el suspense poético genérico y las frases grandilocuentes.',
            'No conviertas el pasaje en otra escena: intensifica lo que ya está ahí.',
          ],
          scopeReminder:
              'Puede aumentar inquietud, pero no debe convertir una frase mínima en una escena completa.',
          maxLengthExpansionRatio: 1.3,
          thinkingMessages: const [
            'Invocando Musa de Tensión…',
            'Buscando la grieta de la escena…',
            'Midiendo amenaza e incertidumbre…',
          ],
          streamingMessages: const [
            'Cargando la escena de fricción…',
            'Ajustando amenaza implícita…',
            'Reescribiendo con nervio…',
          ],
        );

  @override
  List<String> _detectLocalRules(String selection) {
    final rules = <String>[];
    final signals = buildEditorialSignals(selection);
    final hasPhysicalOrOperationalAction =
        signals.physicalActionScore > 0 || signals.operationalScore > 0;

    // 1. Diálogo estancado
    if (signals.dialogueMarksCount >= 2 && !hasPhysicalOrOperationalAction) {
      rules.add(
        'He detectado un intercambio de diálogo sin acción ni consecuencias; introduce gestos, movimientos o decisiones que hagan avanzar la escena y aumenten la tensión real.',
      );
    }

    // 2. Muchas preguntas sin acción
    if (signals.questionCount >= 3 && !hasPhysicalOrOperationalAction) {
      rules.add(
        'He detectado múltiples interrogantes sin señales de acción; prioriza las consecuencias y la fricción dramática frente a la duda pura.',
      );
    }

    // 3. Pasaje estático sin acción
    if (selection.length > 60 && !hasPhysicalOrOperationalAction) {
      rules.add(
        'El pasaje parece estático; inyecta verbos de acción física o fricción concreta para elevar la tensión.',
      );
    }

    return rules;
  }
}

class RhythmMusa extends Musa {
  const RhythmMusa()
      : super(
          id: 'rhythm',
          name: 'Musa de Ritmo',
          shortName: 'Ritmo',
          icon: 'tune',
          editorialIntent:
              'Mejora el flujo del pasaje para que respire mejor y se lea con musicalidad.',
          editorialRules: const [
            'Ajusta longitud de frases, pausas y enlaces para mejorar la lectura.',
            'Puedes dividir o unir frases si eso mejora el pulso del pasaje.',
            'Prioriza musicalidad, continuidad y claridad de la respiración textual.',
            'No adornes ni añadas ideas nuevas: trabaja sobre el movimiento del texto.',
          ],
          scopeReminder:
              'Puede reestructurar sintaxis, dividir o comprimir internamente, pero no añadir contenido fuera de los límites semánticos del fragmento.',
          maxLengthExpansionRatio: 1.4,
          thinkingMessages: const [
            'Invocando Musa de Ritmo…',
            'Escuchando el pulso del párrafo…',
            'Midiendo pausas y acentos…',
          ],
          streamingMessages: const [
            'Reordenando la respiración…',
            'Ajustando el compás…',
            'Reescribiendo con mejor flujo…',
          ],
        );

  @override
  List<String> _detectLocalRules(String selection) {
    final rules = <String>[];
    
    // Split into sentences using common ending punctuation
    final rawSentences = selection.split(RegExp(r'[\.\?!]+'));
    final sentences = rawSentences.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    if (sentences.isEmpty) return rules;

    int longSentences = 0;
    int currentConsecutiveShorts = 0;
    int maxConsecutiveShorts = 0;

    for (final sentence in sentences) {
      final wordCount = sentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      
      if (wordCount > 25) {
        longSentences++;
      }

      if (wordCount < 6) {
        currentConsecutiveShorts++;
        if (currentConsecutiveShorts > maxConsecutiveShorts) {
          maxConsecutiveShorts = currentConsecutiveShorts;
        }
      } else {
        currentConsecutiveShorts = 0;
      }
    }

    if (longSentences >= 2) {
      rules.add(
          'He detectado frases muy largas y complejas; busca dividirlas o alternar su longitud para que el pasaje respire mejor.');
    }

    if (maxConsecutiveShorts >= 3) {
      rules.add(
          'He detectado varias frases muy cortas consecutivas; considera enlazar algunas para evitar un ritmo demasiado fragmentado o monótono.');
    }

    return rules;
  }
}

class ClarityMusa extends Musa {
  const ClarityMusa()
      : super(
          id: 'clarity',
          name: 'Musa de Claridad',
          shortName: 'Claridad',
          icon: 'visibility',
          editorialIntent:
              'Aclara el pasaje sin empobrecerlo, conservando tono, sentido y voz narrativa.',
          editorialRules: const [
            'Elimina ambigüedad innecesaria y mejora la comprensión inmediata.',
            'Simplifica solo cuando haga el texto más nítido, no más plano.',
            'Conserva tono, matiz y subtexto siempre que sigan siendo legibles.',
            'No traduzcas ni reinterpretes la escena: despeja el pasaje desde dentro.',
          ],
          scopeReminder:
              'Debe ser la Musa más estricta con el alcance: aclarar no implica expandir.',
          maxLengthExpansionRatio: 1.2,
          thinkingMessages: const [
            'Invocando Musa de Claridad…',
            'Separando lo nítido de lo confuso…',
            'Ajustando precisión y enfoque…',
          ],
          streamingMessages: const [
            'Limpiando ambigüedad…',
            'Aclarando la línea narrativa…',
            'Reescribiendo con precisión…',
          ],
        );

  @override
  List<String> _detectLocalRules(String selection) {
    final rules = <String>[];
    if ('?'.allMatches(selection).length >= 2) {
      rules.add(
          'El fragmento tiene múltiples preguntas; prioriza la nitidez y el sentido sobre añadir más incertidumbre.');
    }
    final hasDialogue =
        selection.contains('—') || selection.contains('"') || selection.contains('“');
    if (hasDialogue && selection.length < 150) {
      rules.add(
          'Diálogo breve detectado; busca que la réplica sea nítida y directa, evitando la exposición verbal innecesaria.');
    }
    return rules;
  }
}
