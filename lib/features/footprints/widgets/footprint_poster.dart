import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/constants/strings.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';

class FootprintPosterCard extends StatelessWidget {
  const FootprintPosterCard({
    super.key,
    required this.cityCount,
    required this.momentCount,
    this.mapSnapshot,
  });

  final int cityCount;
  final int momentCount;
  final Uint8List? mapSnapshot;

  static const slogan = '每一步，都有迹可循';

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final scheme = Theme.of(context).colorScheme;

    final backgroundGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), AppColors.backgroundDark],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.appSurfaceContainerLowest,
              context.appSurfaceContainerLow,
            ],
          );

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : context.appOutlineVariant.withValues(alpha: 0.45);

    final titleMuted = isDark ? Colors.white70 : scheme.onSurfaceVariant;
    final headlineColor = isDark ? Colors.white : scheme.onSurface;
    final bodyColor = isDark ? Colors.white : scheme.onSurface;
    final sloganColor = isDark ? Colors.white60 : scheme.onSurfaceVariant;
    final mapPlaceholderColor = isDark ? AppColors.surfaceContainerHighDark : context.appSurfaceContainerHigh;
    final mapIconColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : scheme.onSurfaceVariant.withValues(alpha: 0.55);

    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.appTitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: titleMuted),
          ),
          const SizedBox(height: 8),
          Text(
            '我的足迹',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: headlineColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: mapSnapshot != null
                  ? Image.memory(mapSnapshot!, fit: BoxFit.cover)
                  : Container(
                      color: mapPlaceholderColor,
                      alignment: Alignment.center,
                      child: Icon(Icons.map_outlined, color: mapIconColor, size: 48),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '已点亮 $cityCount 个城市',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: context.appPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '留下 $momentCount 个美好瞬间',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: bodyColor),
          ),
          const SizedBox(height: 16),
          Text(
            slogan,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: sloganColor,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}

abstract final class FootprintPosterShare {
  static Future<void> share({
    required GlobalKey repaintKey,
    int cityCount = 0,
    int momentCount = 0,
  }) async {
    final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/footprint_poster_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '${AppStrings.appTitle} — 我的照片足迹 · $cityCount 个城市，$momentCount 个美好瞬间',
      ),
    );
  }
}
