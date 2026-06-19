import '../models/history_entry.dart';
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

  Future<List<HistoryEntry>> loadEntries() async {
    final albumsResult = await _photo.listAlbums();
    final albumNames = switch (albumsResult) {
      AppSuccess(:final value) => {for (final a in value) a.id: a.name},
      _ => <String, String>{},
    };
    return _organize.getRecentHistory(albumNames: albumNames);
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
