import 'package:sqflite/sqflite.dart';

import '../models/footprint_asset.dart';
import 'database/app_database.dart';

class FootprintCacheRepository {
  FootprintCacheRepository(this._db);

  final AppDatabase _db;
  static const fullScanTtl = Duration(hours: 24);

  Future<List<FootprintAsset>> getAllAssets() async {
    final db = await _db.database;
    final rows = await db.query('footprint_assets');
    return rows.map(FootprintAsset.fromRow).toList();
  }

  Future<List<FootprintAsset>> getAssetsByCityKey(String cityKey) async {
    final db = await _db.database;
    final rows = await db.query(
      'footprint_assets',
      where: 'city_key = ?',
      whereArgs: [cityKey],
      orderBy: 'taken_at DESC',
    );
    return rows.map(FootprintAsset.fromRow).toList();
  }

  Future<List<FootprintAsset>> getAssetsByIds(List<String> assetIds) async {
    if (assetIds.isEmpty) return [];
    final db = await _db.database;
    final placeholders = List.filled(assetIds.length, '?').join(',');
    final rows = await db.query(
      'footprint_assets',
      where: 'asset_id IN ($placeholders)',
      whereArgs: assetIds,
      orderBy: 'taken_at DESC',
    );
    return rows.map(FootprintAsset.fromRow).toList();
  }

  Future<Set<String>> getCachedAssetIds() async {
    final db = await _db.database;
    final rows = await db.query('footprint_assets', columns: ['asset_id']);
    return rows.map((r) => r['asset_id'] as String).toSet();
  }

  Future<void> upsertAssets(List<FootprintAsset> assets) async {
    if (assets.isEmpty) return;
    final db = await _db.database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final asset in assets) {
      batch.insert(
        'footprint_assets',
        asset.toRow(now),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAssetsNotIn(Set<String> keepIds) async {
    final db = await _db.database;
    if (keepIds.isEmpty) {
      await db.delete('footprint_assets');
      return;
    }
    final cached = await getCachedAssetIds();
    final toDelete = cached.difference(keepIds);
    if (toDelete.isEmpty) return;
    final batch = db.batch();
    for (final id in toDelete) {
      batch.delete('footprint_assets', where: 'asset_id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<({DateTime? lastScan, int withGps, int withoutGps, int cities})> getMeta() async {
    final db = await _db.database;
    final rows = await db.query('footprint_scan_meta', where: 'id = 1', limit: 1);
    if (rows.isEmpty) {
      return (lastScan: null, withGps: 0, withoutGps: 0, cities: 0);
    }
    final row = rows.first;
    final lastMs = row['last_full_scan_at'] as int?;
    return (
      lastScan: lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs),
      withGps: row['total_with_gps'] as int? ?? 0,
      withoutGps: row['total_without_gps'] as int? ?? 0,
      cities: row['total_cities'] as int? ?? 0,
    );
  }

  Future<void> updateMeta({
    required int withGps,
    required int withoutGps,
    required int cities,
  }) async {
    final db = await _db.database;
    await db.insert(
      'footprint_scan_meta',
      {
        'id': 1,
        'last_full_scan_at': DateTime.now().millisecondsSinceEpoch,
        'total_with_gps': withGps,
        'total_without_gps': withoutGps,
        'total_cities': cities,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> needsFullResync() async {
    final meta = await getMeta();
    if (meta.lastScan == null) return true;
    return DateTime.now().difference(meta.lastScan!) > fullScanTtl;
  }
}
