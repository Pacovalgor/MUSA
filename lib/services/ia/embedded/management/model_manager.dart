import 'dart:async';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
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

enum ModelImportResult { cancelled, success }

/// The central controller for all AI models in MUSA.
class ModelManager extends StateNotifier<ModelManagerState> {
  static const List<int> _ggufMagicBytes = <int>[0x47, 0x47, 0x55, 0x46];
  final ModelPersistence _persistence = ModelPersistence();
  final Map<String, HttpClient> _activeClients = {};
  Map<String, int> _persistedExpectedBytes = <String, int>{};
  late final Future<void> _initFuture;

  ModelManager() : super(ModelManagerState()) {
    _initFuture = _initPersistence();
  }

  Future<void> _initPersistence() async {
    final tPrefsStart = DateTime.now();
    debugPrint('[INIT] Loading preferences...');
    final persistedInstalledIds = await _persistence.getInstalledModels();
    final persistedActiveId = await _persistence.getActiveModelId();
    _persistedExpectedBytes = await _persistence.getExpectedBytesByModel();
    final tPrefsEnd = DateTime.now();
    debugPrint(
        '[INIT] Preferences loaded in ${tPrefsEnd.difference(tPrefsStart).inMilliseconds}ms (installedIds: ${persistedInstalledIds.length}, activeId: $persistedActiveId)');
    final installedIds = <String>[];
    final validatedPaths = <String, String>{};
    String? activePath;
    String? activeId;

    final tValidateStart = DateTime.now();
    for (final id in persistedInstalledIds) {
      final modelDef = _tryFindModelDefinition(id);
      if (modelDef == null) {
        continue;
      }

      final validation = await validateModelFile(modelDef);
      if (validation.isValid) {
        installedIds.add(id);
        if (validation.path != null) validatedPaths[id] = validation.path!;
        if (id == persistedActiveId) {
          activeId = id;
          activePath = validation.path;
        }
      } else {
        debugPrint('[MUSA] MODEL INVALID ON INIT: $id → ${validation.error}');
      }
    }
    final tValidateEnd = DateTime.now();
    debugPrint(
        '[INIT] Validation loop done in ${tValidateEnd.difference(tValidateStart).inMilliseconds}ms (valid: ${installedIds.length})');

    // ── Reconciliation: discover models present on disk but missing from prefs ──
    final tReconcileStart = DateTime.now();
    await _reconcileInstalledModels(installedIds, validatedPaths);
    final tReconcileEnd = DateTime.now();
    debugPrint(
        '[INIT] Reconciliation done in ${tReconcileEnd.difference(tReconcileStart).inMilliseconds}ms (total installed: ${installedIds.length})');

    final tActiveStart = DateTime.now();
    if (activeId == null && installedIds.isNotEmpty) {
      activeId = installedIds.first;
      final activeDef = _tryFindModelDefinition(activeId);
      activePath = activeDef == null ? null : await resolveModelPath(activeDef);
    }
    final tActiveEnd = DateTime.now();
    debugPrint(
        '[INIT] Active model resolution done in ${tActiveEnd.difference(tActiveStart).inMilliseconds}ms (activeId: $activeId)');

    final Map<String, ModelInstallState> states = {};
    for (final id in installedIds) {
      states[id] = id == activeId
          ? ModelInstallState.active
          : ModelInstallState.installed;
    }

    final tPersistStart = DateTime.now();
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
    final tPersistEnd = DateTime.now();
    debugPrint(
        '[INIT] State persistence done in ${tPersistEnd.difference(tPersistStart).inMilliseconds}ms');
    debugPrint('[INIT] Final installedIds: $installedIds');
    debugPrint('[INIT] ActiveId: $activeId');
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

  Future<ModelImportResult> importModelFromFile() async {
    final t0 = DateTime.now();
    debugPrint('[IMPORT] Start importModelFromFile at $t0');
    debugPrint('[IMPORT] Opening file picker...');
    final tPickerStart = DateTime.now();
    const typeGroup = XTypeGroup(
      label: 'Modelo GGUF',
      extensions: ['gguf'],
      uniformTypeIdentifiers: ['public.data'],
    );
    final file = await openFile(
      acceptedTypeGroups: const [typeGroup],
      confirmButtonText: 'Importar',
    );
    final tPickerEnd = DateTime.now();
    debugPrint(
        '[IMPORT] Picker returned in ${tPickerEnd.difference(tPickerStart).inMilliseconds}ms');
    if (file == null) {
      debugPrint('[IMPORT] Picker returned null');
      return ModelImportResult.cancelled;
    }
    debugPrint('[IMPORT] Selected file: ${file.path}');

    try {
      state = state.copyWith(
          isImportingModel: true,
          importProgress: 0.0,
          importPhase: 'preparing');

      debugPrint('[IMPORT] Waiting for init...');
      final tInitStart = DateTime.now();
      await _initFuture;
      final tInitEnd = DateTime.now();
      debugPrint(
          '[IMPORT] Init completed in ${tInitEnd.difference(tInitStart).inMilliseconds}ms');

      final basename = p.basename(file.path);
      final directory = await getApplicationSupportDirectory();
      final targetPath = '${directory.path}/models/$basename';
      final targetFile = File(targetPath);

      // ── If destination already exists ──
      final tDestCheckStart = DateTime.now();
      if (await targetFile.exists()) {
        ModelDefinition? matched;
        for (final candidate in ModelCatalog.availableModels) {
          if (candidate.localFilename == basename) {
            matched = candidate;
            break;
          }
        }
        if (matched != null) {
          state = state.copyWith(importPhase: 'validating');
          final tDestValidateStart = DateTime.now();
          final existingValidation = await validateModelFile(
            matched,
            onHashProgress: (progress) {
              state = state.copyWith(importProgress: progress);
            },
          );
          final tDestValidateEnd = DateTime.now();
          debugPrint(
              '[IMPORT] Existing file validation done in ${tDestValidateEnd.difference(tDestValidateStart).inMilliseconds}ms (valid: ${existingValidation.isValid})');
          if (existingValidation.isValid) {
            final currentIds = state.downloadedModelIds;
            final updatedIds = currentIds.contains(matched.id)
                ? currentIds
                : [...currentIds, matched.id];

            final updatedStates =
                Map<String, ModelInstallState>.from(state.installStates);
            if (state.activeModelId != null) {
              updatedStates[state.activeModelId!] = ModelInstallState.installed;
            }
            updatedStates[matched.id] = ModelInstallState.active;

            final resolvedPath = existingValidation.path ?? targetPath;
            state = state.copyWith(
              downloadedModelIds: updatedIds,
              activeModelId: matched.id,
              activeModelPath: resolvedPath,
              installStates: updatedStates,
            );

            await _persistence.saveInstalledModels(updatedIds);
            await _persistence.saveActiveModelId(matched.id);
            return ModelImportResult.success;
          } else {
            debugPrint('[IMPORT] Existing file invalid, deleting...');
            try {
              await targetFile.delete();
            } catch (_) {}
          }
        } else {
          throw StateError('Este modelo no está en el catálogo de MUSA.');
        }
      }
      final tDestCheckEnd = DateTime.now();
      debugPrint(
          '[IMPORT] Destination check completed in ${tDestCheckEnd.difference(tDestCheckStart).inMilliseconds}ms');

      // ── Copy from selected file ──
      debugPrint('[IMPORT] Copying file...');
      final tCopyStart = DateTime.now();
      await targetFile.parent.create(recursive: true);
      await File(file.path).copy(targetPath);
      final tCopyEnd = DateTime.now();
      debugPrint(
          '[IMPORT] File copy done in ${tCopyEnd.difference(tCopyStart).inMilliseconds}ms');

      // ── Validate the copied file ──
      state = state.copyWith(importPhase: 'validating');
      debugPrint('[IMPORT] Validating copied file...');
      final tValStart = DateTime.now();
      ModelDefinition? matched;
      for (final candidate in ModelCatalog.availableModels) {
        if (candidate.localFilename == basename) {
          matched = candidate;
          break;
        }
      }
      if (matched == null) {
        try {
          await targetFile.delete();
        } catch (_) {}
        throw StateError('Este modelo no está en el catálogo de MUSA.');
      }

      final validation = await validateModelFile(
        matched,
        onHashProgress: (progress) {
          state = state.copyWith(importProgress: progress);
        },
      );
      final tValEnd = DateTime.now();
      debugPrint(
          '[IMPORT] Validation done in ${tValEnd.difference(tValStart).inMilliseconds}ms (valid: ${validation.isValid})');
      if (!validation.isValid) {
        if (await targetFile.exists()) {
          try {
            await targetFile.delete();
          } catch (_) {}
        }
        throw StateError(
            'El archivo no es un modelo válido: ${validation.error}');
      }

      // ── Update state ──
      debugPrint('[IMPORT] Persisting registration...');
      final tPersistStart = DateTime.now();
      final currentIds = state.downloadedModelIds;
      final updatedIds = currentIds.contains(matched.id)
          ? currentIds
          : [...currentIds, matched.id];

      final updatedStates =
          Map<String, ModelInstallState>.from(state.installStates);
      if (state.activeModelId != null) {
        updatedStates[state.activeModelId!] = ModelInstallState.installed;
      }
      updatedStates[matched.id] = ModelInstallState.active;

      final resolvedPath = validation.path ?? targetPath;
      state = state.copyWith(
        downloadedModelIds: updatedIds,
        activeModelId: matched.id,
        activeModelPath: resolvedPath,
        installStates: updatedStates,
      );

      await _persistence.saveInstalledModels(updatedIds);
      await _persistence.saveActiveModelId(matched.id);
      final tPersistEnd = DateTime.now();
      debugPrint(
          '[IMPORT] Registration persisted in ${tPersistEnd.difference(tPersistStart).inMilliseconds}ms');
      final tEnd = DateTime.now();
      debugPrint(
          '[IMPORT] Total import flow: ${tEnd.difference(t0).inMilliseconds}ms');
      return ModelImportResult.success;
    } finally {
      state = state.copyWith(
          isImportingModel: false, importProgress: 0.0, importPhase: '');
    }
  }

  Future<ModelValidationResult> validateModelFile(
    ModelDefinition model, {
    String? pathOverride,
    int? expectedBytesOverride,
    void Function(double progress)? onHashProgress,
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
      computedSha256 = await _computeSha256(file, onProgress: onHashProgress);
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

  Future<String> _computeSha256(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    final totalBytes = await file.length();
    int bytesProcessed = 0;
    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        bytesProcessed += data.length;
        if (totalBytes > 0) {
          onProgress?.call(bytesProcessed / totalBytes);
        }
        sink.add(data);
      },
    );
    final stream = file.openRead().transform(transformer);
    final digest = await sha256.bind(stream).first;
    onProgress?.call(1.0);
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

  Future<void> _reconcileInstalledModels(
    List<String> installedIds,
    Map<String, String> validatedPaths,
  ) async {
    debugPrint('[RECONCILE] Starting model reconciliation');
    final directory = await getApplicationSupportDirectory();
    final modelsDir = Directory('${directory.path}/models');
    debugPrint('[RECONCILE] modelsDir: ${modelsDir.path}');
    if (!await modelsDir.exists()) {
      debugPrint('[RECONCILE] modelsDir does not exist');
      return;
    }

    final files = await modelsDir
        .list(followLinks: false)
        .where((e) => e is File && e.path.endsWith('.gguf'))
        .cast<File>()
        .toList();
    debugPrint('[RECONCILE] Found ${files.length} .gguf files');
    for (final file in files) {
      debugPrint('[RECONCILE] File: ${file.path}');
    }

    for (final file in files) {
      final basename = file.path.split('/').last;
      debugPrint('[RECONCILE] basename: $basename');

      ModelDefinition? matchedModel;
      for (final candidate in ModelCatalog.availableModels) {
        if (candidate.localFilename == basename) {
          matchedModel = candidate;
          break;
        }
      }
      if (matchedModel == null) {
        debugPrint('[RECONCILE] No match for $basename');
        continue;
      }
      debugPrint('[RECONCILE] Matched model: ${matchedModel.id}');
      if (installedIds.contains(matchedModel.id)) continue;

      final validation = await validateModelFile(matchedModel);
      debugPrint(
          '[RECONCILE] Validation for ${matchedModel.id}: ${validation.isValid}');
      if (validation.isValid) {
        debugPrint('[RECONCILE] Adding model: ${matchedModel.id}');
        installedIds.add(matchedModel.id);
        if (validation.path != null) {
          validatedPaths[matchedModel.id] = validation.path!;
        }
      } else {
        debugPrint('[RECONCILE] Validation FAILED for ${matchedModel.id}');
      }
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
  final bool isImportingModel;
  final double importProgress;
  final String importPhase;

  ModelManagerState({
    this.downloadProgress = const {},
    this.installStates = const {},
    this.downloadedModelIds = const [],
    this.activeModelId,
    this.activeModelPath,
    this.downloadError,
    this.isImportingModel = false,
    this.importProgress = 0.0,
    this.importPhase = '',
  });

  ModelManagerState copyWith({
    Map<String, double>? downloadProgress,
    Map<String, ModelInstallState>? installStates,
    List<String>? downloadedModelIds,
    Object? activeModelId = _unset,
    Object? activeModelPath = _unset,
    Object? downloadError = _unset,
    bool clearDownloadError = false,
    bool? isImportingModel,
    double? importProgress,
    String? importPhase,
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
      isImportingModel: isImportingModel ?? this.isImportingModel,
      importProgress: importProgress ?? this.importProgress,
      importPhase: importPhase ?? this.importPhase,
    );
  }
}

final modelManagerProvider =
    StateNotifierProvider<ModelManager, ModelManagerState>((ref) {
  return ModelManager();
});
