import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/musa_project.dart';
import '../models/chapter.dart';
import '../persistence/project_repository.dart';
import '../persistence/file_system_repository.dart';

/// Repository used by the legacy file-based project layer.
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return FileSystemRepository();
});

/// Legacy state notifier for projects stored outside the workspace aggregate.
class ProjectNotifier extends StateNotifier<MusaProject?> {
  final ProjectRepository _repository;

  ProjectNotifier(this._repository) : super(null);

  Future<void> loadProject(String path) async {
    final project = await _repository.loadProject(path);
    state = project;
  }

  Future<void> saveProject() async {
    if (state == null) return;
    await _repository.saveProject(state!);
  }

  void updateChapterContent(String chapterId, String content) {
    if (state == null) return;

    final updatedChapters = state!.chapters.map((c) {
      if (c.id == chapterId) {
        return Chapter(
          id: c.id,
          title: c.title,
          content: content,
          order: c.order,
          lastModified: DateTime.now(),
        );
      }
      return c;
    }).toList();

    state = MusaProject(
      id: state!.id,
      name: state!.name,
      path: state!.path,
      chapters: updatedChapters,
      summary: state!.summary,
      narrativeState: state!.narrativeState,
      storyMemory: state!.storyMemory,
    );
  }

  Future<void> addChapter(String title) async {
    if (state == null) return;

    final newChapter = Chapter(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: "",
      order: state!.chapters.length,
      lastModified: DateTime.now(),
    );

    final updatedChapters = [...state!.chapters, newChapter];

    state = MusaProject(
      id: state!.id,
      name: state!.name,
      path: state!.path,
      chapters: updatedChapters,
      summary: state!.summary,
      narrativeState: state!.narrativeState,
      storyMemory: state!.storyMemory,
    );

    await _repository.saveChapter(state!.path, newChapter);
  }
}

/// Entry point for the legacy project state flow.
final projectProvider =
    StateNotifierProvider<ProjectNotifier, MusaProject?>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return ProjectNotifier(repository);
});

/// Selected chapter identifier inside the legacy project flow.
final currentChapterIdProvider = StateProvider<String?>((ref) => null);

/// Currently open chapter resolved from the selected project and chapter id.
final currentChapterProvider = Provider<Chapter?>((ref) {
  final project = ref.watch(projectProvider);
  final chapterId = ref.watch(currentChapterIdProvider);

  if (project == null || chapterId == null) return null;

  return project.chapters.firstWhere((c) => c.id == chapterId,
      orElse: () => project.chapters.first);
});
