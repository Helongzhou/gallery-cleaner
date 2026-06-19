import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/pending_delete_item.dart';
import '../../providers/providers.dart';
import '../../router/routes.dart';
import '../../shared/constants/strings.dart';
import '../../shared/result.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/loading_view.dart';
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
        width: 200,
        height: 200,
      );
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

  Future<void> _restoreSelected() async {
    await ref.read(organizeRepositoryProvider).removePendingDelete(_selected.toList());
    await _load();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmTitle),
        content: const Text(AppStrings.deleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.systemRed),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    HapticFeedback.heavyImpact();
    final photoService = ref.read(photoLibraryServiceProvider);
    final result = await photoService.deleteAssets(_selected.toList());
    if (!mounted) return;

    if (result is AppFailure<DeleteResult>) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }

    final deleteResult = (result as AppSuccess<DeleteResult>).value;
    await ref.read(organizeRepositoryProvider).removePendingDelete(deleteResult.successIds);

    final message = deleteResult.failedIds.isEmpty
        ? '已删除 ${deleteResult.successIds.length} 张'
        : '成功 ${deleteResult.successIds.length} 张，失败 ${deleteResult.failedIds.length} 张';
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground.withValues(alpha: 0.8),
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
                      color: AppColors.systemGray6.withValues(alpha: 0.5),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '确认后，照片将从所有设备中移除',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selected.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _restoreSelected,
                            child: const Text(AppStrings.restore),
                          ),
                        ),
                      ),
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: _items.length,
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
                              fit: StackFit.expand,
                              children: [
                                if (bytes != null)
                                  Image.memory(bytes, fit: BoxFit.cover)
                                else
                                  ColoredBox(color: context.appSurfaceContainerHigh),
                                if (selected)
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.systemRed.withValues(alpha: 0.35), width: 3),
                                    ),
                                  ),
                                if (selected)
                                  Positioned(
                                    right: 6,
                                    bottom: 6,
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
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _selected.isEmpty ? null : _confirmDelete,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.systemRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('${AppStrings.confirmDelete} ${_selected.length} 张照片'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '照片将移入系统「最近删除」相册',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
    );
  }
}
