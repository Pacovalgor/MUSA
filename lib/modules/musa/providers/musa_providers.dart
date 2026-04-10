import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/providers/workspace_providers.dart';
import '../models/musa_profile.dart';
import '../models/musa_session.dart';
import '../models/musa_suggestion.dart';

final musaProfilesProvider = Provider<List<MusaProfile>>((ref) {
  return ref
          .watch(narrativeWorkspaceProvider)
          .value
          ?.musaProfiles
          .where((profile) => profile.isEnabled)
          .toList() ??
      const [];
});

final musaSessionsProvider = Provider<List<MusaSession>>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  final activeBookId = workspace?.activeBook?.id;
  if (workspace == null || activeBookId == null) return const [];
  return workspace.musaSessions
      .where((session) => session.bookId == activeBookId)
      .toList();
});

final musaSuggestionsProvider = Provider<List<MusaSuggestion>>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  return workspace?.musaSuggestions ?? const [];
});
