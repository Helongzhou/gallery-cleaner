import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/footprint_asset.dart';
import '../../../shared/theme/app_colors.dart';

class FootprintMap extends StatelessWidget {
  const FootprintMap({
    super.key,
    required this.controller,
    required this.assets,
    required this.markersVisible,
    required this.onMarkerCityTap,
    required this.onClusterAssetIds,
    this.tileUrl,
  });

  final MapController controller;
  final List<FootprintAsset> assets;
  final bool markersVisible;
  final void Function(String cityKey) onMarkerCityTap;
  final void Function(List<String> assetIds) onClusterAssetIds;

  static const _defaultTileUrl = 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

  final String? tileUrl;

  @override
  Widget build(BuildContext context) {
    final center = _initialCenter(assets);
    final assetById = {for (final a in assets) a.id: a};

    final markers = assets
        .map(
          (asset) => Marker(
            key: ValueKey<String>(asset.id),
            point: LatLng(asset.lat, asset.lng),
            width: 36,
            height: 36,
            child: _FootprintPin(single: true),
          ),
        )
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: center,
          initialZoom: assets.length <= 3 ? 5 : 4,
          minZoom: 2,
          maxZoom: 18,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: tileUrl ?? _defaultTileUrl,
            userAgentPackageName: 'com.albumorganizer.albumOrganizer',
            retinaMode: RetinaMode.isHighDensity(context),
          ),
          AnimatedOpacity(
            opacity: markersVisible ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 60,
                size: const Size(44, 44),
                markers: markers,
                builder: (context, clusterMarkers) {
                  return _FootprintPin(count: clusterMarkers.length);
                },
                onMarkerTap: (marker) {
                  final id = (marker.key as ValueKey<String>?)?.value;
                  if (id == null) return;
                  final asset = assetById[id];
                  if (asset != null) onMarkerCityTap(asset.cityKey);
                },
                onClusterTap: (cluster) {
                  final ids = cluster.markers
                      .map((m) => (m.key as ValueKey<String>?)?.value)
                      .whereType<String>()
                      .toList();
                  if (ids.isEmpty) return;
                  if (ids.length == 1) {
                    final asset = assetById[ids.first];
                    if (asset != null) onMarkerCityTap(asset.cityKey);
                    return;
                  }
                  onClusterAssetIds(ids);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static LatLng _initialCenter(List<FootprintAsset> assets) {
    if (assets.isEmpty) return const LatLng(35.86, 104.19);
    final lat = assets.fold<double>(0, (sum, a) => sum + a.lat) / assets.length;
    final lng = assets.fold<double>(0, (sum, a) => sum + a.lng) / assets.length;
    return LatLng(lat, lng);
  }
}

class _FootprintPin extends StatelessWidget {
  const _FootprintPin({this.count, this.single = false});

  final int? count;
  final bool single;

  @override
  Widget build(BuildContext context) {
    final isCluster = count != null && count! > 1;
    final size = isCluster ? 44.0 : 32.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: isCluster
          ? Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            )
          : const Icon(Icons.location_on, color: Colors.white, size: 18),
    );
  }
}
