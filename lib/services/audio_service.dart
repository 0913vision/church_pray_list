import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../core/constants/app_constants.dart';

abstract class AudioService {
  Future<void> initialize();
  Future<void> setVolume(double volume);
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
}

class JustAudioService implements AudioService {
  JustAudioService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _player.setAsset(AppConstants.backgroundMusicAsset);
      await _player.setLoopMode(LoopMode.one);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize audio: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}
