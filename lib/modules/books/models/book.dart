import '../../../shared/utils/enum_codec.dart';
import 'narrative_copilot.dart';

/// Lifecycle status for a book inside the workspace.
enum BookStatus { draft, active, archived }

/// Top-level narrative container for manuscript, continuity and editorial setup.
class Book {
  final String id;
  final String title;
  final String? subtitle;
  final BookStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String defaultLanguage;
  final String summary;
  final String toneNotes;
  final String? activeModelProfileId;
  final BookNarrativeProfile narrativeProfile;
  final List<String> dismissedContinuityFindingIds;

  const Book({
    required this.id,
    required this.title,
    this.subtitle,
    this.status = BookStatus.draft,
    required this.createdAt,
    required this.updatedAt,
    this.defaultLanguage = 'es',
    this.summary = '',
    this.toneNotes = '',
    this.activeModelProfileId,
    this.narrativeProfile = const BookNarrativeProfile(),
    this.dismissedContinuityFindingIds = const [],
  });

  Book copyWith({
    String? title,
    String? subtitle,
    bool clearSubtitle = false,
    BookStatus? status,
    DateTime? updatedAt,
    String? defaultLanguage,
    String? summary,
    String? toneNotes,
    String? activeModelProfileId,
    bool clearActiveModelProfileId = false,
    BookNarrativeProfile? narrativeProfile,
    List<String>? dismissedContinuityFindingIds,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      subtitle: clearSubtitle ? null : (subtitle ?? this.subtitle),
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      summary: summary ?? this.summary,
      toneNotes: toneNotes ?? this.toneNotes,
      activeModelProfileId: clearActiveModelProfileId
          ? null
          : (activeModelProfileId ?? this.activeModelProfileId),
      narrativeProfile: narrativeProfile ?? this.narrativeProfile,
      dismissedContinuityFindingIds:
          dismissedContinuityFindingIds ?? this.dismissedContinuityFindingIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'defaultLanguage': defaultLanguage,
        'summary': summary,
        'toneNotes': toneNotes,
        'activeModelProfileId': activeModelProfileId,
        'narrativeProfile': narrativeProfile.toJson(),
        if (dismissedContinuityFindingIds.isNotEmpty)
          'dismissedContinuityFindingIds': dismissedContinuityFindingIds,
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        status: enumFromName(
          BookStatus.values,
          json['status'] as String?,
          BookStatus.draft,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        defaultLanguage: json['defaultLanguage'] as String? ?? 'es',
        summary: json['summary'] as String? ?? '',
        toneNotes: json['toneNotes'] as String? ?? '',
        activeModelProfileId: json['activeModelProfileId'] as String?,
        narrativeProfile: BookNarrativeProfile.fromJson(
          json['narrativeProfile'] as Map<String, dynamic>?,
        ),
        dismissedContinuityFindingIds:
            (json['dismissedContinuityFindingIds'] as List<dynamic>?)
                    ?.cast<String>() ??
                const [],
      );
}
