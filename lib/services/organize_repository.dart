import 'package:sqflite/sqflite.dart';

import '../models/pending_delete_item.dart';
import '../models/process_action.dart';
import '../models/processed_record.dart';
import '../models/swipe_action.dart';
import '../shared/result.dart';
import 'database/app_database.dart';

class OrganizeRepository {
  OrganizeRepository(this._db);

  final AppDatabase _db;

  Future<AppResult<void>> markOrganized({
    required String assetId,
    required String sourceAlbumId,
    required String targetAlbumId,
    required String sessionId,
  }) async {
    try {
      final db = await _db.database;
      await db.insert('processed_records', {
        'asset_id': assetId,
        'source_album_id': sourceAlbumId,
        'target_album_id': targetAlbumId,
        'action': ProcessAction.organized.dbValue,
        'processed_at': DateTime.now().millisecondsSinceEpoch,
        'session_id': sessionId,
      });
      return const AppSuccess(null);
    } catch (e) {
      return AppFailure('记录归入操作失败', cause: e);
    }
  }

  Future<AppResult<void>> markPendingDelete({
    required String assetId,
    required String sourceAlbumId,
    required String sessionId,
  }) async {
    try {
      final db = await _db.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.transaction((txn) async {
        await txn.insert('processed_records', {
          'asset_id': assetId,
          'source_album_id': sourceAlbumId,
          'action': ProcessAction.pendingDelete.dbValue,
          'processed_at': now,
          'session_id': sessionId,
        });
        await txn.insert(
          'pending_delete',
          {
            'asset_id': assetId,
            'source_album_id': sourceAlbumId,
            'marked_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
      return const AppSuccess(null);
    } catch (e) {
      return AppFailure('记录删除标记失败', cause: e);
    }
  }

  Future<int> countSessionActions(String sessionId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM processed_records WHERE session_id = ?',
      [sessionId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<AppResult<SwipeAction?>> undoLastAction(String sessionId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'processed_records',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'processed_at DESC, id DESC',
        limit: 1,
      );
      if (rows.isEmpty) return const AppSuccess(null);

      final record = ProcessedRecord.fromMap(rows.first);
      await db.transaction((txn) async {
        await txn.delete(
          'processed_records',
          where: 'id = ?',
          whereArgs: [record.id],
        );
        if (record.action == ProcessAction.pendingDelete) {
          await txn.delete(
            'pending_delete',
            where: 'asset_id = ?',
            whereArgs: [record.assetId],
          );
        }
      });
      return AppSuccess(SwipeAction(record: record, assetId: record.assetId));
    } catch (e) {
      return AppFailure('撤销失败', cause: e);
    }
  }

  Future<Set<String>> getProcessedIds(String sourceAlbumId) async {
    final db = await _db.database;
    final rows = await db.query(
      'processed_records',
      columns: ['asset_id'],
      where: 'source_album_id = ?',
      whereArgs: [sourceAlbumId],
    );
    return rows.map((r) => r['asset_id'] as String).toSet();
  }

  Future<void> clearProcessed(String sourceAlbumId) async {
    final db = await _db.database;
    await db.delete(
      'processed_records',
      where: 'source_album_id = ?',
      whereArgs: [sourceAlbumId],
    );
  }

  Future<List<PendingDeleteItem>> getPendingDelete() async {
    final db = await _db.database;
    final rows = await db.query(
      'pending_delete',
      orderBy: 'marked_at DESC',
    );
    return rows.map(PendingDeleteItem.fromMap).toList();
  }

  Future<void> removePendingDelete(List<String> assetIds) async {
    if (assetIds.isEmpty) return;
    final db = await _db.database;
    final placeholders = List.filled(assetIds.length, '?').join(',');
    await db.delete(
      'pending_delete',
      where: 'asset_id IN ($placeholders)',
      whereArgs: assetIds,
    );
  }

  Future<int> pendingDeleteCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM pending_delete');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
