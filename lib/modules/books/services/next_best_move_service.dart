import '../models/book.dart';
import '../models/narrative_copilot.dart';

class NextBestMoveRecommendation {
  final String move;
  final String reason;
  final NextBestMoveStrategy strategy;

  const NextBestMoveRecommendation({
    required this.move,
    required this.reason,
    required this.strategy,
  });
}

enum NextBestMoveStrategy {
  setup,
  pressure,
  decision,
  consequence,
  information,
  character,
  support,
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
    String? previousMove,
  }) {
    return recommendDetailed(
      book: book,
      act: act,
      globalTension: globalTension,
      realProgress: realProgress,
      hasInvestigationLoop: hasInvestigationLoop,
      memory: memory,
      diagnostics: diagnostics,
      previousMove: previousMove,
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
    String? previousMove,
  }) {
    final genre = book.narrativeProfile.primaryGenre;
    final previousStrategy = _inferStrategy(previousMove);

    if (book.narrativeProfile.readerPromise?.trim().isEmpty ?? true) {
      return const NextBestMoveRecommendation(
        move:
            'Define una promesa de lectura concreta antes de pedirle más a la próxima escena.',
        reason:
            'El ADN narrativo todavía no dice qué experiencia debe sostener el libro.',
        strategy: NextBestMoveStrategy.setup,
      );
    }

    if (hasInvestigationLoop) {
      if (previousStrategy == NextBestMoveStrategy.information) {
        return const NextBestMoveRecommendation(
          move:
              'No abras otra pista: convierte lo ya encontrado en una consecuencia visible.',
          reason:
              'La última recomendación ya empujaba información; ahora conviene variar hacia consecuencia.',
          strategy: NextBestMoveStrategy.consequence,
        );
      }
      return const NextBestMoveRecommendation(
        move:
            'Rompe la cadena de investigación: la próxima pista debe obligar a elegir, perder algo o exponerse.',
        reason:
            'Detecto varias búsquedas y pistas seguidas sin una consecuencia proporcional.',
        strategy: NextBestMoveStrategy.information,
      );
    }

    if (!realProgress) {
      return switch (genre) {
        BookPrimaryGenre.thriller => const NextBestMoveRecommendation(
            move:
                'Falta presión directa: haz que alguien actúe contra la protagonista o que el tiempo se cierre.',
            reason:
                'El tramo no cambia bastante la amenaza, la información o la posición emocional.',
            strategy: NextBestMoveStrategy.pressure,
          ),
        BookPrimaryGenre.scienceFiction => const NextBestMoveRecommendation(
            move:
                'La idea necesita consecuencia: convierte la explicación en una regla que obligue a decidir.',
            reason:
                'La escena explica, pero todavía no altera el sistema ni el margen de acción.',
            strategy: NextBestMoveStrategy.consequence,
          ),
        BookPrimaryGenre.fantasy => const NextBestMoveRecommendation(
            move:
                'Conserva la atmósfera, pero ata la próxima imagen a una deuda, destino o conflicto latente.',
            reason:
                'La pausa de mundo funciona mejor si deja una presión narrativa debajo.',
            strategy: NextBestMoveStrategy.pressure,
          ),
        _ => const NextBestMoveRecommendation(
            move:
                'Añade un cambio visible: información nueva, amenaza concreta o giro emocional.',
            reason:
                'No detecto un avance claro que modifique la situación de la escena.',
            strategy: NextBestMoveStrategy.consequence,
          ),
      };
    }

    if (globalTension < 30 && genre == BookPrimaryGenre.thriller) {
      return const NextBestMoveRecommendation(
        move:
            'Antes de abrir más contexto, sube la urgencia con amenaza, reloj o persecución.',
        reason:
            'Para thriller, la tensión global sigue baja frente a la promesa del género.',
        strategy: NextBestMoveStrategy.pressure,
      );
    }

    if (memory.openQuestions.length > 4) {
      final question = _specificOpenQuestion(memory);
      if (previousStrategy == NextBestMoveStrategy.information) {
        return NextBestMoveRecommendation(
          move:
              'Convierte una pregunta abierta en una decisión de escena antes de sumar otra línea.',
          reason: question == null
              ? 'La última recomendación ya iba hacia información; ahora conviene variar hacia decisión.'
              : 'La pregunta pendiente “$question” necesita afectar una elección concreta.',
          strategy: NextBestMoveStrategy.decision,
        );
      }
      return const NextBestMoveRecommendation(
        move: 'Cierra o transforma una pregunta abierta antes de plantar otra.',
        reason:
            'Hay demasiadas preguntas abiertas compitiendo por la atención.',
        strategy: NextBestMoveStrategy.information,
      );
    }

    return switch (act) {
      StoryAct.actI => const NextBestMoveRecommendation(
          move:
              'Afila la promesa inicial: presenta una fractura que obligue a seguir leyendo.',
          reason:
              'El Acto I debe introducir el libro y dejar clara su primera tensión.',
          strategy: NextBestMoveStrategy.pressure,
        ),
      StoryAct.actII => const NextBestMoveRecommendation(
          move:
              'Complica la línea principal con una elección que tenga coste narrativo.',
          reason:
              'El Acto II debe convertir lo abierto en presión y consecuencia.',
          strategy: NextBestMoveStrategy.decision,
        ),
      StoryAct.actIII => const NextBestMoveRecommendation(
          move:
              'Confronta la amenaza central y paga una pista o herida plantada antes.',
          reason: 'El Acto III debe llevar lo acumulado a confrontación.',
          strategy: NextBestMoveStrategy.consequence,
        ),
    };
  }

  NextBestMoveStrategy? _inferStrategy(String? move) {
    final lowered = move?.toLowerCase();
    if (lowered == null || lowered.isEmpty) return null;
    if (lowered.contains('pista') ||
        lowered.contains('pregunta') ||
        lowered.contains('información')) {
      return NextBestMoveStrategy.information;
    }
    if (lowered.contains('presión') ||
        lowered.contains('urgencia') ||
        lowered.contains('amenaza')) {
      return NextBestMoveStrategy.pressure;
    }
    if (lowered.contains('decisión') || lowered.contains('eleg')) {
      return NextBestMoveStrategy.decision;
    }
    if (lowered.contains('consecuencia') ||
        lowered.contains('perder') ||
        lowered.contains('coste')) {
      return NextBestMoveStrategy.consequence;
    }
    return null;
  }

  String? _specificOpenQuestion(NarrativeMemory memory) {
    if (memory.openQuestions.isEmpty) return null;
    final question = memory.openQuestions.first.trim();
    if (question.isEmpty) return null;
    if (question.length <= 90) return question;
    return '${question.substring(0, 87).trimRight()}...';
  }
}
