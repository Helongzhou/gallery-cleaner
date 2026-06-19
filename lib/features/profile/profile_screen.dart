import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/footprint_map_style.dart';
import '../../models/theme_preference.dart';
import '../../providers/providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../shared/constants/strings.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_segmented_control.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/widgets/top_toast.dart';

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

  Future<void> _onBiometricToggle(bool value) async {
    if (!value) {
      await ref.read(biometricLockProvider.notifier).setEnabled(false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开启生物识别保护'),
        content: const Text('将调用系统 Face ID / 指纹验证。隐藏相册功能即将推出。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('验证并开启')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    await ref.read(biometricLockProvider.notifier).setEnabled(true);
    HapticFeedback.mediumImpact();
    TopToastInfo.show(context, '已开启（隐藏相册功能即将推出）');
  }

  Future<void> _clearCache() async {
    await ref.read(cacheClearServiceProvider).clearScanCaches();
    HapticFeedback.mediumImpact();
    await _loadCacheInfo();
    if (mounted) TopToastInfo.show(context, '已清除扫描缓存');
  }

  Future<void> _sendFeedback() async {
    const email = 'feedback@albumorganizer.app';
    await Clipboard.setData(ClipboardData(text: email));
    if (mounted) {
      TopToastInfo.show(context, '反馈邮箱已复制：$email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themePreference = ref.watch(themePreferenceProvider);
    final mapStyle = ref.watch(footprintMapStyleProvider);
    final biometric = ref.watch(biometricLockProvider);
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
                  _SectionTitle('隐私安全'),
                  _SettingsCard(
                    child: Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Face ID / 指纹保护隐藏相册'),
                        subtitle: Text(
                          '开启后需生物识别验证（功能即将推出）',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        value: biometric,
                        onChanged: _onBiometricToggle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('缓存管理'),
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
                          '清除截图与足迹扫描缓存，不影响整理记录',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _clearCache,
                          child: const Text('清除应用缓存'),
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
