import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Tracks acceptance/rejection rates for each musa to enable adaptive thresholds.
/// Goal: Musas that get rejected frequently should appear less often,
/// musas that get accepted frequently should appear more often.
class MusaEffectivenessTracker {
  static const String _storageKey = 'musa_effectiveness_stats';
  static const int minimumSamples = 5;

  final Map<String, MusaEffectiveness> _stats = {};
  SharedPreferences? _prefs;

  MusaEffectivenessTracker();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadStats();
  }

  void _loadStats() {
    final json = _prefs?.getString(_storageKey);
    if (json == null) return;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      for (final entry in map.entries) {
        _stats[entry.key] = MusaEffectiveness.fromJson(entry.value);
      }
    } catch (e) {
      // Fallback: clear corrupted data
      _stats.clear();
    }
  }

  Future<void> _saveStats() async {
    if (_prefs == null) return;
    final json = jsonEncode(
      _stats.map((k, v) => MapEntry(k, v.toJson())),
    );
    await _prefs!.setString(_storageKey, json);
  }

  /// Record that a musa suggestion was shown to the user
  Future<void> recordSuggestionShown(String musaSlug) async {
    _stats.putIfAbsent(
      musaSlug,
      () => MusaEffectiveness(slug: musaSlug),
    );
    _stats[musaSlug]!.totalShown += 1;
    await _saveStats();
  }

  /// Record that user accepted a musa suggestion
  Future<void> recordAcceptance(String musaSlug) async {
    final stats = _stats.putIfAbsent(
      musaSlug,
      () => MusaEffectiveness(slug: musaSlug),
    );
    stats.timesAccepted += 1;
    await _saveStats();
  }

  /// Record that user rejected/discarded a musa suggestion
  Future<void> recordRejection(String musaSlug) async {
    final stats = _stats.putIfAbsent(
      musaSlug,
      () => MusaEffectiveness(slug: musaSlug),
    );
    stats.timesRejected += 1;
    await _saveStats();
  }

  /// Get acceptance rate for a musa (0.0-1.0)
  /// Returns 0.5 (neutral) if no data yet
  double getAcceptanceRate(String musaSlug) {
    final stats = _stats[musaSlug];
    if (stats == null || stats.totalShown == 0) return 0.5;
    return stats.timesAccepted / stats.totalShown;
  }

  /// Get threshold adjustment multiplier based on acceptance rate
  /// > 0.8 acceptance: multiply threshold by 1.2 (show more often)
  /// > 0.6 acceptance: multiply by 1.1 (show slightly more)
  /// 0.3-0.6: multiply by 1.0 (keep default)
  /// < 0.3 acceptance: multiply by 0.8 (show less often)
  double getThresholdMultiplier(String musaSlug) {
    final shown = getTotalSuggestionsShown(musaSlug);
    if (shown < minimumSamples) return 1.0;

    final rate = getAcceptanceRate(musaSlug);

    if (rate > 0.8) return 1.2; // Very effective: be more aggressive
    if (rate > 0.6) return 1.1; // Effective: slightly more aggressive
    if (rate < 0.3) return 0.8; // Ineffective: be more conservative
    return 1.0; // Default: unchanged
  }

  /// Get total suggestions shown (for analytics)
  int getTotalSuggestionsShown(String musaSlug) {
    return _stats[musaSlug]?.totalShown ?? 0;
  }

  MusaLearningStatus getLearningStatus(String musaSlug) {
    final stats = _stats[musaSlug] ?? MusaEffectiveness(slug: musaSlug);
    final multiplier = getThresholdMultiplier(musaSlug);
    final hasEnoughData = stats.totalShown >= minimumSamples;
    final label = hasEnoughData
        ? switch (multiplier) {
            > 1.0 => 'Afinada',
            < 1.0 => 'En pausa',
            _ => 'Estable',
          }
        : 'Aprendiendo';

    return MusaLearningStatus(
      slug: musaSlug,
      totalShown: stats.totalShown,
      timesAccepted: stats.timesAccepted,
      timesRejected: stats.timesRejected,
      acceptanceRate: stats.acceptanceRate,
      multiplier: multiplier,
      label: label,
      hasEnoughData: hasEnoughData,
    );
  }

  List<MusaLearningStatus> getLearningStatuses(Iterable<String> musaSlugs) {
    return [
      for (final slug in musaSlugs) getLearningStatus(slug),
    ];
  }

  /// Reset all stats (for testing/reset)
  Future<void> resetAll() async {
    _stats.clear();
    if (_prefs != null) {
      await _prefs!.remove(_storageKey);
    }
  }
}

/// Effectiveness data for a single musa
class MusaEffectiveness {
  final String slug;
  int totalShown = 0;
  int timesAccepted = 0;
  int timesRejected = 0;

  MusaEffectiveness({required this.slug});

  double get acceptanceRate =>
      totalShown == 0 ? 0.5 : timesAccepted / totalShown;

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'totalShown': totalShown,
        'timesAccepted': timesAccepted,
        'timesRejected': timesRejected,
      };

  factory MusaEffectiveness.fromJson(Map<String, dynamic> json) =>
      MusaEffectiveness(slug: json['slug'] as String)
        ..totalShown = json['totalShown'] as int? ?? 0
        ..timesAccepted = json['timesAccepted'] as int? ?? 0
        ..timesRejected = json['timesRejected'] as int? ?? 0;
}

class MusaLearningStatus {
  const MusaLearningStatus({
    required this.slug,
    required this.totalShown,
    required this.timesAccepted,
    required this.timesRejected,
    required this.acceptanceRate,
    required this.multiplier,
    required this.label,
    required this.hasEnoughData,
  });

  final String slug;
  final int totalShown;
  final int timesAccepted;
  final int timesRejected;
  final double acceptanceRate;
  final double multiplier;
  final String label;
  final bool hasEnoughData;
}
