import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pray_list_v2/presentation/providers/theme_provider.dart';
import 'package:pray_list_v2/core/constants/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads saved theme mode from prefs', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.themeModeKey: ThemeMode.dark.name,
    });
    final prefs = await SharedPreferences.getInstance();
    final notifier = ThemeModeNotifier(prefs: prefs);

    await notifier.ready;

    expect(notifier.state, ThemeMode.dark);
  });

  test('toggleTheme switches mode and persists', () async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = ThemeModeNotifier(prefs: prefs);

    await notifier.ready;
    await notifier.setThemeMode(ThemeMode.light);
    await notifier.toggleTheme();

    expect(notifier.state, ThemeMode.dark);
    expect(prefs.getString(AppConstants.themeModeKey), ThemeMode.dark.name);
  });
}
