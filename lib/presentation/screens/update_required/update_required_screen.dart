import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/version_check_provider.dart';

class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionState = ref.watch(versionCheckProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                const Text('\uD83D\uDCF1', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 24),

                // Title
                Text(
                  '\uC5C5\uB370\uC774\uD2B8\uAC00 \uD544\uC694\uD569\uB2C8\uB2E4',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  '\uB354 \uB098\uC740 \uC11C\uBE44\uC2A4\uB97C \uC704\uD574\n\uCD5C\uC2E0 \uBC84\uC804\uC73C\uB85C \uC5C5\uB370\uC774\uD2B8\uD574\uC8FC\uC138\uC694',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF525252),
                  ),
                ),
                const SizedBox(height: 24),

                // Version info box
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF262626)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildVersionRow(
                        '\uD604\uC7AC \uBC84\uC804',
                        'v${versionState.currentVersion}',
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildVersionRow(
                        '\uCD5C\uC2E0 \uBC84\uC804',
                        'v${versionState.minVersion}',
                        isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Update button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleUpdatePress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.buttonUpdateDark
                          : AppColors.buttonUpdateLight,
                      foregroundColor: AppColors.textPrimaryLight,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      Platform.isAndroid
                          ? 'Play \uC2A4\uD1A0\uC5B4\uC5D0\uC11C \uC5C5\uB370\uC774\uD2B8'
                          : 'App Store\uC5D0\uC11C \uC5C5\uB370\uC774\uD2B8',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionRow(String label, String version, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 20,
            color: isDark
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF525252),
          ),
        ),
        Text(
          version,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF171717),
          ),
        ),
      ],
    );
  }

  Future<void> _handleUpdatePress() async {
    final storeUrl = Platform.isAndroid
        ? Uri.parse('market://details?id=com.lovelight.prayerlist')
        : Uri.parse('https://apps.apple.com/app/idYOUR_APP_ID');

    try {
      await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      final webUrl = Platform.isAndroid
          ? Uri.parse(
              'https://play.google.com/store/apps/details?id=com.lovelight.prayerlist')
          : Uri.parse('https://apps.apple.com/app/idYOUR_APP_ID');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }
}
