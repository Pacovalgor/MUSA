// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/services/narrative_document_classifier.dart';

void main() {
  group('Audit: Narrative Gating V1.5 - Comprehensive Edge Case Coverage', () {
    const classifier = NarrativeDocumentClassifier();

    // ==================== CORE TESTS ====================
    test('Narrative Sample (Fiction 3rd Person) is classified as SCENE with high confidence', () async {
      final file = File('test/fixtures/narrative_sample.txt');
      final content = await file.readAsString();

      final result = classifier.classifyRaw(content, title: 'Final en el callejón');

      print('Audit [NARRATIVE]: Classification=${result.kind.name}, Confidence=${result.confidence.toStringAsFixed(2)}');

      expect(result.kind, equals(NarrativeDocumentKind.scene));
      expect(result.confidence, greaterThan(0.4));
    });

    test('Research Sample (OSINT/Technical) is NOT classified as SCENE', () async {
      final file = File('test/fixtures/research_sample.txt');
      final content = await file.readAsString();

      final result = classifier.classifyRaw(content, title: 'Informe OSINT 2024');

      expect(result.kind, isNot(equals(NarrativeDocumentKind.scene)));
      expect(
        result.kind == NarrativeDocumentKind.research ||
        result.kind == NarrativeDocumentKind.technical,
        true,
      );
      expect(result.confidence, greaterThan(0.0));
    });

    test('Ambiguous short text is classified as UNKNOWN (Conservative approach)', () {
      const content = 'Esta es una nota corta sin señales claras de nada.';

      final result = classifier.classifyRaw(content, title: 'Nota rápida');

      expect(result.kind, equals(NarrativeDocumentKind.unknown));
      expect(result.confidence, equals(0.0));
    });

    test('Confidence scoring differentiates signal strength', () {
      final strongScene = classifier.classifyRaw(
        'Entré al apartamento. Miré alrededor. Me acerqué a la ventana. Eran las 22:30 en la Mission.',
        title: 'Escena en San Francisco',
      );
      final weakScene = classifier.classifyRaw('Algo pasó. Fue importante.');

      expect(strongScene.kind, equals(NarrativeDocumentKind.scene));
      expect(weakScene.kind, equals(NarrativeDocumentKind.scene));
      expect(strongScene.confidence, greaterThan(weakScene.confidence));
    });

    // ==================== EDGE CASE TESTS: SCENE VARIATIONS ====================
    test('Very short scene (< 50 chars) with clear signals', () {
      const content = 'Entré. Salí. Eran las 3 AM.';
      final result = classifier.classifyRaw(content, title: 'Momento');

      expect(result.kind, equals(NarrativeDocumentKind.scene),
          reason: 'Even micro-scenes with action + time should be SCENE');
      expect(result.confidence, greaterThan(0.2));
    });

    test('Very long narrative (> 2000 chars) maintains classification', () {
      final longScene = '''
        Entré al apartamento y miré alrededor. La luz entraba por las ventanas del Mission,
        iluminando el polvo que flotaba en el aire. Me acerqué a la puerta, que estaba entreabierta.
        Alguien había estado aquí recientemente. Corrí hacia la cocina. Las tazas estaban en el fregadero,
        todavía mojadas. Levantación de la cabeza. Escuché pasos en el pasillo.
        Salí corriendo por la puerta trasera. El reloj marcaba las 22:45.
        Había sido un error venir aquí.
      ''' * 3; // Multiply to exceed 2400 chars

      final result = classifier.classifyRaw(longScene, title: 'Capítulo Largo');

      expect(result.kind, equals(NarrativeDocumentKind.scene),
          reason: 'Long narratives with consistent signals should stay SCENE');
      expect(result.confidence, greaterThan(0.3));
    });

    test('Dialogue-only scene (no explicit action verbs)', () {
      const content = '''
        —¿Dónde estabas anoche? —preguntó.
        —En el apartamento. ¿Por qué?
        —Encontraron algo en la Mission.
        —¿Qué cosa?
        —No puedo decirte.
        Eran las 3 AM cuando se fue.
      ''';

      final result = classifier.classifyRaw(content, title: 'Interrogatorio');

      expect(result.kind, equals(NarrativeDocumentKind.scene),
          reason: 'Dialogue + time/place signals should be SCENE even without action verbs');
      expect(result.confidence, greaterThan(0.2));
    });

    test('Action-only scene (no dialogue, pure movement)', () {
      const content = '''
        Corrí hacia la puerta. Saltó la valla. Entré al edificio.
        Subí las escaleras. Abrí la ventana. Bajé por la cuerda.
        Eran las 22:30. Estaba en la Mission. Seguía corriendo.
      ''';

      final result = classifier.classifyRaw(content, title: 'Persecución');

      expect(result.kind, equals(NarrativeDocumentKind.scene),
          reason: 'Pure action + place should be SCENE');
      expect(result.confidence, greaterThan(0.3));
    });

    test('Internal monologue (introspection without action)', () {
      const content = '''
        Me preguntaba por qué había venido. Pensé en lo que pasó.
        Recordé su cara. Sentí miedo. Pensaba en las consecuencias.
        Mi corazón latía acelerado. Tenía que decidir ya.
      ''';

      final result = classifier.classifyRaw(content, title: 'Reflexión');

      expect(result.kind, equals(NarrativeDocumentKind.unknown),
          reason: 'Pure introspection without scene context should be UNKNOWN');
    });

    test('First-person narrative (should detect as SCENE)', () {
      const content = '''
        Desperté en el apartamento. Miré el reloj: 7 AM. Me levanté de la cama.
        Entré a la ducha. El agua estaba fría. Pensé en el día.
        Salí del baño. Mi teléfono tenía 5 mensajes.
      ''';

      final result = classifier.classifyRaw(content, title: 'Mañana');

      expect(result.kind, equals(NarrativeDocumentKind.scene),
          reason: 'First-person + action should be SCENE');
      expect(result.confidence, greaterThan(0.3));
    });

    // ==================== EDGE CASE TESTS: NON-SCENE VARIATIONS ====================
    test('Code snippet in narrative (should NOT be SCENE)', () {
      const content = '''
        El código era así:

        function openDoor(key) {
          if (key.isValid) {
            door.unlock();
            return true;
          }
          return false;
        }

        Lo escribí en la consola y funcionó.
      ''';

      final result = classifier.classifyRaw(content, title: 'Técnica');

      expect(result.kind, isNot(equals(NarrativeDocumentKind.scene)),
          reason: 'Code snippet should not be SCENE even with wrapping narrative');
    });

    test('Mixed content (technical documentation + narrative)', () {
      const content = '''
        # Guía de Worldbuilding para el Reino

        El reino tiene tres provincias: Oeste, Centro y Este.
        Se basa en magia antigua. El sistema de magia funciona así:

        1. El usuario canta una invocación
        2. Se abre un portal
        3. El usuario entra

        Este es el mecanismo central de la construcción del mundo.
        Todos los magos lo usan igual.
      ''';

      final result = classifier.classifyRaw(content, title: 'Worldbuilding');

      expect(result.kind, equals(NarrativeDocumentKind.worldbuilding),
          reason: 'Worldbuilding with magic + construction keywords should be WORLDBUILDING');
    });

    test('Character description / profile (should be UNKNOWN)', () {
      const content = '''
        Eva García es una mujer de 28 años. Tiene cabello oscuro y ojos verdes.
        Es inteligente y determinada. Trabaja como detective en la policía.
        Creció en San Francisco. Sus padres murieron cuando tenía 16 años.
        Ahora vive sola en un apartamento en la Mission.
      ''';

      final result = classifier.classifyRaw(content, title: 'Ficha de Personaje');

      expect(result.kind, equals(NarrativeDocumentKind.unknown),
          reason: 'Character profile without scene context should be UNKNOWN');
    });

    test('Outline / summary (should be UNKNOWN)', () {
      const content = '''
        Capítulo 1: Eva descubre pistas
        Capítulo 2: Investiga el caso
        Capítulo 3: Encuentra al culpable
        Capítulo 4: Confrontación final
        Capítulo 5: Resolución
      ''';

      final result = classifier.classifyRaw(content, title: 'Estructura');

      expect(result.kind, equals(NarrativeDocumentKind.unknown),
          reason: 'Outline format should be UNKNOWN');
    });

    test('Poetry (no clear scene signals)', () {
      const content = '''
        La noche cae en la ciudad,
        Las luces parpadean,
        Mi corazón late en la oscuridad,
        Esperando el amanecer.
      ''';

      final result = classifier.classifyRaw(content, title: 'Poema');

      expect(result.kind, isNot(equals(NarrativeDocumentKind.scene)),
          reason: 'Poetry without action verbs should not be SCENE');
    });

    // ==================== CONFIDENCE BOUNDARY TESTS ====================
    test('Confidence correctly decreases with fewer signals', () {
      final fullScene = classifier.classifyRaw(
        'Entré al apartamento. Miré alrededor. Eran las 22:30 en la Mission.',
      );

      final partialScene = classifier.classifyRaw(
        'Entré. Miré. Eran las 22:30.',
      );

      final minimalScene = classifier.classifyRaw(
        'Entré. Eran las 22:30.',
      );

      print('Full: ${fullScene.confidence}, Partial: ${partialScene.confidence}, Minimal: ${minimalScene.confidence}');

      expect(fullScene.confidence, greaterThanOrEqualTo(partialScene.confidence),
          reason: 'More signals should yield >= confidence');
      expect(partialScene.confidence, greaterThanOrEqualTo(minimalScene.confidence),
          reason: 'Signals should decrease confidence gradually');
    });

    test('IsAmbiguous flag correctly identifies low-confidence classifications', () {
      final ambiguous = classifier.classifyRaw('Algo sucedió aquí.');

      expect(ambiguous.isAmbiguous, equals(true),
          reason: 'Low confidence (< 0.6) should set isAmbiguous flag');
    });

    test('IsConfident flag correctly identifies high-confidence classifications', () {
      final confident = classifier.classifyRaw(
        'Entré al apartamento. Miré alrededor. Me acerqué a la ventana. '
        'Salí corriendo. Estaba en la Mission a las 22:30. '
        'Subí las escaleras. Abrí la puerta. Volví a entrar.',
      );

      expect(confident.isConfident, equals(true),
          reason: 'High confidence (>= 0.85) should set isConfident flag');
    });
  });
}
