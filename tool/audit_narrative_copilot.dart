// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_copilot.dart';
import 'package:musa/modules/books/services/narrative_memory_updater.dart';
import 'package:musa/modules/books/services/story_state_updater.dart';
import 'package:musa/modules/manuscript/models/document.dart';

const _defaultWorkspacePath =
    '/Users/paco/Library/Containers/com.example.musa/Data/Library/Application Support/com.example.musa/musa/musa_workspace.json';

void main(List<String> args) {
  final workspacePath = args.isEmpty ? _defaultWorkspacePath : args.first;
  final workspaceJson = jsonDecode(File(workspacePath).readAsStringSync())
      as Map<String, dynamic>;
  final books = (workspaceJson['books'] as List? ?? const [])
      .map((item) => Book.fromJson(item as Map<String, dynamic>))
      .toList();
  final documents = (workspaceJson['documents'] as List? ?? const [])
      .map((item) => Document.fromJson(item as Map<String, dynamic>))
      .toList();
  final booksById = {for (final book in books) book.id: book};
  final docsByBook = <String, List<Document>>{};
  for (final document in documents) {
    if (document.content.trim().isEmpty) continue;
    docsByBook.putIfAbsent(document.bookId, () => []).add(document);
  }
  for (final documents in docsByBook.values) {
    documents.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  final rows = <_AuditRow>[];
  final now = DateTime(2026, 4, 11, 12);

  for (final entry in docsByBook.entries) {
    final book = booksById[entry.key];
    if (book == null) continue;
    final profile = _assumedProfile(book);
    final profiledBook = book.copyWith(narrativeProfile: profile);
    for (var index = 0; index < entry.value.length; index++) {
      rows.add(_runAudit(
        mode: 'perfil asumido',
        book: profiledBook,
        documents: entry.value.take(index + 1).toList(),
        now: now,
      ));
    }
  }

  var stressIndex = 0;
  for (final entry in docsByBook.entries) {
    final book = booksById[entry.key];
    if (book == null) continue;
    for (var index = 0; index < entry.value.length; index++) {
      final profile = _stressProfile(stressIndex++);
      rows.add(_runAudit(
        mode: 'stress ${profile.primaryGenre.name}',
        book: book.copyWith(narrativeProfile: profile),
        documents: entry.value.take(index + 1).toList(),
        now: now,
      ));
    }
  }

  print(
      'mode\tbook\tchapter\tgenre\tact\tfunction\ttension\tmove\treason\tdiagnostics');
  for (final row in rows.take(30)) {
    print([
      row.mode,
      row.bookTitle,
      row.chapterTitle,
      row.genre,
      row.act,
      row.function,
      row.tension,
      row.move,
      row.reason,
      row.diagnostics.join(' | '),
    ].map(_cell).join('\t'));
  }
}

BookNarrativeProfile _assumedProfile(Book book) {
  if (book.title.toLowerCase().contains('ojo invisible')) {
    return const BookNarrativeProfile(
      primaryGenre: BookPrimaryGenre.thriller,
      subgenre: 'misterio noir tecnológico',
      tone: 'íntimo, oscuro, urbano',
      scale: NarrativeScale.intimate,
      targetPace: TargetPace.agile,
      dominantPriority: DominantPriority.tension,
      readerPromise:
          'Una investigación íntima donde cada pista debe aumentar coste o presión.',
      endingType: EndingType.ambiguous,
    );
  }
  return const BookNarrativeProfile(
    primaryGenre: BookPrimaryGenre.mystery,
    subgenre: 'material de investigación para ficción oscura',
    tone: 'preciso, documental',
    scale: NarrativeScale.intimate,
    targetPace: TargetPace.measured,
    dominantPriority: DominantPriority.idea,
    readerPromise:
        'Material útil para convertir investigación en decisiones narrativas.',
    endingType: EndingType.open,
  );
}

BookNarrativeProfile _stressProfile(int index) {
  return switch (index % 3) {
    0 => const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.thriller,
        targetPace: TargetPace.urgent,
        dominantPriority: DominantPriority.tension,
        readerPromise: 'Presión progresiva y consecuencias visibles.',
      ),
    1 => const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.scienceFiction,
        targetPace: TargetPace.measured,
        dominantPriority: DominantPriority.idea,
        readerPromise: 'Ideas y sistemas que cambian el margen de acción.',
      ),
    _ => const BookNarrativeProfile(
        primaryGenre: BookPrimaryGenre.fantasy,
        targetPace: TargetPace.measured,
        dominantPriority: DominantPriority.atmosphere,
        readerPromise: 'Atmósfera con deuda, destino o conflicto latente.',
      ),
  };
}

_AuditRow _runAudit({
  required String mode,
  required Book book,
  required List<Document> documents,
  required DateTime now,
}) {
  final memory = const NarrativeMemoryUpdater().update(
    bookId: book.id,
    documents: documents,
    previous: null,
    now: now,
  );
  final storyState = const StoryStateUpdater().update(
    book: book,
    documents: documents,
    memory: memory,
    previous: null,
    now: now,
  );
  return _AuditRow(
    mode: mode,
    bookTitle: book.title,
    chapterTitle: documents.last.title,
    genre: book.narrativeProfile.primaryGenre.name,
    act: storyState.currentAct.name,
    function: storyState.currentChapterFunction.name,
    tension: storyState.globalTension.toString(),
    move: storyState.nextBestMove,
    reason: storyState.nextBestMoveReason,
    diagnostics: storyState.diagnostics,
  );
}

String _cell(Object? value) {
  return value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _AuditRow {
  final String mode;
  final String bookTitle;
  final String chapterTitle;
  final String genre;
  final String act;
  final String function;
  final String tension;
  final String move;
  final String reason;
  final List<String> diagnostics;

  const _AuditRow({
    required this.mode,
    required this.bookTitle,
    required this.chapterTitle,
    required this.genre,
    required this.act,
    required this.function,
    required this.tension,
    required this.move,
    required this.reason,
    required this.diagnostics,
  });
}
