import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../models/footprint_asset.dart';
import '../../models/photo_permission_status.dart';
import '../../providers/footprint_provider.dart';
import '../../providers/providers.dart';
import '../../shared/constants/strings.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/limited_access_banner.dart';
import 'widgets/city_footprint_list.dart';
import 'widgets/footprint_empty_state.dart';
import 'widgets/footprint_map.dart';
import 'widgets/footprint_photo_sheet.dart';
import 'widgets/footprint_poster.dart';
import 'widgets/footprint_skeleton.dart';

class FootprintsScreen extends ConsumerStatefulWidget {
  const FootprintsScreen({super.key});

  @override
  ConsumerState<FootprintsScreen> createState() => _FootprintsScreenState();
}

class _FootprintsScreenState extends ConsumerState<FootprintsScreen> {
  final _mapController = MapController();
  final _posterKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(footprintControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.marginSide, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.footprintsTitle,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  IconButton(
                    key: const Key('footprint_share_button'),
                    tooltip: '分享足迹海报',
                    onPressed: state.hasData ? () => _sharePoster(state) : null,
                    icon: Icon(Icons.ios_share, color: context.appPrimary),
                  ),
                ],
              ),
            ),
            if (state.permission == PhotoPermissionStatus.limited)
              LimitedAccessBanner(
                onAddMore: () => ref.read(photoLibraryServiceProvider).presentLimitedLibraryPicker(),
              ),
            if (state.lastScannedAt != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.marginSide, 4, AppSpacing.marginSide, 0),
                child: Text(
                  '更新于 ${formatRelativeScanTime(state.lastScannedAt!)}'
                  '${state.withoutGpsCount > 0 ? ' · ${state.withoutGpsCount} 张无位置信息' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            Expanded(child: _buildBody(state)),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.marginSide, 8, AppSpacing.marginSide, 8),
              child: Text(
                AppStrings.footprintsPrivacyNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(FootprintState state) {
    if (state.permission == PhotoPermissionStatus.denied) {
      return FootprintEmptyState(
        title: '需要读取照片位置',
        message: AppStrings.footprintsPermissionBody,
        actionLabel: AppStrings.openSettings,
        onAction: () => ref.read(photoLibraryServiceProvider).openAppSettings(),
      );
    }

    if (state.loading && !state.hasData) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.marginSide),
        child: FootprintMapSkeleton(),
      );
    }

    if (!state.hasData && !state.loading) {
      return FootprintEmptyState(
        title: '还没有足迹',
        message: state.error ?? AppStrings.footprintsEmptyBody,
        actionLabel: '重新扫描',
        onAction: () => ref.read(footprintControllerProvider.notifier).load(forceRefresh: true),
      );
    }

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.marginSide, 12, AppSpacing.marginSide, 8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                FootprintMap(
                  controller: _mapController,
                  assets: state.assets,
                  markersVisible: state.markersVisible,
                  onMarkerCityTap: (cityKey) => _openCity(cityKey, state),
                  onClusterAssetIds: (ids) => _openAssets(ids, state),
                ),
                if (state.scanning)
                  Positioned.fill(
                    child: IgnorePointer(child: FootprintMapSkeleton()),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: CityFootprintList(
            cities: state.cities,
            summaryText: state.summary.headline,
            onCityTap: (city) {
              _mapController.move(LatLng(city.centerLat, city.centerLng), 10);
              _openCity(city.cityKey, state);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openCity(String cityKey, FootprintState state) async {
    final assets = state.assets.where((a) => a.cityKey == cityKey).toList();
    if (assets.isEmpty) return;
    final title = assets.first.displayLabel;
    await _openPhotoSheet(title, assets);
  }

  Future<void> _openAssets(List<String> assetIds, FootprintState state) async {
    final assets = state.assets.where((a) => assetIds.contains(a.id)).toList();
    if (assets.isEmpty) return;
    await _openPhotoSheet('这片区域', assets);
  }

  Future<void> _openPhotoSheet(String title, List<FootprintAsset> assets) async {
    final photoService = ref.read(photoLibraryServiceProvider);
    await showFootprintPhotoSheet(
      context: context,
      title: title,
      assets: assets,
      loadThumbnail: (assetId) => photoService.getThumbnail(assetId: assetId, width: 400, height: 400),
    );
  }

  Future<void> _sharePoster(FootprintState state) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: _posterKey,
                child: FootprintPosterCard(
                  cityCount: state.cities.length,
                  momentCount: state.assets.length,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await FootprintPosterShare.share(
                      repaintKey: _posterKey,
                      cityCount: state.cities.length,
                      momentCount: state.assets.length,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('分享海报'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
