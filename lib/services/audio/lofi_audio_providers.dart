import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lofi_audio_service.dart';
import 'lofi_track.dart';

final lofiAudioServiceProvider = Provider<LofiAudioService>((ref) {
  return LofiAudioService();
});

final lofiCatalogProvider = FutureProvider<LofiCatalog>((ref) async {
  final service = ref.watch(lofiAudioServiceProvider);
  await service.initialize();
  return service.catalog;
});

final lofiCurrentTrackProvider =
    StateNotifierProvider<LofiCurrentTrackNotifier, LofiTrack?>((ref) {
  return LofiCurrentTrackNotifier(ref);
});

class LofiCurrentTrackNotifier extends StateNotifier<LofiTrack?> {
  final Ref ref;

  LofiCurrentTrackNotifier(this.ref) : super(null) {
    _loadLastTrack();
  }

  void _loadLastTrack() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTrackFileName = prefs.getString('lofi_last_track');
    if (lastTrackFileName != null) {
      try {
        final catalog = await ref.read(lofiCatalogProvider.future);
        final track = catalog.tracks
            .firstWhere((t) => t.filename == lastTrackFileName);
        state = track;
      } catch (e) {
        // Track not found, ignore
      }
    }
  }

  void setTrack(LofiTrack track) {
    state = track;
    _saveLastTrack(track.filename);
  }

  void clearTrack() {
    state = null;
    _clearLastTrack();
  }

  Future<void> _saveLastTrack(String filename) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lofi_last_track', filename);
  }

  Future<void> _clearLastTrack() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lofi_last_track');
  }
}

final lofiIsPlayingProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(lofiAudioServiceProvider);
  await service.initialize();
  yield* service.playerStateStream.map((state) => state.playing);
});

final lofiVolumeProvider =
    StateNotifierProvider<LofiVolumeNotifier, double>((ref) {
  return LofiVolumeNotifier(ref);
});

class LofiVolumeNotifier extends StateNotifier<double> {
  final Ref ref;

  LofiVolumeNotifier(this.ref) : super(1.0) {
    _loadVolume();
  }

  void _loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    final volume = prefs.getDouble('lofi_volume') ?? 1.0;
    state = volume;
    final service = ref.read(lofiAudioServiceProvider);
    await service.initialize();
    service.setVolume(volume);
  }

  void setVolume(double volume) {
    state = volume;
    ref.read(lofiAudioServiceProvider).setVolume(volume);
    _saveVolume(volume);
  }

  Future<void> _saveVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lofi_volume', volume);
  }
}
