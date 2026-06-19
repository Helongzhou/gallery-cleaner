import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.systemRed,
      ),
      textTheme: AppTypography.lightTextTheme,
      dividerColor: AppColors.outlineVariant.withValues(alpha: 0.3),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        onPrimary: AppColors.onSurface,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.onSurfaceDark,
        onSurfaceVariant: AppColors.onSurfaceVariantDark,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.systemRed,
      ),
      textTheme: AppTypography.darkTextTheme,
      dividerColor: AppColors.outlineVariant.withValues(alpha: 0.3),
    );
  }
}

extension AppThemeExtension on BuildContext {
  Color get appBackground =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.backgroundDark : AppColors.background;

  Color get appSurfaceContainerLowest => Theme.of(this).brightness == Brightness.dark
      ? AppColors.surfaceContainerLowestDark
      : AppColors.surfaceContainerLowest;

  Color get appSurfaceContainerHigh => Theme.of(this).brightness == Brightness.dark
      ? AppColors.surfaceContainerHighDark
      : AppColors.surfaceContainerHigh;

  Color get appSurfaceContainerHighest => Theme.of(this).brightness == Brightness.dark
      ? AppColors.surfaceContainerHighestDark
      : AppColors.surfaceContainerHighest;

  Color get appPrimary =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.primaryDark : AppColors.primary;
}
