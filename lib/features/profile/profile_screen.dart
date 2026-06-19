import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/theme_preference.dart';
import '../../providers/theme_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_segmented_control.dart';
import '../../shared/widgets/large_title_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(themePreferenceProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const LargeTitleHeader(title: '我的'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginSide,
                  AppSpacing.stackMedium,
                  AppSpacing.marginSide,
                  AppSpacing.stackLoose,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('外观', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.stackMedium),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.marginSide),
                      decoration: BoxDecoration(
                        color: context.appSurfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: context.appOutlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '主题模式',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.stackMedium),
                          AppSegmentedControl<ThemePreference>(
                            key: const Key('theme_preference_segment'),
                            segments: ThemePreference.values
                                .map((mode) => AppSegment(value: mode, label: mode.label))
                                .toList(),
                            selected: preference,
                            onChanged: (mode) {
                              ref.read(themePreferenceProvider.notifier).setPreference(mode);
                            },
                          ),
                          const SizedBox(height: AppSpacing.stackTight),
                          Text(
                            '当前：${preference.label}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLoose),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.marginSide),
                      decoration: BoxDecoration(
                        color: context.appSurfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: context.appOutlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.construction_outlined, color: context.appAccent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '数据看板、隐私保险箱等功能即将推出',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
