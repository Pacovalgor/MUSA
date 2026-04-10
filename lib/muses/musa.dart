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
}
