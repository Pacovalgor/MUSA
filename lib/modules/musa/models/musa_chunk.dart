/// Persisted streaming chunk emitted while a Musa session is generating text.
class MusaChunk {
  final String id;
  final String musaSessionId;
  final String delta;
  final int sequence;
  final DateTime createdAt;

  const MusaChunk({
    required this.id,
    required this.musaSessionId,
    required this.delta,
    required this.sequence,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'musaSessionId': musaSessionId,
        'delta': delta,
        'sequence': sequence,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MusaChunk.fromJson(Map<String, dynamic> json) => MusaChunk(
        id: json['id'] as String,
        musaSessionId: json['musaSessionId'] as String,
        delta: json['delta'] as String? ?? '',
        sequence: json['sequence'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
