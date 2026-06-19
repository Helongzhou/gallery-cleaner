import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../constants/organize_mode.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_pressable.dart';

class AlbumTargetCarousel extends StatelessWidget {
  const AlbumTargetCarousel({
    super.key,
    required this.albums,
    required this.selectedId,
    required this.onSelect,
    required this.onCreate,
    this.thumbnails = const {},
    this.onViewAll,
  });

  final List<({String id, String name})> albums;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;
  final Map<String, Uint8List?> thumbnails;
  final VoidCallback? onViewAll;

  static const _size = 112.0;

  @override
  Widget build(BuildContext context) {
    final deleteOnlySelected = selectedId == OrganizeMode.deleteOnlyTargetId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginSide),
          child: Row(
            children: [
              Text('目标相册', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(
                key: const Key('target_create_album'),
                onPressed: onCreate,
                child: Text('新建相册', style: TextStyle(color: context.appPrimary)),
              ),
              if (onViewAll != null) ...[
                const SizedBox(width: AppSpacing.gutter),
                TextButton(
                  onPressed: onViewAll,
                  child: Text('查看全部', style: TextStyle(color: context.appPrimary)),
                ),
              ],
            ],
          ),
        ),
        if (deleteOnlySelected)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              '当前：仅标记删除，不归入相册',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.systemOrange),
            ),
          ),
        const SizedBox(height: AppSpacing.stackMedium),
        SizedBox(
          height: _size + 28,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginSide),
            children: [
              _DeleteOnlyItem(
                selected: deleteOnlySelected,
                onTap: () => onSelect(OrganizeMode.deleteOnlyTargetId),
              ),
              const SizedBox(width: AppSpacing.gutter),
              ...albums.take(8).map((album) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.gutter),
                  child: _AlbumItem(
                    name: album.name,
                    selected: album.id == selectedId,
                    bytes: thumbnails[album.id],
                    onTap: () => onSelect(album.id),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeleteOnlyItem extends StatelessWidget {
  const _DeleteOnlyItem({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: true,
      child: SizedBox(
        key: const Key('target_delete_only'),
        width: AlbumTargetCarousel._size,
        child: Column(
          children: [
            Container(
              width: AlbumTargetCarousel._size,
              height: AlbumTargetCarousel._size,
              decoration: BoxDecoration(
                color: AppColors.systemRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: selected ? context.appPrimary : context.appOutlineVariant.withValues(alpha: 0.5),
                  width: selected ? 3 : 1,
                ),
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.systemRed, size: 36),
            ),
            const SizedBox(height: 8),
            Text('仅删除', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _AlbumItem extends StatelessWidget {
  const _AlbumItem({
    required this.name,
    required this.selected,
    required this.onTap,
    this.bytes,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: true,
      child: SizedBox(
        width: AlbumTargetCarousel._size,
        child: Column(
          children: [
            Container(
              width: AlbumTargetCarousel._size,
              height: AlbumTargetCarousel._size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: selected ? context.appPrimary : context.appOutlineVariant.withValues(alpha: 0.3),
                  width: selected ? 3 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: bytes != null
                  ? Image.memory(bytes!, fit: BoxFit.cover)
                  : ColoredBox(color: context.appSurfaceContainerHigh),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
