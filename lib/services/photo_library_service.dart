import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:photo_manager/photo_manager.dart';

import '../models/album_info.dart';
import '../models/photo_asset_info.dart';
import '../models/photo_permission_status.dart';
import '../shared/result.dart';

class PhotoLibraryService {
  Future<PhotoPermissionStatus> getPermissionStatus() async {
    final state = await PhotoManager.requestPermissionExtend();
    return _mapPermission(state);
  }

  Future<PhotoPermissionStatus> requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    return _mapPermission(state);
  }

  PhotoPermissionStatus _mapPermission(PermissionState state) {
    if (state.isAuth) {
      return state.hasAccess ? PhotoPermissionStatus.authorized : PhotoPermissionStatus.limited;
    }
    if (state == PermissionState.notDetermined) {
      return PhotoPermissionStatus.notDetermined;
    }
    return PhotoPermissionStatus.denied;
  }

  Future<void> presentLimitedLibraryPicker() async {
    await PhotoManager.presentLimited();
  }

  Future<AppResult<List<AlbumInfo>>> listAlbums({bool writableOnly = false}) async {
    try {
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );
      final albums = <AlbumInfo>[];
      for (final path in paths) {
        final writable = _isWritableAlbum(path);
        if (writableOnly && !writable) continue;
        final count = await path.assetCountAsync;
        albums.add(
          AlbumInfo(
            id: path.id,
            name: path.name,
            assetCount: count,
            isWritable: writable,
          ),
        );
      }
      return AppSuccess(albums);
    } catch (e) {
      return AppFailure('读取相册列表失败', cause: e);
    }
  }

  bool _isWritableAlbum(AssetPathEntity path) {
    if (path.isAll) return false;
    if (path.albumType == 2) return false;
    final darwinType = path.albumTypeEx?.darwin?.type;
    if (darwinType == PMDarwinAssetCollectionType.smartAlbum) return false;
    return true;
  }

  Future<bool> isAssetInAlbum(String assetId, String albumId) async {
    final album = await _findAlbum(albumId);
    if (album == null) return false;
    final count = await album.assetCountAsync;
    if (count == 0) return false;
    final end = count > 2000 ? 2000 : count;
    final assets = await album.getAssetListRange(start: 0, end: end);
    return assets.any((a) => a.id == assetId);
  }

  Future<AppResult<AlbumInfo>> createAlbum(String name) async {
    try {
      final existing = await listAlbums();
      if (existing is AppSuccess<List<AlbumInfo>>) {
        final duplicate = existing.value.any((a) => a.name == name);
        if (duplicate) {
          return const AppFailure('相册名已存在，请换一个');
        }
      }

      final path = await PhotoManager.editor.darwin.createAlbum(name);
      if (path == null) {
        return const AppFailure('创建相册失败');
      }
      final count = await path.assetCountAsync;
      return AppSuccess(
        AlbumInfo(id: path.id, name: path.name, assetCount: count),
      );
    } catch (e) {
      return AppFailure('创建相册失败', cause: e);
    }
  }

  Future<AppResult<List<PhotoAssetInfo>>> getAssets({
    required String albumId,
    Set<String> excludeProcessed = const {},
  }) async {
    try {
      final path = await _findAlbum(albumId);
      if (path == null) {
        return const AppFailure('找不到来源相册');
      }

      final assets = await path.getAssetListRange(start: 0, end: await path.assetCountAsync);
      final filtered = assets
          .where((asset) => !excludeProcessed.contains(asset.id))
          .map(
            (asset) => PhotoAssetInfo(
              id: asset.id,
              createDate: asset.createDateTime,
            ),
          )
          .toList()
        ..sort((a, b) {
          final aDate = a.createDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      return AppSuccess(filtered);
    } catch (e) {
      return AppFailure('读取照片失败', cause: e);
    }
  }

  Future<AppResult<void>> addToAlbum({
    required String assetId,
    required String albumId,
    String? sourceAlbumId,
  }) async {
    try {
      if (sourceAlbumId != null && sourceAlbumId == albumId) {
        return const AppFailure('目标相册不能与来源相册相同');
      }

      final asset = await AssetEntity.fromId(assetId);
      final album = await _findAlbum(albumId);
      if (asset == null) {
        return const AppFailure('找不到该照片');
      }
      if (album == null) {
        return const AppFailure('找不到目标相册');
      }
      if (!_isWritableAlbum(album)) {
        return const AppFailure('该相册不支持写入，请换一个目标相册');
      }

      if (await isAssetInAlbum(assetId, albumId)) {
        return const AppSuccess(null);
      }

      await PhotoManager.editor.copyAssetToPath(
        asset: asset,
        pathEntity: album,
      );
      return const AppSuccess(null);
    } on ArgumentError catch (e) {
      return AppFailure(_humanizeAddError(e.message), cause: e);
    } catch (e) {
      return AppFailure(_humanizeAddError(e.toString()), cause: e);
    }
  }

  String _humanizeAddError(String? raw) {
    final text = raw ?? '';
    if (text.contains('permission') || text.contains('Permission')) {
      return '相册写入权限不足，请在设置中允许访问';
    }
    if (text.contains('not found') || text.contains('不存在')) {
      return '照片或目标相册不存在';
    }
    return '无法加入该相册，请换一个目标相册';
  }

  Future<AppResult<DeleteResult>> deleteAssets(List<String> assetIds) async {
    if (assetIds.isEmpty) {
      return AppSuccess(DeleteResult(successIds: const [], failedIds: const []));
    }

    try {
      final deletedIds = await PhotoManager.editor.deleteWithIds(assetIds);
      final deletedSet = deletedIds.toSet();
      final failed = assetIds.where((id) => !deletedSet.contains(id)).toList();
      return AppSuccess(
        DeleteResult(successIds: deletedIds, failedIds: failed),
      );
    } catch (e) {
      return AppFailure('删除照片失败', cause: e);
    }
  }

  Future<Uint8List?> getThumbnail({
    required String assetId,
    required int width,
    required int height,
  }) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;
    return asset.thumbnailDataWithSize(ThumbnailSize(width, height));
  }

  Future<Uint8List?> getAlbumCover(String albumId, {int size = 400}) async {
    try {
      final path = await _findAlbum(albumId);
      if (path == null) return null;
      final count = await path.assetCountAsync;
      if (count == 0) return null;
      final assets = await path.getAssetListRange(start: 0, end: 1);
      if (assets.isEmpty) return null;
      return assets.first.thumbnailDataWithSize(ThumbnailSize(size, size));
    } catch (_) {
      return null;
    }
  }

  Future<void> openAppSettings() => ph.openAppSettings();

  Future<AssetPathEntity?> _findAlbum(String albumId) async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );
    for (final path in paths) {
      if (path.id == albumId) return path;
    }
    return null;
  }
}

class DeleteResult {
  const DeleteResult({
    required this.successIds,
    required this.failedIds,
  });

  final List<String> successIds;
  final List<String> failedIds;
}
