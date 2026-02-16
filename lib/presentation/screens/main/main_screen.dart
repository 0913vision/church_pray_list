import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/prayer_provider.dart';
import '../../widgets/custom_pull_to_refresh.dart';
import '../../widgets/custom_toast.dart';
import 'widgets/top_bar.dart';
import 'widgets/prayer_display.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final _ptrKey = GlobalKey<CustomPullToRefreshState>();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final notifier = ref.read(prayerProvider.notifier);

    await notifier.loadCachedData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ptrKey.currentState?.triggerRefresh();
    });
  }

  Future<void> _refreshData() async {
    final success =
        await ref.read(prayerProvider.notifier).fetchLatestPrayer();

    if (!mounted) return;

    showCustomToast(
      context,
      message: success ? '최신 기도제목을 불러왔습니다' : '기도제목을 불러오는데 실패했습니다',
      isError: !success,
      duration: Duration(seconds: success ? 2 : 3),
    );
  }

  void _handleEditPress() {
    context.push<bool>('/edit').then((saved) {
      if (saved == true) {
        _ptrKey.currentState?.triggerRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prayerState = ref.watch(prayerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(onEditPress: _handleEditPress),
            Expanded(
              child: CustomPullToRefresh(
                key: _ptrKey,
                onRefresh: _refreshData,
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 24,
                  right: 24,
                  bottom: 32,
                ),
                child: prayerState.prayerData != null
                    ? PrayerDisplay(
                        title: prayerState.prayerData!.title,
                        sections: prayerState.prayerData!.sections,
                        verse: prayerState.prayerData!.verse,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
