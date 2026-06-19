import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme lightTextTheme = TextTheme(
    displaySmall: _style(34, 41, FontWeight.w700, 0.37),
    headlineMedium: _style(28, 34, FontWeight.w700, 0.36),
    titleMedium: _style(17, 22, FontWeight.w600, -0.41),
    bodyLarge: _style(17, 22, FontWeight.w400, -0.41),
    bodyMedium: _style(15, 20, FontWeight.w400, -0.24),
    bodySmall: _style(13, 18, FontWeight.w400, -0.08),
    labelSmall: _style(12, 16, FontWeight.w400, 0),
  ).apply(
    bodyColor: AppColors.onSurface,
    displayColor: AppColors.onSurface,
  );

  static TextTheme darkTextTheme = lightTextTheme.apply(
    bodyColor: AppColors.onSurfaceDark,
    displayColor: AppColors.onSurfaceDark,
  );

  static TextStyle _style(
    double size,
    double height,
    FontWeight weight,
    double spacing,
  ) {
    return TextStyle(
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: spacing,
    );
  }
}
