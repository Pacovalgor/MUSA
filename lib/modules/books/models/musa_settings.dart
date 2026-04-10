import '../../../muses/musa.dart';

enum EditorialIntensity { gentle, balanced, expressive }

enum FragmentFidelity { veryFaithful, faithful, freer }

enum ScopeProtection { strict, balanced, flexible }

enum OutputLanguageMode { matchSelection, spanish, english }

enum PreferredEditorialTone { sober, literary, tense, clear }

enum VisualPresence { visible, subtle, minimal }

enum StyleMusaIntensity { contained, balanced, expressive }

enum TensionMusaIntensity { subtle, medium, marked }

enum RhythmMusaIntensity { light, medium, corrective }

enum ClarityMusaIntensity { light, medium, strict }

class MusaSettings {
  final EditorialIntensity editorialIntensity;
  final FragmentFidelity fragmentFidelity;
  final ScopeProtection scopeProtection;
  final OutputLanguageMode outputLanguageMode;
  final PreferredEditorialTone preferredEditorialTone;
  final VisualPresence visualPresence;
  final StyleMusaIntensity styleIntensity;
  final TensionMusaIntensity tensionIntensity;
  final RhythmMusaIntensity rhythmIntensity;
  final ClarityMusaIntensity clarityIntensity;

  const MusaSettings({
    this.editorialIntensity = EditorialIntensity.balanced,
    this.fragmentFidelity = FragmentFidelity.faithful,
    this.scopeProtection = ScopeProtection.balanced,
    this.outputLanguageMode = OutputLanguageMode.matchSelection,
    this.preferredEditorialTone = PreferredEditorialTone.literary,
    this.visualPresence = VisualPresence.subtle,
    this.styleIntensity = StyleMusaIntensity.balanced,
    this.tensionIntensity = TensionMusaIntensity.medium,
    this.rhythmIntensity = RhythmMusaIntensity.medium,
    this.clarityIntensity = ClarityMusaIntensity.medium,
  });

  MusaSettings copyWith({
    EditorialIntensity? editorialIntensity,
    FragmentFidelity? fragmentFidelity,
    ScopeProtection? scopeProtection,
    OutputLanguageMode? outputLanguageMode,
    PreferredEditorialTone? preferredEditorialTone,
    VisualPresence? visualPresence,
    StyleMusaIntensity? styleIntensity,
    TensionMusaIntensity? tensionIntensity,
    RhythmMusaIntensity? rhythmIntensity,
    ClarityMusaIntensity? clarityIntensity,
  }) {
    return MusaSettings(
      editorialIntensity: editorialIntensity ?? this.editorialIntensity,
      fragmentFidelity: fragmentFidelity ?? this.fragmentFidelity,
      scopeProtection: scopeProtection ?? this.scopeProtection,
      outputLanguageMode: outputLanguageMode ?? this.outputLanguageMode,
      preferredEditorialTone:
          preferredEditorialTone ?? this.preferredEditorialTone,
      visualPresence: visualPresence ?? this.visualPresence,
      styleIntensity: styleIntensity ?? this.styleIntensity,
      tensionIntensity: tensionIntensity ?? this.tensionIntensity,
      rhythmIntensity: rhythmIntensity ?? this.rhythmIntensity,
      clarityIntensity: clarityIntensity ?? this.clarityIntensity,
    );
  }

  Map<String, dynamic> toJson() => {
        'editorialIntensity': editorialIntensity.name,
        'fragmentFidelity': fragmentFidelity.name,
        'scopeProtection': scopeProtection.name,
        'outputLanguageMode': outputLanguageMode.name,
        'preferredEditorialTone': preferredEditorialTone.name,
        'visualPresence': visualPresence.name,
        'styleIntensity': styleIntensity.name,
        'tensionIntensity': tensionIntensity.name,
        'rhythmIntensity': rhythmIntensity.name,
        'clarityIntensity': clarityIntensity.name,
      };

  factory MusaSettings.fromJson(Map<String, dynamic> json) => MusaSettings(
        editorialIntensity: _enumValue(
          EditorialIntensity.values,
          json['editorialIntensity'] as String?,
          EditorialIntensity.balanced,
        ),
        fragmentFidelity: _enumValue(
          FragmentFidelity.values,
          json['fragmentFidelity'] as String?,
          FragmentFidelity.faithful,
        ),
        scopeProtection: _enumValue(
          ScopeProtection.values,
          json['scopeProtection'] as String?,
          ScopeProtection.balanced,
        ),
        outputLanguageMode: _enumValue(
          OutputLanguageMode.values,
          json['outputLanguageMode'] as String?,
          OutputLanguageMode.matchSelection,
        ),
        preferredEditorialTone: _enumValue(
          PreferredEditorialTone.values,
          json['preferredEditorialTone'] as String?,
          PreferredEditorialTone.literary,
        ),
        visualPresence: _enumValue(
          VisualPresence.values,
          json['visualPresence'] as String?,
          VisualPresence.subtle,
        ),
        styleIntensity: _enumValue(
          StyleMusaIntensity.values,
          json['styleIntensity'] as String?,
          StyleMusaIntensity.balanced,
        ),
        tensionIntensity: _enumValue(
          TensionMusaIntensity.values,
          json['tensionIntensity'] as String?,
          TensionMusaIntensity.medium,
        ),
        rhythmIntensity: _enumValue(
          RhythmMusaIntensity.values,
          json['rhythmIntensity'] as String?,
          RhythmMusaIntensity.medium,
        ),
        clarityIntensity: _enumValue(
          ClarityMusaIntensity.values,
          json['clarityIntensity'] as String?,
          ClarityMusaIntensity.medium,
        ),
      );

  double expansionRatioFor(Musa musa) {
    final baseRatio = musa.maxLengthExpansionRatio;
    final intensityMultiplier = switch (editorialIntensity) {
      EditorialIntensity.gentle => 0.92,
      EditorialIntensity.balanced => 1.0,
      EditorialIntensity.expressive => 1.1,
    };
    final fidelityMultiplier = switch (fragmentFidelity) {
      FragmentFidelity.veryFaithful => 0.88,
      FragmentFidelity.faithful => 1.0,
      FragmentFidelity.freer => 1.08,
    };
    final scopeMultiplier = switch (scopeProtection) {
      ScopeProtection.strict => 0.9,
      ScopeProtection.balanced => 1.0,
      ScopeProtection.flexible => 1.12,
    };

    final musaMultiplier = switch (musa) {
      StyleMusa() => switch (styleIntensity) {
          StyleMusaIntensity.contained => 0.92,
          StyleMusaIntensity.balanced => 1.0,
          StyleMusaIntensity.expressive => 1.1,
        },
      TensionMusa() => switch (tensionIntensity) {
          TensionMusaIntensity.subtle => 0.9,
          TensionMusaIntensity.medium => 1.0,
          TensionMusaIntensity.marked => 1.1,
        },
      RhythmMusa() => switch (rhythmIntensity) {
          RhythmMusaIntensity.light => 0.92,
          RhythmMusaIntensity.medium => 1.0,
          RhythmMusaIntensity.corrective => 1.08,
        },
      ClarityMusa() => switch (clarityIntensity) {
          ClarityMusaIntensity.light => 1.02,
          ClarityMusaIntensity.medium => 1.0,
          ClarityMusaIntensity.strict => 0.9,
        },
      _ => 1.0,
    };

    return (baseRatio *
            intensityMultiplier *
            fidelityMultiplier *
            scopeMultiplier *
            musaMultiplier)
        .clamp(1.05, 1.8);
  }

  String get editorialIntensityInstruction => switch (editorialIntensity) {
        EditorialIntensity.gentle =>
          'Toca el texto con suavidad. Mejora solo lo necesario.',
        EditorialIntensity.balanced =>
          'Mejora el texto con naturalidad, sin cambiar demasiado su forma original.',
        EditorialIntensity.expressive =>
          'Puedes dar más forma al lenguaje, pero sin perder el corazón del fragmento.',
      };

  String get fragmentFidelityInstruction => switch (fragmentFidelity) {
        FragmentFidelity.veryFaithful =>
          'Mantente muy cerca del modo en que está escrito el fragmento.',
        FragmentFidelity.faithful =>
          'Mantente fiel al fragmento mientras lo mejoras.',
        FragmentFidelity.freer =>
          'Puedes darte un poco más de libertad, pero sin salirte del fragmento ni cambiar su sentido.',
      };

  String get scopeProtectionInstruction => switch (scopeProtection) {
        ScopeProtection.strict =>
          'Mantente muy cerca del fragmento. No te extiendas más de lo imprescindible.',
        ScopeProtection.balanced =>
          'Mantén el foco en el fragmento. Solo se permiten pequeños desarrollos que sigan claramente dentro de él.',
        ScopeProtection.flexible =>
          'Puedes abrir un poco la frase si ayuda, pero no continúes la escena ni añadas hechos nuevos.',
      };

  String get preferredToneInstruction => switch (preferredEditorialTone) {
        PreferredEditorialTone.sober =>
          'Prefiere una voz sobria, precisa y contenida.',
        PreferredEditorialTone.literary =>
          'Prefiere una voz literaria, cuidada y con tacto verbal.',
        PreferredEditorialTone.tense =>
          'Prefiere una voz con más nervio e inquietud.',
        PreferredEditorialTone.clear =>
          'Prefiere una voz limpia, nítida y fácil de seguir.',
      };

  String musaIntensityInstruction(Musa musa) {
    return switch (musa) {
      StyleMusa() => switch (styleIntensity) {
          StyleMusaIntensity.contained =>
            'En Estilo, mejora la frase sin apartarte demasiado de cómo ya está escrita.',
          StyleMusaIntensity.balanced =>
            'En Estilo, refina con tacto y sin imponerte sobre la voz del texto.',
          StyleMusaIntensity.expressive =>
            'En Estilo, puedes dar más vuelo al lenguaje, pero sin inventar nada nuevo.',
        },
      TensionMusa() => switch (tensionIntensity) {
          TensionMusaIntensity.subtle =>
            'En Tensión, añade inquietud con una mano ligera.',
          TensionMusaIntensity.medium =>
            'En Tensión, aumenta el nervio sin romper la medida del fragmento.',
          TensionMusaIntensity.marked =>
            'En Tensión, marca más la fricción y la amenaza implícita, sin convertirlo en otra escena.',
        },
      RhythmMusa() => switch (rhythmIntensity) {
          RhythmMusaIntensity.light =>
            'En Ritmo, ajusta solo lo necesario para que la frase respire mejor.',
          RhythmMusaIntensity.medium =>
            'En Ritmo, busca un fluir más natural y legible.',
          RhythmMusaIntensity.corrective =>
            'En Ritmo, puedes reorganizar con más decisión si la frase lo pide.',
        },
      ClarityMusa() => switch (clarityIntensity) {
          ClarityMusaIntensity.light =>
            'En Claridad, despeja lo justo sin volverlo plano.',
          ClarityMusaIntensity.medium =>
            'En Claridad, limpia la frase con equilibrio.',
          ClarityMusaIntensity.strict =>
            'En Claridad, prioriza nitidez y evita rodeos.',
        },
      _ => '',
    };
  }

  bool get shouldBlockScopeViolation =>
      scopeProtection == ScopeProtection.strict;
  bool get shouldShowScopeWarning =>
      scopeProtection == ScopeProtection.balanced;
  bool get shouldMuteScopeWarning =>
      scopeProtection == ScopeProtection.flexible;

  bool get showInvocationBadge => visualPresence == VisualPresence.visible;
  bool get showAnimatedStatusMessages =>
      visualPresence == VisualPresence.visible;
  bool get showStreamingChip => visualPresence != VisualPresence.minimal;
  bool get showSecondaryWaitingCopy => visualPresence == VisualPresence.visible;
  bool get showBreathLine => visualPresence != VisualPresence.minimal;
}

T _enumValue<T extends Enum>(List<T> values, String? rawValue, T fallback) {
  if (rawValue == null) {
    return fallback;
  }

  for (final value in values) {
    if (value.name == rawValue) {
      return value;
    }
  }

  return fallback;
}
