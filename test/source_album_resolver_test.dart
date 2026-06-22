import 'package:album_organizer/models/album_info.dart';
import 'package:album_organizer/shared/utils/source_album_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const albums = [
    AlbumInfo(id: 'all', name: '所有照片', assetCount: 100),
    AlbumInfo(id: 'camera', name: '相机', assetCount: 20),
  ];

  test('defaults to first album when preferred id is missing', () {
    expect(resolveSourceAlbum(albums), albums.first);
    expect(resolveSourceAlbum(albums, preferredId: null), albums.first);
  });

  test('uses preferred id when it exists in the album list', () {
    expect(resolveSourceAlbum(albums, preferredId: 'camera'), albums[1]);
  });

  test('falls back to first album when preferred id is stale', () {
    expect(resolveSourceAlbum(albums, preferredId: 'missing'), albums.first);
  });
}
