import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_copilot.dart';
import 'package:musa/modules/books/services/next_best_move_service.dart';
import 'package:musa/modules/books/services/narrative_document_classifier.dart';

void main() {
  group('NextBestMoveService: Local Context Refinement', () {
    const service = NextBestMoveService();
    final now = DateTime.now();
    const profile = BookNarrativeProfile(readerPromise: 'Una promesa real');

    Book createBook() => Book(
          id: 'test-book',
          title: 'Test Book',
          createdAt: now,
          updatedAt: now,
          narrativeProfile: profile,
        );

    test('Refines recommendation when too many questions are detected', () {
      final book = createBook();
      const text = '¿Quién era? ¿Qué quería de mí? ¿Por qué ahora?';
      
      final result = service.recommendDetailed(
        book: book,
        act: StoryAct.actI,
        globalTension: 50,
        realProgress: true,
        hasInvestigationLoop: false,
        memory: NarrativeMemory.empty(book.id, now),
        diagnostics: [],
        currentText: text,
        documentKind: NarrativeDocumentKind.scene,
      );

      expect(result.reason, contains('acumula interrogantes'));
      expect(result.suggestedAction, contains('En lugar de otra pregunta'));
    });

    test('Refines recommendation when exposition lacks action and dialogue', () {
      final book = createBook();
      // "consequence" strategy is usually triggered when realProgress is false and genre is not specific
      const text = 'La habitación estaba fría. El sol entraba por la ventana. Las paredes eran blancas.';
      
      final result = service.recommendDetailed(
        book: book,
        act: StoryAct.actI,
        globalTension: 50,
        realProgress: false, 
        hasInvestigationLoop: false,
        memory: NarrativeMemory.empty(book.id, now),
        diagnostics: [],
        currentText: text,
        documentKind: NarrativeDocumentKind.scene,
      );

      // In this case, Strategy should be consequence (default fallback for !realProgress)
      expect(result.reason, contains('puramente expositivo'));
      expect(result.suggestedAction, contains('movimiento físico'));
    });

    test('Refines recommendation when dialogue is static without action', () {
      final book = createBook();
      // Thriller genre + low tension triggers "pressure" strategy
      final thrillerBook = book.copyWith(
        narrativeProfile: profile.copyWith(primaryGenre: BookPrimaryGenre.thriller),
      );
      const text = '—No lo sé —dijo él.\n—Deberías saberlo —respondió ella.';
      
      final result = service.recommendDetailed(
        book: thrillerBook,
        act: StoryAct.actI,
        globalTension: 20, // Low tension for thriller -> pressure strategy
        realProgress: true,
        hasInvestigationLoop: false,
        memory: NarrativeMemory.empty(book.id, now),
        diagnostics: [],
        currentText: text,
        documentKind: NarrativeDocumentKind.scene,
      );

      expect(result.reason, contains('estancado en lo verbal'));
      expect(result.suggestedAction, contains('rompiendo el diálogo'));
    });
  });
}
