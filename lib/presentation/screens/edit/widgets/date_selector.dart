import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/font_size_provider.dart';
import '../../../../core/constants/app_colors.dart';

class DateSelector extends ConsumerWidget {
  const DateSelector({
    super.key,
    required this.date,
    required this.onDateChange,
  });

  final String date; // YYYY-MM-DD
  final ValueChanged<String> onDateChange;

  String _formatDateForDisplay(String dateString) {
    final parts = dateString.split('-');
    if (parts.length != 3) return dateString;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\uC791\uC131 \uB0A0\uC9DC',
            style: TextStyle(
              fontSize: fontSize * 0.14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showDatePicker(context),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF262626)
                    : Colors.white,
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : const Color(0xFFD1D5DB),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDateForDisplay(date),
                style: TextStyle(
                  fontSize: fontSize * 0.16,
                  color: isDark ? Colors.white : const Color(0xFF171717),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final parts = date.split('-');
    final initialDate = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final year = picked.year.toString();
      final month = picked.month.toString().padLeft(2, '0');
      final day = picked.day.toString().padLeft(2, '0');
      onDateChange('$year-$month-$day');
    }
  }
}
