import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../services/audio_service.dart';

typedef DelayFn = Future<void> Function(Duration duration);

final audioProvider = StateNotifierProvider<AudioNotifier, bool>((ref) {
  return AudioNotifier(audioService: JustAudioService());
});

class AudioNotifier extends StateNotifier<bool> {
  AudioNotifier({required AudioService audioService, DelayFn delay = _delay})
      : _audioService = audioService,
        _delayFn = delay,
        super(false) {
    _ready = _audioService.initialize();
  }

  final AudioService _audioService;
  final DelayFn _delayFn;
  late final Future<void> _ready;

  static const int _fadeSteps = 10;
  static const Duration _fadeStepDuration = Duration(milliseconds: 100);

  int _fadeToken = 0;
  double _volume = 0.0;

  Future<void> get ready => _ready;

  Future<void> play() async {
    await _ready;
    if (state) return;
    state = true;
    _fadeToken++;

    try {
      _volume = 0.0;
      await _audioService.setVolume(0.0);
      _audioService.play(); // don't await - completes when playback ends
      await _fadeIn();
    } catch (e) {
      debugPrint('Failed to play: $e');
      state = false;
    }
  }

  Future<void> pause() async {
    await _ready;
    if (!state) return;
    state = false;
    _fadeToken++;

    try {
      await _fadeOut();
      await _audioService.pause();
    } catch (e) {
      debugPrint('Failed to pause: $e');
    }
  }

  Future<void> _fadeIn() async {
    final token = _fadeToken;
    for (var step = 1; step <= _fadeSteps; step++) {
      if (_fadeToken != token) return;
      await _delayFn(_fadeStepDuration);
      if (_fadeToken != token) return;
      _volume = step / _fadeSteps;
      await _audioService.setVolume(_volume);
    }
  }

  Future<void> _fadeOut() async {
    final token = _fadeToken;
    final startVol = _volume;
    for (var step = 1; step <= _fadeSteps; step++) {
      if (_fadeToken != token) return;
      await _delayFn(_fadeStepDuration);
      if (_fadeToken != token) return;
      _volume = startVol * (1.0 - step / _fadeSteps);
      await _audioService.setVolume(_volume);
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}

Future<void> _delay(Duration duration) => Future.delayed(duration);
