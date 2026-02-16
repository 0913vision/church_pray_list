import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/editable_prayer_data.dart';
import '../../providers/audio_provider.dart';
import '../../providers/font_size_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../widgets/animated_modal.dart';
import '../../widgets/custom_toast.dart';
import 'widgets/date_selector.dart';
import 'widgets/prayer_section_editor.dart';

class EditScreen extends ConsumerStatefulWidget {
  const EditScreen({super.key});

  @override
  ConsumerState<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends ConsumerState<EditScreen> {
  late EditablePrayerData _prayerData;
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isLoadingData = false;
  bool _wasPlaying = false;
  late final AudioNotifier _audioNotifier;
  int _sectionIdCounter = 0;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // Pause music on edit entry
    _audioNotifier = ref.read(audioProvider.notifier);
    _wasPlaying = ref.read(audioProvider);
    if (_wasPlaying) {
      _audioNotifier.pause();
    }

    // Initialize empty prayer data
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final baseTimestamp = DateTime.now().millisecondsSinceEpoch;

    _prayerData = EditablePrayerData(
      date: dateStr,
      sections: [
        EditablePrayerSection(
          id: 'section-$baseTimestamp',
          isNew: true,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore music if it was playing before entering edit
    if (_wasPlaying) {
      _audioNotifier.play();
    }
    super.dispose();
  }

  String _generateSectionId() =>
      'section-${DateTime.now().millisecondsSinceEpoch}-${_sectionIdCounter++}';

  void _addSection() {
    final newIndex = _prayerData.sections.length;
    setState(() {
      _prayerData.sections.add(EditablePrayerSection(
        id: _generateSectionId(),
        isNew: true,
      ));
      _hasChanges = true;
      _currentPage = newIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _updateSection(String sectionId, EditablePrayerSection updatedSection) {
    setState(() {
      final index =
          _prayerData.sections.indexWhere((s) => s.id == sectionId);
      if (index != -1) {
        _prayerData.sections[index] = updatedSection;
      }
      _hasChanges = true;
    });
  }

  void _removeSection(String sectionId) {
    setState(() {
      _prayerData.sections.removeWhere((s) => s.id == sectionId);
      _hasChanges = true;
      if (_currentPage >= _prayerData.sections.length) {
        _currentPage = _prayerData.sections.length - 1;
      }
      if (_currentPage < 0) _currentPage = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  String? _validateData() {
    if (_prayerData.sections.isEmpty) {
      return '\uCD5C\uC18C \uD558\uB098\uC758 \uC774\uB984/\uC8FC\uC81C\uB97C \uCD94\uAC00\uD574\uC8FC\uC138\uC694.';
    }

    for (final section in _prayerData.sections) {
      if (section.name.trim().isEmpty) {
        return '\uBAA8\uB4E0 \uC774\uB984/\uC8FC\uC81C\uB97C \uC785\uB825\uD574\uC8FC\uC138\uC694.';
      }

      final validItems =
          section.items.where((item) => item.content.trim().isNotEmpty);
      final validSubsections = section.subsections
          .where((sub) => sub.name.trim().isNotEmpty);

      for (final subsection in section.subsections) {
        if (subsection.name.trim().isEmpty) {
          return '"${section.name}" \uC774\uB984/\uC8FC\uC81C\uC758 \uC138\uBD80 \uC8FC\uC81C \uC774\uB984\uC744 \uBAA8\uB450 \uC785\uB825\uD574\uC8FC\uC138\uC694.';
        }
      }

      if (validItems.isEmpty && validSubsections.isEmpty) {
        return '"${section.name}" \uC774\uB984/\uC8FC\uC81C\uC5D0 \uCD5C\uC18C \uD558\uB098\uC758 \uACF5\uD1B5 \uAE30\uB3C4\uC81C\uBAA9 \uB610\uB294 \uC138\uBD80 \uC8FC\uC81C\uB97C \uCD94\uAC00\uD574\uC8FC\uC138\uC694.';
      }
    }

    return null;
  }

  void _handleSave() {
    final error = _validateData();
    if (error != null) {
      _showErrorModal(error);
      return;
    }

    // Generate save title
    final dateParts = _prayerData.date.split('-');
    final year = dateParts[0];
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);
    final autoTitle = '$year\uB144 $month\uC6D4 $day\uC77C \uAE30\uB3C4\uC81C\uBAA9';

    _showSaveModal(autoTitle);
  }

  Future<void> _handleConfirmSave(String autoTitle) async {
    setState(() => _isSaving = true);

    final prayerDataToUpload = _prayerData.toPrayerData();
    final success =
        await ref.read(prayerProvider.notifier).uploadPrayer(prayerDataToUpload);

    if (!mounted) return;

    setState(() => _isSaving = false);
    Navigator.of(context).pop(); // Close save modal

    if (success) {
      showCustomToast(context, message: '\uAE30\uB3C4\uC81C\uBAA9\uC774 \uC800\uC7A5\uB418\uC5C8\uC2B5\uB2C8\uB2E4');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.pop(true);
      });
    } else {
      showCustomToast(
        context,
        message: '\uC800\uC7A5\uC5D0 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4',
        isError: true,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _handleCancel() {
    if (_hasChanges) {
      _showExitModal();
    } else {
      context.pop();
    }
  }

  Future<void> _handleLoadData() async {
    setState(() => _isLoadingData = true);

    try {
      final success =
          await ref.read(prayerProvider.notifier).fetchLatestPrayer();
      final prayerState = ref.read(prayerProvider);

      if (!mounted) return;

      setState(() => _isLoadingData = false);
      Navigator.of(context).pop(); // Close load modal

      if (success && prayerState.prayerData != null) {
        setState(() {
          _prayerData =
              EditablePrayerData.fromPrayerData(prayerState.prayerData!);
          _hasChanges = false;
          _currentPage = 0;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        });
        showCustomToast(context, message: '\uAE30\uB3C4\uC81C\uBAA9\uC744 \uBD88\uB7EC\uC654\uC2B5\uB2C8\uB2E4');
      } else {
        showCustomToast(
          context,
          message: '\uAE30\uB3C4\uC81C\uBAA9\uC744 \uBD88\uB7EC\uC624\uB294\uB370 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4',
          isError: true,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingData = false);
      Navigator.of(context).pop();
      showCustomToast(
        context,
        message: '\uAE30\uB3C4\uC81C\uBAA9\uC744 \uBD88\uB7EC\uC624\uB294\uB370 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4',
        isError: true,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _buildAddSectionPage(
      int fontSize, bool isDark, Color primaryColor) {
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: GestureDetector(
            onTap: _addSection,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: borderColor,
                borderRadius: 8,
                dashWidth: 6,
                dashGap: 4,
                strokeWidth: 1.5,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 40,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\uC774\uB984/\uC8FC\uC81C \uCD94\uAC00',
                    style: TextStyle(
                      fontSize: fontSize * 0.16,
                      fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }

  // --- Modal helpers ---

  void _showSaveModal(String autoTitle) {
    final fontSize = ref.read(fontSizeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAnimatedDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Center(
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
            child: _isSaving
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\uC800\uC7A5 \uC911...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize * 0.16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF171717),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CircularProgressIndicator(
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\uAE30\uB3C4\uC81C\uBAA9 \uC800\uC7A5',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize * 0.16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF171717),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\uB2E4\uC74C \uC81C\uBAA9\uC73C\uB85C \uC800\uC7A5\uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize * 0.13,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          autoTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSize * 0.15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF171717),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEditModalButton(
                              '\uCDE8\uC18C',
                              fontSize * 0.14,
                              isDark,
                              false,
                              () => Navigator.of(dialogContext).pop(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildEditModalButton(
                              '\uC800\uC7A5',
                              fontSize * 0.14,
                              isDark,
                              false,
                              () => _handleConfirmSave(autoTitle),
                              isPrimary: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _showLoadModal() {
    final fontSize = ref.read(fontSizeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAnimatedDialog(
      context: context,
      barrierDismissible: !_isLoadingData,
      builder: (dialogContext) => Center(
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
          child: _isLoadingData
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\uBD88\uB7EC\uC624\uB294 \uC911...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize * 0.16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\uAE30\uB3C4\uC81C\uBAA9\uC744 \uBD88\uB7EC\uC624\uACE0 \uC788\uC5B4\uC694.\n\uC7A0\uAE50\uB9CC \uAE30\uB2E4\uB824\uC8FC\uC138\uC694.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize * 0.13,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CircularProgressIndicator(
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\uAE30\uB3C4\uC81C\uBAA9 \uBD88\uB7EC\uC624\uAE30',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize * 0.16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\uB9C8\uC9C0\uB9C9\uC5D0 \uC791\uC131\uD55C \uAE30\uB3C4\uC81C\uBAA9\uC744 \uBD88\uB7EC\uC62C\uAE4C\uC694?\n\uD604\uC7AC \uC791\uC131 \uC911\uC778 \uB0B4\uC6A9\uC740 \uBAA8\uB450 \uC0AC\uB77C\uC9D1\uB2C8\uB2E4.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize * 0.13,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildEditModalButton(
                            '\uCDE8\uC18C',
                            fontSize * 0.14,
                            isDark,
                            false,
                            () => Navigator.of(dialogContext).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildEditModalButton(
                            '\uBD88\uB7EC\uC624\uAE30',
                            fontSize * 0.14,
                            isDark,
                            false,
                            _handleLoadData,
                            isPrimary: true,
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

  void _showExitModal() {
    final fontSize = ref.read(fontSizeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAnimatedDialog(
      context: context,
      builder: (dialogContext) => Center(
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
                '\uD3B8\uC9D1 \uCDE8\uC18C',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize * 0.16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '\uC791\uC131 \uC911\uC778 \uB0B4\uC6A9\uC774 \uBAA8\uB450 \uCD08\uAE30\uD654\uB429\uB2C8\uB2E4.\n\uC815\uB9D0 \uB098\uAC00\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize * 0.13,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildEditModalButton(
                      '\uACC4\uC18D \uC791\uC131',
                      fontSize * 0.14,
                      isDark,
                      false,
                      () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEditModalButton(
                      '\uB098\uAC00\uAE30',
                      fontSize * 0.14,
                      isDark,
                      true,
                      () {
                        Navigator.of(dialogContext).pop();
                        context.pop();
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

  void _showErrorModal(String message) {
    final fontSize = ref.read(fontSizeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAnimatedDialog(
      context: context,
      builder: (dialogContext) => Center(
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
                '\uC624\uB958',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize * 0.16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize * 0.14,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _buildEditModalButton(
                  '\uD655\uC778',
                  fontSize * 0.14,
                  isDark,
                  false,
                  () => Navigator.of(dialogContext).pop(),
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditModalButton(
    String label,
    double fontSize,
    bool isDark,
    bool isDestructive,
    VoidCallback onPressed, {
    bool isPrimary = false,
  }) {
    Color backgroundColor;
    Color textColor;

    if (isDestructive) {
      backgroundColor =
          isDark ? const Color(0xFFDC2626) : const Color(0xFFEF4444);
      textColor = Colors.white;
    } else if (isPrimary) {
      backgroundColor = isDark
          ? AppColors.primaryDark
          : AppColors.primaryLight;
      textColor = isDark
          ? AppColors.buttonTextDark
          : AppColors.buttonTextLight;
    } else {
      backgroundColor =
          isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
      textColor =
          isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937);
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
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
          fontWeight:
              (isDestructive || isPrimary) ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(fontSizeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitModal();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Left: back + download
                    SizedBox(
                      width: 96,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _handleCancel,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.chevron_left,
                                  color: primaryColor, size: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _showLoadModal(),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.download,
                                  color: primaryColor, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Center: title
                    Expanded(
                      child: Text(
                        '\uAE30\uB3C4\uC81C\uBAA9 \uD3B8\uC9D1',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize * 0.16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF171717),
                        ),
                      ),
                    ),

                    // Right: save
                    SizedBox(
                      width: 96,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(width: 24),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _handleSave,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.check,
                                  color: primaryColor, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Fixed area: Date selector + page indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DateSelector(
                      date: _prayerData.date,
                      onDateChange: (date) {
                        setState(() {
                          _prayerData.date = date;
                          _hasChanges = true;
                        });
                      },
                    ),
                    // Page indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0;
                            i < _prayerData.sections.length + 1;
                            i++)
                          Container(
                            width: i == _currentPage ? 20 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 3),
                            decoration: BoxDecoration(
                              color: i == _currentPage
                                  ? primaryColor
                                  : (isDark
                                      ? const Color(0xFF525252)
                                      : const Color(0xFFD1D5DB)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Swipeable section pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _prayerData.sections.length + 1,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  itemBuilder: (context, index) {
                    // Last page: add section
                    if (index == _prayerData.sections.length) {
                      return _buildAddSectionPage(
                          fontSize, isDark, primaryColor);
                    }
                    // Section editor page
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      child: PrayerSectionEditor(
                        key: ValueKey(
                            _prayerData.sections[index].id),
                        section: _prayerData.sections[index],
                        sectionIndex: index + 1,
                        onUpdate: _updateSection,
                        onRemove: _removeSection,
                        canRemove:
                            _prayerData.sections.length > 1,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.dashWidth,
    required this.dashGap,
    required this.strokeWidth,
  });

  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = _createDashedPath(path);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        result.addPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = end + dashGap;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
