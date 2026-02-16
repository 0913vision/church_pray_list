import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/audio_provider.dart';

class PrayListApp extends ConsumerStatefulWidget {
  const PrayListApp({super.key});

  @override
  ConsumerState<PrayListApp> createState() => _PrayListAppState();
}

class _PrayListAppState extends ConsumerState<PrayListApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audioNotifier = ref.read(audioProvider.notifier);
    final isPlaying = ref.read(audioProvider);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background - pause music
      if (isPlaying) {
        audioNotifier.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '\uC0AC\uBE5B\uAD50 \uAE30\uB3C4\uC81C\uBAA9',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
    );
  }
}
