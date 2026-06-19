import 'package:uuid/uuid.dart';

import '../models/active_session.dart';
import '../models/process_action.dart';
import '../models/session_stats.dart';
import 'database/app_database.dart';

class SessionService {
  SessionService(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<ActiveSession> startSession({
    required String sourceAlbumId,
    required String targetAlbumId,
  }) async {
    final db = await _db.database;
    final session = ActiveSession(
      sessionId: _uuid.v4(),
      sourceAlbumId: sourceAlbumId,
      targetAlbumId: targetAlbumId,
      startedAt: DateTime.now(),
    );
    await db.insert('sessions', session.toMap());
    return session;
  }

  Future<ActiveSession?> getActiveSession() async {
    final db = await _db.database;
    final rows = await db.query(
      'sessions',
      where: 'is_completed = 0',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ActiveSession.fromMap(rows.first);
  }

  Future<void> completeSession(String sessionId) async {
    final db = await _db.database;
    await db.update(
      'sessions',
      {'is_completed': 1},
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<SessionStats> getSessionStats(String sessionId) async {
    final db = await _db.database;
    final rows = await db.query(
      'processed_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    var organized = 0;
    var pendingDelete = 0;
    for (final row in rows) {
      if (row['action'] == ProcessAction.organized.dbValue) {
        organized++;
      } else if (row['action'] == ProcessAction.pendingDelete.dbValue) {
        pendingDelete++;
      }
    }

    return SessionStats(
      totalProcessed: rows.length,
      organizedCount: organized,
      pendingDeleteCount: pendingDelete,
    );
  }
}
