import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_pressable.dart';

class LargeTitleHeader extends StatelessWidget {
  const LargeTitleHeader({
    super.key,
    required this.title,
    this.onProfileTap,
  });

  final String title;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginSide,
          8,
          AppSpacing.marginSide,
          AppSpacing.stackMedium,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.displaySmall),
            ),
            AppPressable(
              onTap: onProfileTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.appSurfaceContainerHigh.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_outline, color: context.appPrimary, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
