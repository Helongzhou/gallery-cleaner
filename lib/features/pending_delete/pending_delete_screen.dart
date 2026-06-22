import 'dart:typed_data';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/pending_delete_item.dart';
import '../../providers/history_provider.dart';
import '../../providers/providers.dart';
import '../../router/routes.dart';
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

class PendingDeleteScreen extends ConsumerStatefulWidget {
  const PendingDeleteScreen({super.key});

  @override
  ConsumerState<PendingDeleteScreen> createState() => _PendingDeleteScreenState();
}

class _PendingDeleteScreenState extends ConsumerState<PendingDeleteScreen> {
  bool _loading = true;
  bool _allSelected = true;
  List<PendingDeleteItem> _items = [];
  final Set<String> _selected = {};
  final Map<String, Uint8List?> _thumbnails = {};
  final Map<String, int> _fileSizes = {};
  final Map<String, double> _aspectRatios = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await ref.read(organizeRepositoryProvider).getPendingDelete();
    final photoService = ref.read(photoLibraryServiceProvider);

    for (final item in items) {
      _thumbnails[item.assetId] = await photoService.getThumbnail(
        assetId: item.assetId,
        width: 280,
        height: 280,
      );
      _fileSizes[item.assetId] = await photoService.getAssetFileSize(item.assetId) ?? 0;
      final dims = await photoService.getAssetDimensions(item.assetId);
      if (dims != null && dims.height > 0) {
        _aspectRatios[item.assetId] = dims.width / dims.height;
      } else {
        _aspectRatios[item.assetId] = 1.0;
      }
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = items;
      _selected
        ..clear()
        ..addAll(items.map((e) => e.assetId));
      _allSelected = items.isNotEmpty;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _allSelected = !_allSelected;
      if (_allSelected) {
        _selected.addAll(_items.map((e) => e.assetId));
      } else {
        _selected.clear();
      }
    });
  }

  int get _selectedBytes {
    var total = 0;
    for (final id in _selected) {
      total += _fileSizes[id] ?? 0;
    }
    return total;
  }

  Future<void> _restoreSelected() async {
    if (_selected.isEmpty) return;
    await ref.read(organizeRepositoryProvider).removePendingDelete(_selected.toList());
    ref.read(homeRefreshProvider.notifier).state++;
    await _load();
  }

  Future<void> _confirmDelete() async {
    if (_selected.isEmpty) return;

    final confirmed = await UniversalModal.showAction(
      context,
      title: AppStrings.deleteConfirmTitle,
      content: AppStrings.deleteConfirmContent(android: Platform.isAndroid),
      primaryBtnText: AppStrings.confirmDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    HapticFeedback.heavyImpact();
    final photoService = ref.read(photoLibraryServiceProvider);
    final partitioned = await photoService.partitionExistingAssetIds(_selected.toList());
    if (!mounted) return;

    if (partitioned.stale.isNotEmpty) {
      await ref.read(organizeRepositoryProvider).removePendingDelete(partitioned.stale);
      ref.read(homeRefreshProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.pendingDeleteStaleRemovedMessage(partitioned.stale.length))),
      );
    }

    if (partitioned.existing.isEmpty) {
      await _load();
      return;
    }

    final result = await photoService.deleteAssets(partitioned.existing);
    if (!mounted) return;

    if (result is AppFailure<DeleteResult>) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }

    final deleteResult = (result as AppSuccess<DeleteResult>).value;
    if (deleteResult.successIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.deleteNothingMessage)),
      );
      return;
    }

    await ref.read(organizeRepositoryProvider).removePendingDelete(deleteResult.successIds);
    ref.read(homeRefreshProvider.notifier).state++;

    final message = deleteResult.failedIds.isEmpty
        ? AppStrings.deleteSuccessMessage(deleteResult.successIds.length)
        : AppStrings.deletePartialMessage(
            deleteResult.successIds.length,
            deleteResult.failedIds.length,
          );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        leading: TextButton(
          key: const Key('pending_delete_cancel'),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
          child: Text('取消', style: TextStyle(color: context.appPrimary)),
        ),
        leadingWidth: 72,
        title: Text(AppStrings.pendingDelete, style: Theme.of(context).textTheme.titleMedium),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _items.isEmpty ? null : _toggleSelectAll,
            child: Text(_allSelected ? AppStrings.deselectAll : AppStrings.selectAll),
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _items.isEmpty
              ? const Center(child: Text('没有待删除的照片'))
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
                        itemCount: _items.length,
                        itemHeight: (index) {
                          final item = _items[index];
                          final ratio = _aspectRatios[item.assetId] ?? 1.0;
                          return 160 * (ratio < 0.6 ? 1.4 : ratio > 1.6 ? 0.75 : ratio);
                        },
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final selected = _selected.contains(item.assetId);
                          final bytes = _thumbnails[item.assetId];

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selected.remove(item.assetId);
                                } else {
                                  _selected.add(item.assetId);
                                }
                                _allSelected = _selected.length == _items.length;
                              });
                            },
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox.expand(
                                    child: bytes != null
                                        ? Image.memory(bytes, fit: BoxFit.cover)
                                        : ColoredBox(color: context.appSurfaceContainerHigh),
                                  ),
                                ),
                                if (selected)
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.systemRed.withValues(alpha: 0.6), width: 3),
                                      ),
                                    ),
                                  ),
                                if (selected)
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: AppColors.systemRed,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _items.isEmpty
          ? null
          : GlassContainer(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _selected.isEmpty ? null : _restoreSelected,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(AppStrings.removeFromPending),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _selected.isEmpty ? null : _confirmDelete,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.systemRed,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(AppStrings.confirmDelete),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.pendingDeleteTrashHint(android: Platform.isAndroid),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
