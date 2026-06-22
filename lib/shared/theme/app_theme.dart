import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primary,
      onSecondary: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      error: AppColors.systemRed,
      onError: AppColors.onPrimary,
    );

    return _baseTheme(scheme, AppColors.background, AppTypography.lightTextTheme);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      secondary: AppColors.accentDark,
      onSecondary: AppColors.onPrimaryDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      onSurfaceVariant: AppColors.onSurfaceVariantDark,
      outline: AppColors.outlineDark,
      outlineVariant: AppColors.outlineVariantDark,
      error: AppColors.systemRed,
      onError: AppColors.onPrimaryDark,
    );

    return _baseTheme(scheme, AppColors.backgroundDark, AppTypography.darkTextTheme);
  }

  static ThemeData _baseTheme(ColorScheme scheme, Color scaffoldColor, TextTheme textTheme) {
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: scaffoldColor,
      colorScheme: scheme,
      textTheme: textTheme,
      dividerColor: scheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.3),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldColor.withValues(alpha: 0.82),
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffoldColor.withValues(alpha: 0.92),
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.12 : 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
      ),
    );
  }
}

extension AppThemeExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground =>
      isDarkMode ? AppColors.backgroundDark : AppColors.background;

  Color get appSurfaceContainerLowest => isDarkMode
      ? AppColors.surfaceContainerLowestDark
      : AppColors.surfaceContainerLowest;

  Color get appSurfaceContainerLow => isDarkMode
      ? AppColors.surfaceContainerLowDark
      : AppColors.surfaceContainerLow;

  Color get appSurfaceContainerHigh => isDarkMode
      ? AppColors.surfaceContainerHighDark
      : AppColors.surfaceContainerHigh;

  Color get appSurfaceContainerHighest => isDarkMode
      ? AppColors.surfaceContainerHighestDark
      : AppColors.surfaceContainerHighest;

  Color get appSurfaceVariant =>
      isDarkMode ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;

  Color get appOutlineVariant =>
      isDarkMode ? AppColors.outlineVariantDark : AppColors.outlineVariant;

  /// CTA fill: blue (light) / white (dark).
  Color get appPrimary => Theme.of(this).colorScheme.primary;

  /// Text & icons on CTA.
  Color get appOnPrimary => Theme.of(this).colorScheme.onPrimary;

  /// Links, icons, subtle highlights.
  Color get appAccent =>
      isDarkMode ? AppColors.accentDark : AppColors.primary;
}
