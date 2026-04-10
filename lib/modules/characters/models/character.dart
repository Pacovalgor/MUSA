class Character {
  final String id;
  final String bookId;
  final String name;
  final String role;
  final String summary;
  final String voice;
  final String motivation;
  final String internalConflict;
  final String whatTheyHide;
  final String currentState;
  final String notes;
  final bool isProtagonist;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Character({
    required this.id,
    required this.bookId,
    required this.name,
    this.role = '',
    this.summary = '',
    this.voice = '',
    this.motivation = '',
    this.internalConflict = '',
    this.whatTheyHide = '',
    this.currentState = '',
    this.notes = '',
    this.isProtagonist = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return isProtagonist ? 'Protagonista' : 'Personaje sin nombre';
  }

  Character copyWith({
    String? name,
    String? role,
    String? summary,
    String? voice,
    String? motivation,
    String? internalConflict,
    String? whatTheyHide,
    String? currentState,
    String? notes,
    bool? isProtagonist,
    DateTime? updatedAt,
  }) {
    return Character(
      id: id,
      bookId: bookId,
      name: name ?? this.name,
      role: role ?? this.role,
      summary: summary ?? this.summary,
      voice: voice ?? this.voice,
      motivation: motivation ?? this.motivation,
      internalConflict: internalConflict ?? this.internalConflict,
      whatTheyHide: whatTheyHide ?? this.whatTheyHide,
      currentState: currentState ?? this.currentState,
      notes: notes ?? this.notes,
      isProtagonist: isProtagonist ?? this.isProtagonist,
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
        'voice': voice,
        'motivation': motivation,
        'internalConflict': internalConflict,
        'whatTheyHide': whatTheyHide,
        'currentState': currentState,
        'notes': notes,
        'isProtagonist': isProtagonist,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        summary: (json['summary'] ??
                json['shortDescription'] ??
                json['arcSummary']) as String? ??
            '',
        voice: (json['voice'] ?? json['voiceNotes']) as String? ?? '',
        motivation: (json['motivation'] ?? json['coreDesire']) as String? ?? '',
        internalConflict:
            (json['internalConflict'] ?? json['contradictions']) as String? ??
                '',
        whatTheyHide:
            (json['whatTheyHide'] ?? json['coreFear']) as String? ?? '',
        currentState: (json['currentState'] ?? json['wound']) as String? ?? '',
        notes: (json['notes'] ?? json['physicalNotes']) as String? ?? '',
        isProtagonist: json['isProtagonist'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
