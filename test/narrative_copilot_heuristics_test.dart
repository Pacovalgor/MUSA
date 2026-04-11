import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_copilot.dart';
import 'package:musa/modules/books/services/narrative_memory_updater.dart';
import 'package:musa/modules/books/services/story_state_updater.dart';
import 'package:musa/modules/manuscript/models/document.dart';

void main() {
  final now = DateTime(2026, 4, 11, 12);

  test('thriller detects investigation loop and asks for consequence', () {
    final state = _analyze(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.thriller,
        targetPace: TargetPace.urgent,
        readerPromise: 'Una investigación con presión creciente.',
        dominantPriority: DominantPriority.tension,
      ),
      texts: const [
        'Clara investiga la llamada y encuentra una pista en la mesa. '
            'Busca al portero, pregunta por el coche y descubre otra pista bajo la lluvia. '
            'Nadie la amenaza todavía, pero el rastro vuelve al mismo callejón.',
        'Clara investiga el archivo. La señal de sangre se repite y ella averigua que el reloj estaba parado.',
        'Clara busca una huella nueva. La pista no cambia la situación.',
        'Clara pregunta otra vez por el coche. La pista confirma lo que ya sabía.',
      ],
    );

    expect(state.currentAct, StoryAct.actII);
    expect(state.currentChapterFunction, CurrentChapterFunction.complicate);
    expect(state.diagnostics,
        contains('Se repite el patrón investigar-pista-investigar.'));
    expect(state.nextBestMove, contains('Rompe la cadena de investigación'));
    expect(state.nextBestMoveReason, contains('búsquedas y pistas'));
  });

  test('science fiction accepts explanation when it changes system rules', () {
    final state = _analyze(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.scienceFiction,
        readerPromise: 'Una colonia donde cada idea altera el sistema.',
        dominantPriority: DominantPriority.idea,
      ),
      texts: const [
        'La colonia despierta con una nueva regla del sistema. '
            'El protocolo de oxígeno cambia el coste de cada puerta y obliga a Mara a decidir quién cruza primero. '
            'La explicación técnica no resuelve el peligro: lo desplaza hacia la siguiente cámara.',
        'Mara comprende que el algoritmo limita el acceso a los niños.',
        'El sistema cambia otra consecuencia de la órbita.',
        'El protocolo obliga a elegir entre energía y aire.',
      ],
    );

    expect(state.currentAct, StoryAct.actII);
    expect(
      state.diagnostics,
      contains(
          'Ciencia ficción: la explicación aporta porque cambia reglas o consecuencias.'),
    );
    expect(state.diagnostics,
        isNot(contains(contains('No se detecta cambio claro'))));
    expect(state.nextBestMove, contains('Complica la línea principal'));
  });

  test('fantasy tolerates atmosphere when destiny or debt adds pressure', () {
    final state = _analyze(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.fantasy,
        targetPace: TargetPace.measured,
        readerPromise:
            'Un viaje de destino con mundo antiguo y deuda familiar.',
        dominantPriority: DominantPriority.atmosphere,
      ),
      texts: const [
        'El bosque respira bajo la luna y el templo abre sus puertas de piedra. '
            'La magia no ataca, pero la deuda del juramento marca a Irea y su destino exige cruzar antes del alba. '
            'La sombra del exilio sigue detrás de la comitiva.',
        'El reino recuerda la maldición y el juramento familiar.',
        'Irea duda ante el oráculo, pero conserva la deuda.',
        'La magia del templo empuja el destino hacia la guerra.',
      ],
    );

    expect(state.currentAct, StoryAct.actII);
    expect(
      state.diagnostics,
      contains('Fantasía: la atmósfera queda sostenida por conflicto latente.'),
    );
    expect(state.diagnostics,
        isNot(contains(contains('No se detecta cambio claro'))));
    expect(state.nextBestMove, contains('Complica la línea principal'));
  });

  test('thriller atmosphere without direct pressure is flagged', () {
    final state = _analyze(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.thriller,
        targetPace: TargetPace.urgent,
        readerPromise: 'Un thriller seco con presión creciente.',
        dominantPriority: DominantPriority.tension,
      ),
      texts: const [
        'La ciudad amanecía húmeda y Clara miraba los reflejos del bar. '
            'El humo, las luces y el silencio alargaban la espera sin cambiar su situación.',
        'Clara camina bajo la lluvia y piensa en el caso sin encontrar nada nuevo.',
        'El callejón conserva el mismo olor metálico. Nadie la sigue y nada cambia.',
        'La noche pesa sobre los cristales. Clara espera otra llamada.',
      ],
    );

    expect(
        state.diagnostics,
        contains(
            'No se detecta cambio claro de información, amenaza o estado emocional.'));
    expect(state.nextBestMove, contains('Falta presión directa'));
    expect(state.nextBestMoveReason, contains('no cambia bastante'));
  });

  test('science fiction exposition without changed rules is flagged', () {
    final state = _analyze(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.scienceFiction,
        readerPromise: 'Una novela de ideas donde el sistema debe tener coste.',
        dominantPriority: DominantPriority.idea,
      ),
      texts: const [
        'El sistema central tenía una arquitectura elegante. '
            'La tecnología era antigua, modular y luminosa, con capas de cálculo descritas durante páginas. '
            'Mara observa la sala sin que la explicación cambie lo que puede hacer.',
        'El algoritmo se describe con precisión, pero nadie decide nada.',
        'La colonia conserva su rutina y el protocolo queda como contexto.',
        'La tecnología ocupa la escena sin coste visible.',
      ],
    );

    expect(
      state.diagnostics,
      contains(
          'Ciencia ficción: la explicación necesita una consecuencia práctica.'),
    );
    expect(
        state.diagnostics,
        contains(
            'No se detecta cambio claro de información, amenaza o estado emocional.'));
    expect(state.nextBestMove, contains('La idea necesita consecuencia'));
  });

  test('fantasy atmosphere without latent pressure is not forgiven', () {
    final state = _analyze(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.fantasy,
        readerPromise:
            'Fantasía de atmósfera con conflicto bajo la superficie.',
        dominantPriority: DominantPriority.atmosphere,
      ),
      texts: const [
        'El reino brillaba al amanecer y la magia cruzaba las torres como una canción antigua. '
            'El bosque olía a lluvia, el templo dormía y los estandartes ondeaban sin empujar a nadie.',
        'La magia del mercado colorea la escena sin deuda ni amenaza.',
        'El reino celebra una fiesta larga sin juramento ni coste.',
        'El bosque y el templo permanecen hermosos, pero nada exige actuar.',
      ],
    );

    expect(
      state.diagnostics,
      contains(
          'Fantasía: la atmósfera necesita deuda, destino o conflicto debajo.'),
    );
    expect(
        state.diagnostics,
        contains(
            'No se detecta cambio claro de información, amenaza o estado emocional.'));
    expect(state.nextBestMove, contains('Conserva la atmósfera'));
  });

  test('ambiguous hybrid chapter does not overstate confrontation', () {
    final state = _analyze(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.mystery,
        readerPromise: 'Un misterio íntimo de avance lento.',
        targetPace: TargetPace.measured,
      ),
      texts: const [
        'Clara recuerda una carta, observa la habitación y duda antes de hablar. '
            'Hay una pista posible, pero la escena funciona más como preparación que como choque abierto.',
        'La carta queda sobre la mesa y la conversación se aplaza.',
      ],
    );

    expect(state.currentAct, StoryAct.actI);
    expect(state.currentChapterFunction, CurrentChapterFunction.introduce);
    expect(
        state.currentChapterFunction, isNot(CurrentChapterFunction.confront));
    expect(state.globalTension, lessThan(45));
  });
}

StoryState _analyze({
  required DateTime now,
  required BookNarrativeProfile profile,
  required List<String> texts,
}) {
  final book = Book(
    id: 'book-1',
    title: 'Fixture',
    createdAt: now,
    updatedAt: now,
    narrativeProfile: profile,
  );
  final documents = texts
      .asMap()
      .entries
      .map(
        (entry) => Document(
          id: 'doc-${entry.key}',
          bookId: book.id,
          title: 'Capítulo ${entry.key + 1}',
          orderIndex: entry.key,
          content: entry.value,
          wordCount: entry.value.split(RegExp(r'\s+')).length,
          createdAt: now,
          updatedAt: now,
        ),
      )
      .toList();
  final memory = const NarrativeMemoryUpdater().update(
    bookId: book.id,
    documents: documents,
    previous: null,
    now: now,
  );
  return const StoryStateUpdater().update(
    book: book,
    documents: documents,
    memory: memory,
    previous: null,
    now: now,
  );
}
