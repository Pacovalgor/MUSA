import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/musa_project.dart';
import '../models/chapter.dart';
import '../models/summary.dart';
import '../models/narrative_state.dart';
import '../models/continuity_memory.dart';
import 'project_repository.dart';


class FileSystemRepository implements ProjectRepository {
  @override
  Future<MusaProject> loadProject(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      throw FileSystemException("Project directory does not exist", path);
    }

    final stateFile = File(p.join(path, 'state.json'));
    final summaryFile = File(p.join(path, 'summary.md'));
    final memoryFile = File(p.join(path, 'continuity.json'));
    
    return MusaProject(
      id: p.basename(path),
      name: p.basenameWithoutExtension(path),
      path: path,
      chapters: await loadChapters(path),
      summary: await _loadSummary(summaryFile),
      narrativeState: await _loadState(stateFile),
      storyMemory: await _loadMemory(memoryFile),
    );
  }

  @override
  Future<void> saveProject(MusaProject project) async {
    final dir = Directory(project.path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    final chaptersDir = Directory(p.join(project.path, 'chapters'));
    if (!await chaptersDir.exists()) {
      await chaptersDir.create();
    }

    // Save summary
    final summaryFile = File(p.join(project.path, 'summary.md'));
    await summaryFile.writeAsString(project.summary.content);

    // Save state
    final stateFile = File(p.join(project.path, 'state.json'));
    await stateFile.writeAsString(jsonEncode(project.narrativeState.toJson()));

    // Save memory
    final memoryFile = File(p.join(project.path, 'continuity.json'));
    await memoryFile.writeAsString(jsonEncode(project.storyMemory.toJson()));

    // Save all chapters
    for (var chapter in project.chapters) {
      await saveChapter(project.path, chapter);
    }
  }

  @override
  Future<List<Chapter>> loadChapters(String projectPath) async {
    final chaptersDir = Directory(p.join(projectPath, 'chapters'));
    if (!await chaptersDir.exists()) return [];

    final result = <Chapter>[];
    final files = await chaptersDir.list().toList();
    
    // Sort files by name to maintain order (e.g. 01_intro.md)
    files.sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      if (file is File && file.path.endsWith('.md')) {
        result.add(Chapter(
          id: p.basenameWithoutExtension(file.path),
          title: p.basenameWithoutExtension(file.path).replaceAll(RegExp(r'^\d+_'), ''),
          content: await file.readAsString(),
          order: result.length, 
          lastModified: await file.lastModified(),
        ));
      }
    }
    return result;
  }

  @override
  Future<void> saveChapter(String projectPath, Chapter chapter) async {
    final chaptersDir = Directory(p.join(projectPath, 'chapters'));
    if (!await chaptersDir.exists()) await chaptersDir.create();

    // Use a prefixed name for ordering: 01_chapter-id.md
    final prefix = chapter.order.toString().padLeft(2, '0');
    final filePath = p.join(projectPath, 'chapters', '${prefix}_${chapter.id}.md');
    
    final file = File(filePath);
    await file.writeAsString(chapter.content);
  }

  @override
  Future<void> deleteChapter(String projectPath, String chapterId) async {
    final chaptersDir = Directory(p.join(projectPath, 'chapters'));
    if (!await chaptersDir.exists()) return;

    await for (final file in chaptersDir.list()) {
      if (file is File && file.path.contains(chapterId)) {
        await file.delete();
      }
    }
  }

  Future<Summary> _loadSummary(File file) async {
    if (!await file.exists()) {
      return Summary(content: "", plotPoints: "", lastUpdated: DateTime.now());
    }
    return Summary(
      content: await file.readAsString(),
      plotPoints: "",
      lastUpdated: await file.lastModified(),
    );
  }

  Future<NarrativeState> _loadState(File file) async {
    if (!await file.exists()) {
      return NarrativeState(
        currentChapterIndex: 0,
        totalWordCount: 0,
        currentTensionLevel: "Low",
        nextGoal: "",
      );
    }
    final content = await file.readAsString();
    return NarrativeState.fromJson(jsonDecode(content));
  }

  Future<ContinuityMemory> _loadMemory(File file) async {
    if (!await file.exists()) {
      return ContinuityMemory();
    }
    final content = await file.readAsString();
    return ContinuityMemory.fromJson(jsonDecode(content));
  }
}
