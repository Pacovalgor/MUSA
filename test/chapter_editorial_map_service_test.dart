import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_copilot.dart';
import 'package:musa/modules/editorial/models/chapter_editorial_map.dart';
import 'package:musa/modules/editorial/services/chapter_editorial_map_service.dart';
import 'package:musa/modules/manuscript/models/document.dart';

void main() {
  group('ChapterEditorialMapService', () {
    test('orders narrative chapters and labels structural thirds', () {
      final report = const ChapterEditorialMapService().build(
        book: _book(),
        documents: [
          _doc('c3', 'Capítulo 3', 30,
              'Clara entró en el pasillo. La puerta seguía cerrada.'),
          _doc('c1', 'Capítulo 1', 10,
              'Clara entró en la casa y prometió abrir la puerta.'),
          _doc('c2', 'Research', 20,
              'Notas de investigación y fuentes técnicas sobre cerraduras.',
              kind: DocumentKind.noteDoc),
        ],
        memory: NarrativeMemory.empty('book', _now),
        storyState: null,
        now: _now,
      );

      expect(report.chapters.map((chapter) => chapter.documentId), [
        'c1',
        'c3',
      ]);
      expect(report.chapters.first.stage, ChapterEditorialStage.opening);
      expect(report.chapters.last.stage, ChapterEditorialStage.closing);
    });

    test(
        'asks for consequence when a chapter repeats investigation without cost',
        () {
      final report = const ChapterEditorialMapService().build(
        book: _book(),
        documents: [
          _doc('c1', 'Capítulo 1', 1, 'Clara investigó el archivo.'),
          _doc('c2', 'Capítulo 2', 2,
              'Clara investigó la puerta. Observó la cerradura.'),
        ],
        memory: NarrativeMemory(
          bookId: 'book',
          scenePatternWarnings: const [
            'Investigación sin consecuencia visible',
          ],
          updatedAt: _now,
        ),
        storyState: null,
        now: _now,
      );

      expect(
          report.chapters.last.primaryNeed, ChapterEditorialNeed.consequence);
      expect(report.chapters.last.nextAction, contains('consecuencia'));
      expect(report.summaryActions.first, contains('consecuencia'));
    });

    test('prioritizes promise payment near the closing third', () {
      final report = const ChapterEditorialMapService().build(
        book: _book(),
        documents: [
          _doc('c1', 'Capítulo 1', 1,
              'Clara entró en la casa y prometió encontrar la llave.'),
          _doc('c2', 'Capítulo 2', 2,
              'La sombra volvió a llamarla cuando Clara caminó al pasillo.'),
          _doc('c3', 'Capítulo 3', 3,
              'Clara miró la puerta cerrada y caminó sin encontrar salida.'),
        ],
        memory: NarrativeMemory(
          bookId: 'book',
          readerPromises: const ['encontrar la llave'],
          unresolvedPromises: const ['encontrar la llave'],
          updatedAt: _now,
        ),
        storyState: null,
        now: _now,
      );

      expect(report.chapters.last.primaryNeed, ChapterEditorialNeed.promise);
      expect(report.chapters.last.nextAction, contains('promesa'));
    });

    test('compares rhythm against professional profile in readable terms', () {
      final report = const ChapterEditorialMapService().build(
        book: _book(genre: BookPrimaryGenre.thriller),
        documents: [
          _doc(
            'c1',
            'Capítulo 1',
            1,
            'Clara entró en la casa porque la llamada había llegado tarde y la ciudad respiraba una humedad espesa que parecía pegar cada pensamiento contra las paredes del pasillo antes de que pudiera decidir qué hacer.',
          ),
        ],
        memory: NarrativeMemory.empty('book', _now),
        storyState: null,
        now: _now,
      );

      expect(report.chapters.single.professionalRhythmLabel, isNotEmpty);
      expect(
          report.chapters.single.professionalRhythmLabel, isNot('sin perfil'));
    });
  });
}

final _now = DateTime(2026, 5, 6);

Book _book({BookPrimaryGenre genre = BookPrimaryGenre.literary}) {
  return Book(
    id: 'book',
    title: 'Libro',
    createdAt: _now,
    updatedAt: _now,
    narrativeProfile: BookNarrativeProfile(
      primaryGenre: genre,
      readerPromise: 'Una investigación con coste.',
    ),
  );
}

Document _doc(
  String id,
  String title,
  int orderIndex,
  String content, {
  DocumentKind kind = DocumentKind.chapter,
}) {
  return Document(
    id: id,
    bookId: 'book',
    title: title,
    kind: kind,
    orderIndex: orderIndex,
    content: content,
    createdAt: _now,
    updatedAt: _now,
  );
}
