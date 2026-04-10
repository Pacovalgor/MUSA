import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/providers/workspace_providers.dart';
import '../models/installed_model.dart';
import '../models/model_profile.dart';

/// Catalog of model definitions known by the workspace.
final modelProfilesProvider = Provider<List<ModelProfile>>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.modelProfiles ?? const [];
});

/// Installation records for models available on the local machine.
final installedModelsProvider = Provider<List<InstalledModel>>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.installedModels ??
      const [];
});
