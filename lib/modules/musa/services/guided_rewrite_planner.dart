import '../../books/models/book.dart';
import '../../books/models/narrative_copilot.dart';
import '../../books/models/novel_status.dart';
import '../../continuity/models/continuity_audit.dart';
import '../models/guided_rewrite.dart';

class GuidedRewritePlanner {
  const GuidedRewritePlanner();

  GuidedRewriteRecommendation? recommend({
    required String selection,
    required Book? book,
    required NovelStatusReport? novelStatus,
    required List<ContinuityFinding> continuityFindings,
    required NarrativeMemory? memory,
    required StoryState? storyState,
  }) {
    final trimmed = selection.trim();
    if (trimmed.length < 24) return null;

    final candidates = <GuidedRewriteRecommendation>[
      if (_looksExpository(trimmed)) _reduceExposition(trimmed),
      if (_dialogueNeedsPhysicalBeat(trimmed)) _naturalizeDialogue(trimmed),
      if (_hasPromisePressure(continuityFindings, memory))
        _clarifyPromise(continuityFindings, memory),
      if (_needsMoreTension(book, novelStatus, storyState))
        _raiseTension(book, novelStatus, storyState),
    ];

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.priority.compareTo(a.priority));
    return candidates.first;
  }

  bool _needsMoreTension(
    Book? book,
    NovelStatusReport? novelStatus,
    StoryState? storyState,
  ) {
    final tensionScore = novelStatus?.tensionScore ?? storyState?.globalTension;
    if (tensionScore == null) return false;
    if (book?.narrativeProfile.primaryGenre == BookPrimaryGenre.thriller) {
      return tensionScore < 42;
    }
    return tensionScore < 30;
  }

  bool _looksExpository(String text) {
    final lower = text.toLowerCase();
    final markers = <String>[
      'sabía que',
      'desde hacía',
      'había aprendido',
      'era importante porque',
      'recordaba que',
      'comprendía que',
    ];
    return markers.any(lower.contains);
  }

  bool _dialogueNeedsPhysicalBeat(String text) {
    final dialogueMarks = RegExp(r'—').allMatches(text).length;
    if (dialogueMarks < 2) return false;
    final lower = text.toLowerCase();
    final physicalMarkers = <String>[
      'miró',
      'respiró',
      'silencio',
      'mano',
      'ojos',
      'gesto',
      'sonrió',
      'se levantó',
    ];
    return !physicalMarkers.any(lower.contains);
  }

  bool _hasPromisePressure(
    List<ContinuityFinding> findings,
    NarrativeMemory? memory,
  ) {
    if ((memory?.unresolvedPromises.length ?? 0) >= 2) return true;
    return findings.any(
      (finding) =>
          finding.type == ContinuityFindingType.unresolvedPromise &&
          finding.severity != ContinuityFindingSeverity.info,
    );
  }

  GuidedRewriteRecommendation _raiseTension(
    Book? book,
    NovelStatusReport? novelStatus,
    StoryState? storyState,
  ) {
    final score = novelStatus?.tensionScore ?? storyState?.globalTension ?? 0;
    final genre =
        book?.narrativeProfile.primaryGenre == BookPrimaryGenre.thriller
            ? 'thriller'
            : 'la promesa del libro';
    return GuidedRewriteRecommendation(
      action: GuidedRewriteAction.raiseTension,
      title: 'Subir tensión',
      reason:
          'El fragmento puede empujar más: $genre está leyendo la tensión actual como baja.',
      evidence: '$score/100',
      priority: book?.narrativeProfile.primaryGenre == BookPrimaryGenre.thriller
          ? 70
          : 45,
    );
  }

  GuidedRewriteRecommendation _reduceExposition(String text) {
    return const GuidedRewriteRecommendation(
      action: GuidedRewriteAction.reduceExposition,
      title: 'Reducir exposición',
      reason:
          'La selección contiene explicación acumulada; conviene dejar que mande la acción concreta.',
      evidence: 'marcadores de explicación',
      priority: 90,
    );
  }

  GuidedRewriteRecommendation _naturalizeDialogue(String text) {
    return const GuidedRewriteRecommendation(
      action: GuidedRewriteAction.naturalizeDialogue,
      title: 'Diálogo natural',
      reason:
          'El diálogo avanza sin suficiente respiración física entre las réplicas.',
      evidence: 'réplicas seguidas',
      priority: 82,
    );
  }

  GuidedRewriteRecommendation _clarifyPromise(
    List<ContinuityFinding> findings,
    NarrativeMemory? memory,
  ) {
    final finding = findings.cast<ContinuityFinding?>().firstWhere(
          (item) => item?.type == ContinuityFindingType.unresolvedPromise,
          orElse: () => null,
        );
    final evidence = finding?.evidence.isNotEmpty == true
        ? finding!.evidence
        : (memory?.unresolvedPromises.take(3).join(' · ') ?? '');
    return GuidedRewriteRecommendation(
      action: GuidedRewriteAction.clarify,
      title: 'Aclarar promesa',
      reason:
          'Hay promesas abiertas cerca del estado de continuidad; el fragmento debería orientar mejor qué debe recordar el lector.',
      evidence: evidence,
      priority: 78,
    );
  }
}
