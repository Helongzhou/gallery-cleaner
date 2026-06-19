import 'package:flutter/material.dart';

/// Design tokens from v1.1 theme spec (light + dark HTML exports).
abstract final class AppColors {
  // --- Light ---
  static const primary = Color(0xFF0058BC);
  static const onPrimary = Color(0xFFFFFFFF);
  static const background = Color(0xFFFAF9FE);
  static const surface = Color(0xFFFAF9FE);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF4F3F8);
  static const surfaceContainer = Color(0xFFEEEDF3);
  static const surfaceContainerHigh = Color(0xFFE9E7ED);
  static const surfaceContainerHighest = Color(0xFFE3E2E7);
  static const surfaceVariant = Color(0xFFE3E2E7);
  static const onSurface = Color(0xFF1A1B1F);
  static const onSurfaceVariant = Color(0xFF414755);
  static const outline = Color(0xFF717786);
  static const outlineVariant = Color(0xFFC1C6D7);
  static const systemRed = Color(0xFFFF3B30);
  static const systemGreen = Color(0xFF34C759);
  static const systemOrange = Color(0xFFFF9500);
  static const systemGray6 = Color(0xFFF2F2F7);

  // --- Dark (#131313 palette) ---
  static const backgroundDark = Color(0xFF131313);
  static const surfaceDark = Color(0xFF131313);
  static const surfaceContainerLowestDark = Color(0xFF0E0E0E);
  static const surfaceContainerLowDark = Color(0xFF1C1B1B);
  static const surfaceContainerDark = Color(0xFF212121);
  static const surfaceContainerHighDark = Color(0xFF2B2B2B);
  static const surfaceContainerHighestDark = Color(0xFF363636);
  static const surfaceVariantDark = Color(0xFF353534);
  static const onSurfaceDark = Color(0xFFFFFFFF);
  static const onSurfaceVariantDark = Color(0xFFA1A1A1);
  static const outlineDark = Color(0xFF393939);
  static const outlineVariantDark = Color(0xFF2A2A2A);
  static const primaryDark = Color(0xFFFFFFFF);
  static const onPrimaryDark = Color(0xFF000000);
  static const accentDark = Color(0xFFE5E2E1);
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
