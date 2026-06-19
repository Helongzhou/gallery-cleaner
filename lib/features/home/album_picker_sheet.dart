import 'package:flutter/material.dart';

import '../../models/album_info.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';

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
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    final pending = pendingCounts[album.id] ?? album.assetCount;
                    final selected = album.id == selectedId;
                    return ListTile(
                      leading: Icon(
                        selected ? Icons.check_circle : Icons.photo_album_outlined,
                        color: selected ? context.appPrimary : null,
                      ),
                      title: Text(album.name),
                      subtitle: Text('共 ${album.assetCount} 张 · 待整理 $pending'),
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
