import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Representa una sugerencia guardada en el historial
class HistoricalSuggestion {
  final String id;
  final String originalText;
  final String suggestedText;
  final String musaId;
  final String musaName;
  final DateTime timestamp;
  final bool wasAccepted;

  const HistoricalSuggestion({
    required this.id,
    required this.originalText,
    required this.suggestedText,
    required this.musaId,
    required this.musaName,
    required this.timestamp,
    this.wasAccepted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalText': originalText,
    'suggestedText': suggestedText,
    'musaId': musaId,
    'musaName': musaName,
    'timestamp': timestamp.toIso8601String(),
    'wasAccepted': wasAccepted,
  };

  factory HistoricalSuggestion.fromJson(Map<String, dynamic> json) =>
      HistoricalSuggestion(
        id: json['id'] as String,
        originalText: json['originalText'] as String,
        suggestedText: json['suggestedText'] as String,
        musaId: json['musaId'] as String,
        musaName: json['musaName'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        wasAccepted: json['wasAccepted'] as bool? ?? false,
      );
}

/// Gestor del historial de sugerencias (máximo 5 entradas)
class SuggestionHistoryManager {
  static const String _storageKey = 'suggestion_history';
  static const int _maxHistorySize = 5;

  final List<HistoricalSuggestion> _history = [];
  SharedPreferences? _prefs;

  SuggestionHistoryManager();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadHistory();
  }

  void _loadHistory() {
    final json = _prefs?.getString(_storageKey);
    if (json == null) return;

    try {
      final list = jsonDecode(json) as List<dynamic>;
      _history.clear();
      for (final item in list) {
        _history.add(HistoricalSuggestion.fromJson(item as Map<String, dynamic>));
      }
    } catch (e) {
      _history.clear();
    }
  }

  Future<void> _saveHistory() async {
    if (_prefs == null) return;
    final json = jsonEncode(_history.map((s) => s.toJson()).toList());
    await _prefs!.setString(_storageKey, json);
  }

  /// Agregar sugerencia al historial (LIFO stack)
  Future<void> addSuggestion(HistoricalSuggestion suggestion) async {
    _history.insert(0, suggestion);

    // Limitar a 5 entradas
    if (_history.length > _maxHistorySize) {
      _history.removeRange(_maxHistorySize, _history.length);
    }

    await _saveHistory();
  }

  /// Obtener sugerencia anterior en el historial
  HistoricalSuggestion? getPrevious() {
    return _history.isNotEmpty ? _history.first : null;
  }

  /// Obtener todas las sugerencias del historial
  List<HistoricalSuggestion> getAll() => List.from(_history);

  /// Limpiar historial
  Future<void> clear() async {
    _history.clear();
    if (_prefs != null) {
      await _prefs!.remove(_storageKey);
    }
  }

  /// Obtener índice de sugerencia en historial
  int? indexOf(HistoricalSuggestion suggestion) {
    for (int i = 0; i < _history.length; i++) {
      if (_history[i].id == suggestion.id) return i;
    }
    return null;
  }

  /// Saltar a una sugerencia anterior específica
  HistoricalSuggestion? jumpToIndex(int index) {
    if (index >= 0 && index < _history.length) {
      return _history[index];
    }
    return null;
  }

  int get totalInHistory => _history.length;
}
