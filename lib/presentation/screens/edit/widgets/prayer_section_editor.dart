import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/editable_prayer_data.dart';
import '../../../providers/font_size_provider.dart';
import '../../../widgets/animated_modal.dart';
import 'prayer_item_editor.dart';
import 'prayer_subsection_editor.dart';

class PrayerSectionEditor extends ConsumerStatefulWidget {
  const PrayerSectionEditor({
    super.key,
    required this.section,
    required this.sectionIndex,
    required this.onUpdate,
    required this.onRemove,
    required this.canRemove,
  });

  final EditablePrayerSection section;
  final int sectionIndex;
  final void Function(String sectionId, EditablePrayerSection section) onUpdate;
  final void Function(String sectionId) onRemove;
  final bool canRemove;

  @override
  ConsumerState<PrayerSectionEditor> createState() =>
      _PrayerSectionEditorState();
}

class _PrayerSectionEditorState extends ConsumerState<PrayerSectionEditor>
    with SingleTickerProviderStateMixin {
  bool _isDeleting = false;
  late AnimationController _deleteController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _heightAnimation;

  int _itemIdCounter = 0;
  int _subsectionIdCounter = 0;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.section.name);
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
  void didUpdateWidget(covariant PrayerSectionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.name != widget.section.name &&
        widget.section.name != _nameController.text) {
      _nameController.text = widget.section.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deleteController.dispose();
    super.dispose();
  }

  String _generateItemId() =>
      'item-${DateTime.now().millisecondsSinceEpoch}-${_itemIdCounter++}';
  String _generateSubsectionId() =>
      'subsection-${DateTime.now().millisecondsSinceEpoch}-${_subsectionIdCounter++}';

  void _updateSectionName(String name) {
    widget.onUpdate(widget.section.id, EditablePrayerSection(
      id: widget.section.id,
      name: name,
      items: widget.section.items,
      subsections: widget.section.subsections,
      isNew: widget.section.isNew,
    ));
  }

  void _addItem() {
    final newItem = EditablePrayerItem(
      id: _generateItemId(),
      isNew: true,
    );
    widget.onUpdate(widget.section.id, EditablePrayerSection(
      id: widget.section.id,
      name: widget.section.name,
      items: [...widget.section.items, newItem],
      subsections: widget.section.subsections,
      isNew: widget.section.isNew,
    ));
  }

  void _updateItem(String itemId, EditablePrayerItem updatedItem) {
    widget.onUpdate(widget.section.id, EditablePrayerSection(
      id: widget.section.id,
      name: widget.section.name,
      items: widget.section.items
          .map((item) => item.id == itemId ? updatedItem : item)
          .toList(),
      subsections: widget.section.subsections,
      isNew: widget.section.isNew,
    ));
  }

  void _removeItem(String itemId) {
    widget.onUpdate(widget.section.id, EditablePrayerSection(
      id: widget.section.id,
      name: widget.section.name,
      items:
          widget.section.items.where((item) => item.id != itemId).toList(),
      subsections: widget.section.subsections,
      isNew: widget.section.isNew,
    ));
  }

  void _addSubsection() {
    final newSubsection = EditablePrayerSubsection(
      id: _generateSubsectionId(),
      isNew: true,
    );
    widget.onUpdate(widget.section.id, EditablePrayerSection(
      id: widget.section.id,
      name: widget.section.name,
      items: widget.section.items,
      subsections: [...widget.section.subsections, newSubsection],
      isNew: widget.section.isNew,
    ));
  }

  void _updateSubsection(
      String subsectionId, EditablePrayerSubsection updatedSubsection) {
    widget.onUpdate(widget.section.id, EditablePrayerSection(
      id: widget.section.id,
      name: widget.section.name,
      items: widget.section.items,
      subsections: widget.section.subsections
          .map((sub) => sub.id == subsectionId ? updatedSubsection : sub)
          .toList(),
      isNew: widget.section.isNew,
    ));
  }

  void _removeSubsection(String subsectionId) {
    widget.onUpdate(widget.section.id, EditablePrayerSection(
      id: widget.section.id,
      name: widget.section.name,
      items: widget.section.items,
      subsections: widget.section.subsections
          .where((sub) => sub.id != subsectionId)
          .toList(),
      isNew: widget.section.isNew,
    ));
  }

  void _startDeleteAnimation() {
    setState(() => _isDeleting = true);
    _deleteController.forward().then((_) {
      widget.onRemove(widget.section.id);
    });
  }

  void _handleDeletePress() {
    if (!widget.canRemove) return;

    final hasName = widget.section.name.trim().isNotEmpty;
    final hasItems =
        widget.section.items.any((item) => item.content.trim().isNotEmpty);
    final hasSubsections = widget.section.subsections.any((sub) {
      final hasSubName = sub.name.trim().isNotEmpty;
      final hasSubItems =
          sub.items.any((item) => item.content.trim().isNotEmpty);
      return hasSubName || hasSubItems;
    });

    if (!hasName && !hasItems && !hasSubsections) {
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
                '\uC774\uB984/\uC8FC\uC81C \uC0AD\uC81C',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize * 0.16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '\uC774 \uC774\uB984/\uC8FC\uC81C\uB97C \uC0AD\uC81C\uD560\uAE4C\uC694?\n\uACF5\uD1B5 \uAE30\uB3C4\uC81C\uBAA9\uACFC \uC138\uBD80 \uC8FC\uC81C\uAC00 \uBAA8\uB450 \uC9C0\uC6CC\uC9D1\uB2C8\uB2E4.',
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
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFF5F5F5),
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
          // Section name + delete button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  onChanged: _updateSectionName,
                  style: TextStyle(
                    fontSize: fontSize * 0.14,
                    color: isDark ? Colors.white : const Color(0xFF171717),
                  ),
                  decoration: InputDecoration(
                    hintText: '\uC774\uB984 \uB610\uB294 \uC8FC\uC81C (\uD544\uC218, \uC608: \uD64D\uAE38\uB3D9)',
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
              GestureDetector(
                onTap: _handleDeletePress,
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                  child: Icon(
                    Icons.delete_outline,
                    size: fontSize * 0.14,
                    color: widget.canRemove
                        ? (isDark
                            ? AppColors.errorDark
                            : AppColors.errorLight)
                        : (isDark
                            ? AppColors.disabledDark
                            : AppColors.disabledLight),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Common prayer items label
          Text(
            '\uACF5\uD1B5 \uAE30\uB3C4\uC81C\uBAA9',
            style: TextStyle(
              fontSize: fontSize * 0.13,
              height: 1.5,
              color: isDark
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF525252),
            ),
          ),
          const SizedBox(height: 8),

          // Prayer items
          for (int i = 0; i < widget.section.items.length; i++)
            PrayerItemEditor(
              key: ValueKey(widget.section.items[i].id),
              item: widget.section.items[i],
              itemIndex: i + 1,
              onUpdate: _updateItem,
              onRemove: _removeItem,
              canRemove: widget.section.items.isNotEmpty,
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
                '+ \uACF5\uD1B5 \uAE30\uB3C4\uC81C\uBAA9 \uCD94\uAC00',
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

          const SizedBox(height: 16),

          // Subsections label
          Text(
            '\uC138\uBD80 \uC8FC\uC81C',
            style: TextStyle(
              fontSize: fontSize * 0.13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFF374151),
            ),
          ),

          // Subsections
          for (int i = 0; i < widget.section.subsections.length; i++)
            PrayerSubsectionEditor(
              key: ValueKey(widget.section.subsections[i].id),
              subsection: widget.section.subsections[i],
              subsectionIndex: i + 1,
              onUpdate: _updateSubsection,
              onRemove: _removeSubsection,
            ),

          // Add subsection button
          GestureDetector(
            onTap: _addSubsection,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
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
                '+ \uC138\uBD80 \uC8FC\uC81C \uCD94\uAC00',
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
