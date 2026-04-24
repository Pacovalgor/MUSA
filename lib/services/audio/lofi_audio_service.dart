import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'lofi_track.dart';

class LofiAudioService {
  late final AudioPlayer _audioPlayer;
  late LofiCatalog _catalog;
  bool _initialized = false;

  LofiAudioService() {
    _audioPlayer = AudioPlayer();
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final catalogJson =
          await rootBundle.loadString('assets/lofi_music/catalog.json');
      final catalogData = jsonDecode(catalogJson) as Map<String, dynamic>;
      _catalog = LofiCatalog.fromJson(catalogData);
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize LofiAudioService: $e');
    }
  }

  LofiCatalog get catalog {
    if (!_initialized) throw Exception('LofiAudioService not initialized');
    return _catalog;
  }

  Future<void> playTrack(LofiTrack track) async {
    try {
      final assetPath = 'assets/lofi_music/${track.filename}';
      await _audioPlayer.setAsset(assetPath);
      await _audioPlayer.play();
    } catch (e) {
      throw Exception('Failed to play track: $e');
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  void setVolume(double volume) {
    _audioPlayer.setVolume(volume);
  }

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  bool get isPlaying => _audioPlayer.playing;
  LofiTrack? _currentTrack;

  LofiTrack? get currentTrack => _currentTrack;

  void setCurrentTrack(LofiTrack? track) {
    _currentTrack = track;
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
