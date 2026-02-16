import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/font_size_provider.dart';
import '../../../providers/audio_provider.dart';
import '../../../providers/theme_provider.dart';

class TopBar extends ConsumerWidget {
  const TopBar({super.key, this.onEditPress});

  final VoidCallback? onEditPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final isPlaying = ref.watch(audioProvider);
    final iconColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF171717).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color(0xFF404040).withValues(alpha: 0.3)
                : const Color(0xFFE5E7EB).withValues(alpha: 0.5),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (authState.isAuthor)
                _IconButton(
                  icon: Icons.edit_outlined,
                  color: iconColor,
                  onPressed: onEditPress,
                ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _IconButton(
                icon: Icons.remove,
                color: iconColor,
                size: 20,
                onPressed: fontSize <= FontSizeNotifier.minSize
                    ? null
                    : () => ref.read(fontSizeProvider.notifier).decrease(),
              ),
              _IconButton(
                icon: Icons.add,
                color: iconColor,
                size: 20,
                onPressed: fontSize >= FontSizeNotifier.maxSize
                    ? null
                    : () => ref.read(fontSizeProvider.notifier).increase(),
              ),
              _IconButton(
                icon: isPlaying ? Icons.volume_up : Icons.volume_off,
                color: iconColor,
                onPressed: () {
                  final notifier = ref.read(audioProvider.notifier);
                  isPlaying ? notifier.pause() : notifier.play();
                },
              ),
              _IconButton(
                icon: isDark
                    ? Icons.wb_sunny_outlined
                    : Icons.dark_mode_outlined,
                color: iconColor,
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggleTheme(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.color,
    this.onPressed,
    this.size = 24,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: size,
          color: onPressed != null ? color : color.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
