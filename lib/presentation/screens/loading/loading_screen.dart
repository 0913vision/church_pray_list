import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, this.message = '\uB85C\uB529 \uC911...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 22,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF525252),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
