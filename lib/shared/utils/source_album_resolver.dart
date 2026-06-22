import '../../models/album_info.dart';

/// Picks [preferredId] when present in [albums], otherwise the first album.
AlbumInfo? resolveSourceAlbum(List<AlbumInfo> albums, {String? preferredId}) {
  if (albums.isEmpty) return null;
  if (preferredId != null) {
    for (final album in albums) {
      if (album.id == preferredId) return album;
    }
  }
  return albums.first;
}
