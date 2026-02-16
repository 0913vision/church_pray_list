import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pray_list_v2/presentation/providers/font_size_provider.dart';
import 'package:pray_list_v2/core/constants/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads saved font size and clamps', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.fontSizeKey: 999,
    });
    final prefs = await SharedPreferences.getInstance();
    final notifier = FontSizeNotifier(prefs: prefs);

    await notifier.ready;

    expect(notifier.state, FontSizeNotifier.maxSize);
  });

  test('increase/decrease persists', () async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = FontSizeNotifier(prefs: prefs);

    await notifier.ready;
    await notifier.increase();
    expect(notifier.state, 110);
    expect(prefs.getInt(AppConstants.fontSizeKey), 110);

    await notifier.decrease();
    expect(notifier.state, 100);
    expect(prefs.getInt(AppConstants.fontSizeKey), 100);
  });

  test('getScaledSize returns scaled value', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.fontSizeKey: 150,
    });
    final prefs = await SharedPreferences.getInstance();
    final notifier = FontSizeNotifier(prefs: prefs);

    await notifier.ready;

    expect(notifier.getScaledSize(20), 30);
  });
}
