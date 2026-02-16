import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/prayer_data.dart';
import '../../data/repositories/prayer_repository.dart';

class PrayerState {
  final PrayerData? prayerData;
  final bool loading;
  final String? error;

  const PrayerState({
    this.prayerData,
    this.loading = false,
    this.error,
  });

  PrayerState copyWith({
    PrayerData? prayerData,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return PrayerState(
      prayerData: prayerData ?? this.prayerData,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final prayerProvider =
    StateNotifierProvider<PrayerNotifier, PrayerState>((ref) {
  return PrayerNotifier();
});

class PrayerNotifier extends StateNotifier<PrayerState> {
  PrayerNotifier({PrayerRepository? repository})
      : _repository = repository ?? PrayerRepository(),
        super(const PrayerState());

  final PrayerRepository _repository;

  /// Load cached data first, then fetch from server
  Future<void> loadCachedData() async {
    try {
      final cached = await _repository.loadCachedData();
      if (cached != null) {
        state = state.copyWith(prayerData: cached);
      }
    } catch (e) {
      debugPrint('Error loading cached data: $e');
    }
  }

  /// Fetch latest prayer from server
  Future<bool> fetchLatestPrayer() async {
    try {
      state = state.copyWith(loading: true, clearError: true);

      final data = await _repository.fetchLatestPrayer();

      if (data != null) {
        state = state.copyWith(prayerData: data, loading: false);
        return true;
      } else {
        state = state.copyWith(
          loading: false,
          error: '\uAE30\uB3C4\uC81C\uBAA9\uC744 \uBD88\uB7EC\uC624\uB294\uB370 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Upload prayer data
  Future<bool> uploadPrayer(PrayerData data) async {
    try {
      state = state.copyWith(loading: true, clearError: true);
      final success = await _repository.uploadPrayer(data);
      state = state.copyWith(loading: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: '\uAE30\uB3C4\uC81C\uBAA9\uC744 \uC5C5\uB85C\uB4DC\uD558\uB294\uB370 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4',
      );
      return false;
    }
  }
}
