import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/providers/workspace_providers.dart';
import '../../continuity/providers/continuity_providers.dart';
import '../models/editorial_audit.dart';
import '../models/chapter_editorial_map.dart';
import '../models/editorial_director.dart';
import '../services/editorial_audit_service.dart';
import '../services/chapter_editorial_map_service.dart';
import '../services/editorial_director_service.dart';

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

final chapterEditorialMapServiceProvider =
    Provider<ChapterEditorialMapService>((ref) {
  return const ChapterEditorialMapService();
});

final activeChapterEditorialMapProvider =
    Provider<ChapterEditorialMapReport?>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  final book = workspace?.activeBook;
  if (workspace == null || book == null) return null;

  return ref.watch(chapterEditorialMapServiceProvider).build(
        book: book,
        documents: workspace.activeBookDocuments,
        memory: workspace.activeNarrativeMemory,
        storyState: workspace.activeStoryState,
        now: DateTime.now(),
      );
});

final editorialDirectorServiceProvider =
    Provider<EditorialDirectorService>((ref) {
  return const EditorialDirectorService();
});

final activeEditorialDirectorProvider =
    Provider<EditorialDirectorReport?>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  final book = workspace?.activeBook;
  if (workspace == null || book == null) return null;

  return ref.watch(editorialDirectorServiceProvider).build(
        book: book,
        documents: workspace.activeBookDocuments,
        memory: workspace.activeNarrativeMemory,
        novelStatus: ref.watch(activeNovelStatusProvider),
        editorialAudit: ref.watch(activeEditorialAuditProvider),
        chapterMap: ref.watch(activeChapterEditorialMapProvider),
        storyState: workspace.activeStoryState,
        now: DateTime.now(),
      );
});
