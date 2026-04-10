import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../modules/books/models/book.dart';
import '../../modules/manuscript/models/document.dart';

final printServiceProvider = Provider<PrintService>((ref) {
  return const PrintService();
});

class PrintException implements Exception {
  const PrintException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PrintService {
  const PrintService();

  Future<void> printChapter({
    required Book book,
    required Document document,
  }) async {
    final trimmedContent = document.content.trim();
    if (trimmedContent.isEmpty) {
      throw const PrintException('Este capitulo esta vacio.');
    }

    final bytes = await _buildChapterPdf(
      format: PdfPageFormat.a4,
      book: book,
      document: document,
    );

    await Printing.layoutPdf(
      name: _safeFileName('${book.title} - ${document.title}'),
      format: PdfPageFormat.a4,
      dynamicLayout: false,
      onLayout: (_) async => bytes,
    );
  }

  Future<void> printBook({
    required Book book,
    required List<Document> documents,
  }) async {
    final printableDocuments = _printableDocuments(documents);
    if (printableDocuments.isEmpty) {
      throw const PrintException(
        'Este libro no tiene capitulos o escenas con contenido para imprimir.',
      );
    }

    final bytes = await _buildBookPdf(
      format: PdfPageFormat.a4,
      book: book,
      documents: printableDocuments,
    );

    await Printing.layoutPdf(
      name: _safeFileName(book.title),
      format: PdfPageFormat.a4,
      dynamicLayout: false,
      onLayout: (_) async => bytes,
    );
  }

  Future<void> printChapterBooklet({
    required Book book,
    required Document document,
  }) async {
    final trimmedContent = document.content.trim();
    if (trimmedContent.isEmpty) {
      throw const PrintException('Este capitulo esta vacio.');
    }

    final source = await _buildChapterPdf(
      format: PdfPageFormat.a5,
      book: book,
      document: document,
    );
    final booklet = await _buildBookletPdf(
      source,
      title: document.title,
      documentName: book.title,
    );

    await Printing.layoutPdf(
      name: _safeFileName('${book.title} - ${document.title} - cuadernillo'),
      format: PdfPageFormat.a4.landscape,
      dynamicLayout: false,
      onLayout: (_) async => booklet,
    );
  }

  Future<void> printBookBooklet({
    required Book book,
    required List<Document> documents,
  }) async {
    final printableDocuments = _printableDocuments(documents);
    if (printableDocuments.isEmpty) {
      throw const PrintException(
        'Este libro no tiene capitulos o escenas con contenido para imprimir.',
      );
    }

    final source = await _buildBookPdf(
      format: PdfPageFormat.a5,
      book: book,
      documents: printableDocuments,
    );
    final booklet = await _buildBookletPdf(
      source,
      title: book.title,
      documentName: book.title,
    );

    await Printing.layoutPdf(
      name: _safeFileName('${book.title} - cuadernillo'),
      format: PdfPageFormat.a4.landscape,
      dynamicLayout: false,
      onLayout: (_) async => booklet,
    );
  }

  Future<Uint8List> _buildChapterPdf({
    required PdfPageFormat format,
    required Book book,
    required Document document,
  }) async {
    final fonts = await _pdfFonts;
    final pdf = pw.Document(
      title: document.title,
      author: 'MUSA',
      subject: book.title,
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(format, fonts),
        header: (context) => _runningHeader(
          label: book.title,
          title: document.title,
          pageNumber: context.pageNumber,
          fonts: fonts,
        ),
        build: (context) => [
          _chapterHeading(document.title, fonts),
          pw.SizedBox(height: 24),
          ..._paragraphWidgets(document.content, fonts),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _buildBookPdf({
    required PdfPageFormat format,
    required Book book,
    required List<Document> documents,
  }) async {
    final fonts = await _pdfFonts;
    final pdf = pw.Document(
      title: book.title,
      author: 'MUSA',
      subject: 'Libro',
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(format, fonts),
        build: (context) => [
          pw.SizedBox(height: 48),
          pw.Text(
            book.title,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 28,
            ),
          ),
          if ((book.subtitle ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              book.subtitle!.trim(),
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 16,
                color: PdfColors.grey700,
              ),
            ),
          ],
          if (book.summary.trim().isNotEmpty) ...[
            pw.SizedBox(height: 28),
            ..._paragraphWidgets(
              book.summary.trim(),
              fonts,
              fontSize: 12,
              lineSpacing: 4,
              color: PdfColors.grey800,
              bottomSpacing: 10,
            ),
          ],
        ],
      ),
    );

    for (var index = 0; index < documents.length; index++) {
      final document = documents[index];
      pdf.addPage(
        pw.MultiPage(
          pageTheme: _pageTheme(format, fonts),
          header: (context) => _runningHeader(
            label: book.title,
            title: document.title,
            pageNumber: context.pageNumber,
            fonts: fonts,
          ),
          build: (context) => [
            if (index > 0) pw.SizedBox(height: 8),
            _chapterHeading(document.title, fonts),
            pw.SizedBox(height: 24),
            ..._paragraphWidgets(document.content, fonts),
          ],
        ),
      );
    }

    return pdf.save();
  }

  Future<Uint8List> _buildBookletPdf(
    Uint8List sourcePdf, {
    required String title,
    required String documentName,
  }) async {
    final fonts = await _pdfFonts;
    final rasterPages = <Uint8List>[];
    await for (final page in Printing.raster(
      sourcePdf,
      pages: null,
      dpi: 144,
    )) {
      rasterPages.add(await page.toPng());
    }

    if (rasterPages.isEmpty) {
      throw const PrintException(
          'No hay paginas suficientes para el cuadernillo.');
    }

    final paddedCount = ((rasterPages.length + 3) ~/ 4) * 4;
    final paddedPages = List<Uint8List?>.from(rasterPages);
    while (paddedPages.length < paddedCount) {
      paddedPages.add(null);
    }

    final pdf = pw.Document(
      title: '$title · cuadernillo',
      author: 'MUSA',
      subject: documentName,
    );

    final pageFormat = PdfPageFormat.a4.landscape;
    final sheetCount = paddedCount ~/ 4;
    for (var sheet = 0; sheet < sheetCount; sheet++) {
      final frontLeft = paddedPages[paddedCount - 1 - (sheet * 2)];
      final frontRight = paddedPages[sheet * 2];
      pdf.addPage(
        _bookletSheet(
          pageFormat: pageFormat,
          label: '$documentName · cuadernillo',
          leftPage: frontLeft,
          rightPage: frontRight,
          fonts: fonts,
        ),
      );

      final backLeft = paddedPages[(sheet * 2) + 1];
      final backRight = paddedPages[paddedCount - 2 - (sheet * 2)];
      pdf.addPage(
        _bookletSheet(
          pageFormat: pageFormat,
          label: '$documentName · cuadernillo',
          leftPage: backLeft,
          rightPage: backRight,
          rotateSheet: true,
          fonts: fonts,
        ),
      );
    }

    return pdf.save();
  }

  pw.PageTheme _pageTheme(PdfPageFormat format, _PdfFonts fonts) {
    final isA5 = format.width <= PdfPageFormat.a5.width + 0.1 &&
        format.height <= PdfPageFormat.a5.height + 0.1;

    return pw.PageTheme(
      pageFormat: format,
      margin: isA5
          ? const pw.EdgeInsets.fromLTRB(30, 32, 30, 34)
          : const pw.EdgeInsets.fromLTRB(54, 56, 54, 56),
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
        italic: fonts.italic,
        boldItalic: fonts.boldItalic,
      ),
    );
  }

  pw.Page _bookletSheet({
    required PdfPageFormat pageFormat,
    required String label,
    required Uint8List? leftPage,
    required Uint8List? rightPage,
    required _PdfFonts fonts,
    bool rotateSheet = false,
  }) {
    return pw.Page(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.fromLTRB(10, 10, 10, 10),
      build: (context) {
        final content = pw.Column(
          children: [
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Expanded(child: _bookletSlot(leftPage)),
                  pw.Container(
                    width: 1,
                    margin: const pw.EdgeInsets.symmetric(horizontal: 6),
                    color: PdfColors.grey300,
                  ),
                  pw.Expanded(child: _bookletSlot(rightPage)),
                ],
              ),
            ),
          ],
        );

        if (!rotateSheet) return content;
        return pw.Transform.rotateBox(angle: math.pi, child: content);
      },
    );
  }

  pw.Widget _bookletSlot(Uint8List? pageBytes) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      padding: const pw.EdgeInsets.all(2),
      child: pageBytes == null
          ? pw.SizedBox.expand()
          : pw.FittedBox(
              fit: pw.BoxFit.contain,
              child: pw.Image(pw.MemoryImage(pageBytes)),
            ),
    );
  }

  pw.Widget _runningHeader({
    required String label,
    required String title,
    required int pageNumber,
    required _PdfFonts fonts,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 24),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.6),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              '$label · $title',
              maxLines: 1,
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Text(
            '$pageNumber',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _chapterHeading(String title, _PdfFonts fonts) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        font: fonts.bold,
        fontSize: 20,
      ),
    );
  }

  List<pw.Widget> _paragraphWidgets(
    String content,
    _PdfFonts fonts, {
    double fontSize = 12.5,
    double lineSpacing = 5,
    PdfColor color = PdfColors.grey900,
    double bottomSpacing = 14,
  }) {
    return _paragraphsFromContent(content)
        .map(
          (paragraph) => pw.Padding(
            padding: pw.EdgeInsets.only(bottom: bottomSpacing),
            child: pw.Text(
              paragraph,
              textAlign: pw.TextAlign.justify,
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: fontSize,
                lineSpacing: lineSpacing,
                color: color,
              ),
            ),
          ),
        )
        .toList();
  }

  List<Document> _printableDocuments(List<Document> documents) {
    final proseDocuments = documents
        .where(
          (document) =>
              (document.kind == DocumentKind.chapter ||
                  document.kind == DocumentKind.scene) &&
              document.content.trim().isNotEmpty,
        )
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    if (proseDocuments.isNotEmpty) return proseDocuments;

    return documents
        .where((document) => document.content.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  List<String> _paragraphsFromContent(String content) {
    return content
        .split(RegExp(r'\n\s*\n'))
        .map((paragraph) => paragraph.replaceAll(RegExp(r'\n+'), ' ').trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .expand(_splitParagraphForPdf)
        .toList();
  }

  Iterable<String> _splitParagraphForPdf(String paragraph) sync* {
    const maxChunkLength = 520;
    if (paragraph.length <= maxChunkLength) {
      yield paragraph;
      return;
    }

    final sentences = paragraph
        .split(RegExp(r'(?<=[.!?…])\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (sentences.isEmpty) {
      yield* _splitLongRun(paragraph, maxChunkLength);
      return;
    }

    final buffer = StringBuffer();
    for (final sentence in sentences) {
      if (sentence.length > maxChunkLength) {
        if (buffer.isNotEmpty) {
          yield buffer.toString().trim();
          buffer.clear();
        }
        yield* _splitLongRun(sentence, maxChunkLength);
        continue;
      }

      final nextLength = buffer.isEmpty
          ? sentence.length
          : buffer.length + 1 + sentence.length;
      if (nextLength > maxChunkLength && buffer.isNotEmpty) {
        yield buffer.toString().trim();
        buffer.clear();
      }

      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write(sentence);
    }

    if (buffer.isNotEmpty) {
      yield buffer.toString().trim();
    }
  }

  Iterable<String> _splitLongRun(String text, int maxChunkLength) sync* {
    final clauses = text
        .split(RegExp(r'(?<=[,;:])\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (clauses.length > 1) {
      final buffer = StringBuffer();
      for (final clause in clauses) {
        final nextLength =
            buffer.isEmpty ? clause.length : buffer.length + 1 + clause.length;
        if (nextLength > maxChunkLength && buffer.isNotEmpty) {
          yield buffer.toString().trim();
          buffer.clear();
        }
        if (buffer.isNotEmpty) {
          buffer.write(' ');
        }
        buffer.write(clause);
      }
      if (buffer.isNotEmpty) {
        yield buffer.toString().trim();
      }
      return;
    }

    final words = text.split(RegExp(r'\s+'));
    final buffer = StringBuffer();
    for (final word in words) {
      if (word.isEmpty) continue;
      final nextLength =
          buffer.isEmpty ? word.length : buffer.length + 1 + word.length;
      if (nextLength > maxChunkLength && buffer.isNotEmpty) {
        yield buffer.toString().trim();
        buffer.clear();
      }
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write(word);
    }
    if (buffer.isNotEmpty) {
      yield buffer.toString().trim();
    }
  }

  String _safeFileName(String value) {
    final normalized = value.trim().isEmpty ? 'musa' : value.trim();
    return normalized.replaceAll(RegExp(r'[\\\\/:*?"<>|]+'), '-');
  }
}

final Future<_PdfFonts> _pdfFonts = (() async {
  try {
    final regular = await PdfGoogleFonts.notoSerifRegular();
    final bold = await PdfGoogleFonts.notoSerifBold();
    final italic = await PdfGoogleFonts.notoSerifItalic();
    final boldItalic = await PdfGoogleFonts.notoSerifBoldItalic();
    return _PdfFonts(
      regular: regular,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
    );
  } catch (_) {
    return _PdfFonts(
      regular: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      italic: pw.Font.helveticaOblique(),
      boldItalic: pw.Font.helveticaBoldOblique(),
    );
  }
})();

class _PdfFonts {
  const _PdfFonts({
    required this.regular,
    required this.bold,
    required this.italic,
    required this.boldItalic,
  });

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font italic;
  final pw.Font boldItalic;
}
