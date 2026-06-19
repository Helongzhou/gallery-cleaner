import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_pressable.dart';

class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
    this.semanticLabel,
    this.child,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool showBadge;
  final String? semanticLabel;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final inner = child ??
        Icon(icon, color: context.appPrimary, size: 22);

    final button = AppPressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.appSurfaceContainerHigh.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        child: Center(child: inner),
      ),
    );

    if (!showBadge) {
      return Semantics(label: semanticLabel, button: true, child: button);
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFF3B30),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
