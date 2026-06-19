class ActiveSession {
  const ActiveSession({
    required this.sessionId,
    required this.sourceAlbumId,
    required this.targetAlbumId,
    required this.startedAt,
    this.isCompleted = false,
    this.id,
  });

  final int? id;
  final String sessionId;
  final String sourceAlbumId;
  final String targetAlbumId;
  final DateTime startedAt;
  final bool isCompleted;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'session_id': sessionId,
        'source_album_id': sourceAlbumId,
        'target_album_id': targetAlbumId,
        'started_at': startedAt.millisecondsSinceEpoch,
        'is_completed': isCompleted ? 1 : 0,
      };

  factory ActiveSession.fromMap(Map<String, Object?> map) {
    return ActiveSession(
      id: map['id'] as int?,
      sessionId: map['session_id'] as String,
      sourceAlbumId: map['source_album_id'] as String,
      targetAlbumId: map['target_album_id'] as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int),
      isCompleted: (map['is_completed'] as int) == 1,
    );
  }
}
