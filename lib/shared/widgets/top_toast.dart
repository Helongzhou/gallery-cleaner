import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class TopToast {
  TopToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    bool isError = true,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 3),
  }) {
    dismiss();

    final overlay = Overlay.of(context);
    final top = MediaQuery.paddingOf(context).top;

    _entry = OverlayEntry(
      builder: (context) => Positioned(
        top: top + 8,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (isError ? AppColors.systemRed : AppColors.systemGreen).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                  if (onRetry != null)
                    TextButton(
                      onPressed: () {
                        dismiss();
                        onRetry();
                      },
                      child: const Text('重试', style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_entry!);
    _timer = Timer(duration, dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

/// 成功类提示用中性毛玻璃样式
class TopToastInfo {
  TopToastInfo._();

  static OverlayEntry? _entry;

  static void show(BuildContext context, String message) {
    TopToast.dismiss();
    _entry?.remove();

    final overlay = Overlay.of(context);
    final top = MediaQuery.paddingOf(context).top;

    _entry = OverlayEntry(
      builder: (context) => Positioned(
        top: top + 8,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.appBackground.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_entry!);
    Future.delayed(const Duration(seconds: 2), () {
      _entry?.remove();
      _entry = null;
    });
  }
}
