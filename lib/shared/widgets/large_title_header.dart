import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/immersive_system_ui.dart';

class LargeTitleHeader extends StatelessWidget {
  const LargeTitleHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.marginSide,
          context.statusBarTop + 8,
          AppSpacing.marginSide,
          AppSpacing.stackMedium,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.displaySmall),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
