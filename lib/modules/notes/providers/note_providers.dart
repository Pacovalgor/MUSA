import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/models/narrative_workspace.dart';
import '../../books/providers/workspace_providers.dart';
import '../../manuscript/providers/document_providers.dart';
import '../models/note.dart';
import '../models/voice_memo.dart';

final notesProvider = Provider<List<Note>>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  final activeBookId = workspace?.activeBook?.id;
  if (workspace == null || activeBookId == null) return const [];
  final results = workspace.notes
      .where((note) => note.bookId == activeBookId)
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return results;
});

final voiceMemosProvider = Provider<List<VoiceMemo>>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  final activeBookId = workspace?.activeBook?.id;
  if (workspace == null || activeBookId == null) return const [];
  return workspace.voiceMemos
      .where((memo) => memo.bookId == activeBookId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final currentNoteProvider = Provider<Note?>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  final selectedNoteId = workspace?.selectedNoteId;
  final notes = ref.watch(notesProvider);
  if (selectedNoteId == null || notes.isEmpty) return null;
  for (final note in notes) {
    if (note.id == selectedNoteId) return note;
  }
  return notes.first;
});

class EditorContentItem {
  final String id;
  final String title;
  final String content;
  final bool isNote;

  const EditorContentItem({
    required this.id,
    required this.title,
    required this.content,
    required this.isNote,
  });
}

final currentEditorContentProvider = Provider<EditorContentItem?>((ref) {
  final mode = ref.watch(editorModeProvider);
  if (mode == WorkspaceEditorMode.note) {
    final note = ref.watch(currentNoteProvider);
    if (note == null) return null;
    return EditorContentItem(
      id: note.id,
      title: note.title ?? 'Nota sin título',
      content: note.content,
      isNote: true,
    );
  }

  if (mode == WorkspaceEditorMode.character ||
      mode == WorkspaceEditorMode.scenario) {
    return null;
  }

  final document = ref.watch(currentDocumentProvider);
  if (document == null) return null;
  return EditorContentItem(
    id: document.id,
    title: document.title,
    content: document.content,
    isNote: false,
  );
});
