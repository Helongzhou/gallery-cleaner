import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/footprint_map_style.dart';
import '../../models/theme_preference.dart';
import '../../providers/history_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/footprint_provider.dart';
import '../../shared/constants/strings.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_segmented_control.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/widgets/top_toast.dart';
import '../../shared/widgets/universal_modal.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _cacheEntries = 0;
  bool _loadingCache = true;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    final count = await ref.read(cacheClearServiceProvider).estimatedCacheEntryCount();
    if (mounted) {
      setState(() {
        _cacheEntries = count;
        _loadingCache = false;
      });
    }
  }

  Future<void> _clearCache() async {
    await ref.read(cacheClearServiceProvider).clearScanCaches();
    HapticFeedback.mediumImpact();
    await _loadCacheInfo();
    if (mounted) TopToastInfo.show(context, AppStrings.clearScanCacheSuccess);
  }

  Future<void> _resetOrganizeProgress() async {
    final confirmed = await UniversalModal.showAction(
      context,
      title: AppStrings.resetOrganizeTitle,
      content: AppStrings.resetOrganizeBody,
      primaryBtnText: AppStrings.resetOrganizeConfirm,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final stats = await ref.read(cacheClearServiceProvider).resetOrganizeProgress();
    ref.read(homeRefreshProvider.notifier).state++;
    ref.read(smartRefreshProvider.notifier).state++;
    await ref.read(homeControllerProvider.notifier).load(silent: true);
    ref.read(homeControllerProvider.notifier).refreshLibraryTabState();
    await ref.read(footprintControllerProvider.notifier).load(forceRefresh: true);
    await ref.read(historyProvider.notifier).refresh();
    HapticFeedback.heavyImpact();
    await _loadCacheInfo();
    if (mounted) {
      TopToastInfo.show(
        context,
        AppStrings.resetOrganizeSuccessDetail(
          processedCount: stats.processedCount,
          pendingDeleteCount: stats.pendingDeleteCount,
        ),
      );
    }
  }

  Future<void> _sendFeedback() async {
    const email = 'zhouhlwork@foxmail.com';
    await Clipboard.setData(ClipboardData(text: email));
    if (mounted) {
      TopToastInfo.show(context, '反馈邮箱已复制：$email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themePreference = ref.watch(themePreferenceProvider);
    final mapStyle = ref.watch(footprintMapStyleProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const LargeTitleHeader(title: AppStrings.profileTitle),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginSide,
                AppSpacing.stackMedium,
                AppSpacing.marginSide,
                AppSpacing.stackLoose,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionTitle('个性化'),
                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('主题模式', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        AppSegmentedControl<ThemePreference>(
                          segments: ThemePreference.values
                              .map((m) => AppSegment(value: m, label: m.label))
                              .toList(),
                          selected: themePreference,
                          onChanged: (m) => ref.read(themePreferenceProvider.notifier).setPreference(m),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('足迹地图样式', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        AppSegmentedControl<FootprintMapStyle>(
                          segments: FootprintMapStyle.values
                              .map((s) => AppSegment(value: s, label: s.label))
                              .toList(),
                          selected: mapStyle,
                          onChanged: (s) => ref.read(footprintMapStyleProvider.notifier).setStyle(s),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(AppStrings.dataManagementSection),
                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _loadingCache ? '计算中…' : '可清理扫描缓存条目：$_cacheEntries',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.clearScanCacheHint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _clearCache,
                          child: const Text(AppStrings.clearScanCacheLabel),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '清空整理进度与扫描缓存，让照片重新出现在待整理列表中。',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _resetOrganizeProgress,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.systemRed,
                            side: const BorderSide(color: AppColors.systemRed),
                          ),
                          child: const Text(AppStrings.resetOrganizeLabel),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('关于与反馈'),
                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('版本 v1.1.0', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.mail_outline, color: context.appPrimary),
                          title: const Text('意见反馈'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _sendFeedback,
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.marginSide),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.appOutlineVariant.withValues(alpha: 0.35)),
        ),
        child: child,
      ),
    );
  }
}
