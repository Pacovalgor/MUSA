import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/providers/workspace_providers.dart';
import '../models/continuity_state.dart';
import '../models/timeline_event.dart';

final continuityStateProvider = Provider<ContinuityState?>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.activeContinuityState;
});

final timelineEventsProvider = Provider<List<TimelineEvent>>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  final activeBookId = workspace?.activeBook?.id;
  if (workspace == null || activeBookId == null) return const [];
  return workspace.timelineEvents
      .where((event) => event.bookId == activeBookId)
      .toList();
});
