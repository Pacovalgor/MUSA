import '../../../shared/utils/enum_codec.dart';

enum NoteKind { idea, research, structural, character, scenario, loose }

enum NoteStatus { inbox, linked, archived }

enum NoteAnchorState { exact, fuzzy, detached }

class NoteAnchorResolution {
  const NoteAnchorResolution({
    required this.noteId,
    required this.state,
    this.resolvedTextSnapshot,
    this.resolvedStartOffset,
    this.resolvedEndOffset,
  });

  final String noteId;
  final NoteAnchorState state;
  final String? resolvedTextSnapshot;
  final int? resolvedStartOffset;
  final int? resolvedEndOffset;
}

class Note {
  final String id;
  final String bookId;
  final String? title;
  final String content;
  final NoteKind kind;
  final NoteStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> characterIds;
  final List<String> scenarioIds;
  final List<String> documentIds;
  final String? anchorTextSnapshot;
  final int? anchorStartOffset;
  final int? anchorEndOffset;
  final NoteAnchorState? anchorState;

  const Note({
    required this.id,
    required this.bookId,
    this.title,
    this.content = '',
    this.kind = NoteKind.loose,
    this.status = NoteStatus.inbox,
    required this.createdAt,
    required this.updatedAt,
    this.characterIds = const [],
    this.scenarioIds = const [],
    this.documentIds = const [],
    this.anchorTextSnapshot,
    this.anchorStartOffset,
    this.anchorEndOffset,
    this.anchorState,
  });

  Note copyWith({
    String? title,
    bool clearTitle = false,
    String? content,
    NoteKind? kind,
    NoteStatus? status,
    DateTime? updatedAt,
    List<String>? characterIds,
    List<String>? scenarioIds,
    List<String>? documentIds,
    String? anchorTextSnapshot,
    int? anchorStartOffset,
    int? anchorEndOffset,
    NoteAnchorState? anchorState,
  }) {
    return Note(
      id: id,
      bookId: bookId,
      title: clearTitle ? null : (title ?? this.title),
      content: content ?? this.content,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      characterIds: characterIds ?? this.characterIds,
      scenarioIds: scenarioIds ?? this.scenarioIds,
      documentIds: documentIds ?? this.documentIds,
      anchorTextSnapshot: anchorTextSnapshot ?? this.anchorTextSnapshot,
      anchorStartOffset: anchorStartOffset ?? this.anchorStartOffset,
      anchorEndOffset: anchorEndOffset ?? this.anchorEndOffset,
      anchorState: anchorState ?? this.anchorState,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'title': title,
        'content': content,
        'kind': kind.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'characterIds': characterIds,
        'scenarioIds': scenarioIds,
        'documentIds': documentIds,
        'anchorTextSnapshot': anchorTextSnapshot,
        'anchorStartOffset': anchorStartOffset,
        'anchorEndOffset': anchorEndOffset,
        'anchorState': anchorState?.name,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        title: json['title'] as String?,
        content: json['content'] as String? ?? '',
        kind: enumFromName(
            NoteKind.values, json['kind'] as String?, NoteKind.loose),
        status: enumFromName(
          NoteStatus.values,
          json['status'] as String?,
          NoteStatus.inbox,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        characterIds:
            List<String>.from(json['characterIds'] as List? ?? const []),
        scenarioIds:
            List<String>.from(json['scenarioIds'] as List? ?? const []),
        documentIds:
            List<String>.from(json['documentIds'] as List? ?? const []),
        anchorTextSnapshot: json['anchorTextSnapshot'] as String?,
        anchorStartOffset: json['anchorStartOffset'] as int?,
        anchorEndOffset: json['anchorEndOffset'] as int?,
        anchorState: json['anchorState'] == null
            ? ((json['anchorTextSnapshot'] as String?) != null
                ? NoteAnchorState.exact
                : null)
            : enumFromName(
                NoteAnchorState.values,
                json['anchorState'] as String?,
                NoteAnchorState.exact,
              ),
      );
}
