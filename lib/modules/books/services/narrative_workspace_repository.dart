import '../models/narrative_workspace.dart';

abstract class NarrativeWorkspaceRepository {
  Future<NarrativeWorkspace> loadWorkspace();
  Future<void> saveWorkspace(NarrativeWorkspace workspace);
}
