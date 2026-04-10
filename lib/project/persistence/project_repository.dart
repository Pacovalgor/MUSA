import '../models/musa_project.dart';
import '../models/chapter.dart';

abstract class ProjectRepository {
  Future<MusaProject> loadProject(String path);
  Future<void> saveProject(MusaProject project);
  
  Future<List<Chapter>> loadChapters(String projectPath);
  Future<void> saveChapter(String projectPath, Chapter chapter);
  
  Future<void> deleteChapter(String projectPath, String chapterId);
}
