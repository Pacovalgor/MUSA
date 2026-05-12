import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/ia/embedded/management/model_manager.dart';
import '../services/guided_rewrite_generation_service.dart';
import '../services/guided_rewrite_planner.dart';
import '../services/llama_guided_rewrite_model_client.dart';

final guidedRewritePlannerProvider = Provider<GuidedRewritePlanner>((ref) {
  return const GuidedRewritePlanner();
});

/// Provides a [GuidedRewriteGenerationService] backed by the local model when
/// one is active, or falling back to the deterministic service otherwise.
///
/// The provider rebuilds whenever the active model path changes so the UI
/// picks up the new client without a restart.
final guidedRewriteGenerationServiceProvider =
    Provider<GuidedRewriteGenerationService>((ref) {
  if (!Platform.isMacOS) {
    return const GuidedRewriteGenerationService();
  }

  final activeModelPath = ref.watch(
    modelManagerProvider.select((s) => s.activeModelPath),
  );

  if (activeModelPath == null || activeModelPath.isEmpty) {
    return const GuidedRewriteGenerationService();
  }

  final dylibPath = LlamaGuidedRewriteModelClient.resolveDylibPath();
  if (dylibPath == null) {
    return const GuidedRewriteGenerationService();
  }

  return GuidedRewriteGenerationService(
    modelClient: LlamaGuidedRewriteModelClient(
      modelPath: activeModelPath,
      dylibPath: dylibPath,
    ),
  );
});
