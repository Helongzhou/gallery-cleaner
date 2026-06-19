import 'process_action.dart';
import 'processed_record.dart';

class SwipeAction {
  const SwipeAction({
    required this.record,
    required this.assetId,
  });

  final ProcessedRecord record;
  final String assetId;

  ProcessAction get action => record.action;
}
