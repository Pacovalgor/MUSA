import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'characters/character_autofill_service.dart';
import 'characters/embedded_character_autofill_service.dart';
import 'characters/unavailable_character_autofill_service.dart';
import 'ia/embedded/management/model_manager.dart';

final characterAutofillServiceProvider =
    Provider<CharacterAutofillService>((ref) {
  if (Platform.isMacOS) {
    final activeModelPath = ref.watch(
      modelManagerProvider.select((s) => s.activeModelPath),
    );
    return EmbeddedCharacterAutofillService(activeModelPath: activeModelPath);
  }

  return UnavailableCharacterAutofillService();
});
