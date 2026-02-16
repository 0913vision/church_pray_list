import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/datasources/remote/supabase_datasource.dart';

class VersionCheckState {
  final bool isUpdateRequired;
  final bool isChecking;
  final String currentVersion;
  final String minVersion;

  const VersionCheckState({
    this.isUpdateRequired = false,
    this.isChecking = true,
    this.currentVersion = '1.0.0',
    this.minVersion = '1.0.0',
  });

  VersionCheckState copyWith({
    bool? isUpdateRequired,
    bool? isChecking,
    String? currentVersion,
    String? minVersion,
  }) {
    return VersionCheckState(
      isUpdateRequired: isUpdateRequired ?? this.isUpdateRequired,
      isChecking: isChecking ?? this.isChecking,
      currentVersion: currentVersion ?? this.currentVersion,
      minVersion: minVersion ?? this.minVersion,
    );
  }
}

final versionCheckProvider =
    StateNotifierProvider<VersionCheckNotifier, VersionCheckState>((ref) {
  return VersionCheckNotifier();
});

class VersionCheckNotifier extends StateNotifier<VersionCheckState> {
  VersionCheckNotifier({SupabaseDatasource? datasource})
      : _datasource = datasource ?? SupabaseDatasource(),
        super(const VersionCheckState()) {
    _checkVersion();
  }

  final SupabaseDatasource _datasource;

  Future<void> _checkVersion() async {
    try {
      state = state.copyWith(isChecking: true);

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      state = state.copyWith(currentVersion: currentVersion);

      final platform = Platform.isAndroid ? 'android' : 'ios';
      final config = await _datasource.fetchAppConfig(platform);

      if (config == null) {
        state = state.copyWith(isUpdateRequired: false, isChecking: false);
        return;
      }

      state = state.copyWith(
        minVersion: config.minVersion,
        isUpdateRequired: currentBuildNumber < config.minVersionCode,
        isChecking: false,
      );
    } catch (e) {
      debugPrint('Version check error: $e');
      state = state.copyWith(isUpdateRequired: false, isChecking: false);
    }
  }
}
