import 'chapter.dart';
import 'summary.dart';
import 'narrative_state.dart';
import 'continuity_memory.dart';

class MusaProject {
  final String id;
  final String name;
  final String path;
  final List<Chapter> chapters;
  final Summary summary;
  final NarrativeState narrativeState;
  final ContinuityMemory storyMemory;

  MusaProject({
    required this.id,
    required this.name,
    required this.path,
    required this.chapters,
    required this.summary,
    required this.narrativeState,
    required this.storyMemory,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
  };
}
