import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/narrative_copilot.dart';
import 'package:musa/modules/books/services/narrative_memory_updater.dart';
import 'package:musa/modules/manuscript/models/document.dart';

void main() {
  final now = DateTime(2026, 5, 6, 12);

  group('NarrativeMemory V1.8', () {
    test('fromJson accepts legacy projects without V1.8 fields', () {
      final memory = NarrativeMemory.fromJson({
        'bookId': 'book-1',
        'openQuestions': ['¿Quién dejó la llave?'],
        'plantedClues': ['La llave seguía bajo la alfombra.'],
        'activeThreats': ['Alguien vigilaba la casa.'],
        'importantFacts': ['La puerta estaba abierta.'],
        'recentCharacterShifts': ['Diane decidió mentir.'],
        'updatedAt': now.toIso8601String(),
      });

      expect(memory.readerPromises, isEmpty);
      expect(memory.unresolvedPromises, isEmpty);
      expect(memory.toneSignals, isEmpty);
      expect(memory.scenePatternWarnings, isEmpty);
    });

    test('extracts promises, tone and repeated scene pattern warnings', () {
      final memory = const NarrativeMemoryUpdater().update(
        bookId: 'book-1',
        documents: [
          _chapter(
            now,
            0,
            'Promesa: Diane descubrirá quién dejó la llave antes del amanecer. '
            'El pasillo estaba oscuro y la amenaza respiraba detrás de la puerta. '
            'Diane investiga la pista en silencio. ¿Quién dejó la llave?',
          ),
          _chapter(
            now,
            1,
            'El ambiente seguía sombrío, con miedo y sombras en cada ventana. '
            'Diane investiga otra pista, busca una señal y vuelve a investigar sin consecuencia. '
            'La pregunta seguía abierta: ¿quién dejó la llave?',
          ),
        ],
        previous: null,
        now: now,
      );

      expect(memory.readerPromises, isNotEmpty);
      expect(memory.readerPromises.first, contains('Diane descubrirá'));
      expect(memory.unresolvedPromises, isNotEmpty);
      expect(memory.toneSignals, contains('sombrío'));
      expect(memory.scenePatternWarnings, isNotEmpty);
      expect(
        memory.scenePatternWarnings.first,
        contains('investigación sin consecuencia'),
      );
    });

    test('does not let research or worldbuilding contaminate story promises',
        () {
      final memory = const NarrativeMemoryUpdater().update(
        bookId: 'book-1',
        documents: [
          _support(
            now,
            0,
            'Documento de investigación',
            'Este documento analiza una promesa falsa para el lector. '
                'Hallazgo: la investigación indica que ese recurso funciona como apoyo.',
          ),
          _support(
            now,
            1,
            'Reglas del mundo',
            'Reglas del mundo: el reino usa magia antigua para diseñar rituales.',
          ),
          _chapter(
            now,
            2,
            'Diane entró en el callejón. La lluvia golpeó el suelo. '
            'Alguien corrió detrás de ella y la puerta se cerró.',
          ),
        ],
        previous: null,
        now: now,
      );

      expect(memory.readerPromises, isEmpty);
      expect(memory.unresolvedPromises, isEmpty);
      expect(memory.worldRules, isNotEmpty);
      expect(memory.researchFindings, isNotEmpty);
    });
  });
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

Document _support(DateTime now, int index, String title, String content) {
  return Document(
    id: 'support-$index',
    bookId: 'book-1',
    title: title,
    kind: DocumentKind.noteDoc,
    orderIndex: index,
    content: content,
    wordCount: content.split(RegExp(r'\s+')).length,
    createdAt: now,
    updatedAt: now,
  );
}
