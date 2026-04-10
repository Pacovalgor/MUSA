class Chapter {
  final String id;
  final String title;
  final String content;
  final int order;
  final DateTime lastModified;

  Chapter({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'order': order,
    'lastModified': lastModified.toIso8601String(),
  };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    order: json['order'],
    lastModified: DateTime.parse(json['lastModified']),
  );
}
