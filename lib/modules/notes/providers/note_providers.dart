import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/models/narrative_workspace.dart';
import '../../books/models/workspace_snapshot.dart';
import '../../books/providers/workspace_providers.dart';
import '../../manuscript/providers/document_providers.dart';
import '../models/note.dart';
import '../models/voice_memo.dart';

/// Notes scoped to the active book and ordered by recent activity.
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

/// Voice memos associated with the active book.
final voiceMemosProvider = Provider<List<VoiceMemo>>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  final activeBookId = workspace?.activeBook?.id;
  if (workspace == null || activeBookId == null) return const [];
  return workspace.voiceMemos
      .where((memo) => memo.bookId == activeBookId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Currently selected note, resolved against the active note collection.
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

/// Workflow notes attached to the document currently open in the editor.
final currentDocumentWorkflowNotesProvider = Provider<List<Note>>((ref) {
  final document = ref.watch(currentDocumentProvider);
  final notes = ref.watch(notesProvider);
  if (document == null) return const [];
  return notes
      .where((note) =>
          note.kind == NoteKind.structural &&
          note.workflowType != null &&
          (note.sourceDocumentId == document.id ||
              note.documentIds.contains(document.id)))
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
});

/// Saved snapshots available for the active book.
final snapshotsProvider = Provider<List<WorkspaceSnapshot>>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  return workspace?.activeBookSnapshots ?? const [];
});

/// Small adapter used by the editor to consume documents and notes uniformly.
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

/// Current editable content item, abstracting over document and note modes.
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
