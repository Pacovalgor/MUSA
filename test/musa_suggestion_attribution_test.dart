import 'package:flutter_test/flutter_test.dart';
import 'package:musa/domain/musa/musa_objects.dart';

void main() {
  test('MusaSuggestion carries source musa id for learning attribution', () {
    final suggestion = MusaSuggestion(
      id: 'suggestion-1',
      originalText: 'La puerta estaba abierta.',
      suggestedText: 'La puerta seguia abierta.',
      sourceMusaId: 'tension',
    );

    expect(suggestion.sourceMusaId, 'tension');
  });
}
