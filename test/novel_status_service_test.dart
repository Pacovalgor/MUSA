import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_copilot.dart';
import 'package:musa/modules/books/models/novel_status.dart';
import 'package:musa/modules/books/services/novel_status_service.dart';
import 'package:musa/modules/manuscript/models/document.dart';

void main() {
  final now = DateTime(2026, 5, 6, 12);

  group('NovelStatusService', () {
    test('flags low thriller tension against the professional baseline', () {
      final report = const NovelStatusService().build(
        book: _book(
          now,
          profile: const BookNarrativeProfile(
            primaryGenre: BookPrimaryGenre.thriller,
            readerPromise: 'Una investigación urgente con peligro creciente.',
            targetPace: TargetPace.urgent,
          ),
        ),
        documents: [
          _chapter(now, 0,
              'Diane miró la mesa. Pensó en la carta. Caminó despacio.'),
        ],
        memory: NarrativeMemory(
          bookId: 'book-1',
          readerPromises: const [
            'Una investigación urgente con peligro creciente.'
          ],
          updatedAt: now,
        ),
        storyState: StoryState(
          bookId: 'book-1',
          globalTension: 18,
          updatedAt: now,
        ),
        now: now,
      );

      expect(report.healthLevel, NovelStatusHealth.watch);
      expect(
          report.signals
              .any((signal) => signal.area == NovelStatusArea.tension),
          isTrue);
      expect(report.nextActions.first, contains('tensión'));
    });

    test('many unresolved promises lower the promise score', () {
      final report = const NovelStatusService().build(
        book: _book(now),
        documents: [
          _chapter(
              now, 0, '¿Quién llamó? ¿Dónde estaba Diane? ¿Por qué mintió?'),
        ],
        memory: NarrativeMemory(
          bookId: 'book-1',
          readerPromises: const ['Diane descubrirá la verdad.'],
          unresolvedPromises: const [
            '¿Quién llamó?',
            '¿Dónde estaba Diane?',
            '¿Por qué mintió?',
            '¿Qué oculta la casa?',
            '¿Quién abrió la puerta?',
          ],
          updatedAt: now,
        ),
        storyState: StoryState(bookId: 'book-1', updatedAt: now),
        now: now,
      );

      final promiseSignal = report.signals.firstWhere(
        (signal) => signal.area == NovelStatusArea.promise,
      );
      expect(report.promiseScore, lessThan(60));
      expect(promiseSignal.level, NovelStatusSignalLevel.warning);
      expect(promiseSignal.detail, contains('promesas abiertas'));
    });

    test('compares manuscript rhythm with the professional profile', () {
      final report = const NovelStatusService().build(
        book: _book(
          now,
          profile: const BookNarrativeProfile(
            primaryGenre: BookPrimaryGenre.thriller,
            readerPromise: 'Una persecución doméstica de alta presión.',
          ),
        ),
        documents: [
          _chapter(
            now,
            0,
            'Diane se detuvo en el umbral porque la noche, que parecía cerrarse '
            'sobre la casa con una paciencia insoportable, arrastraba cada ruido '
            'hacia el pasillo donde la carta seguía brillando bajo la lámpara.',
          ),
        ],
        memory: NarrativeMemory(
          bookId: 'book-1',
          readerPromises: const ['Una persecución doméstica de alta presión.'],
          updatedAt: now,
        ),
        storyState: StoryState(bookId: 'book-1', updatedAt: now),
        now: now,
      );

      final comparison = report.professionalComparisons.firstWhere(
        (item) => item.metric == 'Longitud media de frase',
      );
      expect(comparison.professionalValue, greaterThan(0));
      expect(comparison.differenceLabel, 'por encima');
    });

    test('uses neutral baseline safely for genres without professional profile',
        () {
      final report = const NovelStatusService().build(
        book: _book(
          now,
          profile: const BookNarrativeProfile(
            primaryGenre: BookPrimaryGenre.scienceFiction,
            readerPromise: 'Una idea que cambia las reglas del sistema.',
          ),
        ),
        documents: [
          _chapter(
              now, 0, 'La estación cambió de órbita y nadie pudo explicarlo.'),
        ],
        memory: NarrativeMemory(
          bookId: 'book-1',
          readerPromises: const ['Una idea que cambia las reglas del sistema.'],
          updatedAt: now,
        ),
        storyState: StoryState(bookId: 'book-1', updatedAt: now),
        now: now,
      );

      expect(report.professionalComparisons, isEmpty);
      expect(report.overallScore, inInclusiveRange(0, 100));
      expect(report.healthLevel, isNot(NovelStatusHealth.critical));
    });
  });
}

Book _book(
  DateTime now, {
  BookNarrativeProfile profile = const BookNarrativeProfile(
    primaryGenre: BookPrimaryGenre.literary,
    readerPromise:
        'Una transformación íntima sostenida por decisiones visibles.',
  ),
}) {
  return Book(
    id: 'book-1',
    title: 'Fixture',
    createdAt: now,
    updatedAt: now,
    narrativeProfile: profile,
  );
}

Document _chapter(DateTime now, int index, String content) {
  return Document(
    id: 'chapter-$index',
    bookId: 'book-1',
    title: 'Capítulo ${index + 1}',
    orderIndex: index,
    content: content,
    wordCount: content.split(RegExp(r'\s+')).length,
    createdAt: now,
    updatedAt: now,
  );
}
