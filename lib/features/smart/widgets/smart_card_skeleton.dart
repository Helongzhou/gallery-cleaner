import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import 'smart_skeleton.dart';

/// In-card loading placeholders (header + segment + stat + CTA).
class SmartCardSkeleton extends StatelessWidget {
  const SmartCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SkeletonBox(height: 52, width: 52, radius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 18, width: 120),
                  SizedBox(height: 8),
                  SkeletonBox(height: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SkeletonBox(height: 40),
        const SizedBox(height: 20),
        SkeletonBox(height: 56),
        const SizedBox(height: 20),
        SkeletonBox(height: 56, radius: AppRadius.lg),
      ],
    );
  }
}
