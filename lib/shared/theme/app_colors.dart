import 'package:flutter/material.dart';

abstract final class AppColors {
  // Light
  static const primary = Color(0xFF0058BC);
  static const onPrimary = Color(0xFFFFFFFF);
  static const background = Color(0xFFFAF9FE);
  static const surface = Color(0xFFFAF9FE);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF4F3F8);
  static const surfaceContainerHigh = Color(0xFFE9E7ED);
  static const surfaceContainerHighest = Color(0xFFE3E2E7);
  static const surfaceVariant = Color(0xFFE3E2E7);
  static const onSurface = Color(0xFF1A1B1F);
  static const onSurfaceVariant = Color(0xFF414755);
  static const outlineVariant = Color(0xFFC1C6D7);
  static const systemRed = Color(0xFFFF3B30);
  static const systemGreen = Color(0xFF34C759);
  static const systemOrange = Color(0xFFFF9500);
  static const systemGray6 = Color(0xFFF2F2F7);

  // Dark
  static const backgroundDark = Color(0xFF1A1B1F);
  static const surfaceDark = Color(0xFF1A1B1F);
  static const surfaceContainerLowestDark = Color(0xFF2F3034);
  static const surfaceContainerHighDark = Color(0xFF3A3B3F);
  static const surfaceContainerHighestDark = Color(0xFF3A3B3F);
  static const surfaceVariantDark = Color(0xFF3A3B3F);
  static const onSurfaceDark = Color(0xFFF1F0F5);
  static const onSurfaceVariantDark = Color(0xFFC1C6D7);
  static const primaryDark = Color(0xFFADC6FF);
}

abstract final class AppSpacing {
  static const marginSide = 16.0;
  static const stackTight = 4.0;
  static const stackMedium = 12.0;
  static const stackLoose = 20.0;
  static const gutter = 8.0;
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}
