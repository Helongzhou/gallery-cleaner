import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.radius = AppRadius.md,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.appSurfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SmartSkeleton extends StatelessWidget {
  const SmartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.marginSide),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 32, width: 120),
          const SizedBox(height: 24),
          SkeletonBox(height: 140),
          const SizedBox(height: 16),
          SkeletonBox(height: 56),
          const SizedBox(height: 12),
          SkeletonBox(height: 56),
          const SizedBox(height: 12),
          SkeletonBox(height: 56),
        ],
      ),
    );
  }
}
