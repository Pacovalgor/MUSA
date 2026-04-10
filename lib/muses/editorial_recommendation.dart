import 'musa.dart';

enum EditorialRecommendationType {
  singleMusa,
  pipeline,
}

class EditorialRecommendation {
  final EditorialRecommendationType type;
  final List<Musa> musas;
  final String reason;
  final double confidence;

  const EditorialRecommendation({
    required this.type,
    required this.musas,
    required this.reason,
    required this.confidence,
  });

  bool get isPipeline => type == EditorialRecommendationType.pipeline;
  Musa get primaryMusa => musas.first;

  String get displayLabel => musas.map((musa) => musa.shortName).join(' > ');
}
