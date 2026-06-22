import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Edge-to-edge system UI helpers (transparent status / navigation bars).
abstract final class ImmersiveSystemUi {
  static Future<void> enable() {
    return SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  static SystemUiOverlayStyle overlayStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: iconBrightness,
    );
  }
}

extension ImmersiveViewInsets on BuildContext {
  double get statusBarTop => MediaQuery.viewPaddingOf(this).top;

  double get homeIndicatorBottom => MediaQuery.viewPaddingOf(this).bottom;
}
