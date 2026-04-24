import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/services/narrative_document_classifier.dart';

void main() {
  group('Audit: Narrative Gating V1.3 Structural Classification', () {
    const classifier = NarrativeDocumentClassifier();

    test('Narrative Sample (Fiction 3rd Person) is classified as SCENE with high confidence', () async {
      final file = File('test/fixtures/narrative_sample.txt');
      final content = await file.readAsString();

      final result = classifier.classifyRaw(content, title: 'Final en el callejón');

      print('Audit [NARRATIVE]: Classification=${result.kind.name}, Confidence=${result.confidence.toStringAsFixed(2)}, Reason=${result.reason}');

      expect(result.kind, equals(NarrativeDocumentKind.scene),
          reason: 'A complex 3rd person scene with action and place signals should be detected as SCENE');
      expect(result.confidence, greaterThan(0.4),
          reason: 'Narrative with multiple scene signals should have confidence > 0.4');
    });

    test('Research Sample (OSINT/Technical) is NOT classified as SCENE', () async {
      final file = File('test/fixtures/research_sample.txt');
      final content = await file.readAsString();

      final result = classifier.classifyRaw(content, title: 'Informe OSINT 2024');

      print('Audit [SUPPORT]: Classification=${result.kind.name}, Confidence=${result.confidence.toStringAsFixed(2)}, Reason=${result.reason}');

      expect(result.kind, isNot(equals(NarrativeDocumentKind.scene)),
          reason: 'A technical/research document should NEVER be detected as SCENE');
      expect(result.kind == NarrativeDocumentKind.research || result.kind == NarrativeDocumentKind.technical, true,
          reason: 'Should be classified as either research or technical');
      expect(result.confidence, greaterThan(0.0),
          reason: 'Research/technical classification should have meaningful confidence');
    });

    test('Ambiguous short text is classified as UNKNOWN (Conservative approach)', () {
      const content = 'Esta es una nota corta sin señales claras de nada.';

      final result = classifier.classifyRaw(content, title: 'Nota rápida');

      print('Audit [UNKNOWN]: Classification=${result.kind.name}, Confidence=${result.confidence.toStringAsFixed(2)}, Reason=${result.reason}');

      expect(result.kind, equals(NarrativeDocumentKind.unknown),
          reason: 'Ambiguous text should be UNKNOWN to avoid false narrative positives');
      expect(result.confidence, equals(0.0),
          reason: 'Unknown classification should have 0.0 confidence (no signals detected)');
    });

    test('Confidence scoring differentiates signal strength', () {
      final strongScene = classifier.classifyRaw(
        'Entré al apartamento. Miré alrededor. Me acerqué a la ventana. Eran las 22:30 en la Mission.',
        title: 'Escena en San Francisco',
      );
      final weakScene = classifier.classifyRaw(
        'Algo pasó. Fue importante.',
      );

      print('Audit [CONFIDENCE]: Strong=${strongScene.confidence.toStringAsFixed(2)}, Weak=${weakScene.confidence.toStringAsFixed(2)}');

      expect(strongScene.kind, equals(NarrativeDocumentKind.scene), reason: 'Strong signals → SCENE');
      expect(weakScene.kind, equals(NarrativeDocumentKind.scene), reason: 'Even weak signals → SCENE');
      expect(strongScene.confidence, greaterThan(weakScene.confidence),
          reason: 'Strong signals should have higher confidence than weak ones');
    });
  });
}
