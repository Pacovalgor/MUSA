import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../modules/notes/models/note.dart';
import '../../modules/books/models/writing_settings.dart';

class _NoteRange {
  final int start;
  final int end;
  final Note note;
  _NoteRange(this.start, this.end, this.note);
}

class _IndexedNormalizedText {
  const _IndexedNormalizedText({
    required this.normalized,
    required this.indexMap,
  });

  final String normalized;
  final List<int> indexMap;
}

class MusaTextEditingController extends TextEditingController {
  MusaTextEditingController({
    super.text, 
    required this.writingSettings,
  });

  WritingSettings writingSettings;
  List<Note> activeNotes = [];
  void Function(String)? onNoteTap;

  void updateSettings(WritingSettings settings) {
    if (writingSettings == settings) return;
    writingSettings = settings;
    notifyListeners();
  }

  void updateNotes(List<Note> notes) {
    if (_sameNoteAnchors(activeNotes, notes)) return;
    activeNotes = List<Note>.unmodifiable(notes);
    notifyListeners();
  }

  bool _sameNoteAnchors(List<Note> a, List<Note> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.id != right.id ||
          left.anchorTextSnapshot != right.anchorTextSnapshot ||
          left.anchorStartOffset != right.anchorStartOffset ||
          left.anchorEndOffset != right.anchorEndOffset) {
        return false;
      }
    }
    return true;
  }

  void _addStyledSpan(
    List<InlineSpan> spans, 
    String chunk, 
    TextStyle style, 
    int startOffset,
    List<_NoteRange> noteRanges,
    Color noteMarkerColor,
  ) {
    if (chunk.isEmpty) return;
    int endOffset = startOffset + chunk.length;
    
    final overlappingNotes = noteRanges
        .where((nr) => nr.start < endOffset && nr.end > startOffset)
        .toList();
    
    if (overlappingNotes.isEmpty) {
      spans.add(TextSpan(text: chunk, style: style));
      return;
    }
    
    int currentOffset = startOffset;
    while (currentOffset < endOffset) {
      int nextBoundary = endOffset;
      Note? activeNote;
      
      for (final nr in overlappingNotes) {
        if (nr.start <= currentOffset && nr.end > currentOffset) {
          activeNote = nr.note;
          if (nr.end < nextBoundary) nextBoundary = nr.end;
        } else if (nr.start > currentOffset && nr.start < nextBoundary) {
          nextBoundary = nr.start;
        }
      }
      
      final subChunk = text.substring(currentOffset, nextBoundary);
      TextStyle finalStyle = style;
      
      if (activeNote != null && writingSettings.showNoteMarkers) {
        finalStyle = style.copyWith(
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: noteMarkerColor,
        );
      }
      
      spans.add(TextSpan(
        text: subChunk, 
        style: finalStyle, 
      ));
      
      currentOffset = nextBoundary;
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!writingSettings.enableBold && !writingSettings.enableItalics && !writingSettings.showNoteMarkers) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    // Default style
    final defaultStyle = style ?? const TextStyle();
    final tokens = Theme.of(context).extension<MusaThemeTokens>();
    final noteMarkerColor = (tokens?.warningText ?? defaultStyle.color ?? Colors.amber)
        .withValues(alpha: 0.78);

    // Visual styles for markdown markers
    final isVisualMode = writingSettings.formatRenderMode == FormatRenderMode.visual;
    
    // In visual mode, we make the asterisks virtually invisible but physically 
    // present so cursor navigation still works exactly the same in the raw text.
    final markerStyle = isVisualMode
        ? defaultStyle.copyWith(color: Colors.transparent, fontSize: 0.1)
        : defaultStyle.copyWith(color: defaultStyle.color?.withValues(alpha: 0.4));

    final boldStyle = defaultStyle.copyWith(fontWeight: FontWeight.bold);
    final italicStyle = defaultStyle.copyWith(fontStyle: FontStyle.italic);

    final List<InlineSpan> spans = [];
    
    final noteRanges = resolveAnchors()
        .where(
          (resolution) =>
              resolution.resolvedStartOffset != null &&
              resolution.resolvedEndOffset != null,
        )
        .map((resolution) {
          final note = activeNotes.firstWhere((item) => item.id == resolution.noteId);
          return _NoteRange(
            resolution.resolvedStartOffset!,
            resolution.resolvedEndOffset!,
            note,
          );
        })
        .toList();
    
    // Regex matches **bold**, then *italics*.
    final regex = RegExp(r'(\*\*[^\*]+\*\*)|(\*[^\*]+\*)');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        _addStyledSpan(spans, text.substring(lastMatchEnd, match.start), defaultStyle, lastMatchEnd, noteRanges, noteMarkerColor);
      }

      final matchedText = match.group(0)!;
      final isBold = matchedText.startsWith('**') && writingSettings.enableBold;
      final isItalic = !isBold && matchedText.startsWith('*') && writingSettings.enableItalics;
      
      if (isBold) {
        _addStyledSpan(spans, '**', markerStyle, match.start, noteRanges, noteMarkerColor);
        _addStyledSpan(spans, matchedText.substring(2, matchedText.length - 2), boldStyle, match.start + 2, noteRanges, noteMarkerColor);
        _addStyledSpan(spans, '**', markerStyle, match.end - 2, noteRanges, noteMarkerColor);
      } else if (isItalic) {
        _addStyledSpan(spans, '*', markerStyle, match.start, noteRanges, noteMarkerColor);
        _addStyledSpan(spans, matchedText.substring(1, matchedText.length - 1), italicStyle, match.start + 1, noteRanges, noteMarkerColor);
        _addStyledSpan(spans, '*', markerStyle, match.end - 1, noteRanges, noteMarkerColor);
      } else {
        _addStyledSpan(spans, matchedText, defaultStyle, match.start, noteRanges, noteMarkerColor);
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      _addStyledSpan(spans, text.substring(lastMatchEnd), defaultStyle, lastMatchEnd, noteRanges, noteMarkerColor);
    }

    // Add composing span support manually because we're overriding.
    if (withComposing && value.composing.isValid) {
       // While doing composing, Flutter recommends relying on super if doing complex stuff,
       // but for our simple text we just return the full spans. It works well enough in most desktop environments.
    }

    return TextSpan(style: defaultStyle, children: spans);
  }

  List<NoteAnchorResolution> resolveAnchors() {
    return activeNotes
        .where((note) => note.anchorTextSnapshot != null && note.anchorStartOffset != null)
        .map(_resolveAnchor)
        .toList(growable: false);
  }

  String? noteIdAtOffset(int offset, {int edgeTolerance = 1}) {
    final resolutions = resolveAnchors();

    for (final resolution in resolutions) {
      final start = resolution.resolvedStartOffset;
      final end = resolution.resolvedEndOffset;
      if (start == null || end == null) continue;
      if (offset >= start && offset < end) {
        return resolution.noteId;
      }
    }

    if (edgeTolerance <= 0) return null;

    String? closestNoteId;
    var closestDistance = edgeTolerance + 1;
    for (final resolution in resolutions) {
      final start = resolution.resolvedStartOffset;
      final end = resolution.resolvedEndOffset;
      if (start == null || end == null) continue;

      final distanceToStart = (offset - start).abs();
      final distanceToEnd = (offset - end).abs();
      final distance = distanceToStart < distanceToEnd
          ? distanceToStart
          : distanceToEnd;

      if (distance <= edgeTolerance && distance < closestDistance) {
        closestDistance = distance;
        closestNoteId = resolution.noteId;
      }
    }

    if (closestNoteId != null) return closestNoteId;

    for (final delta in [1, -1, 2, -2]) {
      final candidateOffset = offset + delta;
      if (candidateOffset < 0 || candidateOffset > text.length) continue;
      for (final resolution in resolutions) {
        final start = resolution.resolvedStartOffset;
        final end = resolution.resolvedEndOffset;
        if (start == null || end == null) continue;
        if (candidateOffset >= start && candidateOffset < end) {
          return resolution.noteId;
        }
      }
    }

    return null;
  }

  NoteAnchorResolution _resolveAnchor(Note note) {
    final snapshot = note.anchorTextSnapshot?.trim();
    if (snapshot == null || snapshot.isEmpty) {
      return NoteAnchorResolution(
        noteId: note.id,
        state: NoteAnchorState.detached,
      );
    }

    final anchorStart = note.anchorStartOffset ?? 0;
    final anchorEnd =
        note.anchorEndOffset ?? (anchorStart + snapshot.length).clamp(0, text.length);
    final localWindowStart = (anchorStart - 400).clamp(0, text.length).toInt();
    final localWindowEnd =
        (anchorEnd + 400).clamp(0, text.length).toInt();

    final exactIndex = _findExact(snapshot, localWindowStart, localWindowEnd) ??
        _findExact(snapshot, 0, text.length);
    if (exactIndex != null) {
      return NoteAnchorResolution(
        noteId: note.id,
        state: NoteAnchorState.exact,
        resolvedTextSnapshot: text.substring(
          exactIndex,
          exactIndex + snapshot.length,
        ),
        resolvedStartOffset: exactIndex,
        resolvedEndOffset: exactIndex + snapshot.length,
      );
    }

    final normalized = _findNormalized(snapshot, localWindowStart, localWindowEnd);
    if (normalized != null) {
      return NoteAnchorResolution(
        noteId: note.id,
        state: NoteAnchorState.fuzzy,
        resolvedTextSnapshot: text.substring(
          normalized.$1,
          normalized.$2,
        ),
        resolvedStartOffset: normalized.$1,
        resolvedEndOffset: normalized.$2,
      );
    }

    final fuzzy = _findFuzzy(snapshot, localWindowStart, localWindowEnd);
    if (fuzzy != null) {
      return NoteAnchorResolution(
        noteId: note.id,
        state: NoteAnchorState.fuzzy,
        resolvedTextSnapshot: text.substring(fuzzy.$1, fuzzy.$2),
        resolvedStartOffset: fuzzy.$1,
        resolvedEndOffset: fuzzy.$2,
      );
    }

    return NoteAnchorResolution(
      noteId: note.id,
      state: NoteAnchorState.detached,
    );
  }

  int? _findExact(String snapshot, int start, int end) {
    final window = text.substring(start, end);
    final match = window.indexOf(snapshot);
    if (match == -1) return null;
    return start + match;
  }

  (int, int)? _findNormalized(String snapshot, int start, int end) {
    final normalizedSnapshot = _normalizeWithIndex(snapshot);
    if (normalizedSnapshot.normalized.isEmpty) return null;
    final normalizedWindow = _normalizeWithIndex(text.substring(start, end));
    final match = normalizedWindow.normalized.indexOf(normalizedSnapshot.normalized);
    if (match == -1) return null;
    final originalStart = start + normalizedWindow.indexMap[match];
    final originalEnd =
        start + normalizedWindow.indexMap[match + normalizedSnapshot.normalized.length - 1] + 1;
    return (originalStart, originalEnd);
  }

  (int, int)? _findFuzzy(String snapshot, int start, int end) {
    final target = _normalizeForSimilarity(snapshot);
    if (target.isEmpty) return null;

    final window = text.substring(start, end);
    final boundaries = <int>[0];
    for (var i = 1; i < window.length; i++) {
      final previous = window.codeUnitAt(i - 1);
      final current = window.codeUnitAt(i);
      final startsWord = _isBoundary(previous) && !_isBoundary(current);
      if (startsWord) boundaries.add(i);
    }

    var bestScore = 0.0;
    (int, int)? bestRange;
    final targetLength = snapshot.length.clamp(24, 220);
    for (final localStart in boundaries.take(160)) {
      final remainingLength = window.length - localStart;
      if (remainingLength <= 0) continue;
      for (final factor in const [0.7, 1.0, 1.35]) {
        final minimumLength = remainingLength < 16 ? 1 : 16;
        final candidateLength =
            (targetLength * factor).round().clamp(minimumLength, remainingLength);
        final localEnd =
            (localStart + candidateLength).clamp(localStart + 1, window.length);
        final candidate = window.substring(localStart, localEnd).trim();
        if (candidate.isEmpty) continue;
        final score = _similarityScore(target, _normalizeForSimilarity(candidate));
        if (score > bestScore) {
          bestScore = score;
          final globalStart = start + localStart;
          final globalEnd = globalStart + candidate.length;
          bestRange = (globalStart, globalEnd);
        }
      }
    }

    if (bestScore < 0.72 || bestRange == null) return null;
    return bestRange;
  }

  _IndexedNormalizedText _normalizeWithIndex(String source) {
    final buffer = StringBuffer();
    final indexMap = <int>[];
    var lastWasSpace = false;
    for (var i = 0; i < source.length; i++) {
      final code = source.codeUnitAt(i);
      if (_isWhitespace(code)) {
        if (buffer.isEmpty || lastWasSpace) continue;
        buffer.write(' ');
        indexMap.add(i);
        lastWasSpace = true;
        continue;
      }
      buffer.write(String.fromCharCode(code).toLowerCase());
      indexMap.add(i);
      lastWasSpace = false;
    }
    final normalized = buffer.toString();
    var trimStart = 0;
    var trimEnd = normalized.length;
    while (trimStart < trimEnd && normalized[trimStart] == ' ') {
      trimStart++;
    }
    while (trimEnd > trimStart && normalized[trimEnd - 1] == ' ') {
      trimEnd--;
    }
    return _IndexedNormalizedText(
      normalized: normalized.substring(trimStart, trimEnd),
      indexMap: indexMap.sublist(trimStart, trimEnd),
    );
  }

  String _normalizeForSimilarity(String input) {
    final lowercase = input.toLowerCase();
    final stripped = lowercase.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');
    return stripped.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  double _similarityScore(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    final wordScore = _diceCoefficient(a.split(' '), b.split(' '));
    final trigramScore = _diceCoefficient(_trigrams(a), _trigrams(b));
    return (wordScore * 0.65) + (trigramScore * 0.35);
  }

  double _diceCoefficient(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final counts = <String, int>{};
    for (final item in a) {
      counts[item] = (counts[item] ?? 0) + 1;
    }
    var overlap = 0;
    for (final item in b) {
      final count = counts[item] ?? 0;
      if (count > 0) {
        overlap++;
        counts[item] = count - 1;
      }
    }
    return (2 * overlap) / (a.length + b.length);
  }

  List<String> _trigrams(String input) {
    if (input.length < 3) return [input];
    final trigrams = <String>[];
    for (var i = 0; i <= input.length - 3; i++) {
      trigrams.add(input.substring(i, i + 3));
    }
    return trigrams;
  }

  bool _isWhitespace(int codeUnit) =>
      codeUnit == 32 || codeUnit == 10 || codeUnit == 13 || codeUnit == 9;

  bool _isBoundary(int codeUnit) =>
      _isWhitespace(codeUnit) ||
      codeUnit == 46 ||
      codeUnit == 44 ||
      codeUnit == 59 ||
      codeUnit == 58 ||
      codeUnit == 33 ||
      codeUnit == 63 ||
      codeUnit == 40 ||
      codeUnit == 41 ||
      codeUnit == 91 ||
      codeUnit == 93 ||
      codeUnit == 123 ||
      codeUnit == 125 ||
      codeUnit == 34;
}
