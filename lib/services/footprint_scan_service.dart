import '../models/city_footprint.dart';
import '../models/footprint_asset.dart';
import 'footprint_cache_repository.dart';
import 'footprint_city_grouper.dart';
import 'geocoding_service.dart';
import 'photo_library_service.dart';

class FootprintScanResult {
  const FootprintScanResult({
    required this.assets,
    required this.cities,
    required this.withoutGpsCount,
    required this.lastScannedAt,
  });

  final List<FootprintAsset> assets;
  final List<CityFootprint> cities;
  final int withoutGpsCount;
  final DateTime? lastScannedAt;

  FootprintSummary get summary => FootprintSummary(
        cityCount: cities.length,
        momentCount: assets.length,
        withoutGpsCount: withoutGpsCount,
        lastScannedAt: lastScannedAt,
      );
}

class FootprintScanService {
  FootprintScanService(
    this._photoService,
    this._cache,
    this._geocoding,
  );

  final PhotoLibraryService _photoService;
  final FootprintCacheRepository _cache;
  final GeocodingService _geocoding;

  Future<FootprintScanResult> load({bool forceRefresh = false}) async {
    final needsSync = forceRefresh || await _cache.needsFullResync();
    if (!needsSync) {
      return _fromCache();
    }
    return _syncLibrary();
  }

  Future<FootprintScanResult> _fromCache() async {
    final assets = await _cache.getAllAssets();
    final meta = await _cache.getMeta();
    final cities = FootprintCityGrouper.group(assets);
    return FootprintScanResult(
      assets: assets,
      cities: cities,
      withoutGpsCount: meta.withoutGps,
      lastScannedAt: meta.lastScan,
    );
  }

  Future<FootprintScanResult> _syncLibrary() async {
    final scan = await _photoService.scanGeoTaggedAssets();
    final libraryIds = scan.geoTagged.map((a) => a.id).toSet();
    await _cache.deleteAssetsNotIn(libraryIds);

    final cachedIds = await _cache.getCachedAssetIds();
    final newItems = scan.geoTagged.where((a) => !cachedIds.contains(a.id)).toList();

    final toInsert = <FootprintAsset>[];
    for (final raw in newItems) {
      final geo = await _geocoding.reverseGeocode(raw.lat, raw.lng);
      toInsert.add(
        FootprintAsset(
          id: raw.id,
          lat: raw.lat,
          lng: raw.lng,
          cityKey: geo.cityKey,
          cityName: geo.cityName,
          district: geo.district,
          takenAt: raw.takenAt,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    await _cache.upsertAssets(toInsert);

    final assets = await _cache.getAllAssets();
    final cities = FootprintCityGrouper.group(assets);
    await _cache.updateMeta(
      withGps: assets.length,
      withoutGps: scan.withoutGps,
      cities: cities.length,
    );
    final meta = await _cache.getMeta();

    return FootprintScanResult(
      assets: assets,
      cities: cities,
      withoutGpsCount: scan.withoutGps,
      lastScannedAt: meta.lastScan,
    );
  }
}
