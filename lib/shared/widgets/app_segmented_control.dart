import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Equal-width segmented control. Each segment gets the same flex so label
/// length changes do not resize the control.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appSurfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: context.appOutlineVariant.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: _SegmentTile<T>(
                  segment: segments[i],
                  selected: segments[i].value == selected,
                  enabled: enabled,
                  selectedColor: scheme.primary,
                  selectedForeground: isDark ? AppColors.onPrimaryDark : AppColors.onPrimary,
                  unselectedForeground: scheme.onSurfaceVariant,
                  onTap: () {
                    if (!enabled || segments[i].value == selected) return;
                    HapticFeedback.selectionClick();
                    onChanged(segments[i].value);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppSegment<T> {
  const AppSegment({required this.value, required this.label});

  final T value;
  final String label;
}

class _SegmentTile<T> extends StatelessWidget {
  const _SegmentTile({
    required this.segment,
    required this.selected,
    required this.enabled,
    required this.selectedColor,
    required this.selectedForeground,
    required this.unselectedForeground,
    required this.onTap,
  });

  final AppSegment<T> segment;
  final bool selected;
  final bool enabled;
  final Color selectedColor;
  final Color selectedForeground;
  final Color unselectedForeground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? (context.isDarkMode ? AppColors.onPrimaryDark : selectedForeground)
        : unselectedForeground;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.sm - 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm - 2),
            boxShadow: selected && !context.isDarkMode
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                segment.label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
