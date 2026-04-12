import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_copilot.dart';
import 'package:musa/modules/books/services/next_best_move_service.dart';
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
    expect(state.nextBestMove, contains('restricción'));
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
    expect(state.nextBestMove, contains('concepto'));
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

  test('research document does not contaminate previous story state', () {
    final previous = StoryState(
      bookId: 'book-1',
      currentAct: StoryAct.actII,
      currentChapterFunction: CurrentChapterFunction.complicate,
      globalTension: 62,
      nextBestMove:
          'Complica la línea principal con una elección que tenga coste narrativo.',
      updatedAt: now,
    );
    final state = _analyze(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.mystery,
        readerPromise: 'Una investigación íntima.',
      ),
      texts: const [
        'Resumen ejecutivo. Este documento analiza símbolos, apofenia y sesgos cognitivos. '
            'Objetivo de este documento: servir como material de investigación, no como escena.',
      ],
      previous: previous,
    );

    expect(state.currentAct, previous.currentAct);
    expect(state.globalTension, previous.globalTension);
    expect(
        state.diagnostics, contains('Documento no narrativo: investigación.'));
    expect(state.nextBestMove, contains('investigación'));
  });

  test('research document enriches contextual memory without story state', () {
    final memory = _memory(
      now: now,
      texts: const [
        'Documento de investigación. Hallazgo de investigación: el símbolo aparece en casos de apofenia colectiva y sirve como señal persistente.',
      ],
    );
    final previous = StoryState(
      bookId: 'book-1',
      globalTension: 44,
      updatedAt: now,
    );
    final state = _analyze(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.mystery,
        readerPromise: 'Una investigación íntima.',
      ),
      texts: const [
        'Documento de investigación. Hallazgo de investigación: el símbolo aparece en casos de apofenia colectiva y sirve como señal persistente.',
      ],
      previous: previous,
    );

    expect(memory.openQuestions, isEmpty);
    expect(memory.researchFindings, isNotEmpty);
    expect(memory.persistentConcepts, isNotEmpty);
    expect(state.globalTension, previous.globalTension);
    expect(state.nextBestMove, contains('suma contexto'));
  });

  test('worldbuilding stores affirmed rules and constraints only', () {
    final memory = _memory(
      now: now,
      texts: const [
        'Worldbuilding del reino. Regla del mundo: toda magia exige un coste de memoria. '
            'El juramento obliga a la orden a custodiar el templo.',
      ],
    );
    final state = _analyze(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.fantasy,
        readerPromise: 'Fantasía de deuda y destino.',
      ),
      texts: const [
        'Worldbuilding del reino. Regla del mundo: toda magia exige un coste de memoria. '
            'El juramento obliga a la orden a custodiar el templo.',
      ],
    );

    expect(memory.worldRules, isNotEmpty);
    expect(memory.systemConstraints, isNotEmpty);
    expect(
        state.diagnostics, contains('Documento no narrativo: worldbuilding.'));
    expect(state.nextBestMove, contains('regla persistente'));
  });

  test('worldbuilding atmosphere alone is not stored as context rule', () {
    final memory = _memory(
      now: now,
      texts: const [
        'Worldbuilding del reino. La magia brilla sobre las torres y el templo duerme bajo una luna azul.',
      ],
    );

    expect(memory.worldRules, isEmpty);
    expect(memory.systemConstraints, isEmpty);
    expect(memory.researchFindings, isEmpty);
  });

  test('technical document is ignored as narrative input', () {
    final state = _analyze(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.thriller,
        readerPromise: 'Presión progresiva.',
      ),
      texts: const [
        'ENTREVISTA FULL STACK — MANUAL COMPLETO. OBJETIVO Transmitir estabilidad. '
            'REGLA BASE: pensar antes de responder. API, frontend, backend y pull request.',
      ],
    );

    expect(state.diagnostics, contains('Documento no narrativo: técnico.'));
    expect(state.nextBestMove, contains('material técnico'));
    expect(state.globalTension, 0);
  });

  test('technical document does not enrich contextual memory', () {
    final memory = _memory(
      now: now,
      texts: const [
        'ENTREVISTA FULL STACK — MANUAL COMPLETO. REGLA BASE: pensar antes de responder. API, frontend y backend.',
      ],
    );

    expect(memory.worldRules, isEmpty);
    expect(memory.systemConstraints, isEmpty);
    expect(memory.researchFindings, isEmpty);
    expect(memory.persistentConcepts, isEmpty);
  });

  test('negated evidence is not stored as contextual memory', () {
    final memory = _memory(
      now: now,
      texts: const [
        'Worldbuilding del reino. No hay regla para la magia y el ritual opera sin coste. Nadie está obligado por juramento.',
      ],
    );

    expect(memory.worldRules, isEmpty);
    expect(memory.systemConstraints, isEmpty);
  });

  test('scene keeps narrative behavior and can enrich context', () {
    final memory = _memory(
      now: now,
      texts: const [
        'San Francisco, 6:48 a.m. Me desperté y miré la pantalla. '
            'La regla del sistema obliga a pagar un coste cada vez que Clara abre el mapa.',
      ],
    );
    final state = _analyze(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.thriller,
        readerPromise: 'Presión progresiva.',
      ),
      texts: const [
        'San Francisco, 6:48 a.m. Me desperté y miré la pantalla. '
            'La regla del sistema obliga a pagar un coste cada vez que Clara abre el mapa.',
      ],
    );

    expect(memory.worldRules, isNotEmpty);
    expect(memory.systemConstraints, isNotEmpty);
    expect(
        state.diagnostics, isNot(contains('Documento no narrativo: escena.')));
    expect(state.nextBestMove, isNot(contains('Documento tratado')));
  });

  test('scene uses contextual rule when the text matches it', () {
    final recommendation = _recommend(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.thriller,
        readerPromise: 'Presión progresiva.',
      ),
      currentText:
          'La regla del sistema obliga a pagar un coste cada vez que Clara abre el mapa.',
      memory: NarrativeMemory(
        bookId: 'book-1',
        worldRules: const [
          'La regla del sistema obliga a pagar un coste cada vez que Clara abre el mapa.',
        ],
        updatedAt: now,
      ),
    );

    expect(recommendation.focus, 'regla del mundo');
    expect(recommendation.suggestedAction, contains('regla'));
    expect(recommendation.riskIfIgnored, contains('regla'));
  });

  test('scene uses system constraint before generic advice', () {
    final recommendation = _recommend(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.scienceFiction,
        readerPromise: 'Una colonia donde cada idea altera el sistema.',
      ),
      currentText:
          'El protocolo de oxígeno limita el acceso y obliga a Mara a decidir quién cruza primero.',
      memory: NarrativeMemory(
        bookId: 'book-1',
        systemConstraints: const [
          'El protocolo de oxígeno limita el acceso y obliga a Mara a decidir quién cruza primero.',
        ],
        updatedAt: now,
      ),
    );

    expect(recommendation.focus, 'restricción del sistema');
    expect(recommendation.suggestedAction, contains('restricción'));
    expect(recommendation.strategy, NextBestMoveStrategy.decision);
    expect(recommendation.contextTrace, 'contextAcceptedSystemConstraints');
  });

  test('dialog-like short constraint is rejected and falls back', () {
    final recommendation = _recommend(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.thriller,
        readerPromise: 'Una investigación con presión creciente.',
      ),
      act: StoryAct.actII,
      currentText:
          'Clara escucha “depende de quien lo mire” y vuelve al pasillo sin nueva presión.',
      memory: NarrativeMemory(
        bookId: 'book-1',
        systemConstraints: const ['—Depende de quien lo mire.'],
        updatedAt: now,
      ),
    );

    expect(recommendation.focus, 'urgencia');
    expect(recommendation.contextTrace, 'contextRejectedDialogLike');
  });

  test('lexical overlap without structure is rejected and falls back', () {
    final recommendation = _recommend(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.thriller,
        readerPromise: 'Una investigación con presión creciente.',
      ),
      act: StoryAct.actII,
      currentText:
          'Clara piensa que el ambiente del barrio confunde la lectura del caso.',
      memory: NarrativeMemory(
        bookId: 'book-1',
        systemConstraints: const ['El ambiente del barrio era raro y confuso.'],
        updatedAt: now,
      ),
    );

    expect(recommendation.focus, 'urgencia');
    expect(
      recommendation.contextTrace,
      'contextRejectedNoStructuralMarkers',
    );
  });

  test('world rule with strong structure passes the gate', () {
    final recommendation = _recommend(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.fantasy,
        readerPromise: 'Fantasía de deuda y destino.',
      ),
      currentText:
          'La regla del juramento exige un coste de sangre y nadie puede romperla.',
      memory: NarrativeMemory(
        bookId: 'book-1',
        worldRules: const [
          'La regla del juramento exige un coste de sangre y nadie puede romperla.'
        ],
        updatedAt: now,
      ),
    );

    expect(recommendation.focus, 'regla del mundo');
    expect(recommendation.contextTrace, 'contextAcceptedWorldRules');
  });

  test('scene without contextual match keeps generic output', () {
    final recommendation = _recommend(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.mystery,
        readerPromise: 'Una investigación íntima.',
      ),
      act: StoryAct.actII,
      currentText:
          'Clara cruza la calle y observa el escaparate sin encontrar nada nuevo.',
      memory: NarrativeMemory(
        bookId: 'book-1',
        worldRules: const ['La luna gobierna el mar y las mareas del reino.'],
        researchFindings: const ['Un hallazgo sobre la piedra azul antigua.'],
        persistentConcepts: const ['El concepto de sombra heredada.'],
        updatedAt: now,
      ),
    );

    expect(recommendation.focus, 'coste narrativo');
    expect(recommendation.suggestedAction,
        contains('Complica la línea principal'));
  });

  test('scene does not invent context when overlap is absent', () {
    final recommendation = _recommend(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.fantasy,
        readerPromise: 'Fantasía de deuda y destino.',
      ),
      currentText:
          'Clara entra en la cafetería y pide agua mientras mira la lluvia.',
      memory: NarrativeMemory(
        bookId: 'book-1',
        worldRules: const ['El juramento exige silencio al amanecer.'],
        systemConstraints: const ['La puerta solo se abre con sangre.'],
        researchFindings: const ['El archivo confirma una deriva orbital.'],
        persistentConcepts: const ['La sombra del heredero.'],
        updatedAt: now,
      ),
    );

    expect(recommendation.focus, 'promesa inicial');
    expect(recommendation.suggestedAction, contains('fractura'));
  });

  test('repeated information strategy is diversified into decision', () {
    final recommendation = _recommend(
      now: now,
      profile: const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.thriller,
        readerPromise: 'Una investigación con presión creciente.',
      ),
      currentText: 'Clara mira la mesa y decide no abrir otra pista todavía.',
      memory: NarrativeMemory(
        bookId: 'book-1',
        openQuestions: const [
          '¿Quién llamó primero?',
          '¿Qué vio en la puerta?',
          '¿Por qué mentía el portero?',
          '¿Quién borró la cámara?',
          '¿Qué ocultó la víctima?',
        ],
        updatedAt: now,
      ),
      previousMove:
          'Cierra o transforma una pregunta abierta antes de plantar otra.',
    );

    expect(recommendation.focus, 'decisión');
    expect(recommendation.suggestedAction, contains('decisión de escena'));
    expect(recommendation.reason, contains('pregunta pendiente'));
  });
}

StoryState _analyze({
  required DateTime now,
  required BookNarrativeProfile profile,
  required List<String> texts,
  StoryState? previous,
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
    previous: previous,
    now: now,
  );
}

NarrativeMemory _memory({
  required DateTime now,
  required List<String> texts,
}) {
  final documents = texts
      .asMap()
      .entries
      .map(
        (entry) => Document(
          id: 'doc-${entry.key}',
          bookId: 'book-1',
          title: 'Capítulo ${entry.key + 1}',
          orderIndex: entry.key,
          content: entry.value,
          wordCount: entry.value.split(RegExp(r'\s+')).length,
          createdAt: now,
          updatedAt: now,
        ),
      )
      .toList();
  return const NarrativeMemoryUpdater().update(
    bookId: 'book-1',
    documents: documents,
    previous: null,
    now: now,
  );
}

NextBestMoveRecommendation _recommend({
  required DateTime now,
  required BookNarrativeProfile profile,
  required String currentText,
  required NarrativeMemory memory,
  StoryAct act = StoryAct.actI,
  int globalTension = 12,
  bool realProgress = true,
  bool hasInvestigationLoop = false,
  List<String> diagnostics = const [],
  String? previousMove,
}) {
  final book = Book(
    id: 'book-1',
    title: 'Fixture',
    createdAt: now,
    updatedAt: now,
    narrativeProfile: profile,
  );
  return const NextBestMoveService().recommendDetailed(
    book: book,
    act: act,
    globalTension: globalTension,
    realProgress: realProgress,
    hasInvestigationLoop: hasInvestigationLoop,
    memory: memory,
    diagnostics: diagnostics,
    currentText: currentText,
    previousMove: previousMove,
  );
}
