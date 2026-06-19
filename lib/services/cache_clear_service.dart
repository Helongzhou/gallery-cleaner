import 'package:sqflite/sqflite.dart';

import '../services/database/app_database.dart';
import 'footprint_cache_repository.dart';
import 'screenshot_cache_repository.dart';

class CacheClearService {
  CacheClearService(this._db, this._screenshotCache, this._footprintCache);

  final AppDatabase _db;
  final ScreenshotCacheRepository _screenshotCache;
  final FootprintCacheRepository _footprintCache;

  Future<int> estimatedCacheEntryCount() async {
    final db = await _db.database;
    final screenshot = await db.rawQuery('SELECT COUNT(*) AS c FROM screenshot_scan_cache');
    final footprint = await db.rawQuery('SELECT COUNT(*) AS c FROM footprint_assets');
    final s = Sqflite.firstIntValue(screenshot) ?? 0;
    final f = Sqflite.firstIntValue(footprint) ?? 0;
    return s + f;
  }

  Future<void> clearScanCaches() async {
    await _screenshotCache.clearAll();
    final db = await _db.database;
    await db.delete('footprint_assets');
    await db.delete('footprint_scan_meta');
  }
}
