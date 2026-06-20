import 'dart:io';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:photo_manager/photo_manager.dart';

import '../models/footprint_asset.dart';
import '../models/album_info.dart';
import '../models/photo_asset_info.dart';
import '../models/photo_permission_status.dart';
import '../shared/constants/organize_constants.dart';
import '../shared/result.dart';

class PhotoLibraryService {
  /// 1×1 transparent PNG used to create Android album buckets.
  static final Uint8List _androidAlbumPlaceholder = Uint8List.fromList(const <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);

  Future<PhotoPermissionStatus> getPermissionStatus() async {
    final state = await PhotoManager.requestPermissionExtend();
    return _mapPermission(state);
  }

  Future<PhotoPermissionStatus> requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend(
      requestOption: _photoPermissionOption(includeMediaLocation: false),
    );
    return _mapPermission(state);
  }

  /// Android 10+ needs ACCESS_MEDIA_LOCATION to read GPS from photos.
  Future<void> ensureMediaLocationAccess() async {
    if (!Platform.isAndroid) return;
    await PhotoManager.requestPermissionExtend(
      requestOption: _photoPermissionOption(includeMediaLocation: true),
    );
  }

  PermissionRequestOption _photoPermissionOption({required bool includeMediaLocation}) {
    if (Platform.isAndroid) {
      return PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.common,
          mediaLocation: includeMediaLocation,
        ),
      );
    }
    return const PermissionRequestOption();
  }

  Future<({double? lat, double? lng})> _resolveAssetLocation(AssetEntity asset) async {
    var lat = asset.latitude;
    var lng = asset.longitude;
    if (lat != null && lng != null && !(lat == 0 && lng == 0)) {
      return (lat: lat, lng: lng);
    }
    try {
      final latLng = await asset.latlngAsync();
      if (latLng != null) {
        return (lat: latLng.latitude, lng: latLng.longitude);
      }
    } catch (_) {}
    return (lat: null, lng: null);
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
    if (!Platform.isIOS && !Platform.isAndroid) return;
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

    if (Platform.isIOS || Platform.isMacOS) {
      if (path.albumType == 2) return false;
      final darwinType = path.albumTypeEx?.darwin?.type;
      if (darwinType == PMDarwinAssetCollectionType.smartAlbum) return false;
      return true;
    }

    if (Platform.isAndroid) {
      final lower = path.name.toLowerCase();
      if (lower == 'download' || lower == 'downloads' || lower == '下载') return false;
      return true;
    }

    return !path.isAll;
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
      if (name.length > OrganizeConstants.maxAlbumNameLength) {
        return AppFailure('相册名不能超过 ${OrganizeConstants.maxAlbumNameLength} 个字');
      }

      final existing = await listAlbums();
      if (existing is AppSuccess<List<AlbumInfo>>) {
        final duplicate = existing.value.any((a) => a.name == name);
        if (duplicate) {
          return const AppFailure('相册名已存在，请换一个');
        }
      }

      if (Platform.isIOS || Platform.isMacOS) {
        return _createAlbumDarwin(name);
      }
      if (Platform.isAndroid) {
        return _createAlbumAndroid(name);
      }
      return const AppFailure('当前平台不支持创建相册');
    } catch (e) {
      return AppFailure('创建相册失败', cause: e);
    }
  }

  Future<AppResult<AlbumInfo>> _createAlbumDarwin(String name) async {
    final path = await PhotoManager.editor.darwin.createAlbum(name);
    if (path == null) {
      return const AppFailure('创建相册失败');
    }
    final count = await path.assetCountAsync;
    return AppSuccess(
      AlbumInfo(id: path.id, name: path.name, assetCount: count, isWritable: true),
    );
  }

  Future<AppResult<AlbumInfo>> _createAlbumAndroid(String name) async {
    await PhotoManager.editor.saveImage(
      _androidAlbumPlaceholder,
      filename: '.album_placeholder.png',
      title: '.album_placeholder',
      relativePath: 'Pictures/$name',
    );

    final paths = await PhotoManager.getAssetPathList(type: RequestType.image, hasAll: true);
    for (final path in paths) {
      if (path.name == name) {
        final count = await path.assetCountAsync;
        return AppSuccess(
          AlbumInfo(id: path.id, name: path.name, assetCount: count, isWritable: true),
        );
      }
    }
    return const AppFailure('创建相册失败，请检查存储权限');
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
      final deletedIds = await _deleteAssetIds(assetIds);
      final deletedSet = deletedIds.toSet();
      final failed = assetIds.where((id) => !deletedSet.contains(id)).toList();
      return AppSuccess(
        DeleteResult(successIds: deletedIds, failedIds: failed),
      );
    } catch (e) {
      return AppFailure('删除照片失败', cause: e);
    }
  }

  Future<List<String>> _deleteAssetIds(List<String> assetIds) async {
    if (Platform.isAndroid) {
      final sdk = int.tryParse(await PhotoManager.systemVersion()) ?? 0;
      if (sdk >= 30) {
        final entities = <AssetEntity>[];
        for (final id in assetIds) {
          final entity = await AssetEntity.fromId(id);
          if (entity != null) {
            entities.add(entity);
          }
        }
        if (entities.isEmpty) {
          return const [];
        }
        final trashed = await PhotoManager.editor.android.moveToTrash(entities);
        if (trashed.isNotEmpty) {
          return trashed;
        }
        return PhotoManager.editor.deleteWithIds(assetIds);
      }
    }
    return PhotoManager.editor.deleteWithIds(assetIds);
  }

  Future<({List<String> existing, List<String> stale})> partitionExistingAssetIds(
    List<String> assetIds,
  ) async {
    final existing = <String>[];
    final stale = <String>[];
    for (final id in assetIds) {
      final entity = await AssetEntity.fromId(id);
      if (entity == null) {
        stale.add(id);
      } else {
        existing.add(id);
      }
    }
    return (existing: existing, stale: stale);
  }

  Future<List<PhotoAssetInfo>> getAssetsByIds(List<String> assetIds) async {
    if (assetIds.isEmpty) return [];

    final results = <PhotoAssetInfo>[];
    for (final id in assetIds) {
      final asset = await AssetEntity.fromId(id);
      if (asset == null) continue;
      results.add(
        PhotoAssetInfo(
          id: asset.id,
          createDate: asset.createDateTime,
          width: asset.width,
          height: asset.height,
        ),
      );
    }
    return results;
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

  Future<int?> getAssetFileSize(String assetId) async {
    try {
      final asset = await AssetEntity.fromId(assetId);
      if (asset == null) return null;
      final file = await asset.file;
      return file?.length();
    } catch (_) {
      return null;
    }
  }

  Future<({int width, int height})?> getAssetDimensions(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;
    return (width: asset.width, height: asset.height);
  }

  Future<AppResult<List<PhotoAssetInfo>>> getScreenshotAssetsOlderThan(DateTime cutoff) async {
    try {
      final album = await _findScreenshotsAlbum();
      if (album == null) {
        return const AppSuccess([]);
      }

      final count = await album.assetCountAsync;
      if (count == 0) return const AppSuccess([]);

      final results = <PhotoAssetInfo>[];
      const batchSize = 80;
      for (var start = 0; start < count; start += batchSize) {
        final end = (start + batchSize > count) ? count : start + batchSize;
        final assets = await album.getAssetListRange(start: start, end: end);
        for (final asset in assets) {
          final created = asset.createDateTime;
          if (created.isBefore(cutoff)) {
            results.add(
              PhotoAssetInfo(
                id: asset.id,
                createDate: created,
                width: asset.width,
                height: asset.height,
              ),
            );
          }
        }
        await Future<void>.delayed(Duration.zero);
      }

      results.sort((a, b) {
        final aDate = a.createDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return AppSuccess(results);
    } catch (e) {
      return AppFailure('读取截图失败', cause: e);
    }
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

  Future<AppResult<void>> removeFromAlbum({
    required String assetId,
    required String albumId,
  }) async {
    try {
      final asset = await AssetEntity.fromId(assetId);
      final album = await _findAlbum(albumId);
      if (asset == null) return const AppFailure('找不到该照片');
      if (album == null) return const AppFailure('找不到目标相册');

      if (Platform.isIOS || Platform.isMacOS) {
        final removed = await PhotoManager.editor.darwin.removeInAlbum(asset, album);
        if (!removed) {
          return const AppFailure('无法从相册移除照片');
        }
        return const AppSuccess(null);
      }

      if (Platform.isAndroid) {
        final copy = await _findCopiedAssetInAlbum(
          sourceAssetId: assetId,
          album: album,
          source: asset,
        );
        if (copy == null) {
          return const AppFailure('无法从相册移除照片');
        }
        final deleted = await PhotoManager.editor.deleteWithIds([copy.id]);
        if (deleted.isEmpty) {
          return const AppFailure('无法从相册移除照片');
        }
        return const AppSuccess(null);
      }

      return const AppFailure('当前平台不支持从相册移除照片');
    } catch (e) {
      return AppFailure('从相册移除失败', cause: e);
    }
  }

  Future<AssetEntity?> _findCopiedAssetInAlbum({
    required String sourceAssetId,
    required AssetPathEntity album,
    required AssetEntity source,
  }) async {
    final count = await album.assetCountAsync;
    if (count == 0) return null;
    final end = count > 500 ? 500 : count;
    final assets = await album.getAssetListRange(start: 0, end: end);
    for (final candidate in assets) {
      if (candidate.id == sourceAssetId) continue;
      if (candidate.width == source.width &&
          candidate.height == source.height &&
          candidate.createDateTime == source.createDateTime) {
        return candidate;
      }
    }
    return null;
  }

  /// Scans all accessible photos/videos for GPS coordinates (batched, non-blocking).
  Future<({List<RawGeoAsset> geoTagged, int withoutGps})> scanGeoTaggedAssets({
    void Function(int processed, int total)? onProgress,
  }) async {
    try {
      await ensureMediaLocationAccess();

      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: true,
      );
      if (paths.isEmpty) {
        return (geoTagged: <RawGeoAsset>[], withoutGps: 0);
      }

      final allAlbum = paths.firstWhere(
        (path) => path.isAll,
        orElse: () => paths.first,
      );

      final count = await allAlbum.assetCountAsync;
      if (count == 0) {
        return (geoTagged: <RawGeoAsset>[], withoutGps: 0);
      }

      final geoTagged = <RawGeoAsset>[];
      var withoutGps = 0;
      const batchSize = 80;

      for (var start = 0; start < count; start += batchSize) {
        final end = (start + batchSize > count) ? count : start + batchSize;
        final assets = await allAlbum.getAssetListRange(start: start, end: end);
        for (final asset in assets) {
          final coords = await _resolveAssetLocation(asset);
          final lat = coords.lat;
          final lng = coords.lng;
          if (lat == null || lng == null || (lat == 0 && lng == 0)) {
            withoutGps++;
            continue;
          }
          geoTagged.add(
            RawGeoAsset(
              id: asset.id,
              lat: lat,
              lng: lng,
              takenAt: asset.createDateTime,
            ),
          );
        }
        onProgress?.call(end, count);
        await Future<void>.delayed(Duration.zero);
      }

      return (geoTagged: geoTagged, withoutGps: withoutGps);
    } catch (_) {
      return (geoTagged: <RawGeoAsset>[], withoutGps: 0);
    }
  }

  Future<AssetPathEntity?> _findScreenshotsAlbum() async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );
    for (final path in paths) {
      if (Platform.isIOS || Platform.isMacOS) {
        final subtype = path.albumTypeEx?.darwin?.subtype;
        if (subtype == PMDarwinAssetCollectionSubtype.smartAlbumScreenshots) {
          return path;
        }
      }

      final name = path.name.toLowerCase();
      if (_isScreenshotsAlbumName(name)) {
        return path;
      }
    }
    return null;
  }

  bool _isScreenshotsAlbumName(String lowerName) {
    return lowerName.contains('screenshot') ||
        lowerName.contains('screen shot') ||
        lowerName.contains('screen_shot') ||
        lowerName.contains('截屏') ||
        lowerName.contains('屏幕快照') ||
        lowerName == 'screenshots';
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
