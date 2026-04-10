import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/ia/ia_interfaces.dart';
import 'ia/embedded/embedded_ia_service.dart';
import 'ia/embedded/management/model_manager.dart';
import 'ia/fallback/unavailable_ia_service.dart';

/// Resolves the concrete AI service for the current platform and active model.
final iaServiceProvider = Provider<IAService>((ref) {
  if (Platform.isMacOS) {
    final activeModelPath = ref.watch(
      modelManagerProvider.select((s) => s.activeModelPath),
    );
    return EmbeddedIAService(activeModelPath: activeModelPath);
  }
  return UnavailableIAService();
});
