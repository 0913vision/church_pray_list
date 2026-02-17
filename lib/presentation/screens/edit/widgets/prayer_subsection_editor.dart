import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/editable_prayer_data.dart';
import '../../../providers/font_size_provider.dart';
import '../../../widgets/animated_modal.dart';
import 'prayer_item_editor.dart';

class PrayerSubsectionEditor extends ConsumerStatefulWidget {
  const PrayerSubsectionEditor({
    super.key,
    required this.subsection,
    required this.subsectionIndex,
    required this.onUpdate,
    required this.onRemove,
  });

  final EditablePrayerSubsection subsection;
  final int subsectionIndex;
  final void Function(String subsectionId, EditablePrayerSubsection subsection)
      onUpdate;
  final void Function(String subsectionId) onRemove;

  @override
  ConsumerState<PrayerSubsectionEditor> createState() =>
      _PrayerSubsectionEditorState();
}

class _PrayerSubsectionEditorState
    extends ConsumerState<PrayerSubsectionEditor>
    with SingleTickerProviderStateMixin {
  bool _isDeleting = false;
  late AnimationController _deleteController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _heightAnimation;

  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subsection.name);
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
  void didUpdateWidget(covariant PrayerSubsectionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subsection.name != widget.subsection.name &&
        widget.subsection.name != _nameController.text) {
      _nameController.text = widget.subsection.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deleteController.dispose();
    super.dispose();
  }

  int _itemIdCounter = 0;
  String _generateItemId() =>
      'sub-item-${DateTime.now().millisecondsSinceEpoch}-${_itemIdCounter++}';

  void _addItem() {
    final newItem = EditablePrayerItem(
      id: _generateItemId(),
      isNew: true,
    );
    widget.onUpdate(widget.subsection.id, EditablePrayerSubsection(
      id: widget.subsection.id,
      name: widget.subsection.name,
      items: [...widget.subsection.items, newItem],
      isNew: widget.subsection.isNew,
    ));
  }

  void _updateItem(String itemId, EditablePrayerItem updatedItem) {
    widget.onUpdate(widget.subsection.id, EditablePrayerSubsection(
      id: widget.subsection.id,
      name: widget.subsection.name,
      items: widget.subsection.items
          .map((item) => item.id == itemId ? updatedItem : item)
          .toList(),
      isNew: widget.subsection.isNew,
    ));
  }

  void _removeItem(String itemId) {
    widget.onUpdate(widget.subsection.id, EditablePrayerSubsection(
      id: widget.subsection.id,
      name: widget.subsection.name,
      items: widget.subsection.items
          .where((item) => item.id != itemId)
          .toList(),
      isNew: widget.subsection.isNew,
    ));
  }

  void _updateName(String name) {
    widget.onUpdate(widget.subsection.id, EditablePrayerSubsection(
      id: widget.subsection.id,
      name: name,
      items: widget.subsection.items,
      isNew: widget.subsection.isNew,
    ));
  }

  void _startDeleteAnimation() {
    setState(() => _isDeleting = true);
    _deleteController.forward().then((_) {
      widget.onRemove(widget.subsection.id);
    });
  }

  void _handleRemovePress() {
    if (_isDeleting) return;

    final hasName = widget.subsection.name.trim().isNotEmpty;
    final hasContent =
        widget.subsection.items.any((item) => item.content.trim().isNotEmpty);

    if (!hasName && !hasContent) {
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
                '\uC138\uBD80 \uC8FC\uC81C \uC0AD\uC81C',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize * 0.16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '\uC774 \uC138\uBD80 \uC8FC\uC81C\uB97C \uC0AD\uC81C\uD560\uAE4C\uC694?\n\uC138\uBD80 \uC8FC\uC81C\uC758 \uBAA8\uB4E0 \uAE30\uB3C4\uC81C\uBAA9\uC774 \uD568\uAED8 \uC9C0\uC6CC\uC9D1\uB2C8\uB2E4.',
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
                    child: _buildModalButton(
                      '\uCDE8\uC18C', fontSize * 0.14, isDark, false,
                      () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModalButton(
                      '\uC0AD\uC81C', fontSize * 0.14, isDark, true,
                      () {
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

  Widget _buildModalButton(String label, double fontSize, bool isDark,
      bool isDestructive, VoidCallback onPressed) {
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

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(fontSizeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171717) : Colors.white,
        border: Border.all(
          color: isDark
              ? const Color(0xFF404040)
              : const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subsection name + delete button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  onChanged: _updateName,
                  style: TextStyle(
                    fontSize: fontSize * 0.13,
                    color: isDark ? Colors.white : const Color(0xFF171717),
                  ),
                  decoration: InputDecoration(
                    hintText:
                        '\uC138\uBD80 \uC8FC\uC81C ${widget.subsectionIndex} (\uD544\uC218)',
                    hintStyle: TextStyle(
                      fontSize: fontSize * 0.13,
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
                        ? const Color(0xFF262626)
                        : const Color(0xFFF9FAFB),
                    isDense: true,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _handleRemovePress,
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                  child: Icon(
                    Icons.delete_outline,
                    size: fontSize * 0.13,
                    color: isDark
                        ? AppColors.errorDark
                        : AppColors.errorLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items
          for (int i = 0; i < widget.subsection.items.length; i++)
            PrayerItemEditor(
              key: ValueKey(widget.subsection.items[i].id),
              item: widget.subsection.items[i],
              itemIndex: i + 1,
              onUpdate: _updateItem,
              onRemove: _removeItem,
              canRemove: widget.subsection.items.length > 1,
            ),

          // Add item button
          GestureDetector(
            onTap: _addItem,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+ \uC138\uBD80 \uC8FC\uC81C \uAE30\uB3C4\uC81C\uBAA9 \uCD94\uAC00',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize * 0.14,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
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
