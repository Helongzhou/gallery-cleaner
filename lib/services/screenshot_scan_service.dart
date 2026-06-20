import '../models/photo_asset_info.dart';
import '../models/screenshot_bucket.dart';
import '../shared/result.dart';
import 'photo_library_service.dart';
import 'screenshot_cache_repository.dart';

class ScreenshotScanService {
  ScreenshotScanService(this._photoService, this._cache);

  final PhotoLibraryService _photoService;
  final ScreenshotCacheRepository _cache;

  Future<Map<ScreenshotBucket, int>> getCounts({bool forceRefresh = false}) async {
    final counts = <ScreenshotBucket, int>{};
    for (final bucket in ScreenshotBucket.values) {
      final ids = await _scanBucket(bucket, forceRefresh: forceRefresh);
      counts[bucket] = ids.length;
    }
    return counts;
  }

  Future<DateTime?> getLatestScannedAt() async {
    DateTime? latest;
    for (final bucket in ScreenshotBucket.values) {
      final scannedAt = await _cache.getScannedAt(bucket);
      if (scannedAt == null) continue;
      if (latest == null || scannedAt.isAfter(latest)) {
        latest = scannedAt;
      }
    }
    return latest;
  }

  Future<List<PhotoAssetInfo>> getAssets(
    ScreenshotBucket bucket, {
    bool forceRefresh = false,
  }) async {
    final ids = await _scanBucket(bucket, forceRefresh: forceRefresh);
    if (ids.isEmpty) return [];
    return _photoService.getAssetsByIds(ids);
  }

  Future<List<String>> _scanBucket(ScreenshotBucket bucket, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _cache.getCachedIds(bucket);
      if (cached != null) return cached;
    }

    final cutoff = bucket.cutoffAt(DateTime.now());
    final result = await _photoService.getScreenshotAssetsOlderThan(cutoff);
    if (result is AppFailure<List<PhotoAssetInfo>>) return [];

    final assets = (result as AppSuccess<List<PhotoAssetInfo>>).value;
    final ids = assets.map((a) => a.id).toList();
    if (ids.isNotEmpty) {
      await _cache.save(bucket, ids);
    }
    return ids;
  }
}
