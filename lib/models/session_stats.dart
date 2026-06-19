class SessionStats {
  const SessionStats({
    required this.totalProcessed,
    required this.organizedCount,
    required this.pendingDeleteCount,
  });

  final int totalProcessed;
  final int organizedCount;
  final int pendingDeleteCount;
}
