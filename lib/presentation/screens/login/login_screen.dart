import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;

    if (authState.loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                const Text(
                  '\uD83D\uDD10',
                  style: TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  '\uC0AC\uB791\uC758\uBE5B\uAD50\uD68C \uAE30\uB3C4 \uC81C\uBAA9',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  '\uAE30\uB3C4 \uC81C\uBAA9\uC744 \uD655\uC778\uD558\uB824\uBA74\n\uB85C\uADF8\uC778\uC774 \uD544\uC694\uD574\uC694',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.44,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF525252),
                  ),
                ),
                const SizedBox(height: 24),

                // Kakao Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleKakaoLogin(context, ref),
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
                    child: const Text(
                      '\uCE74\uCE74\uC624\uB85C \uB85C\uADF8\uC778',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Terms notice
                Text(
                  '\uB85C\uADF8\uC778\uD558\uBA74 \uC11C\uBE44\uC2A4 \uC774\uC6A9\uC57D\uAD00\uC5D0 \uB3D9\uC758\uD558\uAC8C \uB429\uB2C8\uB2E4',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleKakaoLogin(BuildContext context, WidgetRef ref) async {
    final error = await ref.read(authProvider.notifier).signInWithKakao();

    if (error != null && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('\uB85C\uADF8\uC778 \uC624\uB958'),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('\uD655\uC778'),
            ),
          ],
        ),
      );
    }
  }
}
