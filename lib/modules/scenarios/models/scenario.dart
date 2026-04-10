/// Scenario or location sheet connected to the active book and manuscript.
class Scenario {
  final String id;
  final String bookId;
  final String name;
  final String role;
  final String summary;
  final String atmosphere;
  final String importance;
  final String whatItHides;
  final String currentState;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Scenario({
    required this.id,
    required this.bookId,
    required this.name,
    this.role = '',
    this.summary = '',
    this.atmosphere = '',
    this.importance = '',
    this.whatItHides = '',
    this.currentState = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'Escenario sin nombre' : trimmed;
  }

  Scenario copyWith({
    String? name,
    String? role,
    String? summary,
    String? atmosphere,
    String? importance,
    String? whatItHides,
    String? currentState,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Scenario(
      id: id,
      bookId: bookId,
      name: name ?? this.name,
      role: role ?? this.role,
      summary: summary ?? this.summary,
      atmosphere: atmosphere ?? this.atmosphere,
      importance: importance ?? this.importance,
      whatItHides: whatItHides ?? this.whatItHides,
      currentState: currentState ?? this.currentState,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'name': name,
        'role': role,
        'summary': summary,
        'atmosphere': atmosphere,
        'importance': importance,
        'whatItHides': whatItHides,
        'currentState': currentState,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Scenario.fromJson(Map<String, dynamic> json) {
    String read(String key, [String fallback = '']) =>
        (json[key] as String? ?? fallback).trim();

    return Scenario(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      name: read('name', 'Escenario nuevo'),
      role: read('role', read('narrativeFunction')),
      summary: read('summary', read('shortDescription')),
      atmosphere: read('atmosphere'),
      importance: read('importance', read('associatedEmotion')),
      whatItHides: read('whatItHides', read('historyNotes')),
      currentState: read('currentState', read('sensoryNotes')),
      notes: read('notes'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
