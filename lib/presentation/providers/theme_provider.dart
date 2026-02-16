import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier({SharedPreferences? prefs})
      : _prefsFuture =
            prefs != null ? Future.value(prefs) : SharedPreferences.getInstance(),
        super(ThemeMode.system) {
    _ready = _loadThemeMode();
  }

  final Future<SharedPreferences> _prefsFuture;
  late final Future<void> _ready;

  Future<void> get ready => _ready;

  Future<void> _loadThemeMode() async {
    final prefs = await _prefsFuture;
    final themeString = prefs.getString(AppConstants.themeModeKey);

    if (themeString != null) {
      state = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeString,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> toggleTheme() async {
    final newTheme =
        state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newTheme);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await _prefsFuture;
    await prefs.setString(AppConstants.themeModeKey, mode.name);
  }
}
