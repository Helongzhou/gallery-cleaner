class AlbumInfo {
  const AlbumInfo({
    required this.id,
    required this.name,
    required this.assetCount,
    this.isWritable = true,
  });

  final String id;
  final String name;
  final int assetCount;
  final bool isWritable;
}
