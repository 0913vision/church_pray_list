import 'package:flutter/material.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Text('\uD83D\uDEAB', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 24),

                // Title
                Text(
                  '\uC811\uADFC \uAD8C\uD55C\uC774 \uC5C6\uC2B5\uB2C8\uB2E4',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  '\uC774 \uC571\uC744 \uC0AC\uC6A9\uD558\uB824\uBA74\n\uAD00\uB9AC\uC790\uC758 \uC2B9\uC778\uC774 \uD544\uC694\uD569\uB2C8\uB2E4',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.27,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF525252),
                  ),
                ),
                const SizedBox(height: 24),

                // Info box
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF262626)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '\uAD00\uB9AC\uC790\uC5D0\uAC8C \uBB38\uC758\uD558\uC5EC\n\uC0AC\uC6A9 \uAD8C\uD55C\uC744 \uC694\uCCAD\uD574\uC8FC\uC138\uC694',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.4,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF525252),
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
}
