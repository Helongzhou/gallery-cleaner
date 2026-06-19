import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/photo_asset_info.dart';
import '../../models/swipe_action.dart';
import '../../providers/history_provider.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';
import '../../router/routes.dart';
import '../../shared/constants/organize_constants.dart';
import '../../shared/constants/strings.dart';
import '../../shared/result.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_pressable.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/top_toast.dart';
import 'widgets/swipe_header.dart';

class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key, required this.args});

  final SwipeRouteArgs args;

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  final _swiperController = CardSwiperController();
  bool _loading = true;
  String? _error;
  List<PhotoAssetInfo> _assets = [];
  final Map<String, Uint8List?> _thumbnails = {};
  int _processedInSession = 0;
  int _undosPerformed = 0;
  int _sessionActionCount = 0;

  bool get _deleteOnly => widget.args.deleteOnly;

  int get _remainingUndoSteps {
    final cap = OrganizeConstants.maxUndoStepsPerSession - _undosPerformed;
    if (cap <= 0) return 0;
    return _sessionActionCount < cap ? _sessionActionCount : cap;
  }

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  @override
  void dispose() {
    TopToast.dismiss();
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final organizeRepo = ref.read(organizeRepositoryProvider);
    final photoService = ref.read(photoLibraryServiceProvider);
    final processed = await organizeRepo.getProcessedIds(widget.args.sourceAlbumId);
    final result = await photoService.getAssets(
      albumId: widget.args.sourceAlbumId,
      excludeProcessed: processed,
    );

    if (!mounted) return;
    if (result is AppFailure<List<PhotoAssetInfo>>) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }

    final assets = (result as AppSuccess<List<PhotoAssetInfo>>).value;
    setState(() {
      _loading = false;
      _assets = assets;
    });
    await _preloadThumbnails(0);
    await _refreshUndoState();
  }

  Future<void> _refreshUndoState() async {
    final count = await ref.read(organizeRepositoryProvider).countSessionActions(widget.args.sessionId);
    if (mounted) setState(() => _sessionActionCount = count);
  }

  Future<void> _preloadThumbnails(int index) async {
    final photoService = ref.read(photoLibraryServiceProvider);
    final size = MediaQuery.sizeOf(context);
    final width = size.width.ceil();
    final height = (size.width * 4 / 3).ceil();

    for (var i = index; i < index + 3 && i < _assets.length; i++) {
      final asset = _assets[i];
      if (_thumbnails.containsKey(asset.id)) continue;
      final bytes = await photoService.getThumbnail(
        assetId: asset.id,
        width: width,
        height: height,
      );
      if (mounted) setState(() => _thumbnails[asset.id] = bytes);
    }
  }

  Future<bool> _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    if (previousIndex >= _assets.length) return false;
    final asset = _assets[previousIndex];
    final organizeRepo = ref.read(organizeRepositoryProvider);
    final photoService = ref.read(photoLibraryServiceProvider);

    if (direction == CardSwiperDirection.right) {
      if (_deleteOnly) {
        if (previousIndex + 1 >= _assets.length) {
          await _finishSession();
        } else {
          await _preloadThumbnails(previousIndex + 1);
        }
        return true;
      }

      HapticFeedback.mediumImpact();
      final targetId = widget.args.targetAlbumId;
      if (targetId == null) return false;

      final addResult = await photoService.addToAlbum(
        assetId: asset.id,
        albumId: targetId,
        sourceAlbumId: widget.args.sourceAlbumId,
      );
      if (addResult is AppFailure<void>) {
        if (mounted) {
          TopToast.show(context, message: addResult.message);
        }
        return false;
      }
      final markResult = await organizeRepo.markOrganized(
        assetId: asset.id,
        sourceAlbumId: widget.args.sourceAlbumId,
        targetAlbumId: targetId,
        sessionId: widget.args.sessionId,
      );
      if (markResult is AppFailure<void>) {
        if (mounted) {
          TopToast.show(context, message: markResult.message);
        }
        return false;
      }
      if (mounted) {
        TopToastInfo.show(context, '已归入「${widget.args.targetAlbumName}」');
      }
    } else if (direction == CardSwiperDirection.left) {
      HapticFeedback.mediumImpact();
      final markResult = await organizeRepo.markPendingDelete(
        assetId: asset.id,
        sourceAlbumId: widget.args.sourceAlbumId,
        sessionId: widget.args.sessionId,
      );
      if (markResult is AppFailure<void>) {
        if (mounted) {
          TopToast.show(context, message: markResult.message);
        }
        return false;
      }
      if (mounted) {
        TopToastInfo.show(context, '已标记删除');
      }
    } else {
      return false;
    }

    setState(() {
      _processedInSession++;
      _sessionActionCount++;
    });
    ref.read(historyProvider.notifier).refresh();
    ref.read(homeRefreshProvider.notifier).state++;

    if (previousIndex + 1 >= _assets.length) {
      await _finishSession();
    } else {
      await _preloadThumbnails(previousIndex + 1);
    }
    return true;
  }

  Future<void> _undoLast() async {
    if (_remainingUndoSteps <= 0) return;

    final result = await ref.read(organizeRepositoryProvider).undoLastAction(widget.args.sessionId);
    if (!mounted) return;
    if (result is AppFailure<SwipeAction?>) {
      TopToast.show(context, message: result.message);
      return;
    }
    final action = (result as AppSuccess<SwipeAction?>).value;
    if (action == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _processedInSession = (_processedInSession - 1).clamp(0, 9999);
      _undosPerformed++;
      _sessionActionCount = (_sessionActionCount - 1).clamp(0, 9999);
    });
    ref.read(historyProvider.notifier).refresh();
    ref.read(homeRefreshProvider.notifier).state++;
    await _loadAssets();
    if (mounted) {
      TopToastInfo.show(context, '已撤销');
    }
  }

  Future<void> _finishSession() async {
    final sessionService = ref.read(sessionServiceProvider);
    final stats = await sessionService.getSessionStats(widget.args.sessionId);
    await sessionService.completeSession(widget.args.sessionId);
    if (!mounted) return;
    context.go(
      AppRoutes.summary,
      extra: SummaryRouteArgs(
        sessionId: widget.args.sessionId,
        targetAlbumName: widget.args.targetAlbumName,
        targetAlbumId: widget.args.targetAlbumId,
        totalProcessed: stats.totalProcessed,
        organizedCount: stats.organizedCount,
        pendingDeleteCount: stats.pendingDeleteCount,
        deleteOnly: _deleteOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.appBackground,
        body: const LoadingView(message: '加载照片...'),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: context.appBackground,
        body: Column(
          children: [
            SwipeHeader(
              title: widget.args.sourceAlbumName,
              current: _processedInSession,
              total: widget.args.totalCount,
              onBack: () => context.pop(),
            ),
            Expanded(child: ErrorView(message: _error!, onRetry: _loadAssets)),
          ],
        ),
      );
    }
    if (_assets.isEmpty) {
      return Scaffold(
        backgroundColor: context.appBackground,
        body: Column(
          children: [
            SwipeHeader(
              title: widget.args.sourceAlbumName,
              current: _processedInSession,
              total: widget.args.totalCount,
              onBack: () => context.pop(),
            ),
            const Expanded(child: Center(child: Text('没有待整理的照片'))),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('yyyy年M月d日 · HH:mm');

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            SwipeHeader(
              title: widget.args.sourceAlbumName,
              current: _processedInSession,
              total: widget.args.totalCount,
              onBack: () => context.pop(),
            ),
            if (_deleteOnly)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  '仅删除模式：左滑删除 · 右滑跳过',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.systemOrange),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    width: MediaQuery.sizeOf(context).width * 0.9,
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CardSwiper(
                      controller: _swiperController,
                      cardsCount: _assets.length,
                      onSwipe: _onSwipe,
                      allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true),
                      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                        final asset = _assets[index];
                        final bytes = _thumbnails[asset.id];
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AspectRatio(
                              aspectRatio: 3 / 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (bytes != null)
                                      Image.memory(bytes, fit: BoxFit.cover)
                                    else
                                      ColoredBox(
                                        color: context.appSurfaceContainerHigh,
                                        child: const Center(child: CircularProgressIndicator()),
                                      ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withValues(alpha: 0.8),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Text(
                                            asset.createDate != null
                                                ? dateFormat.format(asset.createDate!)
                                                : '',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.white.withValues(alpha: 0.85),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!_deleteOnly)
                              SwipeStampOverlay(percentX: percentThresholdX),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (!_deleteOnly)
                    const Opacity(
                      opacity: 0.35,
                      child: Row(
                        children: [
                          Icon(Icons.close, color: AppColors.systemRed, size: 20),
                          SizedBox(width: 48),
                          Icon(Icons.check, color: AppColors.systemGreen, size: 20),
                        ],
                      ),
                    )
                  else
                    const Opacity(
                      opacity: 0.35,
                      child: Row(
                        children: [
                          Icon(Icons.close, color: AppColors.systemRed, size: 20),
                          SizedBox(width: 8),
                          Text('左滑删除', style: TextStyle(fontSize: 12, color: AppColors.systemRed)),
                          SizedBox(width: 48),
                          Icon(Icons.redo, size: 20, color: Color(0xFF8E8E93)),
                          SizedBox(width: 8),
                          Text('右滑跳过', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                        ],
                      ),
                    ),
                  const Spacer(),
                  AppPressable(
                    onTap: _remainingUndoSteps > 0 ? _undoLast : null,
                    child: Opacity(
                      opacity: _remainingUndoSteps > 0 ? 1 : 0.4,
                      child: Container(
                        key: const Key('swipe_undo_button'),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.appSurfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.undo, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              AppStrings.undoWithCount(_remainingUndoSteps),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
