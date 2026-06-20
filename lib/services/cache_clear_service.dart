import 'package:sqflite/sqflite.dart';

import '../services/database/app_database.dart';
import 'footprint_cache_repository.dart';
import 'organize_repository.dart';
import 'screenshot_cache_repository.dart';

class ResetOrganizeStats {
  const ResetOrganizeStats({
    required this.processedCount,
    required this.pendingDeleteCount,
    required this.sessionCount,
    required this.cacheEntryCount,
  });

  final int processedCount;
  final int pendingDeleteCount;
  final int sessionCount;
  final int cacheEntryCount;
}

class CacheClearService {
  CacheClearService(
    this._db,
    this._organize,
    this._screenshotCache,
    this._footprintCache,
  );

  final AppDatabase _db;
  final OrganizeRepository _organize;
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

  Future<ResetOrganizeStats> collectResetStats() async {
    final db = await _db.database;
    final processed = await db.rawQuery('SELECT COUNT(*) AS c FROM processed_records');
    final pending = await db.rawQuery('SELECT COUNT(*) AS c FROM pending_delete');
    final sessions = await db.rawQuery('SELECT COUNT(*) AS c FROM sessions');
    return ResetOrganizeStats(
      processedCount: Sqflite.firstIntValue(processed) ?? 0,
      pendingDeleteCount: Sqflite.firstIntValue(pending) ?? 0,
      sessionCount: Sqflite.firstIntValue(sessions) ?? 0,
      cacheEntryCount: await estimatedCacheEntryCount(),
    );
  }

  Future<ResetOrganizeStats> resetOrganizeProgress() async {
    final stats = await collectResetStats();
    await _organize.resetAllOrganizeState();
    await clearScanCaches();
    return stats;
  }
}
