import 'package:sqflite/sqflite.dart';

import '../models/active_session.dart';
import '../models/history_entry.dart';
import '../models/history_session.dart';
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

  static const historyLimit = 50;
  static const sessionHistoryLimit = 20;

  Future<int> historyCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM processed_records');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<HistoryEntry>> getRecentHistory({
    required Map<String, String> albumNames,
    int limit = historyLimit,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'processed_records',
      orderBy: 'processed_at DESC, id DESC',
      limit: limit,
    );
    return rows.map((row) {
      final record = ProcessedRecord.fromMap(row);
      return HistoryEntry(
        record: record,
        label: _historyLabel(record, albumNames),
        targetAlbumName: record.targetAlbumId != null
            ? albumNames[record.targetAlbumId!]
            : null,
      );
    }).toList();
  }

  Future<List<HistorySession>> getRecentHistorySessions({
    required Map<String, String> albumNames,
    int limit = sessionHistoryLimit,
  }) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        p.session_id AS session_id,
        MAX(p.processed_at) AS last_action_at,
        SUM(CASE WHEN p.action = ? THEN 1 ELSE 0 END) AS organized_count,
        SUM(CASE WHEN p.action = ? THEN 1 ELSE 0 END) AS delete_count
      FROM processed_records p
      WHERE p.session_id IS NOT NULL
      GROUP BY p.session_id
      ORDER BY last_action_at DESC
      LIMIT ?
      ''',
      [
        ProcessAction.organized.dbValue,
        ProcessAction.pendingDelete.dbValue,
        limit,
      ],
    );

    final sessions = <HistorySession>[];
    for (final row in rows) {
      final sessionId = row['session_id'] as String;
      final sessionRows = await db.query(
        'sessions',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );

      late String sourceAlbumId;
      late String targetAlbumId;
      late DateTime startedAt;

      if (sessionRows.isNotEmpty) {
        final session = ActiveSession.fromMap(sessionRows.first);
        sourceAlbumId = session.sourceAlbumId;
        targetAlbumId = session.targetAlbumId;
        startedAt = session.startedAt;
      } else {
        final recordRows = await db.query(
          'processed_records',
          where: 'session_id = ?',
          whereArgs: [sessionId],
          orderBy: 'processed_at ASC, id ASC',
          limit: 1,
        );
        if (recordRows.isEmpty) continue;
        final record = ProcessedRecord.fromMap(recordRows.first);
        sourceAlbumId = record.sourceAlbumId;
        targetAlbumId = record.targetAlbumId ?? record.sourceAlbumId;
        startedAt = record.processedAt;
      }

      sessions.add(
        HistorySession(
          sessionId: sessionId,
          startedAt: startedAt,
          lastActionAt: DateTime.fromMillisecondsSinceEpoch(row['last_action_at'] as int),
          sourceAlbumName: albumNames[sourceAlbumId] ?? '来源相册',
          targetAlbumName: albumNames[targetAlbumId] ?? '目标相册',
          organizedCount: row['organized_count'] as int? ?? 0,
          deleteCount: row['delete_count'] as int? ?? 0,
        ),
      );
    }
    return sessions;
  }

  Future<List<HistoryEntry>> getSessionHistory({
    required String sessionId,
    required Map<String, String> albumNames,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'processed_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'processed_at DESC, id DESC',
    );
    return rows.map((row) {
      final record = ProcessedRecord.fromMap(row);
      return HistoryEntry(
        record: record,
        label: _historyLabel(record, albumNames),
        targetAlbumName: record.targetAlbumId != null
            ? albumNames[record.targetAlbumId!]
            : null,
      );
    }).toList();
  }

  Future<ProcessedRecord?> getRecordById(int recordId) async {
    final db = await _db.database;
    final rows = await db.query(
      'processed_records',
      where: 'id = ?',
      whereArgs: [recordId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ProcessedRecord.fromMap(rows.first);
  }

  Future<AppResult<SwipeAction?>> undoByRecordId(int recordId) async {
    try {
      final record = await getRecordById(recordId);
      if (record == null) return const AppSuccess(null);

      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.delete(
          'processed_records',
          where: 'id = ?',
          whereArgs: [recordId],
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

  String _historyLabel(ProcessedRecord record, Map<String, String> albumNames) {
    if (record.action == ProcessAction.pendingDelete) {
      return '标记为待删除';
    }
    final name = record.targetAlbumId != null
        ? albumNames[record.targetAlbumId!] ?? '相册'
        : '相册';
    return '移入了 $name';
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
