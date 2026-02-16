import 'package:flutter_test/flutter_test.dart';
import 'package:pray_list_v2/presentation/providers/audio_provider.dart';
import 'package:pray_list_v2/services/audio_service.dart';

class FakeAudioService implements AudioService {
  bool initialized = false;
  bool disposed = false;
  int playCount = 0;
  int pauseCount = 0;
  final List<double> volumes = [];

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> play() async {
    playCount += 1;
  }

  @override
  Future<void> pause() async {
    pauseCount += 1;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

Future<void> _immediateDelay(Duration _) async {}

void main() {
  test('initializes audio on create', () async {
    final service = FakeAudioService();
    final notifier = AudioNotifier(
      audioService: service,
      delay: _immediateDelay,
    );

    await notifier.ready;

    expect(service.initialized, isTrue);
  });

  test('play fades in and updates state', () async {
    final service = FakeAudioService();
    final notifier = AudioNotifier(
      audioService: service,
      delay: _immediateDelay,
    );

    await notifier.ready;
    await notifier.play();

    expect(service.playCount, 1);
    expect(notifier.state, isTrue);
    expect(service.volumes.first, 0.0);
    expect(service.volumes.last, 1.0);
    expect(service.volumes.length, 12);
  });

  test('pause fades out and updates state', () async {
    final service = FakeAudioService();
    final notifier = AudioNotifier(
      audioService: service,
      delay: _immediateDelay,
    );

    await notifier.ready;
    await notifier.pause();

    expect(service.pauseCount, 1);
    expect(notifier.state, isFalse);
    expect(service.volumes.first, 1.0);
    expect(service.volumes.last, 0.0);
    expect(service.volumes.length, 11);
  });
}
