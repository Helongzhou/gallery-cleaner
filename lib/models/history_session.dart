class HistorySession {
  const HistorySession({
    required this.sessionId,
    required this.startedAt,
    required this.lastActionAt,
    required this.sourceAlbumName,
    required this.targetAlbumName,
    required this.organizedCount,
    required this.deleteCount,
  });

  final String sessionId;
  final DateTime startedAt;
  final DateTime lastActionAt;
  final String sourceAlbumName;
  final String targetAlbumName;
  final int organizedCount;
  final int deleteCount;

  int get totalCount => organizedCount + deleteCount;

  String get routeLabel => '$sourceAlbumName → $targetAlbumName';

  String get statsLabel {
    final parts = <String>[];
    if (organizedCount > 0) parts.add('整理 $organizedCount 张');
    if (deleteCount > 0) parts.add('待删 $deleteCount 张');
    return parts.join(' · ');
  }
}
