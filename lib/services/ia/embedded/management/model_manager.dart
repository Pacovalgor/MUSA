import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'model_catalog.dart';
import 'hardware_detector.dart';
import 'model_persistence.dart';

enum ModelInstallState {
  notInstalled,
  downloading,
  paused,
  verifying,
  installed,
  failed,
  cancelled,
  active,
}

/// The central controller for all AI models in MUSA.
class ModelManager extends StateNotifier<ModelManagerState> {
  static const List<int> _ggufMagicBytes = <int>[0x47, 0x47, 0x55, 0x46];
  final ModelPersistence _persistence = ModelPersistence();
  final Map<String, HttpClient> _activeClients = {};
  Map<String, int> _persistedExpectedBytes = <String, int>{};

  ModelManager() : super(ModelManagerState()) {
    _initPersistence();
  }

  Future<void> _initPersistence() async {
    final persistedInstalledIds = await _persistence.getInstalledModels();
    final persistedActiveId = await _persistence.getActiveModelId();
    _persistedExpectedBytes = await _persistence.getExpectedBytesByModel();
    final installedIds = <String>[];
    String? activePath;
    String? activeId;

    for (final id in persistedInstalledIds) {
      final modelDef = _tryFindModelDefinition(id);
      if (modelDef == null) {
        continue;
      }

      final validation = await validateModelFile(modelDef);
      if (validation.isValid) {
        installedIds.add(id);
        if (id == persistedActiveId) {
          activeId = id;
          activePath = validation.path;
        }
      } else {
        debugPrint('[MUSA] MODEL INVALID ON INIT: $id → ${validation.error}');
      }
    }

    if (activeId == null && installedIds.isNotEmpty) {
      activeId = installedIds.first;
      final activeDef = _tryFindModelDefinition(activeId);
      activePath = activeDef == null ? null : await resolveModelPath(activeDef);
    }

    final Map<String, ModelInstallState> states = {};
    for (final id in installedIds) {
      states[id] = id == activeId
          ? ModelInstallState.active
          : ModelInstallState.installed;
    }

    state = state.copyWith(
      downloadedModelIds: installedIds,
      activeModelId: activeId,
      activeModelPath: activePath,
      installStates: states,
    );

    if (!_sameIds(installedIds, persistedInstalledIds)) {
      await _persistence.saveInstalledModels(installedIds);
    }
    if (activeId != persistedActiveId) {
      await _persistence.saveActiveModelId(activeId);
    }
  }

  Future<MacHardwareProfile> detectHardware() async {
    return await HardwareDetector.detect();
  }

  /// The SINGLE source of truth for where a model lives on disk.
  /// Both download and inference must use this method.
  static Future<String> resolveModelPath(ModelDefinition model) async {
    final directory = await getApplicationSupportDirectory();
    final path = '${directory.path}/models/${model.localFilename}';
    debugPrint('[MUSA] ACTIVE MODEL PATH: $path');
    return path;
  }

  Future<void> startDownload(ModelDefinition model) async {
    final targetPath = await resolveModelPath(model);
    final partPath = '$targetPath.part';

    debugPrint('[MUSA] DOWNLOAD REAL START: ${model.name}');
    debugPrint('[MUSA] DOWNLOAD URL: ${model.url}');
    debugPrint('[MUSA] DOWNLOAD TARGET PATH: $targetPath');

    // Ensure models directory exists
    final modelsDir = File(targetPath).parent;
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    // Clean up any leftover .part from a previous failed attempt
    final partFile = File(partPath);
    if (await partFile.exists()) {
      await partFile.delete();
      debugPrint('[MUSA] DOWNLOAD: eliminado archivo .part previo incompleto');
    }

    state = state.copyWith(
      downloadProgress: {...state.downloadProgress, model.id: 0.0},
      installStates: {
        ...state.installStates,
        model.id: ModelInstallState.downloading
      },
      clearDownloadError: true,
    );

    IOSink? sink;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      _activeClients[model.id] = client;

      final request = await client.getUrl(Uri.parse(model.url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode} al descargar el modelo');
      }

      final contentLength = response.contentLength;
      final expectedBytes = _resolveExpectedBytes(model, contentLength);
      debugPrint('[MUSA] DOWNLOAD BYTES WRITTEN: esperados ${contentLength}B');
      debugPrint(
          '[MUSA] MODEL EXPECTED BYTES: ${expectedBytes > 0 ? expectedBytes : 'unknown'}');

      // Write to .part file — never to the final path directly
      sink = File(partPath).openWrite();
      int bytesWritten = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        bytesWritten += chunk.length;

        if (contentLength > 0) {
          final progress = (bytesWritten / contentLength).clamp(0.0, 1.0);
          if ((progress * 100).round() % 2 == 0) {
            state = state.copyWith(
              downloadProgress: {...state.downloadProgress, model.id: progress},
            );
          }
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;
      _activeClients.remove(model.id);

      state = state.copyWith(
        installStates: {
          ...state.installStates,
          model.id: ModelInstallState.verifying
        },
      );

      // ── Verification before promoting .part → .gguf ──────────────────────
      final partSize = await File(partPath).length();
      debugPrint('[MUSA] DOWNLOAD BYTES WRITTEN: $bytesWritten bytes en .part');
      debugPrint('[MUSA] MODEL FILE SIZE: ${partSize}B en disco');
      final partValidation = await validateModelFile(
        model,
        pathOverride: partPath,
        expectedBytesOverride: expectedBytes,
      );
      if (!partValidation.isValid) {
        throw Exception(partValidation.error);
      }

      // Atomic rename: .part → .gguf
      await File(partPath).rename(targetPath);

      final finalValidation = await validateModelFile(
        model,
        pathOverride: targetPath,
        expectedBytesOverride: expectedBytes,
      );
      debugPrint(
          '[MUSA] MODEL EXISTS AFTER DOWNLOAD: ${finalValidation.exists}');
      debugPrint(
        '[MUSA] MODEL FILE SIZE (final): ${finalValidation.actualBytes ?? 0}B',
      );

      if (!finalValidation.isValid) {
        throw Exception(finalValidation.error);
      }

      if (finalValidation.hashVerified) {
        await _clearQuarantineIfPresent(targetPath);
      }

      await _onDownloadFinished(model, targetPath, expectedBytes);
    } catch (e) {
      debugPrint('[MUSA] DOWNLOAD ERROR: $e');

      // Check if it was explicitly cancelled
      final isCancelled =
          state.installStates[model.id] == ModelInstallState.cancelled;

      // Cleanup .part so it doesn't block future downloads
      await sink?.close();
      if (await File(partPath).exists()) {
        await File(partPath).delete();
        debugPrint(
            '[MUSA] DOWNLOAD: archivo .part eliminado tras error/cancelación');
      }

      state = state.copyWith(
        downloadProgress: Map.from(state.downloadProgress)..remove(model.id),
        installStates: {
          ...state.installStates,
          model.id: isCancelled
              ? ModelInstallState.cancelled
              : ModelInstallState.failed,
        },
        downloadError:
            isCancelled ? null : 'Error al descargar ${model.name}: $e',
      );
    } finally {
      _activeClients.remove(model.id);
    }
  }

  Future<void> cancelDownload(String modelId) async {
    final client = _activeClients[modelId];
    if (client != null) {
      debugPrint('[MUSA] DOWNLOAD CANCELADO por el usuario: $modelId');
      state = state.copyWith(
        installStates: {
          ...state.installStates,
          modelId: ModelInstallState.cancelled
        },
      );
      client.close(force: true);
      _activeClients.remove(modelId);
    }
  }

  Future<void> retryDownload(String modelId) async {
    final modelDef = ModelCatalog.availableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => ModelCatalog.availableModels.first,
    );
    await startDownload(modelDef);
  }

  Future<void> _onDownloadFinished(
    ModelDefinition model,
    String path,
    int expectedBytes,
  ) async {
    debugPrint('[MUSA] DOWNLOAD COMPLETE: ${model.name} → $path');
    final updatedInstalled = [...state.downloadedModelIds, model.id];
    if (expectedBytes > 0) {
      _persistedExpectedBytes = <String, int>{
        ..._persistedExpectedBytes,
        model.id: expectedBytes,
      };
    }

    // Update states map
    final updatedStates =
        Map<String, ModelInstallState>.from(state.installStates);

    // Make previous active just installed, new active is active
    if (state.activeModelId != null) {
      updatedStates[state.activeModelId!] = ModelInstallState.installed;
    }
    updatedStates[model.id] = ModelInstallState.active;

    state = state.copyWith(
      downloadedModelIds: updatedInstalled,
      activeModelId: model.id,
      activeModelPath: path,
      downloadProgress: Map.from(state.downloadProgress)..remove(model.id),
      installStates: updatedStates,
      clearDownloadError: true,
    );

    await _persistence.saveInstalledModels(updatedInstalled);
    await _persistence.saveActiveModelId(model.id);
    await _persistence.saveExpectedBytesByModel(_persistedExpectedBytes);
  }

  Future<void> selectModel(String modelId) async {
    if (state.downloadedModelIds.contains(modelId)) {
      final model =
          ModelCatalog.availableModels.firstWhere((m) => m.id == modelId);
      final validation = await validateModelFile(model);
      if (!validation.isValid || validation.path == null) {
        throw StateError(
            'No se puede activar ${model.name}: ${validation.error}');
      }
      final path = validation.path!;

      final updatedStates =
          Map<String, ModelInstallState>.from(state.installStates);
      if (state.activeModelId != null) {
        updatedStates[state.activeModelId!] = ModelInstallState.installed;
      }
      updatedStates[modelId] = ModelInstallState.active;

      state = state.copyWith(
        activeModelId: modelId,
        activeModelPath: path,
        installStates: updatedStates,
      );

      await _persistence.saveActiveModelId(modelId);
    }
  }

  Future<void> deleteModel(String modelId) async {
    final updatedInstalled =
        state.downloadedModelIds.where((id) => id != modelId).toList();
    final isActive = state.activeModelId == modelId;
    final updatedActiveId = isActive ? null : state.activeModelId;
    final updatedActivePath = isActive ? null : state.activeModelPath;

    final updatedStates =
        Map<String, ModelInstallState>.from(state.installStates)
          ..remove(modelId);

    // If we delete the active model, there is no active model anymore
    state = state.copyWith(
      downloadedModelIds: updatedInstalled,
      activeModelId: updatedActiveId,
      activeModelPath: updatedActivePath,
      installStates: updatedStates,
    );

    // Physically delete file if possible
    final modelDef =
        ModelCatalog.availableModels.firstWhere((m) => m.id == modelId);
    final path = await resolveModelPath(modelDef);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    _persistedExpectedBytes = Map<String, int>.from(_persistedExpectedBytes)
      ..remove(modelId);

    await _persistence.saveInstalledModels(updatedInstalled);
    await _persistence.saveActiveModelId(updatedActiveId);
    await _persistence.saveExpectedBytesByModel(_persistedExpectedBytes);
  }

  Future<ModelValidationResult> validateModelFile(
    ModelDefinition model, {
    String? pathOverride,
    int? expectedBytesOverride,
  }) async {
    final path = pathOverride ?? await resolveModelPath(model);
    final file = File(path);
    if (!await file.exists()) {
      return ModelValidationResult.invalid(
          path, 'El archivo del modelo no existe.');
    }

    final actualBytes = await file.length();
    final expectedBytes =
        expectedBytesOverride ?? _resolveExpectedBytes(model, -1);
    if (expectedBytes <= 0) {
      return ModelValidationResult.invalid(
        path,
        'No hay expectedBytes disponible para validar ${model.name}.',
        actualBytes: actualBytes,
      );
    }

    if (actualBytes != expectedBytes) {
      return ModelValidationResult.invalid(
        path,
        'Tamaño inválido para ${model.name}: esperado ${expectedBytes}B, obtenido ${actualBytes}B.',
        actualBytes: actualBytes,
      );
    }

    final headerValid = await _hasValidGgufHeader(file);
    if (!headerValid) {
      return ModelValidationResult.invalid(
        path,
        'Cabecera GGUF inválida en ${model.name}.',
        actualBytes: actualBytes,
      );
    }

    String? computedSha256;
    var hashVerified = false;
    if (model.sha256 != null && model.sha256!.isNotEmpty) {
      computedSha256 = await _computeSha256(file);
      hashVerified =
          computedSha256.toLowerCase() == model.sha256!.toLowerCase();
      if (!hashVerified) {
        return ModelValidationResult.invalid(
          path,
          'SHA-256 inválido para ${model.name}.',
          actualBytes: actualBytes,
          actualSha256: computedSha256,
        );
      }
    }

    return ModelValidationResult.valid(
      path,
      actualBytes: actualBytes,
      actualSha256: computedSha256,
      hashVerified: hashVerified,
    );
  }

  int _resolveExpectedBytes(ModelDefinition model, int responseContentLength) {
    if (model.expectedBytes > 0) {
      return model.expectedBytes;
    }
    final persistedValue = _persistedExpectedBytes[model.id] ?? 0;
    if (persistedValue > 0) {
      return persistedValue;
    }
    if (responseContentLength > 0) {
      return responseContentLength;
    }
    return 0;
  }

  Future<bool> _hasValidGgufHeader(File file) async {
    final raf = await file.open();
    try {
      final header = await raf.read(_ggufMagicBytes.length);
      if (header.length != _ggufMagicBytes.length) {
        return false;
      }
      for (var i = 0; i < _ggufMagicBytes.length; i += 1) {
        if (header[i] != _ggufMagicBytes[i]) {
          return false;
        }
      }
      return true;
    } finally {
      await raf.close();
    }
  }

  Future<String> _computeSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<void> _clearQuarantineIfPresent(String path) async {
    if (!Platform.isMacOS) {
      return;
    }

    try {
      final readResult = await Process.run(
          'xattr', <String>['-p', 'com.apple.quarantine', path]);
      if (readResult.exitCode != 0) {
        return;
      }
      final deleteResult = await Process.run(
        'xattr',
        <String>['-d', 'com.apple.quarantine', path],
      );
      if (deleteResult.exitCode == 0) {
        debugPrint('[MUSA] MODEL QUARANTINE CLEARED: $path');
      }
    } catch (error) {
      debugPrint('[MUSA] MODEL QUARANTINE CLEAR SKIPPED: $error');
    }
  }

  ModelDefinition? _tryFindModelDefinition(String modelId) {
    for (final model in ModelCatalog.availableModels) {
      if (model.id == modelId) {
        return model;
      }
    }
    return null;
  }

  bool _sameIds(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var i = 0; i < left.length; i += 1) {
      if (left[i] != right[i]) {
        return false;
      }
    }
    return true;
  }
}

class ModelValidationResult {
  final bool isValid;
  final bool exists;
  final String? path;
  final int? actualBytes;
  final String? actualSha256;
  final bool hashVerified;
  final String? error;

  const ModelValidationResult._({
    required this.isValid,
    required this.exists,
    required this.path,
    required this.actualBytes,
    required this.actualSha256,
    required this.hashVerified,
    required this.error,
  });

  factory ModelValidationResult.valid(
    String path, {
    required int actualBytes,
    String? actualSha256,
    required bool hashVerified,
  }) {
    return ModelValidationResult._(
      isValid: true,
      exists: true,
      path: path,
      actualBytes: actualBytes,
      actualSha256: actualSha256,
      hashVerified: hashVerified,
      error: null,
    );
  }

  factory ModelValidationResult.invalid(
    String path,
    String error, {
    int? actualBytes,
    String? actualSha256,
  }) {
    return ModelValidationResult._(
      isValid: false,
      exists: true,
      path: path,
      actualBytes: actualBytes,
      actualSha256: actualSha256,
      hashVerified: false,
      error: error,
    );
  }
}

class ModelManagerState {
  static const Object _unset = Object();
  final Map<String, double> downloadProgress;
  final Map<String, ModelInstallState> installStates;
  final List<String> downloadedModelIds;
  final String? activeModelId;
  final String? activeModelPath; // The real on-disk path
  final String? downloadError;

  ModelManagerState({
    this.downloadProgress = const {},
    this.installStates = const {},
    this.downloadedModelIds = const [],
    this.activeModelId,
    this.activeModelPath,
    this.downloadError,
  });

  ModelManagerState copyWith({
    Map<String, double>? downloadProgress,
    Map<String, ModelInstallState>? installStates,
    List<String>? downloadedModelIds,
    Object? activeModelId = _unset,
    Object? activeModelPath = _unset,
    Object? downloadError = _unset,
    bool clearDownloadError = false,
  }) {
    return ModelManagerState(
      downloadProgress: downloadProgress ?? this.downloadProgress,
      installStates: installStates ?? this.installStates,
      downloadedModelIds: downloadedModelIds ?? this.downloadedModelIds,
      activeModelId: identical(activeModelId, _unset)
          ? this.activeModelId
          : activeModelId as String?,
      activeModelPath: identical(activeModelPath, _unset)
          ? this.activeModelPath
          : activeModelPath as String?,
      downloadError: clearDownloadError
          ? null
          : (identical(downloadError, _unset)
              ? this.downloadError
              : downloadError as String?),
    );
  }
}

final modelManagerProvider =
    StateNotifierProvider<ModelManager, ModelManagerState>((ref) {
  return ModelManager();
});
