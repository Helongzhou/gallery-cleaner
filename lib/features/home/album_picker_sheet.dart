import 'package:flutter/material.dart';

import '../../models/album_info.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/album_icon_resolver.dart';

Future<AlbumInfo?> showAlbumPickerSheet({
  required BuildContext context,
  required String title,
  required List<AlbumInfo> albums,
  required Map<String, int> pendingCounts,
  String? selectedId,
}) {
  return showModalBottomSheet<AlbumInfo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appSurfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appOutlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.appPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.photo_library_outlined, color: context.appPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    final pending = pendingCounts[album.id] ?? album.assetCount;
                    final selected = album.id == selectedId;
                    final icon = AlbumIconResolver.resolve(album.name);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? context.appPrimary.withValues(alpha: 0.12)
                              : context.appSurfaceContainerHigh.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 22,
                          color: selected
                              ? context.appPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      title: Text(
                        album.name,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text('共 ${album.assetCount} 张 · 待整理 $pending'),
                      trailing: selected
                          ? Icon(Icons.check_circle, color: context.appPrimary)
                          : null,
                      onTap: () => Navigator.pop(context, album),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
