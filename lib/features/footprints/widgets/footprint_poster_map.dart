import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/footprint_asset.dart';
import 'footprint_pin.dart';

class FootprintPosterMapCapture extends StatefulWidget {
  const FootprintPosterMapCapture({
    super.key,
    required this.assets,
    required this.tileUrl,
    required this.repaintKey,
    required this.onCaptured,
  });

  final List<FootprintAsset> assets;
  final String tileUrl;
  final GlobalKey repaintKey;
  final ValueChanged<Uint8List> onCaptured;

  @override
  State<FootprintPosterMapCapture> createState() => _FootprintPosterMapCaptureState();
}

class _FootprintPosterMapCaptureState extends State<FootprintPosterMapCapture> {
  final _mapController = MapController();
  var _captured = false;

  @override
  Widget build(BuildContext context) {
    final bounds = _boundsForAssets(widget.assets);
    final markers = widget.assets
        .map(
          (asset) => Marker(
            key: ValueKey<String>(asset.id),
            point: LatLng(asset.lat, asset.lng),
            width: 32,
            height: 32,
            child: const FootprintPin(single: true),
          ),
        )
        .toList();

    return RepaintBoundary(
      key: widget.repaintKey,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(20),
          ),
          minZoom: 2,
          maxZoom: 14,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          onMapReady: _scheduleCapture,
        ),
        children: [
          TileLayer(
            urlTemplate: widget.tileUrl,
            userAgentPackageName: 'com.albumorganizer.albumOrganizer',
            retinaMode: RetinaMode.isHighDensity(context),
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  Future<void> _scheduleCapture() async {
    if (_captured || !mounted) return;
    _captured = true;

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final boundary =
        widget.repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null || !mounted) return;

    widget.onCaptured(byteData.buffer.asUint8List());
  }

  static LatLngBounds _boundsForAssets(List<FootprintAsset> assets) {
    if (assets.isEmpty) {
      const point = LatLng(35.86, 104.19);
      return LatLngBounds(point, point);
    }

    var minLat = assets.first.lat;
    var maxLat = assets.first.lat;
    var minLng = assets.first.lng;
    var maxLng = assets.first.lng;

    for (final asset in assets.skip(1)) {
      minLat = minLat < asset.lat ? minLat : asset.lat;
      maxLat = maxLat > asset.lat ? maxLat : asset.lat;
      minLng = minLng < asset.lng ? minLng : asset.lng;
      maxLng = maxLng > asset.lng ? maxLng : asset.lng;
    }

    if ((maxLat - minLat).abs() < 0.01) {
      minLat -= 0.05;
      maxLat += 0.05;
    }
    if ((maxLng - minLng).abs() < 0.01) {
      minLng -= 0.05;
      maxLng += 0.05;
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }
}
