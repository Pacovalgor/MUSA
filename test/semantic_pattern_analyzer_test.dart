import 'package:flutter_test/flutter_test.dart';
import 'package:musa/editor/services/semantic_pattern_analyzer.dart';
import 'package:musa/editor/services/narrative_consistency_analyzer.dart';

void main() {
  group('Semantic Pattern Analysis', () {
    const analyzer = SemanticPatternAnalyzer();

    test('Detects tension atmosphere in fast-paced action scene', () {
      const content = '''
        Corrió hacia la puerta. Su corazón acelerado. Miedo creciente.
        La alarma sonaba. Urgencia absoluta. Persecución rápida.
      ''';

      final atmosphere = analyzer.analyzeAtmosphere(content);

      expect(atmosphere.tension, greaterThan(0.3));
      expect(atmosphere.dominantMood, equals('tension'));
    });

    test('Detects mystery atmosphere in cryptic narrative', () {
      const content = '''
        Un secreto oculto en la esquina. Misterio sin resolver.
        La incógnita permanecía. Susurros desconocidos.
        Cada pista revelaba enigmas nuevos.
      ''';

      final atmosphere = analyzer.analyzeAtmosphere(content);

      expect(atmosphere.mystery, greaterThan(0.3));
      expect(atmosphere.dominantMood, equals('mystery'));
    });

    test('Detects warmth atmosphere in intimate scene', () {
      const content = '''
        Me abrazó con cariño. Una sonrisa cálida.
        Familia reunida en la paz del hogar.
        Tranquilidad y seguridad en su compañía.
      ''';

      final atmosphere = analyzer.analyzeAtmosphere(content);

      expect(atmosphere.warmth, greaterThan(0.3));
      expect(atmosphere.dominantMood, equals('warmth'));
    });

    test('Detects dread atmosphere in dark narrative', () {
      const content = '''
        La muerte acechaba. Sangre en la oscuridad.
        Dolor y agonía. El abismo se acercaba.
        Desolación absoluta. El fin inevitable.
      ''';

      final atmosphere = analyzer.analyzeAtmosphere(content);

      expect(atmosphere.dread, greaterThan(0.3));
      expect(atmosphere.dominantMood, equals('dread'));
    });

    test('Analyzes pacing: staccato pattern detected', () {
      const content = '''
        Entré. Salí. Corrí. Grité.
        Me detuve. Respiré. Volví. Avancé.
        Cada paso corto. Cada palabra cortante.
      ''';

      final pacing = analyzer.analyzePacing(content);

      expect(pacing.averageLength, lessThan(5));
      expect(pacing.shortPercentage, greaterThan(40));
      expect(pacing.pacePattern, equals('staccato'));
    });

    test('Analyzes pacing: flowing pattern detected', () {
      const content = '''
        Caminé lentamente por el parque mientras pensaba en lo que había sucedido.
        Las hojas caían con una elegancia que parecía bailar en el aire frío de octubre.
        Mi mente divagaba entre los recuerdos más lejanos y las preocupaciones actuales.
      ''';

      final pacing = analyzer.analyzePacing(content);

      expect(pacing.averageLength, greaterThan(10));
      expect(pacing.pacePattern, equals('flowing'));
    });

    test('Detects acceleration in pacing', () {
      const content = '''
        Ese fue un día memorable.
        Sucedieron varias cosas importantes.
        Luego cambió todo rápido.
        Corrí. Salté. Grité.
      ''';

      final pacing = analyzer.analyzePacing(content);

      expect(pacing.accelerating, isTrue);
    });

    test('Identifies thematic echoes: repetition of key words', () {
      const content = '''
        El reino estaba perdido. Un reino de magia antigua.
        Los magos del reino invocaban poder.
        La magia del reino había desaparecido hace años.
        El poder mágico jamás retornaría al reino.
      ''';

      final echoes = analyzer.analyzeThematicEchoes(content);

      expect(echoes.dominantThemes, contains('reino'));
      expect(echoes.dominantThemes, contains('magia'));
      expect(echoes.themeStrength, greaterThan(0.1));
    });

    test('Atmosphere intensity correlates with emotional weight', () {
      const calm = 'Todo estaba bien. La paz reinaba. Era un día normal.';
      const intense =
          'Muerte. Horror. Angustia. Desesperación. Terror absoluto.';

      final calmAtmosphere = analyzer.analyzeAtmosphere(calm);
      final intenseAtmosphere = analyzer.analyzeAtmosphere(intense);

      expect(intenseAtmosphere.intensity, greaterThan(calmAtmosphere.intensity));
    });
  });

  group('Narrative Consistency Analysis', () {
    const analyzer = NarrativeConsistencyAnalyzer();

    test('Detects POV shift from first to third person', () {
      const content = '''
        Yo entré a la habitación. Miré alrededor.
        Él cerró la puerta detrás de mí. Su mirada era fría.
      ''';

      final pov = analyzer.analyzePOV(content);

      expect(pov.inconsistencies, isNotEmpty);
      expect(pov.isConsistent, isFalse);
    });

    test('Maintains consistent POV throughout narrative', () {
      const content = '''
        Yo entré a la habitación. Miré alrededor.
        Me acerqué a la ventana. Vi el amanecer.
      ''';

      final pov = analyzer.analyzePOV(content);

      expect(pov.dominantPOV, equals('first'));
      expect(pov.inconsistencies, isEmpty);
      expect(pov.isConsistent, isTrue);
    });

    test('Detects tone shift from formal to casual', () {
      const content = '''
        De acuerdo con el análisis metodológico de la situación.
        Oye tío, la cosa está de lujo, ¿no te parece?
      ''';

      final tone = analyzer.analyzeTone(content);

      expect(tone.toneShifts, isNotEmpty);
      expect(tone.isConsistent, isFalse);
    });

    test('Maintains consistent tone throughout narrative', () {
      const content = '''
        Caminé hacia la puerta. Mi corazón latía rápido.
        Entré sin dudarlo. El miedo me envolvía.
      ''';

      final tone = analyzer.analyzeTone(content);

      expect(tone.isConsistent, isTrue);
    });

    test('Detects temporal jumps without transition', () {
      const content = '''
        Eran las 3 AM cuando llegué.
        El sol brillaba en el horizonte, era las 22:30 del mismo día.
      ''';

      final jumps = analyzer.analyzeNarrativeJumps(content);

      expect(jumps.hasTemporalGaps, isTrue);
      expect(jumps.jumps, isNotEmpty);
    });

    test('Detects spatial jumps without transition', () {
      const content = '''
        Me encontraba en el apartamento mirando por la ventana.
        La calle del callejón estaba vacía.
      ''';

      final jumps = analyzer.analyzeNarrativeJumps(content);

      expect(jumps.hasSpatialGaps, isTrue);
    });

    test('Analyzes dialogue integrity', () {
      const content = '''
        —¿Dónde estabas? —preguntó.
        —En el apartamento —respondí.
        —¿Realmente?
      ''';

      final dialogue = analyzer.analyzeDialogue(content);

      expect(dialogue.hasUnclosedDialogue, isTrue);
    });
  });
}
