class LofiTrack {
  final String title;
  final String filename;
  final String category;

  LofiTrack({
    required this.title,
    required this.filename,
    required this.category,
  });

  factory LofiTrack.fromJson(Map<String, dynamic> json) => LofiTrack(
        title: json['title'] as String,
        filename: json['filename'] as String,
        category: json['category'] as String,
      );
}

class LofiCatalog {
  final String name;
  final String version;
  final String license;
  final String description;
  final int trackCount;
  final List<LofiCategory> categories;
  final List<LofiTrack> tracks;

  LofiCatalog({
    required this.name,
    required this.version,
    required this.license,
    required this.description,
    required this.trackCount,
    required this.categories,
    required this.tracks,
  });

  factory LofiCatalog.fromJson(Map<String, dynamic> json) => LofiCatalog(
        name: json['name'] as String,
        version: json['version'] as String,
        license: json['license'] as String,
        description: json['description'] as String,
        trackCount: json['trackCount'] as int,
        categories: (json['categories'] as List)
            .map((cat) => LofiCategory.fromJson(cat as Map<String, dynamic>))
            .toList(),
        tracks: (json['tracks'] as List)
            .map((track) => LofiTrack.fromJson(track as Map<String, dynamic>))
            .toList(),
      );
}

class LofiCategory {
  final String slug;
  final String label;
  final int trackCount;

  LofiCategory({
    required this.slug,
    required this.label,
    required this.trackCount,
  });

  factory LofiCategory.fromJson(Map<String, dynamic> json) => LofiCategory(
        slug: json['slug'] as String,
        label: json['label'] as String,
        trackCount: json['trackCount'] as int,
      );
}
