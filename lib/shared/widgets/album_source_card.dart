import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_pressable.dart';

class AlbumSourceCard extends StatelessWidget {
  const AlbumSourceCard({
    super.key,
    required this.albumName,
    required this.totalCount,
    required this.pendingCount,
    this.coverBytes,
    this.onTap,
  });

  final String albumName;
  final int totalCount;
  final int pendingCount;
  final Uint8List? coverBytes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginSide),
      child: AppPressable(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Transform.rotate(
                angle: -0.02,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Transform.rotate(
                angle: 0.02,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverBytes != null)
                      Image.memory(coverBytes!, fit: BoxFit.cover)
                    else
                      ColoredBox(color: context.appSurfaceContainerHigh),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      albumName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                                    ),
                                    Text(
                                      '$totalCount 张照片',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.9),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.systemOrange.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '待整理: $pendingCount',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
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
    );
  }
}
