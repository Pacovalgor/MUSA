import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/books/models/app_settings.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_workspace.dart';
import 'package:musa/modules/books/providers/workspace_providers.dart';
import 'package:musa/modules/books/services/narrative_workspace_repository.dart';
import 'package:musa/modules/manuscript/models/document.dart';
import 'package:musa/modules/notes/models/note.dart';

class _MemoryWorkspaceRepository implements NarrativeWorkspaceRepository {
  _MemoryWorkspaceRepository(this.workspace);

  NarrativeWorkspace workspace;

  @override
  Future<NarrativeWorkspace> loadWorkspace() async => workspace;

  @override
  Future<void> saveWorkspace(NarrativeWorkspace workspace) async {
    this.workspace = workspace;
  }
}

void main() {
  test('workflow notes persist metadata and snapshots restore workspace', () async {
    final now = DateTime(2026, 4, 10, 12);
    const bookId = 'book-1';
    const documentId = 'doc-1';

    final repository = _MemoryWorkspaceRepository(
      NarrativeWorkspace(
        appSettings: const AppSettings(activeBookId: bookId),
        books: [
          Book(
            id: bookId,
            title: 'Libro',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        documents: [
          Document(
            id: documentId,
            bookId: bookId,
            title: 'Capítulo 1',
            createdAt: now,
            updatedAt: now,
            orderIndex: 0,
          ),
        ],
        selectedDocumentId: documentId,
      ),
    );

    final notifier = NarrativeWorkspaceNotifier(repository);
    await notifier.bootstrap();

    final created = await notifier.createWorkflowNote(
      title: 'Empujar momento en Capítulo 1',
      content: 'Nota estructurada',
      workflowType: EditorialWorkflowType.expandMoment,
      workflowDirectionKey: 'raise_tension',
      sourceDocumentId: documentId,
      sourceDocumentTitle: 'Capítulo 1',
    );

    expect(created, isNotNull);
    expect(notifier.state.value?.notes, hasLength(1));
    expect(notifier.state.value?.notes.first.workflowType,
        EditorialWorkflowType.expandMoment);
    expect(notifier.state.value?.notes.first.workflowDirectionKey,
        'raise_tension');
    expect(notifier.state.value?.notes.first.sourceDocumentId, documentId);

    await notifier.updateNoteStatus(created!.id, NoteStatus.used);
    expect(notifier.state.value?.notes.first.status, NoteStatus.used);

    final snapshot = await notifier.createSnapshot(label: 'Antes del cambio');
    expect(snapshot, isNotNull);
    expect(notifier.state.value?.snapshots, hasLength(1));

    await notifier.updateBookDetails(bookId: bookId, summary: 'Versión nueva');
    expect(notifier.state.value?.activeBook?.summary, 'Versión nueva');

    await notifier.restoreSnapshot(snapshot!.id);
    expect(notifier.state.value?.activeBook?.summary, isEmpty);
    expect(notifier.state.value?.snapshots, hasLength(1));
  });
}
