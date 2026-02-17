import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/editable_prayer_data.dart';
import '../../../providers/font_size_provider.dart';
import '../../../widgets/animated_modal.dart';

class PrayerItemEditor extends ConsumerStatefulWidget {
  const PrayerItemEditor({
    super.key,
    required this.item,
    required this.itemIndex,
    required this.onUpdate,
    required this.onRemove,
    required this.canRemove,
  });

  final EditablePrayerItem item;
  final int itemIndex;
  final void Function(String itemId, EditablePrayerItem item) onUpdate;
  final void Function(String itemId) onRemove;
  final bool canRemove;

  @override
  ConsumerState<PrayerItemEditor> createState() => _PrayerItemEditorState();
}

class _PrayerItemEditorState extends ConsumerState<PrayerItemEditor>
    with SingleTickerProviderStateMixin {
  bool _isDeleting = false;
  late AnimationController _deleteController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _heightAnimation;
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.item.content);
    _deleteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: -400.0).animate(
      CurvedAnimation(
        parent: _deleteController,
        curve: const Interval(0.0, 0.56, curve: Curves.easeInOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _deleteController,
        curve: const Interval(0.0, 0.56, curve: Curves.easeInOut),
      ),
    );

    _heightAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _deleteController,
        curve: const Interval(0.56, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant PrayerItemEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.content != widget.item.content &&
        widget.item.content != _textController.text) {
      _textController.text = widget.item.content;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _deleteController.dispose();
    super.dispose();
  }

  void _startDeleteAnimation() {
    setState(() => _isDeleting = true);
    _deleteController.forward().then((_) {
      widget.onRemove(widget.item.id);
    });
  }

  void _handleRemovePress() {
    if (!widget.canRemove || _isDeleting) return;

    if (widget.item.content.trim().isEmpty) {
      _startDeleteAnimation();
      return;
    }

    _showDeleteConfirmation();
  }

  void _showDeleteConfirmation() {
    final fontSize = ref.read(fontSizeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAnimatedDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 384),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262626) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\uAE30\uB3C4\uC81C\uBAA9 \uC0AD\uC81C',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize * 0.16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '\uC774 \uAE30\uB3C4\uC81C\uBAA9\uC744 \uC0AD\uC81C\uD560\uAE4C\uC694?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize * 0.13,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF525252),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _ModalButton(
                      label: '\uCDE8\uC18C',
                      fontSize: fontSize * 0.14,
                      isDark: isDark,
                      isDestructive: false,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModalButton(
                      label: '\uC0AD\uC81C',
                      fontSize: fontSize * 0.14,
                      isDark: isDark,
                      isDestructive: true,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _startDeleteAnimation();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(fontSizeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    Widget content = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Bullet
          SizedBox(
            width: 20,
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Text input
          Expanded(
            child: TextField(
              controller: _textController,
              onChanged: (value) {
                widget.onUpdate(
                  widget.item.id,
                  EditablePrayerItem(
                    id: widget.item.id,
                    content: value,
                    isNew: widget.item.isNew,
                  ),
                );
              },
              maxLines: null,
              style: TextStyle(
                fontSize: fontSize * 0.14,
                color: isDark ? Colors.white : const Color(0xFF171717),
              ),
              decoration: InputDecoration(
                hintText: '${widget.itemIndex}\uBC88\uC9F8 \uAE30\uB3C4\uC81C\uBAA9',
                hintStyle: TextStyle(
                  fontSize: fontSize * 0.14,
                  color: isDark
                      ? AppColors.textPlaceholderDark
                      : AppColors.textPlaceholderLight,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF404040)
                    : Colors.white,
                isDense: true,
              ),
            ),
          ),

          // Delete button
          GestureDetector(
            onTap: _handleRemovePress,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
              child: Icon(
                Icons.delete_outline,
                size: fontSize * 0.14,
                color: widget.canRemove
                    ? (isDark ? AppColors.errorDark : AppColors.errorLight)
                    : (isDark
                        ? AppColors.disabledDark
                        : AppColors.disabledLight),
              ),
            ),
          ),
        ],
      ),
    );

    if (_isDeleting) {
      return AnimatedBuilder(
        animation: _deleteController,
        builder: (context, child) {
          return ClipRect(
            child: Align(
              alignment: Alignment.topLeft,
              heightFactor: _heightAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.translate(
                  offset: Offset(_slideAnimation.value, 0),
                  child: content,
                ),
              ),
            ),
          );
        },
      );
    }

    return content;
  }
}

class _ModalButton extends StatelessWidget {
  const _ModalButton({
    required this.label,
    required this.fontSize,
    required this.isDark,
    required this.isDestructive,
    required this.onPressed,
  });

  final String label;
  final double fontSize;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive
            ? (isDark ? const Color(0xFFDC2626) : const Color(0xFFEF4444))
            : (isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB)),
        foregroundColor: isDestructive
            ? Colors.white
            : (isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
