import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pray_list_v2/core/constants/app_colors.dart';
import 'package:pray_list_v2/core/theme/app_theme.dart';

void main() {
  test('light theme uses AppColors', () {
    final theme = AppTheme.lightTheme;

    expect(theme.brightness, Brightness.light);
    expect(theme.primaryColor, AppColors.primaryLight);
    expect(theme.scaffoldBackgroundColor, AppColors.backgroundLight);
    expect(theme.colorScheme.primary, AppColors.primaryLight);
    expect(theme.colorScheme.surface, AppColors.backgroundLight);
    expect(theme.colorScheme.error, AppColors.errorLight);
    expect(theme.appBarTheme.backgroundColor, AppColors.backgroundLight);
    expect(theme.appBarTheme.foregroundColor, AppColors.textPrimaryLight);
  });

  test('dark theme uses AppColors', () {
    final theme = AppTheme.darkTheme;

    expect(theme.brightness, Brightness.dark);
    expect(theme.primaryColor, AppColors.primaryDark);
    expect(theme.scaffoldBackgroundColor, AppColors.backgroundDark);
    expect(theme.colorScheme.primary, AppColors.primaryDark);
    expect(theme.colorScheme.surface, AppColors.backgroundDark);
    expect(theme.colorScheme.error, AppColors.errorDark);
    expect(theme.appBarTheme.backgroundColor, AppColors.backgroundDark);
    expect(theme.appBarTheme.foregroundColor, AppColors.textPrimaryDark);
  });
}
