class OutlineNode {
  final String id;
  final String title;
  final String note;
  final List<OutlineNode> children;

  OutlineNode({
    required this.id,
    required this.title,
    required this.note,
    this.children = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'children': children.map((e) => e.toJson()).toList(),
  };
}

class Outline {
  final List<OutlineNode> nodes;

  Outline({required this.nodes});

  Map<String, dynamic> toJson() => {
    'nodes': nodes.map((e) => e.toJson()).toList(),
  };
}
