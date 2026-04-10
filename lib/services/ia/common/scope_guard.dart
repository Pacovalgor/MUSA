import '../../../muses/musa.dart';
import '../../../modules/books/models/musa_settings.dart';

class ScopeGuardResult {
  final bool isValid;
  final String? reason;

  const ScopeGuardResult._({
    required this.isValid,
    this.reason,
  });

  factory ScopeGuardResult.valid() {
    return const ScopeGuardResult._(isValid: true);
  }

  factory ScopeGuardResult.invalid(String reason) {
    return ScopeGuardResult._(
      isValid: false,
      reason: reason,
    );
  }
}

class ScopeGuard {
  static ScopeGuardResult validate({
    required String original,
    required String candidate,
    required Musa musa,
    required MusaSettings settings,
  }) {
    final input = original.trim();
    final output = candidate.trim();

    if (output.isEmpty) {
      return ScopeGuardResult.invalid('La salida quedó vacía.');
    }

    final inputWords = _wordCount(input);
    final outputWords = _wordCount(output);
    final inputSentences = _sentenceCount(input);
    final outputSentences = _sentenceCount(output);
    final hasInputNewlines = input.contains('\n');
    final hasOutputNewlines = output.contains('\n');

    if (!hasInputNewlines && hasOutputNewlines) {
      return ScopeGuardResult.invalid(
        'La salida introduce saltos de línea fuera del fragmento original.',
      );
    }

    if (!input.contains('—') && output.contains('—')) {
      return ScopeGuardResult.invalid(
        'La salida introduce diálogo que no existe en la selección.',
      );
    }

    if (!input.contains('"') && output.contains('"')) {
      return ScopeGuardResult.invalid(
        'La salida introduce citas o voces nuevas fuera del alcance seleccionado.',
      );
    }

    final allowedWordCeiling =
        (inputWords * settings.expansionRatioFor(musa)).ceil();
    if (outputWords > allowedWordCeiling + 1) {
      return ScopeGuardResult.invalid(
        'La salida se expandió demasiado respecto al fragmento original.',
      );
    }

    if (inputWords <= 4 && outputWords > inputWords + 4) {
      return ScopeGuardResult.invalid(
        'Una selección mínima no debe convertirse en una frase expandida o un párrafo.',
      );
    }

    if (inputSentences <= 1 && outputSentences > 2) {
      return ScopeGuardResult.invalid(
        'La salida añade progresión narrativa más allá de una reescritura quirúrgica.',
      );
    }

    return ScopeGuardResult.valid();
  }

  static ScopeGuardResult validatePartial({
    required String original,
    required String candidate,
    required Musa musa,
    required MusaSettings settings,
  }) {
    final input = original.trim();
    final output = candidate.trimLeft();

    if (output.isEmpty) {
      return ScopeGuardResult.valid();
    }

    final inputWords = _wordCount(input);
    final outputWords = _wordCount(output);
    final inputSentences = _sentenceCount(input);
    final outputSentences = _sentenceCount(output);
    final hasInputNewlines = input.contains('\n');
    final hasOutputNewlines = output.contains('\n');

    if (!hasInputNewlines && hasOutputNewlines) {
      return ScopeGuardResult.invalid(
        'La salida introduce saltos de línea fuera del fragmento original.',
      );
    }

    if (!input.contains('—') && output.contains('—')) {
      return ScopeGuardResult.invalid(
        'La salida introduce diálogo que no existe en la selección.',
      );
    }

    if (!input.contains('"') && output.contains('"')) {
      return ScopeGuardResult.invalid(
        'La salida introduce citas o voces nuevas fuera del alcance seleccionado.',
      );
    }

    final allowedWordCeiling =
        (inputWords * settings.expansionRatioFor(musa)).ceil();
    if (outputWords > allowedWordCeiling + 1) {
      return ScopeGuardResult.invalid(
        'La salida se expandió demasiado respecto al fragmento original.',
      );
    }

    if (inputWords <= 4 && outputWords > inputWords + 2) {
      return ScopeGuardResult.invalid(
        'Una selección mínima no debe convertirse en una frase expandida o un párrafo.',
      );
    }

    if (inputSentences <= 1 &&
        outputSentences > 1 &&
        outputWords > inputWords + 2) {
      return ScopeGuardResult.invalid(
        'La salida añade progresión narrativa más allá de una reescritura quirúrgica.',
      );
    }

    return ScopeGuardResult.valid();
  }

  static int _wordCount(String text) {
    return RegExp(r"[A-Za-zÁÉÍÓÚáéíóúÑñÜü']+").allMatches(text).length;
  }

  static int _sentenceCount(String text) {
    final matches = RegExp(r'[.!?…]+').allMatches(text).length;
    return matches == 0 ? 1 : matches;
  }
}
