// Test diagnóstico (no de regresión): lee EPUBs en test/fixtures/, ejecuta
// el pipeline de análisis narrativo y vuelca un report markdown por libro.
// Se salta automáticamente si los EPUBs no están presentes (no rompe CI).
//
// Para ejecutar:
//   flutter test test/diagnostic/analyze_epub_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musa/editor/models/chapter_analysis.dart';
import 'package:musa/editor/models/fragment_analysis.dart';
import 'package:musa/editor/services/chapter_analysis_service.dart';
import 'package:musa/editor/services/fragment_analysis_service.dart';
import 'package:musa/modules/books/models/book.dart';
import 'package:musa/modules/books/models/narrative_copilot.dart';
import 'package:musa/modules/books/services/narrative_memory_updater.dart';
import 'package:musa/modules/books/services/story_state_updater.dart';
import 'package:musa/modules/manuscript/models/document.dart';

const _chapterAnalysisService = ChapterAnalysisService();
const _fragmentAnalysisService = FragmentAnalysisService();
const _memoryUpdater = NarrativeMemoryUpdater();
const _stateUpdater = StoryStateUpdater();

void main() {
  group('Diagnóstico EPUB', () {
    final cases = <_BookCase>[
      _BookCase('test/fixtures/libro1.epub', BookPrimaryGenre.fantasy),
      _BookCase('test/fixtures/libro2.epub', BookPrimaryGenre.thriller),
      _BookCase('test/fixtures/libro3.epub', BookPrimaryGenre.historical),
    ];

    for (final c in cases) {
      test('analiza ${c.path}', () {
        final file = File(c.path);
        if (!file.existsSync()) {
          markTestSkipped('${c.path} no existe; salta');
          return;
        }
        _runAnalysis(file, c.genre);
      });
    }
  });
}

void _runAnalysis(File epub, BookPrimaryGenre genre) {
  final extracted = _extractEpub(epub);
  final metadata = _parseMetadata(extracted);
  final chapters = _extractChapters(extracted);

  expect(chapters, isNotEmpty,
      reason: 'No se detectaron capítulos en ${epub.path}');

  // Muestreo: 3 capítulos representativos (apertura / medio / cierre).
  // Suficiente para diagnosticar detección sin pasar el libro entero.
  final sampled = _sampleChapters(chapters);

  final book = Book(
    id: 'fixture-${_basename(epub.path)}',
    title: metadata['title'] ?? _basename(epub.path),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    summary: metadata['description'] ?? '',
    narrativeProfile: BookNarrativeProfile(
      primaryGenre: genre,
      readerPromise: 'Análisis diagnóstico de muestra',
    ),
  );

  final report = StringBuffer();
  _writeHeader(report, book, metadata, genre, chapters, sampled);

  final basename = _basename(epub.path);
  // Volcar el texto de los capítulos muestreados para que un revisor pueda
  // cruzar lo detectado con el material real.
  for (final entry in sampled) {
    final out = 'test/fixtures/$basename-cap${entry.key.toString().padLeft(2, '0')}.txt';
    File(out).writeAsStringSync(entry.value.text);
  }

  final accumulatedDocs = <Document>[];
  final now = DateTime.now();
  StoryState? previousState;

  for (final entry in sampled) {
    final i = entry.key;
    final chapter = entry.value;
    final document = Document(
      id: 'cap-${i.toString().padLeft(2, '0')}',
      bookId: book.id,
      title: chapter.title,
      kind: DocumentKind.chapter,
      orderIndex: i,
      content: chapter.text,
      wordCount: _countWords(chapter.text),
      createdAt: now,
      updatedAt: now,
    );
    accumulatedDocs.add(document);

    final chapterAnalysis = _chapterAnalysisService.analyze(
      chapterText: chapter.text,
      characters: const [],
      scenarios: const [],
      linkedCharacterIds: const [],
      linkedScenarioIds: const [],
    );
    final memory = _memoryUpdater.update(
      bookId: book.id,
      documents: accumulatedDocs,
      previous: null,
      now: now,
    );
    final state = _stateUpdater.update(
      book: book,
      documents: accumulatedDocs,
      memory: memory,
      previous: previousState,
      now: now,
    );

    final fragmentAnalysis = _fragmentAnalysisService.analyze(
      selection: _firstParagraphs(chapter.text, 3),
      characters: const [],
      scenarios: const [],
      linkedCharacterIds: const [],
      linkedScenarioIds: const [],
    );

    _writeChapterSection(
      report,
      i,
      chapter,
      document,
      chapterAnalysis,
      fragmentAnalysis,
      memory,
      state,
    );

    previousState = state;
  }

  _writeFooter(report, book, accumulatedDocs, previousState);

  final outPath = 'test/fixtures/report-${_basename(epub.path)}.md';
  File(outPath).writeAsStringSync(report.toString());
  // ignore: avoid_print
  print('  → $outPath');
}

// ─── EPUB extraction ──────────────────────────────────────────────────

class _BookCase {
  final String path;
  final BookPrimaryGenre genre;
  _BookCase(this.path, this.genre);
}

class _ExtractedEpub {
  final Map<String, String> textFiles;
  final String? opfContent;
  _ExtractedEpub(this.textFiles, this.opfContent);
}

_ExtractedEpub _extractEpub(File epub) {
  final archive = ZipDecoder().decodeBytes(epub.readAsBytesSync());
  final textFiles = <String, String>{};
  String? opfContent;
  for (final entry in archive) {
    if (!entry.isFile) continue;
    final name = entry.name;
    if (name.endsWith('.xhtml') || name.endsWith('.html')) {
      textFiles[name] =
          utf8.decode(entry.content as List<int>, allowMalformed: true);
    }
    if (name.endsWith('.opf')) {
      opfContent =
          utf8.decode(entry.content as List<int>, allowMalformed: true);
    }
  }
  return _ExtractedEpub(textFiles, opfContent);
}

Map<String, String> _parseMetadata(_ExtractedEpub extracted) {
  final result = <String, String>{};
  final opf = extracted.opfContent;
  if (opf == null) return result;
  for (final field in ['title', 'creator', 'subject', 'language']) {
    final pattern =
        RegExp(r'<dc:' + field + r'[^>]*>([^<]+)<', dotAll: true);
    final match = pattern.firstMatch(opf);
    if (match != null) result[field] = match.group(1)!.trim();
  }
  final desc = RegExp(r'<dc:description[^>]*>([^<]+)<', dotAll: true)
      .firstMatch(opf);
  if (desc != null) {
    result['description'] = _stripHtml(desc.group(1)!).trim();
  }
  return result;
}

class _Chapter {
  final String filename;
  final String title;
  final String text;
  _Chapter(this.filename, this.title, this.text);
}

/// Muestra 3 capítulos representativos: primero, mitad, último. Cada
/// elemento es (índice 0-based original, capítulo).
List<MapEntry<int, _Chapter>> _sampleChapters(List<_Chapter> chapters) {
  if (chapters.length <= 3) {
    return [
      for (var i = 0; i < chapters.length; i++) MapEntry(i, chapters[i]),
    ];
  }
  final mid = chapters.length ~/ 2;
  final last = chapters.length - 1;
  return <MapEntry<int, _Chapter>>[
    MapEntry(0, chapters[0]),
    MapEntry(mid, chapters[mid]),
    MapEntry(last, chapters[last]),
  ];
}

List<_Chapter> _extractChapters(_ExtractedEpub extracted) {
  final chapters = <_Chapter>[];
  final entries = extracted.textFiles.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  for (final entry in entries) {
    final text = _stripHtml(entry.value).trim();
    if (_countWords(text) < 400) continue;
    final title = _extractTitle(entry.value, entry.key);
    chapters.add(_Chapter(entry.key, title, text));
  }
  return chapters;
}

String _extractTitle(String html, String fallback) {
  final h1 = RegExp(r'<h[12][^>]*>([^<]+)<', dotAll: true).firstMatch(html);
  if (h1 != null) {
    final t = _decodeEntities(h1.group(1)!).trim();
    if (t.isNotEmpty && t.length < 80) return t;
  }
  return fallback.split('/').last.replaceAll(RegExp(r'\.x?html$'), '');
}

String _stripHtml(String html) {
  var s = html;
  s = s.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
  s = s.replaceAll(RegExp(r'<br[^>]*>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n');
  s = s.replaceAll(RegExp(r'<[^>]+>'), '');
  s = _decodeEntities(s);
  s = s.replaceAll(RegExp(r'[ \t]+'), ' ');
  s = s.replaceAll(RegExp(r'\n[ \t]+'), '\n');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return s;
}

String _decodeEntities(String s) {
  return s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#160;', ' ')
      .replaceAll('&laquo;', '«')
      .replaceAll('&raquo;', '»')
      .replaceAll('&mdash;', '—')
      .replaceAll('&ndash;', '–')
      .replaceAll('&hellip;', '…')
      .replaceAll('&iexcl;', '¡')
      .replaceAll('&iquest;', '¿');
}

int _countWords(String text) {
  return RegExp(r'[A-Za-zÁÉÍÓÚÑáéíóúñü]+').allMatches(text).length;
}

String _firstParagraphs(String text, int n) {
  final parts = text.split('\n\n');
  return parts.take(n).join('\n\n');
}

String _basename(String path) {
  final base = path.split('/').last;
  return base.replaceAll(RegExp(r'\.epub$'), '');
}

// ─── Report writing ───────────────────────────────────────────────────

void _writeHeader(
  StringBuffer report,
  Book book,
  Map<String, String> metadata,
  BookPrimaryGenre genre,
  List<_Chapter> allChapters,
  List<MapEntry<int, _Chapter>> sampled,
) {
  report.writeln('# Análisis MUSA: ${book.title}');
  report.writeln();
  report.writeln('**Autor**: ${metadata['creator'] ?? '?'}  ');
  report.writeln('**Subject**: ${metadata['subject'] ?? '?'}  ');
  report.writeln('**Idioma**: ${metadata['language'] ?? '?'}  ');
  report.writeln('**Género asignado**: ${genre.name}  ');
  report.writeln('**Capítulos totales**: ${allChapters.length}  ');
  report.writeln(
      '**Muestreados (apertura/medio/cierre)**: ${sampled.map((e) => e.key + 1).join(", ")}  ');
  final totalWords = allChapters
      .map((c) => _countWords(c.text))
      .fold<int>(0, (a, b) => a + b);
  report.writeln('**Palabras totales (aprox)**: $totalWords  ');
  if (metadata['description'] != null) {
    report.writeln();
    report.writeln('> ${metadata['description']!.split('\n').join('\n> ')}');
  }
  report.writeln();
  report.writeln('---');
  report.writeln();
}

void _writeChapterSection(
  StringBuffer report,
  int index,
  _Chapter chapter,
  Document document,
  ChapterAnalysis chapterAnalysis,
  FragmentAnalysis fragmentAnalysis,
  NarrativeMemory memory,
  StoryState state,
) {
  report.writeln('## Cap ${index + 1} · ${chapter.title}');
  report.writeln();
  report.writeln(
      '- archivo: `${chapter.filename}` · ${document.wordCount} palabras');
  report.writeln(
      '- tensión global tras este cap: **${state.globalTension}** · ritmo: ${state.perceivedRhythm.name} · acto: ${state.currentAct.name}');
  report.writeln(
      '- función capítulo: **${chapterAnalysis.chapterFunction.name}** · momento dominante: ${chapterAnalysis.dominantNarrativeMoment.title}');
  report.writeln('- protagonista state: "${state.protagonistState}"');
  report.writeln();

  final chars = chapterAnalysis.mainCharacters;
  if (chars.isNotEmpty) {
    report.writeln('**Personajes (chapter-level):**');
    for (final c in chars) {
      report.writeln(
          '- `${c.name}` · strength=${c.strengthScore}, relevance=${c.relevanceScore}');
    }
  } else {
    report.writeln('**Personajes (chapter-level):** _ninguno_');
  }
  report.writeln();

  final mainScenario = chapterAnalysis.mainScenario;
  if (mainScenario != null) {
    report.writeln(
        '**Escenario principal:** `${mainScenario.name}` (strength=${mainScenario.strengthScore}) — ${mainScenario.summary}');
  } else {
    report.writeln('**Escenario principal:** _no detectado_');
  }
  report.writeln();

  final rec = chapterAnalysis.recommendation;
  if (rec != null) {
    report.writeln('**Recomendación capítulo:** ${rec.message}');
  }
  report.writeln();

  report.writeln('**Análisis del primer fragmento:**');
  final f = fragmentAnalysis;
  report.writeln(
      '- narrador: ${f.narrator?.title ?? "—"} (${f.narrator?.summary ?? "—"})');
  if (f.characters.isNotEmpty) {
    report.write('- personajes: ');
    report.writeln(
        f.characters.map((c) => '`${c.name}`(${c.strengthScore})').join(', '));
  }
  final fScenario = f.scenario;
  if (fScenario != null) {
    report.writeln(
        '- escenario: `${fScenario.name}` (${fScenario.strengthScore})');
  }
  report.writeln('- momento: ${f.moment.title} — ${f.moment.summary}');
  final fRec = f.recommendation;
  if (fRec != null) {
    report.writeln('- CTA: ${fRec.action.label} (${fRec.reason})');
  }
  report.writeln();

  report.writeln('**Memoria acumulada:**');
  report.writeln('- amenazas activas: ${memory.activeThreats.length}');
  report.writeln('- preguntas abiertas: ${memory.openQuestions.length}');
  report.writeln('- pistas plantadas: ${memory.plantedClues.length}');
  report.writeln('- hechos importantes: ${memory.importantFacts.length}');
  report.writeln(
      '- shifts de personaje: ${memory.recentCharacterShifts.length}');

  if (state.diagnostics.isNotEmpty) {
    report.writeln();
    report.writeln('**Diagnostics:**');
    for (final d in state.diagnostics) {
      report.writeln('- $d');
    }
  }

  if (state.nextBestMove.isNotEmpty) {
    report.writeln();
    report.writeln('**Next best move:** ${state.nextBestMove}');
    if (state.nextBestMoveReason.isNotEmpty) {
      report.writeln('  · razón: ${state.nextBestMoveReason}');
    }
  }
  report.writeln();
  report.writeln('---');
  report.writeln();
}

void _writeFooter(
  StringBuffer report,
  Book book,
  List<Document> documents,
  StoryState? finalState,
) {
  if (finalState == null) return;
  report.writeln('## Resumen final');
  report.writeln();
  report.writeln('- tensión global final: **${finalState.globalTension}**');
  report.writeln('- ritmo percibido: ${finalState.perceivedRhythm.name}');
  report.writeln('- acto: ${finalState.currentAct.name}');
  report.writeln(
      '- función del último capítulo: ${finalState.currentChapterFunction.name}');
  if (finalState.recentKeyEvents.isNotEmpty) {
    report.writeln();
    report.writeln('**Eventos clave acumulados:**');
    for (final e in finalState.recentKeyEvents) {
      report.writeln('- $e');
    }
  }
  if (finalState.diagnostics.isNotEmpty) {
    report.writeln();
    report.writeln('**Últimos diagnósticos:**');
    for (final d in finalState.diagnostics) {
      report.writeln('- $d');
    }
  }
}
