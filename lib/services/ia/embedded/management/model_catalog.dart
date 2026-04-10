import 'hardware_detector.dart';

class ModelDefinition {
  final String id;
  final String name;
  final String description;
  final String sizeDisplay;
  final double sizeGB;
  final int expectedBytes;
  final String? sha256;
  final String url;
  final String localFilename; // The exact filename on disk
  final MusaModelTier requiredTier;

  ModelDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.sizeDisplay,
    required this.sizeGB,
    this.expectedBytes = 0,
    this.sha256,
    required this.url,
    required this.localFilename,
    required this.requiredTier,
  });
}

class ModelCatalog {
  static List<ModelDefinition> get availableModels => [
        ModelDefinition(
          id: "phi-3-mini",
          name: "Musa Lite (Phi-3 Mini)",
          description:
              "Escritura ultrarrápida, ideal para Macs con poca RAM o procesadores Intel antiguos.",
          sizeDisplay: "2.2 GB",
          sizeGB: 2.2,
          expectedBytes: 2393231072,
          url:
              "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf",
          localFilename: "phi-3-mini-q4.gguf",
          requiredTier: MusaModelTier.lite,
        ),
        ModelDefinition(
          id: "mistral-7b-v03",
          name: "Musa Standard (Mistral 7B)",
          description:
              "El equilibrio perfecto entre calidad literaria y velocidad. Recomendada para 8GB+ RAM.",
          sizeDisplay: "4.1 GB",
          sizeGB: 4.1,
          expectedBytes: 0,
          url:
              "https://huggingface.co/bartowski/Mistral-7B-v0.3-GGUF/resolve/main/Mistral-7B-v0.3-Q4_K_M.gguf",
          localFilename: "mistral-7b-v03-q4_k_m.gguf",
          requiredTier: MusaModelTier.standard,
        ),
        ModelDefinition(
          id: "llama-3-8b",
          name: "Musa Pro (Llama 3 8B)",
          description:
              "Máxima precisión creativa y matices literarios. Requiere 16GB RAM o más.",
          sizeDisplay: "5.2 GB",
          sizeGB: 5.2,
          expectedBytes: 4920734272,
          sha256:
              "8ba9baf3a7345f705a11878397500fb25174034f0fd784e83aa4a96aaa47735f",
          url:
              "https://huggingface.co/bartowski/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct-Q4_K_M.gguf",
          localFilename: "llama-3-8b-q4_k_m.gguf",
          requiredTier: MusaModelTier.pro,
        ),
      ];

  static ModelDefinition findRecommended(MacHardwareProfile profile) {
    final tier = profile.recommendedTier;
    return availableModels.firstWhere((m) => m.requiredTier == tier,
        orElse: () => availableModels[1]);
  }
}

class ModelManagerState {
  final Map<String, double> downloadProgress; // id -> percentage (0.0 to 1.0)
  final List<String> downloadedModelIds;
  final String? activeModelId;

  ModelManagerState({
    this.downloadProgress = const {},
    this.downloadedModelIds = const [],
    this.activeModelId,
  });

  ModelManagerState copyWith({
    Map<String, double>? downloadProgress,
    List<String>? downloadedModelIds,
    String? activeModelId,
  }) {
    return ModelManagerState(
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedModelIds: downloadedModelIds ?? this.downloadedModelIds,
      activeModelId: activeModelId ?? this.activeModelId,
    );
  }
}
