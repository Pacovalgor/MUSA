import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/services/narrative_document_classifier.dart';

void main() {
  group('Audit: Narrative Gating V1.3 Structural Classification', () {
    const classifier = NarrativeDocumentClassifier();

    test('Narrative Sample (Fiction 3rd Person) is classified as SCENE', () async {
      final file = File('test/fixtures/narrative_sample.txt');
      final content = await file.readAsString();

      final result = classifier.classifyRaw(content, title: 'Final en el callejón');

      print('Audit [NARRATIVE]: Classification=${result.kind.name}, Reason=${result.reason}');

      expect(result.kind, equals(NarrativeDocumentKind.scene),
          reason: 'A complex 3rd person scene with action and place signals should be detected as SCENE');
    });

    test('Research Sample (OSINT/Technical) is NOT classified as SCENE', () async {
      final file = File('test/fixtures/research_sample.txt');
      final content = await file.readAsString();

      final result = classifier.classifyRaw(content, title: 'Informe OSINT 2024');

      print('Audit [SUPPORT]: Classification=${result.kind.name}, Reason=${result.reason}');

      expect(result.kind, isNot(equals(NarrativeDocumentKind.scene)),
          reason: 'A technical/research document should NEVER be detected as SCENE');
      expect(result.kind == NarrativeDocumentKind.research || result.kind == NarrativeDocumentKind.technical, true,
          reason: 'Should be classified as either research or technical');
    });

    test('Ambiguous short text is classified as UNKNOWN (Conservative approach)', () {
      const content = 'Esta es una nota corta sin señales claras de nada.';

      final result = classifier.classifyRaw(content, title: 'Nota rápida');

      print('Audit [UNKNOWN]: Classification=${result.kind.name}, Reason=${result.reason}');

      expect(result.kind, equals(NarrativeDocumentKind.unknown),
          reason: 'Ambiguous text should be UNKNOWN to avoid false narrative positives');
    });
  });
}
