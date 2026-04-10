import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ModelPersistence {
  static const String _keyActiveModelId = 'musa_active_model_id';
  static const String _keyInstalledModels = 'musa_installed_models';
  static const String _keyExpectedBytesByModel = 'musa_expected_bytes_by_model';
  static const String _keyOnboardingCompleted = 'musa_onboarding_completed';

  Future<void> saveActiveModelId(String? modelId) async {
    final prefs = await SharedPreferences.getInstance();
    if (modelId == null) {
      await prefs.remove(_keyActiveModelId);
    } else {
      await prefs.setString(_keyActiveModelId, modelId);
    }
  }

  Future<String?> getActiveModelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveModelId);
  }

  Future<void> saveInstalledModels(List<String> modelIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyInstalledModels, modelIds);
  }

  Future<List<String>> getInstalledModels() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyInstalledModels) ?? [];
  }

  Future<void> saveExpectedBytesByModel(Map<String, int> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyExpectedBytesByModel, jsonEncode(values));
  }

  Future<Map<String, int>> getExpectedBytesByModel() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyExpectedBytesByModel);
    if (raw == null || raw.isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const {};
    }

    return decoded.map<String, int>((key, value) {
      final intValue = switch (value) {
        int v => v,
        String v => int.tryParse(v) ?? 0,
        _ => 0,
      };
      return MapEntry(key, intValue);
    });
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, completed);
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }
}
