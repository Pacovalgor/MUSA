import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/providers/workspace_providers.dart';
import '../models/continuity_audit.dart';
import '../models/continuity_state.dart';
import '../models/timeline_event.dart';
import '../services/continuity_audit_service.dart';

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

final continuityAuditServiceProvider = Provider<ContinuityAuditService>((ref) {
  return const ContinuityAuditService();
});

final activeContinuityFindingsProvider =
    Provider<List<ContinuityFinding>>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  final book = workspace?.activeBook;
  if (workspace == null || book == null) return const [];

  final dismissed = book.dismissedContinuityFindingIds.toSet();
  final findings = ref.watch(continuityAuditServiceProvider).audit(
        book: book,
        documents: workspace.activeBookDocuments,
        memory: workspace.activeNarrativeMemory,
        storyState: workspace.activeStoryState,
        continuityState: workspace.activeContinuityState,
        characters: workspace.activeBookCharacters,
        scenarios: workspace.activeBookScenarios,
        now: DateTime.now(),
      );

  if (dismissed.isEmpty) return findings;
  return findings.where((f) => !dismissed.contains(f.id)).toList();
});
