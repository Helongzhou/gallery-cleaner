import '../models/history_entry.dart';
import '../models/history_session.dart';
import '../models/process_action.dart';
import '../models/swipe_action.dart';
import '../shared/result.dart';
import 'organize_repository.dart';
import 'photo_library_service.dart';

class HistoryService {
  HistoryService(this._organize, this._photo);

  final OrganizeRepository _organize;
  final PhotoLibraryService _photo;

  Future<int> count() => _organize.historyCount();

  Future<Map<String, String>> _albumNames() async {
    final albumsResult = await _photo.listAlbums();
    return switch (albumsResult) {
      AppSuccess(:final value) => {for (final a in value) a.id: a.name},
      _ => <String, String>{},
    };
  }

  Future<List<HistorySession>> loadSessions() async {
    final albumNames = await _albumNames();
    return _organize.getRecentHistorySessions(albumNames: albumNames);
  }

  Future<List<HistoryEntry>> loadSessionEntries(String sessionId) async {
    final albumNames = await _albumNames();
    return _organize.getSessionHistory(sessionId: sessionId, albumNames: albumNames);
  }

  Future<AppResult<void>> undoEntry(int recordId) async {
    final record = await _organize.getRecordById(recordId);
    if (record == null) {
      return const AppFailure('记录不存在');
    }

    if (record.action == ProcessAction.organized && record.targetAlbumId != null) {
      final removeResult = await _photo.removeFromAlbum(
        assetId: record.assetId,
        albumId: record.targetAlbumId!,
      );
      if (removeResult is AppFailure<void>) {
        return removeResult;
      }
    }

    final undoResult = await _organize.undoByRecordId(recordId);
    if (undoResult is AppFailure<SwipeAction?>) {
      return AppFailure(undoResult.message, cause: undoResult.cause);
    }
    return const AppSuccess(null);
  }
}
