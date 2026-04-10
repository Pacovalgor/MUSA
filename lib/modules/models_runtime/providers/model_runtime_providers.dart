import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/providers/workspace_providers.dart';
import '../models/installed_model.dart';
import '../models/model_profile.dart';

final modelProfilesProvider = Provider<List<ModelProfile>>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.modelProfiles ?? const [];
});

final installedModelsProvider = Provider<List<InstalledModel>>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.installedModels ??
      const [];
});
