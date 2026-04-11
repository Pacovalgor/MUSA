// ignore_for_file: avoid_print

import 'package:musa/editor/services/chapter_analysis_service.dart';
import 'package:musa/modules/characters/models/character.dart';
import 'package:musa/modules/scenarios/models/scenario.dart';

void main() {
  const text = '''San Francisco, 4:03 a.m.
La ciudad dormía, pero este callejón no.

Me detuve a unos metros de la cinta amarilla. El distrito Mission tenía sus rincones, y este era uno de los que no salían en las guías turísticas. La policía había acordonado la zona, los focos iluminaban el suelo mojado, y una ambulancia permanecía inmóvil, como si ya no tuviera nada que hacer. El cuerpo había sido retirado hacía poco, pero la escena seguía viva. Sangre en el suelo. Un móvil caído. Un contenedor abierto. Nada más.

El aire olía a humedad, metal y basura vieja. Me subí la cremallera de la chaqueta. No por frío, sino por incomodidad. No era policía. Ni siquiera periodista oficial. Solo una becaria con un pase temporal de prensa y una curiosidad que no sabía contener.

Diane me había escrito a las tres y media. “Hay movimiento en Mission. Ve, observa, no molestes.” No me dio más detalles. Tampoco los pedí. A veces, cuanto menos sabes, más ves.

Saqué el móvil. No para grabar, sino para buscar.
Abrí X. Busqué Mission District, filtré por publicaciones recientes.
La mayoría eran especulaciones. Fotos borrosas. Comentarios alarmistas.

“Otro muerto en Mission. ¿Qué está pasando últimamente?”
“Alguien cayó esta noche. No es seguro caminar solo.”
“Escuché sirenas. ¿Fue un robo?”

Nada concreto.
Nadie mencionaba nombres.
Nadie sabía nada.
Pero alguien había muerto. Y yo estaba allí, aunque fuera desde fuera.

Me acerqué lo que pude sin cruzar la cinta. El asfalto estaba húmedo. No sabía si por lluvia o por limpieza. Quizá por sangre. No quise pensarlo demasiado.

Un agente hablaba con una mujer mayor que parecía más asustada por las cámaras que por el crimen. Otro tomaba notas sin mirar a nadie. El callejón estaba lleno de movimiento, pero vacío de respuestas.

En la acera opuesta, un chico con gorra grababa con su móvil. Sudadera gris, auriculares colgando, mochila con parches. No era prensa. Solo un curioso. O un vecino.

Me acerqué.

—¿Lo viste? —pregunté.

Se sobresaltó un poco, pero no se alejó.

—No. Pero escuché algo. Como un grito ahogado. Luego pasos. Luego nada.

—¿Grabaste algo?

—Solo después. Cuando llegaron los polis.

—¿Me lo puedes pasar?

Dudó.

—¿Eres prensa?

—Becaria —le mostré mi acreditación.
—¿Y eso sirve?

—Depende de quién lo mire.

Sonrió. Me envió el vídeo por AirDrop. Lo revisé al instante. No se veía el crimen, pero sí algo más interesante: una sombra que se alejaba del callejón, justo antes de que llegara la policía. Alta. Rápida. Chaqueta oscura. Algo en la mano.

Hice una captura.
No era prueba de nada. Pero tampoco era nada.

—¿Crees que fue un robo? —le pregunté.

—Eso dicen. Pero no sé. El tipo parecía tranquilo. Lo veía por aquí a veces.

—¿Sabes dónde trabajaba?

—Ni idea. Siempre con el portátil. Callado. A veces en la cafetería de la esquina. Creo que vivía cerca.

—¿Lo conocías?

—No. Solo de vista. Pero me suena que alguien lo llamó por su nombre una vez. Ethan, creo.

Levanté la vista.

—¿Ethan?

—Sí. O algo así. No estoy seguro. ¿Por qué?

—Por nada —dije, y anoté el nombre en mi libreta.

Se encogió de hombros.

—¿Tú crees que fue solo un robo?

No respondí.
Volví a mirar el callejón.
La cinta amarilla ondeaba con el viento.
Un gato cruzó corriendo entre los contenedores.
Un agente me miró con desconfianza, pero no dijo nada.

No podía entrar.
No podía preguntar.
Pero podía investigar.

Y eso, para mí, era suficiente.''';

  const service = ChapterAnalysisService();
  final analysis = service.analyze(
    chapterText: text,
    characters: const <Character>[],
    scenarios: const <Scenario>[],
    linkedCharacterIds: const <String>[],
    linkedScenarioIds: const <String>[],
  );
  print('moment=${analysis.dominantNarrativeMoment.title}');
  print('summary=${analysis.dominantNarrativeMoment.summary}');
  print('function=${analysis.chapterFunction}');
  print(
      'trajectory=${analysis.trajectory?.startLabel}->${analysis.trajectory?.endLabel}');
  print(
      'mainScenario=${analysis.mainScenario?.name} existing=${analysis.mainScenario?.existingScenarioId}');
  if (analysis.scenarioDevelopments.isNotEmpty) {
    final top = analysis.scenarioDevelopments.first;
    print('topScenarioDev=${top.label} score=${top.score} type=${top.type}');
  }
  print(
      'nextStep=${analysis.nextStep?.type} label=${analysis.nextStep?.label} action=${analysis.nextStep?.actionLabel}');
}
