class PhotoAssetInfo {
  const PhotoAssetInfo({
    required this.id,
    required this.createDate,
    this.width,
    this.height,
    this.fileSizeBytes,
  });

  final String id;
  final DateTime? createDate;
  final int? width;
  final int? height;
  final int? fileSizeBytes;

  double? get aspectRatio {
    if (width == null || height == null || height == 0) return null;
    return width! / height!;
  }
}
