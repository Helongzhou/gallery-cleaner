import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_pressable.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final primary = context.appPrimary;

    return AppPressable(
      onTap: onPressed,
      haptic: enabled,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: enabled ? primary : primary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: context.appOnPrimary),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, color: context.appOnPrimary, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
