import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/immersive_system_ui.dart';

class SwipeHeader extends StatelessWidget {
  const SwipeHeader({
    super.key,
    required this.title,
    required this.current,
    required this.total,
    required this.onBack,
  });

  final String title;
  final int current;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : current / total;

    return GlassSwipeHeader(
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: Icon(Icons.chevron_left, color: context.appPrimary, size: 28),
                      tooltip: '返回',
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      key: const Key('swipe_header_title'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$current / $total',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 3,
              backgroundColor: AppColors.surfaceVariant,
              color: context.appPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class GlassSwipeHeader extends StatelessWidget {
  const GlassSwipeHeader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(8, context.statusBarTop + 8, 8, 12),
          color: context.appBackground.withValues(alpha: 0.7),
          child: child,
        ),
      ),
    );
  }
}

class SwipeStampOverlay extends StatelessWidget {
  const SwipeStampOverlay({super.key, required this.percentX});

  final int percentX;

  @override
  Widget build(BuildContext context) {
    if (percentX == 0) return const SizedBox.shrink();

    final opacity = (percentX.abs() / 100).clamp(0.0, 1.0);
    final isRight = percentX > 0;

    return Positioned(
      top: 24,
      left: isRight ? null : 24,
      right: isRight ? 24 : null,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: 0.8 + opacity * 0.4,
          child: Transform.rotate(
            angle: isRight ? 0.26 : -0.26,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isRight ? AppColors.systemGreen : AppColors.systemRed,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isRight ? '移入相册' : '标记删除',
                style: TextStyle(
                  color: isRight ? AppColors.systemGreen : AppColors.systemRed,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
