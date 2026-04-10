import '../../../shared/utils/enum_codec.dart';

/// Lifecycle state of a recorded voice memo.
enum VoiceMemoStatus { recorded, transcribed, linked, archived }

/// Audio capture linked to the narrative workspace and optionally summarized.
class VoiceMemo {
  final String id;
  final String bookId;
  final String? title;
  final String audioPath;
  final int durationMs;
  final String? transcript;
  final String? summary;
  final VoiceMemoStatus status;
  final DateTime createdAt;
  final List<String> characterIds;
  final List<String> scenarioIds;
  final List<String> documentIds;
  final String? derivedNoteId;

  const VoiceMemo({
    required this.id,
    required this.bookId,
    this.title,
    required this.audioPath,
    this.durationMs = 0,
    this.transcript,
    this.summary,
    this.status = VoiceMemoStatus.recorded,
    required this.createdAt,
    this.characterIds = const [],
    this.scenarioIds = const [],
    this.documentIds = const [],
    this.derivedNoteId,
  });

  VoiceMemo copyWith({
    String? title,
    bool clearTitle = false,
    String? audioPath,
    int? durationMs,
    String? transcript,
    bool clearTranscript = false,
    String? summary,
    bool clearSummary = false,
    VoiceMemoStatus? status,
    List<String>? characterIds,
    List<String>? scenarioIds,
    List<String>? documentIds,
    String? derivedNoteId,
    bool clearDerivedNoteId = false,
  }) {
    return VoiceMemo(
      id: id,
      bookId: bookId,
      title: clearTitle ? null : (title ?? this.title),
      audioPath: audioPath ?? this.audioPath,
      durationMs: durationMs ?? this.durationMs,
      transcript: clearTranscript ? null : (transcript ?? this.transcript),
      summary: clearSummary ? null : (summary ?? this.summary),
      status: status ?? this.status,
      createdAt: createdAt,
      characterIds: characterIds ?? this.characterIds,
      scenarioIds: scenarioIds ?? this.scenarioIds,
      documentIds: documentIds ?? this.documentIds,
      derivedNoteId:
          clearDerivedNoteId ? null : (derivedNoteId ?? this.derivedNoteId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'title': title,
        'audioPath': audioPath,
        'durationMs': durationMs,
        'transcript': transcript,
        'summary': summary,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'characterIds': characterIds,
        'scenarioIds': scenarioIds,
        'documentIds': documentIds,
        'derivedNoteId': derivedNoteId,
      };

  factory VoiceMemo.fromJson(Map<String, dynamic> json) => VoiceMemo(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        title: json['title'] as String?,
        audioPath: json['audioPath'] as String? ?? '',
        durationMs: json['durationMs'] as int? ?? 0,
        transcript: json['transcript'] as String?,
        summary: json['summary'] as String?,
        status: enumFromName(
          VoiceMemoStatus.values,
          json['status'] as String?,
          VoiceMemoStatus.recorded,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        characterIds:
            List<String>.from(json['characterIds'] as List? ?? const []),
        scenarioIds:
            List<String>.from(json['scenarioIds'] as List? ?? const []),
        documentIds:
            List<String>.from(json['documentIds'] as List? ?? const []),
        derivedNoteId: json['derivedNoteId'] as String?,
      );
}
