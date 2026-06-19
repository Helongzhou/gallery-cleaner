import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/city_footprint.dart';
import '../models/footprint_asset.dart';
import '../models/photo_permission_status.dart';
import '../services/footprint_cache_repository.dart';
import '../services/footprint_scan_service.dart';
import '../services/geocoding_service.dart';
import '../services/photo_library_service.dart';
import 'providers.dart';

class FootprintState {
  const FootprintState({
    this.loading = true,
    this.scanning = false,
    this.permission,
    this.assets = const [],
    this.cities = const [],
    this.withoutGpsCount = 0,
    this.lastScannedAt,
    this.error,
    this.markersVisible = false,
  });

  final bool loading;
  final bool scanning;
  final PhotoPermissionStatus? permission;
  final List<FootprintAsset> assets;
  final List<CityFootprint> cities;
  final int withoutGpsCount;
  final DateTime? lastScannedAt;
  final String? error;
  final bool markersVisible;

  bool get hasData => assets.isNotEmpty;

  FootprintSummary get summary => FootprintSummary(
        cityCount: cities.length,
        momentCount: assets.length,
        withoutGpsCount: withoutGpsCount,
        lastScannedAt: lastScannedAt,
      );

  FootprintState copyWith({
    bool? loading,
    bool? scanning,
    PhotoPermissionStatus? permission,
    List<FootprintAsset>? assets,
    List<CityFootprint>? cities,
    int? withoutGpsCount,
    DateTime? lastScannedAt,
    String? error,
    bool? markersVisible,
  }) {
    return FootprintState(
      loading: loading ?? this.loading,
      scanning: scanning ?? this.scanning,
      permission: permission ?? this.permission,
      assets: assets ?? this.assets,
      cities: cities ?? this.cities,
      withoutGpsCount: withoutGpsCount ?? this.withoutGpsCount,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      error: error,
      markersVisible: markersVisible ?? this.markersVisible,
    );
  }
}

final geocodingServiceProvider = Provider((ref) => GeocodingService());

final footprintCacheRepositoryProvider = Provider(
  (ref) => FootprintCacheRepository(ref.watch(databaseProvider)),
);

final footprintScanServiceProvider = Provider(
  (ref) => FootprintScanService(
    ref.watch(photoLibraryServiceProvider),
    ref.watch(footprintCacheRepositoryProvider),
    ref.watch(geocodingServiceProvider),
  ),
);

final footprintControllerProvider =
    StateNotifierProvider<FootprintController, FootprintState>((ref) {
  return FootprintController(
    ref.watch(photoLibraryServiceProvider),
    ref.watch(footprintScanServiceProvider),
  );
});

class FootprintController extends StateNotifier<FootprintState> {
  FootprintController(this._photoService, this._scanService) : super(const FootprintState()) {
    load();
  }

  final PhotoLibraryService _photoService;
  final FootprintScanService _scanService;

  Future<void> load({bool forceRefresh = false}) async {
    state = state.copyWith(loading: true, scanning: true, error: null, markersVisible: false);

    final permission = await _photoService.requestPermission();
    if (permission == PhotoPermissionStatus.denied) {
      state = state.copyWith(
        loading: false,
        scanning: false,
        permission: permission,
        error: '需要相册权限才能生成足迹',
      );
      return;
    }

    try {
      final result = await _scanService.load(forceRefresh: forceRefresh);
      state = state.copyWith(
        loading: false,
        scanning: false,
        permission: permission,
        assets: result.assets,
        cities: result.cities,
        withoutGpsCount: result.withoutGpsCount,
        lastScannedAt: result.lastScannedAt,
        markersVisible: false,
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
      state = state.copyWith(markersVisible: true);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        scanning: false,
        permission: permission,
        error: '足迹扫描失败，请稍后重试',
      );
    }
  }
}
