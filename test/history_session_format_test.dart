import 'package:album_organizer/shared/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatHistorySessionTime uses today label', () {
    final now = DateTime(2026, 3, 15, 18, 0);
    final time = DateTime(2026, 3, 15, 14, 30);
    expect(formatHistorySessionTime(time, now), '今天 14:30');
  });

  test('formatHistorySessionTime uses yesterday label', () {
    final now = DateTime(2026, 3, 15, 18, 0);
    final time = DateTime(2026, 3, 14, 9, 5);
    expect(formatHistorySessionTime(time, now), '昨天 09:05');
  });
}
