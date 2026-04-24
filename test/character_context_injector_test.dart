import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/characters/models/character.dart';
import 'package:musa/editor/services/character_context_injector.dart';
import 'package:musa/editor/services/semantic_pattern_analyzer.dart';

void main() {
  group('Character Context Injection', () {
    final injector = CharacterContextInjector();
    const analyzer = SemanticPatternAnalyzer();

    test('Builds verbose character voice profile', () {
      final chattyCharacter = Character(
        id: '1',
        bookId: 'book1',
        name: 'Eva',
        voice: 'Eva es muy habladora y expresiva. Locuaz y comunicativa.',
        motivation: '',
        internalConflict: '',
        whatTheyHide: '',
        currentState: '',
        isProtagonist: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final profile = injector.buildVoiceProfile(chattyCharacter);

      expect(profile.voicePatterns.isVerbose, isTrue);
      expect(profile.expectedDialogueFrequency, greaterThan(0.7));
    });

    test('Builds taciturn character voice profile', () {
      final quietCharacter = Character(
        id: '2',
        bookId: 'book1',
        name: 'Marcus',
        voice: 'Marcus es callado, reservado y parco en palabras.',
        motivation: '',
        internalConflict: '',
        whatTheyHide: '',
        currentState: '',
        isProtagonist: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final profile = injector.buildVoiceProfile(quietCharacter);

      expect(profile.voicePatterns.isTaciturn, isTrue);
      expect(profile.expectedDialogueFrequency, lessThan(0.3));
    });

    test('Builds formal character voice profile', () {
      final formalCharacter = Character(
        id: '3',
        bookId: 'book1',
        name: 'Dr. Silva',
        voice:
            'Formal, educado y académico. Profesional y erudito en su expresión.',
        motivation: '',
        internalConflict: '',
        whatTheyHide: '',
        currentState: '',
        isProtagonist: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final profile = injector.buildVoiceProfile(formalCharacter);

      expect(profile.voicePatterns.isFormal, isTrue);
    });

    test('Builds action-motivated character profile', () {
      final actionCharacter = Character(
        id: '4',
        bookId: 'book1',
        name: 'Connor',
        voice: '',
        motivation: 'Quiere actuar y luchar. Necesita ganar y dominar.',
        internalConflict: '',
        whatTheyHide: '',
        currentState: '',
        isProtagonist: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final profile = injector.buildVoiceProfile(actionCharacter);

      expect(
        profile.motivationPattern.actionOriented,
        greaterThan(profile.motivationPattern.intellectualOriented),
      );
      expect(profile.expectedActionDensity, greaterThan(0.5));
    });

    test('Builds conflicted character profile', () {
      final conflictedCharacter = Character(
        id: '5',
        bookId: 'book1',
        name: 'Ana',
        voice: '',
        motivation: '',
        internalConflict:
            'Ana está dividida entre su deber y su deseo. Lucha interna constante.',
        whatTheyHide: '',
        currentState: '',
        isProtagonist: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final profile = injector.buildVoiceProfile(conflictedCharacter);

      expect(profile.conflictIntensity, greaterThan(0.4));
    });

    test('Builds secret-burdened character profile', () {
      final secretiveCharacter = Character(
        id: '6',
        bookId: 'book1',
        name: 'Javier',
        voice: '',
        motivation: '',
        internalConflict: '',
        whatTheyHide: 'Javier está ocultando un secreto. Escondiendo su pasado.',
        currentState: '',
        isProtagonist: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final profile = injector.buildVoiceProfile(secretiveCharacter);

      expect(profile.secretBurden, greaterThan(0.4));
    });

    test(
      'Applies context: verbose character allows more dialogue without clarity penalty',
      () {
        final verboseCharacter = Character(
          id: '1',
          bookId: 'book1',
          name: 'Eva',
          voice: 'Muy habladora y expresiva.',
          motivation: '',
          internalConflict: '',
          whatTheyHide: '',
          currentState: '',
          isProtagonist: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final profile = injector.buildVoiceProfile(verboseCharacter);
        final atmosphere = analyzer.analyzeAtmosphere(
          '—¿Dónde estabas? —preguntó Eva. —Estaba ocupada, muy ocupada.',
        );
        final multipliers = injector.applyCharacterContext(profile, atmosphere);

        expect(multipliers.clarity, lessThan(1.0));
      },
    );

    test(
      'Applies context: conflicted character expects tension',
      () {
        final conflictedCharacter = Character(
          id: '5',
          bookId: 'book1',
          name: 'Ana',
          voice: '',
          motivation: '',
          internalConflict: 'Conflicto interno y lucha constante.',
          whatTheyHide: '',
          currentState: '',
          isProtagonist: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final profile = injector.buildVoiceProfile(conflictedCharacter);
        final calmAtmosphere = analyzer.analyzeAtmosphere('Todo estaba bien.');

        final multipliers =
            injector.applyCharacterContext(profile, calmAtmosphere);

        expect(
          multipliers.tension,
          greaterThanOrEqualTo(1.3),
        );
      },
    );

    test('Generates character-aware feedback for verbose character', () {
      final verboseCharacter = Character(
        id: '1',
        bookId: 'book1',
        name: 'Eva',
        voice: 'Muy habladora.',
        motivation: '',
        internalConflict: '',
        whatTheyHide: '',
        currentState: '',
        isProtagonist: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final profile = injector.buildVoiceProfile(verboseCharacter);
      final atmosphere = analyzer.analyzeAtmosphere('—¿Hola? —preguntó.');
      final feedback = injector.generateCharacterAwareFeedback(
        profile,
        atmosphere,
        '—¿Dónde estabas? —preguntó Eva.',
      );

      expect(feedback, isNotEmpty);
      expect(
        feedback.any((f) => f.contains('hablo')),
        isTrue,
      );
    });

    test('Generates character-aware feedback for secretive character', () {
      final secretiveCharacter = Character(
        id: '6',
        bookId: 'book1',
        name: 'Javier',
        voice: '',
        motivation: '',
        internalConflict: '',
        whatTheyHide: 'Ocultando un secreto importante.',
        currentState: '',
        isProtagonist: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final profile = injector.buildVoiceProfile(secretiveCharacter);
      final atmosphere = analyzer.analyzeAtmosphere('Javier caminó lentamente.');
      final feedback = injector.generateCharacterAwareFeedback(
        profile,
        atmosphere,
        'Javier pensó en lo que estaba ocultando.',
      );

      expect(feedback, isNotEmpty);
      expect(
        feedback.any((f) => f.contains('ocultando')),
        isTrue,
      );
    });

    test('Signal multipliers are within reasonable range', () {
      final character = Character(
        id: '1',
        bookId: 'book1',
        name: 'Test',
        voice: 'Hablador y formal.',
        motivation: 'Luchar y vencer.',
        internalConflict: 'Conflicto interno.',
        whatTheyHide: 'Secretos.',
        currentState: '',
        isProtagonist: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final profile = injector.buildVoiceProfile(character);
      final atmosphere = analyzer.analyzeAtmosphere('Mucho texto.');
      final multipliers = injector.applyCharacterContext(profile, atmosphere);

      expect(multipliers.clarity, greaterThanOrEqualTo(0.6));
      expect(multipliers.clarity, lessThanOrEqualTo(1.5));
      expect(multipliers.rhythm, greaterThanOrEqualTo(0.6));
      expect(multipliers.rhythm, lessThanOrEqualTo(1.5));
      expect(multipliers.style, greaterThanOrEqualTo(0.6));
      expect(multipliers.style, lessThanOrEqualTo(1.5));
      expect(multipliers.tension, greaterThanOrEqualTo(0.6));
      expect(multipliers.tension, lessThanOrEqualTo(1.5));
    });
  });
}
