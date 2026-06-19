import 'process_action.dart';

class ProcessedRecord {
  const ProcessedRecord({
    required this.assetId,
    required this.sourceAlbumId,
    required this.action,
    required this.processedAt,
    this.targetAlbumId,
    this.sessionId,
    this.id,
  });

  final int? id;
  final String assetId;
  final String sourceAlbumId;
  final String? targetAlbumId;
  final ProcessAction action;
  final DateTime processedAt;
  final String? sessionId;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'asset_id': assetId,
        'source_album_id': sourceAlbumId,
        'target_album_id': targetAlbumId,
        'action': action.dbValue,
        'processed_at': processedAt.millisecondsSinceEpoch,
        'session_id': sessionId,
      };

  factory ProcessedRecord.fromMap(Map<String, Object?> map) {
    return ProcessedRecord(
      id: map['id'] as int?,
      assetId: map['asset_id'] as String,
      sourceAlbumId: map['source_album_id'] as String,
      targetAlbumId: map['target_album_id'] as String?,
      action: ProcessActionX.fromDb(map['action'] as String),
      processedAt: DateTime.fromMillisecondsSinceEpoch(
        map['processed_at'] as int,
      ),
      sessionId: map['session_id'] as String?,
    );
  }
}
