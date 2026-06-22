import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/screenshot_bucket.dart';
import 'database/app_database.dart';

class ScreenshotCacheRepository {
  ScreenshotCacheRepository(this._db);

  final AppDatabase _db;
  static const cacheTtl = Duration(hours: 24);

  Future<List<String>?> getCachedIds(ScreenshotBucket bucket) async {
    final db = await _db.database;
    final rows = await db.query(
      'screenshot_scan_cache',
      where: 'bucket = ?',
      whereArgs: [bucket.key],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final scannedAt = DateTime.fromMillisecondsSinceEpoch(rows.first['scanned_at'] as int);
    if (DateTime.now().difference(scannedAt) > cacheTtl) return null;

    final raw = rows.first['asset_ids'] as String;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<String>();
  }

  Future<DateTime?> getScannedAt(ScreenshotBucket bucket) async {
    final db = await _db.database;
    final rows = await db.query(
      'screenshot_scan_cache',
      columns: ['scanned_at'],
      where: 'bucket = ?',
      whereArgs: [bucket.key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(rows.first['scanned_at'] as int);
  }

  Future<void> save(ScreenshotBucket bucket, List<String> assetIds) async {
    final db = await _db.database;
    await db.insert(
      'screenshot_scan_cache',
      {
        'bucket': bucket.key,
        'asset_ids': jsonEncode(assetIds),
        'scanned_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearAll() async {
    final db = await _db.database;
    await db.delete('screenshot_scan_cache');
  }

  Future<void> clearBucket(ScreenshotBucket bucket) async {
    final db = await _db.database;
    await db.delete(
      'screenshot_scan_cache',
      where: 'bucket = ?',
      whereArgs: [bucket.key],
    );
  }

  Future<void> removeIds(List<String> assetIds) async {
    if (assetIds.isEmpty) return;
    final removeSet = assetIds.toSet();
    final db = await _db.database;

    for (final bucket in ScreenshotBucket.values) {
      final rows = await db.query(
        'screenshot_scan_cache',
        where: 'bucket = ?',
        whereArgs: [bucket.key],
        limit: 1,
      );
      if (rows.isEmpty) continue;

      final raw = rows.first['asset_ids'] as String;
      final decoded = (jsonDecode(raw) as List<dynamic>).cast<String>();
      final updated = decoded.where((id) => !removeSet.contains(id)).toList();
      if (updated.length == decoded.length) continue;

      if (updated.isEmpty) {
        await db.delete(
          'screenshot_scan_cache',
          where: 'bucket = ?',
          whereArgs: [bucket.key],
        );
      } else {
        await db.update(
          'screenshot_scan_cache',
          {
            'asset_ids': jsonEncode(updated),
            'scanned_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'bucket = ?',
          whereArgs: [bucket.key],
        );
      }
    }
  }
}
