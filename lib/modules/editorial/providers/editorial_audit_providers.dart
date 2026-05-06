import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/providers/workspace_providers.dart';
import '../../continuity/providers/continuity_providers.dart';
import '../models/editorial_audit.dart';
import '../services/editorial_audit_service.dart';

final editorialAuditServiceProvider = Provider<EditorialAuditService>((ref) {
  return const EditorialAuditService();
});

final activeEditorialAuditProvider = Provider<EditorialAuditReport?>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  final book = workspace?.activeBook;
  if (workspace == null || book == null) return null;

  return ref.watch(editorialAuditServiceProvider).audit(
        book: book,
        documents: workspace.activeBookDocuments,
        memory: workspace.activeNarrativeMemory,
        continuityFindings: ref.watch(activeContinuityFindingsProvider),
        now: DateTime.now(),
      );
});
