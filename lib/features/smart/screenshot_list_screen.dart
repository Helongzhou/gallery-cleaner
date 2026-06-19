import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/photo_asset_info.dart';
import '../../models/screenshot_bucket.dart';
import '../../providers/providers.dart';
import '../../shared/constants/strings.dart';
import '../../shared/result.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/universal_modal.dart';
import '../../shared/widgets/waterfall_grid.dart';
import '../../services/photo_library_service.dart';

class ScreenshotListScreen extends ConsumerStatefulWidget {
  const ScreenshotListScreen({super.key, required this.bucket});

  final ScreenshotBucket bucket;

  @override
  ConsumerState<ScreenshotListScreen> createState() => _ScreenshotListScreenState();
}

class _ScreenshotListScreenState extends ConsumerState<ScreenshotListScreen> {
  bool _loading = true;
  List<PhotoAssetInfo> _assets = [];
  final Set<String> _selected = {};
  final Map<String, Uint8List?> _thumbnails = {};
  final Map<String, int> _fileSizes = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final scanService = ref.read(screenshotScanServiceProvider);
    final photoService = ref.read(photoLibraryServiceProvider);
    final assets = await scanService.getAssets(widget.bucket);

    for (final asset in assets) {
      _thumbnails[asset.id] = await photoService.getThumbnail(
        assetId: asset.id,
        width: 240,
        height: 240,
      );
      _fileSizes[asset.id] = await photoService.getAssetFileSize(asset.id) ?? 0;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _assets = assets;
      _selected
        ..clear()
        ..addAll(assets.map((a) => a.id));
    });
  }

  int get _selectedBytes {
    var total = 0;
    for (final id in _selected) {
      total += _fileSizes[id] ?? 0;
    }
    return total;
  }

  Future<void> _cleanSelected() async {
    if (_selected.isEmpty) return;

    final confirmed = await UniversalModal.showAction(
      context,
      title: AppStrings.deleteConfirmTitle,
      content: '将删除 ${_selected.length} 张截图，移入系统「最近删除」。',
      primaryBtnText: '删除',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    HapticFeedback.heavyImpact();
    final photoService = ref.read(photoLibraryServiceProvider);
    final result = await photoService.deleteAssets(_selected.toList());
    if (!mounted) return;

    if (result is AppFailure<DeleteResult>) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }

    await ref.read(screenshotCacheRepositoryProvider).clearAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已清理 ${(result as AppSuccess<DeleteResult>).value.successIds.length} 张截图')),
    );
    if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground.withValues(alpha: 0.9),
        elevation: 0,
        title: Text('${widget.bucket.label}截图', style: Theme.of(context).textTheme.titleMedium),
        centerTitle: true,
      ),
      body: _loading
          ? const LoadingView(message: '加载截图...')
          : _assets.isEmpty
              ? const Center(child: Text('没有符合条件的截图'))
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: context.appPrimary.withValues(alpha: 0.08),
                      child: Text(
                        '已选 ${_selected.length} 张 · 约 ${formatFileSize(_selectedBytes)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.appPrimary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: WaterfallGrid(
                        padding: const EdgeInsets.all(12),
                        itemCount: _assets.length,
                        itemHeight: (index) {
                          final asset = _assets[index];
                          final ratio = asset.aspectRatio ?? 1.0;
                          return 160 * (ratio < 0.6 ? 1.4 : ratio > 1.6 ? 0.75 : ratio);
                        },
                        itemBuilder: (context, index) {
                          final asset = _assets[index];
                          final selected = _selected.contains(asset.id);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selected.remove(asset.id);
                                } else {
                                  _selected.add(asset.id);
                                }
                              });
                            },
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox.expand(
                                    child: _thumbnails[asset.id] != null
                                        ? Image.memory(_thumbnails[asset.id]!, fit: BoxFit.cover)
                                        : ColoredBox(color: context.appSurfaceContainerHigh),
                                  ),
                                ),
                                if (selected)
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: context.appPrimary, width: 3),
                                      ),
                                    ),
                                  ),
                                if (selected)
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: Icon(Icons.check_circle, color: context.appPrimary, size: 24),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _assets.isEmpty
          ? null
          : GlassContainer(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _selected.isEmpty ? null : _cleanSelected,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.systemRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('${AppStrings.cleanSelected} (${_selected.length})'),
                ),
              ),
            ),
    );
  }
}
