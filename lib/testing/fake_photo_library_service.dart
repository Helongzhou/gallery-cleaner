import 'dart:typed_data';

import '../models/album_info.dart';
import '../models/photo_asset_info.dart';
import '../models/photo_permission_status.dart';
import '../services/photo_library_service.dart';
import '../shared/result.dart';

/// Deterministic photo library for widget/integration tests.
class FakePhotoLibraryService extends PhotoLibraryService {
  FakePhotoLibraryService({
    this.sourceAlbum = const AlbumInfo(id: 'source', name: '测试来源', assetCount: 5),
    this.writableAlbum = const AlbumInfo(id: 'target', name: '测试目标', assetCount: 0, isWritable: true),
  });

  final AlbumInfo sourceAlbum;
  final AlbumInfo writableAlbum;

  static final _assets = List.generate(
    5,
    (i) => PhotoAssetInfo(id: 'asset_$i', createDate: DateTime(2024, 1, i + 1)),
  );

  @override
  Future<PhotoPermissionStatus> getPermissionStatus() async => PhotoPermissionStatus.authorized;

  @override
  Future<PhotoPermissionStatus> requestPermission() async => PhotoPermissionStatus.authorized;

  @override
  Future<AppResult<List<AlbumInfo>>> listAlbums({bool writableOnly = false}) async {
    if (writableOnly) return AppSuccess([writableAlbum]);
    return AppSuccess([sourceAlbum, writableAlbum]);
  }

  @override
  Future<AppResult<List<PhotoAssetInfo>>> getAssets({
    required String albumId,
    Set<String> excludeProcessed = const {},
  }) async {
    final assets = _assets.where((a) => !excludeProcessed.contains(a.id)).toList();
    return AppSuccess(assets);
  }

  @override
  Future<Uint8List?> getThumbnail({
    required String assetId,
    required int width,
    required int height,
  }) async =>
      null;

  @override
  Future<Uint8List?> getAlbumCover(String albumId, {int size = 400}) async => null;

  @override
  Future<AppResult<AlbumInfo>> createAlbum(String name) async {
    return AppSuccess(AlbumInfo(id: 'new_$name', name: name, assetCount: 0, isWritable: true));
  }

  @override
  Future<AppResult<void>> addToAlbum({
    required String assetId,
    required String albumId,
    String? sourceAlbumId,
  }) async =>
      const AppSuccess(null);

  @override
  Future<AppResult<DeleteResult>> deleteAssets(List<String> assetIds) async {
    return AppSuccess(DeleteResult(successIds: assetIds, failedIds: const []));
  }

  @override
  Future<int?> getAssetFileSize(String assetId) async => 1024 * 500;

  @override
  Future<({int width, int height})?> getAssetDimensions(String assetId) async => (width: 3, height: 4);

  @override
  Future<AppResult<List<PhotoAssetInfo>>> getScreenshotAssetsOlderThan(DateTime cutoff) async {
    return const AppSuccess([]);
  }

  @override
  Future<List<PhotoAssetInfo>> getAssetsByIds(List<String> assetIds) async => [];
}
