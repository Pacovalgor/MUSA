class Character {
  final String id;
  final String name;
  final String role;
  final String description;
  final Map<String, String> traits;

  Character({
    required this.id,
    required this.name,
    required this.role,
    required this.description,
    this.traits = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'description': description,
    'traits': traits,
  };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json['id'],
    name: json['name'],
    role: json['role'],
    description: json['description'],
    traits: Map<String, String>.from(json['traits'] ?? {}),
  );
}
