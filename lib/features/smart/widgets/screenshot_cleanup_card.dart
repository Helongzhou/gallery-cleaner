import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../models/screenshot_bucket.dart';
import '../../../shared/constants/strings.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_segmented_control.dart';
import '../../../shared/widgets/primary_button.dart';
import 'smart_card_skeleton.dart';

class ScreenshotCleanupCard extends StatelessWidget {
  const ScreenshotCleanupCard({
    super.key,
    required this.loading,
    required this.selectedBucket,
    required this.count,
    required this.lastScannedAt,
    required this.onBucketChanged,
    required this.onOpenList,
  });

  final bool loading;
  final ScreenshotBucket selectedBucket;
  final int count;
  final DateTime? lastScannedAt;
  final ValueChanged<ScreenshotBucket> onBucketChanged;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Transform.rotate(
            angle: -0.015,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.appPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Transform.rotate(
            angle: 0.015,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.appPrimary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.appSurfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.appOutlineVariant.withValues(alpha: 0.35)),
          ),
          child: loading
              ? const SmartCardSkeleton()
              : _LoadedContent(
                  selectedBucket: selectedBucket,
                  count: count,
                  lastScannedAt: lastScannedAt,
                  onBucketChanged: onBucketChanged,
                  onOpenList: onOpenList,
                ),
        ),
      ],
    );
  }
}

class _LoadedContent extends StatelessWidget {
  const _LoadedContent({
    required this.selectedBucket,
    required this.count,
    required this.lastScannedAt,
    required this.onBucketChanged,
    required this.onOpenList,
  });

  final ScreenshotBucket selectedBucket;
  final int count;
  final DateTime? lastScannedAt;
  final ValueChanged<ScreenshotBucket> onBucketChanged;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.appPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(LucideIcons.monitor_smartphone, color: context.appPrimary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.screenshotCleanup, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.screenshotCleanupHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (lastScannedAt != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.refresh_cw, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '更新于 ${formatRelativeScanTime(lastScannedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        AppSegmentedControl<ScreenshotBucket>(
          key: const Key('screenshot_bucket_segment'),
          segments: ScreenshotBucket.values
              .map((b) => AppSegment(value: b, label: b.label))
              .toList(),
          selected: selectedBucket,
          onChanged: onBucketChanged,
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.appSurfaceContainerHigh.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: count == 0
              ? Text(
                  '暂无${selectedBucket.label}的截图',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                )
              : RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                    children: [
                      const TextSpan(text: '您有 '),
                      TextSpan(
                        text: '$count',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: context.appPrimary,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                      ),
                      TextSpan(text: ' 张${selectedBucket.label}的屏幕截图'),
                    ],
                  ),
                ),
        ),
        if (count > 0) ...[
          const SizedBox(height: 8),
          Text(
            '通常已不再需要，可批量清理释放空间',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: count == 0 ? '暂无截图' : '查看并清理',
          icon: count == 0 ? null : LucideIcons.sparkles,
          onPressed: count == 0 ? null : onOpenList,
        ),
      ],
    );
  }
}
