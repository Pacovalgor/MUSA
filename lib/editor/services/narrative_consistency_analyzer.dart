/// Analyzes narrative consistency issues: POV shifts, tone changes, plot jumps, dialogue integrity.
class NarrativeConsistencyAnalyzer {
  NarrativeConsistencyAnalyzer();

  /// Detects point-of-view shifts (1st person → 3rd person, etc).
  /// Returns list of POV inconsistencies with locations.
  POVAnalysis analyzePOV(String content) {
    final lines = content.split('\n');
    final issues = <POVIssue>[];

    String? currentPOV;
    int? firstPOVLine;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line.trim().isEmpty) continue;

      final detectedPOV = _detectPOV(line);
      if (detectedPOV != null) {
        if (currentPOV == null) {
          currentPOV = detectedPOV;
          firstPOVLine = i;
        } else if (currentPOV != detectedPOV) {
          issues.add(POVIssue(
            lineNumber: i,
            from: currentPOV,
            to: detectedPOV,
            context: line.substring(0, (line.length).clamp(0, 60)),
          ));
          currentPOV = detectedPOV;
        }
      }
    }

    return POVAnalysis(
      dominantPOV: currentPOV,
      inconsistencies: issues,
      isConsistent: issues.isEmpty,
    );
  }

  /// Detects abrupt tone changes (formal → casual, serious → humorous, etc).
  ToneAnalysis analyzeTone(String content) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return ToneAnalysis(
        dominantTone: 'unknown',
        toneShifts: [],
        isConsistent: true,
      );
    }

    final issues = <ToneShift>[];
    String? currentTone;

    for (int i = 0; i < lines.length; i++) {
      final tone = _detectTone(lines[i]);
      if (tone != null) {
        if (currentTone != null && currentTone != tone) {
          issues.add(ToneShift(
            lineNumber: i,
            from: currentTone,
            to: tone,
            confidence: _computeToneConfidence(lines[i]),
          ));
        }
        currentTone = tone;
      }
    }

    return ToneAnalysis(
      dominantTone: currentTone ?? 'unknown',
      toneShifts: issues,
      isConsistent: issues.isEmpty,
    );
  }

  /// Detects narrative jumps: time leaps, location changes, plot gaps.
  NarrativeJumpAnalysis analyzeNarrativeJumps(String content) {
    final sentences = content
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (sentences.length < 2) {
      return NarrativeJumpAnalysis(
        jumps: [],
        hasTemporalGaps: false,
        hasSpatialGaps: false,
      );
    }

    final jumps = <NarrativeJump>[];
    String? lastLocation;
    String? lastTime;

    for (int i = 0; i < sentences.length - 1; i++) {
      final current = sentences[i];
      final next = sentences[i + 1];

      final currentLocation = _extractLocation(current);
      final nextLocation = _extractLocation(next);

      if (currentLocation != null &&
          nextLocation != null &&
          currentLocation != nextLocation) {
        jumps.add(NarrativeJump(
          type: 'spatial',
          sentenceIndex: i,
          from: currentLocation,
          to: nextLocation,
        ));
      }

      final currentTime = _extractTime(current);
      final nextTime = _extractTime(next);

      if (currentTime != null &&
          nextTime != null &&
          _isTemporallyDistant(currentTime, nextTime)) {
        jumps.add(NarrativeJump(
          type: 'temporal',
          sentenceIndex: i,
          from: currentTime,
          to: nextTime,
        ));
      }
    }

    final hasTemporal = jumps.any((j) => j.type == 'temporal');
    final hasSpatial = jumps.any((j) => j.type == 'spatial');

    return NarrativeJumpAnalysis(
      jumps: jumps,
      hasTemporalGaps: hasTemporal,
      hasSpatialGaps: hasSpatial,
    );
  }

  /// Detects dialogue integrity issues: unclosed dialogue, mismatched speakers.
  DialogueIntegrityAnalysis analyzeDialogue(String content) {
    final lines = content.split('\n');
    final issues = <DialogueIssue>[];

    int openQuoteCount = 0;
    String? lastSpeaker;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Count unescaped quotes
      openQuoteCount += _countUnescapedQuotes(line);

      if (openQuoteCount % 2 != 0 && i < lines.length - 1) {
        // Check if next line continues dialogue
        final nextLine = lines[i + 1];
        if (!_looksLikeDialogueContinuation(nextLine)) {
          issues.add(DialogueIssue(
            type: 'unclosed',
            lineNumber: i,
            context: line.substring(0, (line.length).clamp(0, 60)),
          ));
        }
      }

      // Detect dialogue speaker patterns
      final speaker = _extractSpeaker(line);
      if (speaker != null) {
        if (lastSpeaker != null && lastSpeaker != speaker) {
          // Speaker changed - this is fine, but note it
        }
        lastSpeaker = speaker;
      }
    }

    return DialogueIntegrityAnalysis(
      issues: issues,
      hasUnclosedDialogue: issues.any((i) => i.type == 'unclosed'),
      estimatedSpeakerCount: lastSpeaker != null ? 2 : 0,
    );
  }

  // === Private Helpers ===

  String? _detectPOV(String line) {
    final firstPersonMarkers = const [
      ' me ', ' mi ', ' mis ', ' conmigo ',
      ' desperté', ' miré', ' caminé', ' pensé', ' sentí',
      'yo ', 'yo,', 'yo.', 'yo!', 'yo?',
    ];

    final thirdPersonMarkers = const [
      'él ', 'ella ', 'ello ', 'ellos ', 'ellas ',
      'se ', 'lo ', 'la ', 'le ', 'les ',
      'su ', 'sus ', 'suyo',
    ];

    for (final marker in firstPersonMarkers) {
      if (line.contains(marker)) return 'first';
    }

    for (final marker in thirdPersonMarkers) {
      if (line.contains(marker)) return 'third';
    }

    return null;
  }

  String? _detectTone(String line) {
    final formalMarkers = const [
      'debe', 'requiere', 'implica', 'análisis',
      'conclusión', 'según', 'respecto', 'metodología',
    ];

    final casualMarkers = const [
      'oye', 'mira', 'bueno', 'pues', 'vale',
      'tipo', 'cosa', 'tío', 'jaja', 'obvio',
    ];

    final seriousMarkers = const [
      'muerte', 'grave', 'terrible', 'horrible',
      'tragedia', 'horror', 'angustia', 'desesperación',
    ];

    final humorousMarkers = const [
      'jaja', 'haha', 'ja', 'jajaja', 'ridículo',
      'gracioso', 'absurdo', 'cómico', 'burla',
    ];

    var formalScore = 0;
    var casualScore = 0;
    var seriousScore = 0;
    var humorousScore = 0;

    for (final marker in formalMarkers) {
      if (line.contains(marker)) formalScore++;
    }
    for (final marker in casualMarkers) {
      if (line.contains(marker)) casualScore++;
    }
    for (final marker in seriousMarkers) {
      if (line.contains(marker)) seriousScore++;
    }
    for (final marker in humorousMarkers) {
      if (line.contains(marker)) humorousScore++;
    }

    if (formalScore > 0) return 'formal';
    if (casualScore > 0) return 'casual';
    if (seriousScore > humorousScore && seriousScore > 0) return 'serious';
    if (humorousScore > seriousScore && humorousScore > 0) return 'humorous';

    return null;
  }

  double _computeToneConfidence(String line) {
    final markers = [
      'muerte', 'grave', 'jaja', 'debe',
      'oye', 'conclusión', 'ridículo',
    ];

    var count = 0;
    for (final marker in markers) {
      if (line.contains(marker)) count++;
    }

    return (count / markers.length).clamp(0.0, 1.0);
  }

  String? _extractLocation(String sentence) {
    const locations = {
      'apartamento': 'apartment',
      'callejón': 'alley',
      'mission': 'mission',
      'san francisco': 'san_francisco',
      'oficina': 'office',
      'café': 'cafe',
      'casa': 'house',
      'calle': 'street',
      'parque': 'park',
      'mercado': 'market',
      'estación': 'station',
      'hospital': 'hospital',
      'escuela': 'school',
    };

    for (final entry in locations.entries) {
      if (sentence.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  String? _extractTime(String sentence) {
    final clockPattern = RegExp(r'\b(\d{1,2}):(\d{2})\b');
    final ampmPattern = RegExp(r'\b(\d{1,2})\s*(?:am|pm)\b');
    final dayPattern = RegExp(r'\b(lunes|martes|miércoles|jueves|viernes|sábado|domingo)\b');
    final periodPattern = RegExp(r'\b(mañana|tarde|noche|madrugada|alba|atardecer)\b');

    if (clockPattern.hasMatch(sentence)) return 'specific_time';
    if (ampmPattern.hasMatch(sentence)) return 'specific_time';
    if (dayPattern.hasMatch(sentence)) return 'day';
    if (periodPattern.hasMatch(sentence)) return 'period';

    return null;
  }

  bool _isTemporallyDistant(String time1, String time2) {
    // Specific times that differ significantly should be flagged
    if (time1 == 'specific_time' && time2 == 'specific_time') {
      // Both specific - assume distant if we can extract hour diff
      return true;
    }

    // Day-to-day should be flagged
    if (time1 == 'day' && time2 == 'day') return true;

    // Period transitions might be distant (night → morning)
    if (time1 == 'period' && time2 == 'period') return true;

    return false;
  }

  int _countUnescapedQuotes(String line) {
    int count = 0;
    bool escaped = false;

    for (int i = 0; i < line.length; i++) {
      if (line[i] == '\\' && !escaped) {
        escaped = true;
        continue;
      }

      if (line[i] == '"' && !escaped) {
        count++;
      }

      escaped = false;
    }

    return count;
  }

  bool _looksLikeDialogueContinuation(String line) {
    final continuation = RegExp(r'^[\s]*[a-z]|^[\s]*—');
    return continuation.hasMatch(line);
  }

  String? _extractSpeaker(String line) {
    final speakerPattern = RegExp(r'—?\s*(?:dijo|preguntó|respondió|exclamó|murmuró)');
    if (speakerPattern.hasMatch(line)) {
      return 'speaker_${line.hashCode}';
    }
    return null;
  }
}

/// POV analysis results
class POVAnalysis {
  final String? dominantPOV;
  final List<POVIssue> inconsistencies;
  final bool isConsistent;

  POVAnalysis({
    required this.dominantPOV,
    required this.inconsistencies,
    required this.isConsistent,
  });
}

/// Individual POV inconsistency
class POVIssue {
  final int lineNumber;
  final String from;
  final String to;
  final String context;

  POVIssue({
    required this.lineNumber,
    required this.from,
    required this.to,
    required this.context,
  });
}

/// Tone analysis results
class ToneAnalysis {
  final String dominantTone;
  final List<ToneShift> toneShifts;
  final bool isConsistent;

  ToneAnalysis({
    required this.dominantTone,
    required this.toneShifts,
    required this.isConsistent,
  });
}

/// Individual tone shift
class ToneShift {
  final int lineNumber;
  final String from;
  final String to;
  final double confidence;

  ToneShift({
    required this.lineNumber,
    required this.from,
    required this.to,
    required this.confidence,
  });
}

/// Narrative jump analysis results
class NarrativeJumpAnalysis {
  final List<NarrativeJump> jumps;
  final bool hasTemporalGaps;
  final bool hasSpatialGaps;

  NarrativeJumpAnalysis({
    required this.jumps,
    required this.hasTemporalGaps,
    required this.hasSpatialGaps,
  });
}

/// Individual narrative jump
class NarrativeJump {
  final String type; // 'temporal' or 'spatial'
  final int sentenceIndex;
  final String from;
  final String to;

  NarrativeJump({
    required this.type,
    required this.sentenceIndex,
    required this.from,
    required this.to,
  });
}

/// Dialogue integrity analysis results
class DialogueIntegrityAnalysis {
  final List<DialogueIssue> issues;
  final bool hasUnclosedDialogue;
  final int estimatedSpeakerCount;

  DialogueIntegrityAnalysis({
    required this.issues,
    required this.hasUnclosedDialogue,
    required this.estimatedSpeakerCount,
  });
}

/// Individual dialogue issue
class DialogueIssue {
  final String type; // 'unclosed', 'mismatched_speakers', etc
  final int lineNumber;
  final String context;

  DialogueIssue({
    required this.type,
    required this.lineNumber,
    required this.context,
  });
}
