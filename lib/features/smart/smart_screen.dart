import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../models/screenshot_bucket.dart';
import '../../providers/history_provider.dart';
import '../../providers/providers.dart';
import '../../router/routes.dart';
import '../../shared/constants/strings.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/large_title_header.dart';
import 'widgets/radar_scan_button.dart';
import 'widgets/screenshot_cleanup_card.dart';
import 'widgets/smart_coming_soon_card.dart';

class SmartScreen extends ConsumerStatefulWidget {
  const SmartScreen({super.key});

  @override
  ConsumerState<SmartScreen> createState() => _SmartScreenState();
}

class _SmartScreenState extends ConsumerState<SmartScreen> {
  bool _loading = true;
  bool _deepScanning = false;
  ScreenshotBucket _selectedBucket = ScreenshotBucket.days30;
  Map<ScreenshotBucket, int> _counts = {};
  DateTime? _lastScannedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    final scanService = ref.read(screenshotScanServiceProvider);
    final counts = await scanService.getCounts(forceRefresh: forceRefresh);
    final lastScannedAt = await scanService.getLatestScannedAt();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _counts = counts;
      _lastScannedAt = lastScannedAt;
    });
  }

  Future<void> _deepScan() async {
    if (_deepScanning) return;
    setState(() => _deepScanning = true);
    await _load(forceRefresh: true);
    if (!mounted) return;
    setState(() => _deepScanning = false);
    HapticFeedback.mediumImpact();
  }

  void _openList() {
    context.push('${AppRoutes.smart}/screenshots?bucket=${_selectedBucket.key}');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(smartRefreshProvider, (previous, next) {
      if (previous != next) _load(forceRefresh: true);
    });

    final count = _counts[_selectedBucket] ?? 0;
    final scheme = Theme.of(context).colorScheme;
    final scanning = _loading || _deepScanning;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              LargeTitleHeader(
                title: AppStrings.smartCleanup,
                trailing: RadarScanButton(
                  scanning: scanning,
                  onTap: scanning ? null : _deepScan,
                ),
              ),
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
                      ScreenshotCleanupCard(
                        loading: scanning,
                        selectedBucket: _selectedBucket,
                        count: count,
                        lastScannedAt: _lastScannedAt,
                        onBucketChanged: (bucket) => setState(() => _selectedBucket = bucket),
                        onOpenList: _openList,
                      ),
                      const SizedBox(height: AppSpacing.stackMedium),
                      const SmartComingSoonCard(
                        icon: Icons.photo_library_outlined,
                        title: '相似照片',
                        subtitle: '智能聚类，释放重复占用空间',
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(LucideIcons.shield_check, size: 20, color: context.appAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppStrings.smartPrivacyNote,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
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
      ),
    );
  }
}
