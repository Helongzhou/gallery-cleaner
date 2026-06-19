import 'processed_record.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.record,
    required this.label,
    this.targetAlbumName,
  });

  final ProcessedRecord record;
  final String label;
  final String? targetAlbumName;

  String get assetId => record.assetId;
  int? get recordId => record.id;
}
