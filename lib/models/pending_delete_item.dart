class PendingDeleteItem {
  const PendingDeleteItem({
    required this.assetId,
    required this.sourceAlbumId,
    required this.markedAt,
    this.id,
  });

  final int? id;
  final String assetId;
  final String sourceAlbumId;
  final DateTime markedAt;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'asset_id': assetId,
        'source_album_id': sourceAlbumId,
        'marked_at': markedAt.millisecondsSinceEpoch,
      };

  factory PendingDeleteItem.fromMap(Map<String, Object?> map) {
    return PendingDeleteItem(
      id: map['id'] as int?,
      assetId: map['asset_id'] as String,
      sourceAlbumId: map['source_album_id'] as String,
      markedAt: DateTime.fromMillisecondsSinceEpoch(map['marked_at'] as int),
    );
  }
}
