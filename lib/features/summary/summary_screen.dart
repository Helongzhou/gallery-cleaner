import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../router/app_router.dart';
import '../../router/routes.dart';
import '../../shared/constants/strings.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/immersive_system_ui.dart';
import '../../shared/widgets/primary_button.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key, required this.args});

  final SummaryRouteArgs args;

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  final List<Uint8List?> _organizedThumbs = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _loadThumbs();
  }

  Future<void> _loadThumbs() async {
    if (widget.args.deleteOnly || widget.args.targetAlbumId == null) return;
    final photoService = ref.read(photoLibraryServiceProvider);
    final cover = await photoService.getAlbumCover(widget.args.targetAlbumId!, size: 120);
    if (mounted) setState(() => _organizedThumbs.add(cover));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: Padding(
        padding: EdgeInsets.fromLTRB(24, context.statusBarTop + 24, 24, 24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.systemGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.systemGreen, size: 56),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${AppStrings.organizeComplete}!',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '您的相册已经焕然一新',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  if (!widget.args.deleteOnly)
                    Expanded(
                      child: _BentoCard(
                        label: '已归类',
                        value: '${widget.args.organizedCount}',
                        valueColor: context.appPrimary,
                        child: _organizedThumbs.isNotEmpty && _organizedThumbs.first != null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: Image.memory(
                                      _organizedThumbs.first!,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  if (widget.args.organizedCount > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Text(
                                        '+${widget.args.organizedCount - 1}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                ],
                              )
                            : const SizedBox(height: 8),
                      ),
                    ),
                  if (!widget.args.deleteOnly) const SizedBox(width: 12),
                  Expanded(
                    child: _BentoCard(
                      label: '待删除',
                      value: '${widget.args.pendingDeleteCount}',
                      valueColor: AppColors.systemRed,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: widget.args.pendingDeleteCount == 0
                                ? 0
                                : (widget.args.pendingDeleteCount / widget.args.totalProcessed).clamp(0.1, 1.0),
                            minHeight: 6,
                            backgroundColor: AppColors.systemRed.withValues(alpha: 0.15),
                            color: AppColors.systemRed,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (widget.args.pendingDeleteCount > 0)
                PrimaryButton(
                  label: '${AppStrings.viewPendingDelete} (${widget.args.pendingDeleteCount})',
                  onPressed: () => context.go(AppRoutes.pendingDelete),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(AppStrings.organizeOther, style: TextStyle(color: context.appPrimary)),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(
                  AppStrings.backHome,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.child,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(color: valueColor),
          ),
          child,
        ],
      ),
    );
  }
}
