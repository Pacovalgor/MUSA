import 'package:flutter_test/flutter_test.dart';
import 'package:musa/editor/models/suggestion_history.dart';

void main() {
  group('Suggestion History Manager', () {
    test('Agregar sugerencia al historial', () async {
      final manager = SuggestionHistoryManager();
      await manager.initialize();

      final suggestion = HistoricalSuggestion(
        id: 'test-1',
        originalText: 'Texto original',
        suggestedText: 'Texto sugerido',
        musaId: 'clarity',
        musaName: 'Claridad',
        timestamp: DateTime.now(),
      );

      await manager.addSuggestion(suggestion);

      expect(manager.totalInHistory, equals(1));
      expect(manager.getPrevious()?.id, equals('test-1'));
    });

    test('Mantener máximo 5 sugerencias en historial', () async {
      final manager = SuggestionHistoryManager();
      await manager.initialize();

      // Agregar 7 sugerencias
      for (int i = 0; i < 7; i++) {
        final suggestion = HistoricalSuggestion(
          id: 'test-$i',
          originalText: 'Original $i',
          suggestedText: 'Sugerido $i',
          musaId: 'rhythm',
          musaName: 'Ritmo',
          timestamp: DateTime.now(),
        );
        await manager.addSuggestion(suggestion);
      }

      expect(manager.totalInHistory, equals(5));
      expect(manager.getAll().first.id, equals('test-6'));
      expect(manager.getAll().last.id, equals('test-2'));
    });

    test('Obtener sugerencia anterior (LIFO)', () async {
      final manager = SuggestionHistoryManager();
      await manager.initialize();

      final sug1 = HistoricalSuggestion(
        id: 'test-1',
        originalText: 'Original 1',
        suggestedText: 'Sugerido 1',
        musaId: 'style',
        musaName: 'Estilo',
        timestamp: DateTime.now(),
      );

      final sug2 = HistoricalSuggestion(
        id: 'test-2',
        originalText: 'Original 2',
        suggestedText: 'Sugerido 2',
        musaId: 'tension',
        musaName: 'Tensión',
        timestamp: DateTime.now(),
      );

      await manager.addSuggestion(sug1);
      await manager.addSuggestion(sug2);

      // El anterior debe ser sug2 (último agregado)
      expect(manager.getPrevious()?.id, equals('test-2'));
    });

    test('Saltar a índice específico en historial', () async {
      final manager = SuggestionHistoryManager();
      await manager.initialize();

      for (int i = 0; i < 3; i++) {
        final suggestion = HistoricalSuggestion(
          id: 'test-$i',
          originalText: 'Original $i',
          suggestedText: 'Sugerido $i',
          musaId: 'clarity',
          musaName: 'Claridad',
          timestamp: DateTime.now(),
        );
        await manager.addSuggestion(suggestion);
      }

      final jumped = manager.jumpToIndex(1);
      expect(jumped?.id, equals('test-1'));
    });

    test('Limpiar historial', () async {
      final manager = SuggestionHistoryManager();
      await manager.initialize();

      final suggestion = HistoricalSuggestion(
        id: 'test-1',
        originalText: 'Original',
        suggestedText: 'Sugerido',
        musaId: 'rhythm',
        musaName: 'Ritmo',
        timestamp: DateTime.now(),
      );

      await manager.addSuggestion(suggestion);
      expect(manager.totalInHistory, equals(1));

      await manager.clear();
      expect(manager.totalInHistory, equals(0));
      expect(manager.getAll(), isEmpty);
    });

    test('Serialización y deserialización de sugerencia', () {
      final now = DateTime.now();
      final suggestion = HistoricalSuggestion(
        id: 'test-1',
        originalText: 'Original',
        suggestedText: 'Sugerido',
        musaId: 'style',
        musaName: 'Estilo',
        timestamp: now,
        wasAccepted: true,
      );

      final json = suggestion.toJson();
      final restored = HistoricalSuggestion.fromJson(json);

      expect(restored.id, equals(suggestion.id));
      expect(restored.originalText, equals(suggestion.originalText));
      expect(restored.suggestedText, equals(suggestion.suggestedText));
      expect(restored.wasAccepted, equals(true));
    });

    test('Encontrar índice de sugerencia en historial', () async {
      final manager = SuggestionHistoryManager();
      await manager.initialize();

      final sug1 = HistoricalSuggestion(
        id: 'test-1',
        originalText: 'Original 1',
        suggestedText: 'Sugerido 1',
        musaId: 'clarity',
        musaName: 'Claridad',
        timestamp: DateTime.now(),
      );

      final sug2 = HistoricalSuggestion(
        id: 'test-2',
        originalText: 'Original 2',
        suggestedText: 'Sugerido 2',
        musaId: 'rhythm',
        musaName: 'Ritmo',
        timestamp: DateTime.now(),
      );

      await manager.addSuggestion(sug1);
      await manager.addSuggestion(sug2);

      expect(manager.indexOf(sug2), equals(0));
      expect(manager.indexOf(sug1), equals(1));
    });
  });
}
