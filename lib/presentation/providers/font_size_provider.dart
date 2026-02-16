import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, int>((ref) {
  return FontSizeNotifier();
});

class FontSizeNotifier extends StateNotifier<int> {
  FontSizeNotifier({SharedPreferences? prefs})
      : _prefsFuture =
            prefs != null ? Future.value(prefs) : SharedPreferences.getInstance(),
        super(_defaultSize) {
    _ready = _loadFontSize();
  }

  static const int minSize = 80;
  static const int maxSize = 200;
  static const int step = 10;
  static const int _defaultSize = 100;

  final Future<SharedPreferences> _prefsFuture;
  late final Future<void> _ready;

  Future<void> get ready => _ready;

  Future<void> _loadFontSize() async {
    final prefs = await _prefsFuture;
    final storedSize = prefs.getInt(AppConstants.fontSizeKey);
    if (storedSize != null) {
      state = storedSize.clamp(minSize, maxSize);
    }
  }

  Future<void> increase() async {
    if (state >= maxSize) return;
    state = (state + step).clamp(minSize, maxSize);
    await _saveFontSize();
  }

  Future<void> decrease() async {
    if (state <= minSize) return;
    state = (state - step).clamp(minSize, maxSize);
    await _saveFontSize();
  }

  Future<void> _saveFontSize() async {
    final prefs = await _prefsFuture;
    await prefs.setInt(AppConstants.fontSizeKey, state);
  }

  double getScaledSize(double baseSize) => baseSize * (state / 100);
}
