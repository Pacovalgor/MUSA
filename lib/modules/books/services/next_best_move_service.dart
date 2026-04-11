import '../models/book.dart';
import '../models/narrative_copilot.dart';

class NextBestMoveRecommendation {
  final String move;
  final String reason;

  const NextBestMoveRecommendation({
    required this.move,
    required this.reason,
  });
}

class NextBestMoveService {
  const NextBestMoveService();

  String recommend({
    required Book book,
    required StoryAct act,
    required int globalTension,
    required bool realProgress,
    required bool hasInvestigationLoop,
    required NarrativeMemory memory,
    required List<String> diagnostics,
  }) {
    return recommendDetailed(
      book: book,
      act: act,
      globalTension: globalTension,
      realProgress: realProgress,
      hasInvestigationLoop: hasInvestigationLoop,
      memory: memory,
      diagnostics: diagnostics,
    ).move;
  }

  NextBestMoveRecommendation recommendDetailed({
    required Book book,
    required StoryAct act,
    required int globalTension,
    required bool realProgress,
    required bool hasInvestigationLoop,
    required NarrativeMemory memory,
    required List<String> diagnostics,
  }) {
    final genre = book.narrativeProfile.primaryGenre;

    if (book.narrativeProfile.readerPromise?.trim().isEmpty ?? true) {
      return const NextBestMoveRecommendation(
        move:
            'Define una promesa de lectura concreta antes de pedirle más a la próxima escena.',
        reason:
            'El ADN narrativo todavía no dice qué experiencia debe sostener el libro.',
      );
    }

    if (hasInvestigationLoop) {
      return const NextBestMoveRecommendation(
        move:
            'Rompe la cadena de investigación: la próxima pista debe obligar a elegir, perder algo o exponerse.',
        reason:
            'Detecto varias búsquedas y pistas seguidas sin una consecuencia proporcional.',
      );
    }

    if (!realProgress) {
      return switch (genre) {
        BookPrimaryGenre.thriller => const NextBestMoveRecommendation(
            move:
                'Falta presión directa: haz que alguien actúe contra la protagonista o que el tiempo se cierre.',
            reason:
                'El tramo no cambia bastante la amenaza, la información o la posición emocional.',
          ),
        BookPrimaryGenre.scienceFiction => const NextBestMoveRecommendation(
            move:
                'La idea necesita consecuencia: convierte la explicación en una regla que obligue a decidir.',
            reason:
                'La escena explica, pero todavía no altera el sistema ni el margen de acción.',
          ),
        BookPrimaryGenre.fantasy => const NextBestMoveRecommendation(
            move:
                'Conserva la atmósfera, pero ata la próxima imagen a una deuda, destino o conflicto latente.',
            reason:
                'La pausa de mundo funciona mejor si deja una presión narrativa debajo.',
          ),
        _ => const NextBestMoveRecommendation(
            move:
                'Añade un cambio visible: información nueva, amenaza concreta o giro emocional.',
            reason:
                'No detecto un avance claro que modifique la situación de la escena.',
          ),
      };
    }

    if (globalTension < 30 && genre == BookPrimaryGenre.thriller) {
      return const NextBestMoveRecommendation(
        move:
            'Antes de abrir más contexto, sube la urgencia con amenaza, reloj o persecución.',
        reason:
            'Para thriller, la tensión global sigue baja frente a la promesa del género.',
      );
    }

    if (memory.openQuestions.length > 4) {
      return const NextBestMoveRecommendation(
        move: 'Cierra o transforma una pregunta abierta antes de plantar otra.',
        reason:
            'Hay demasiadas preguntas abiertas compitiendo por la atención.',
      );
    }

    return switch (act) {
      StoryAct.actI => const NextBestMoveRecommendation(
          move:
              'Afila la promesa inicial: presenta una fractura que obligue a seguir leyendo.',
          reason:
              'El Acto I debe introducir el libro y dejar clara su primera tensión.',
        ),
      StoryAct.actII => const NextBestMoveRecommendation(
          move:
              'Complica la línea principal con una elección que tenga coste narrativo.',
          reason:
              'El Acto II debe convertir lo abierto en presión y consecuencia.',
        ),
      StoryAct.actIII => const NextBestMoveRecommendation(
          move:
              'Confronta la amenaza central y paga una pista o herida plantada antes.',
          reason: 'El Acto III debe llevar lo acumulado a confrontación.',
        ),
    };
  }
}
