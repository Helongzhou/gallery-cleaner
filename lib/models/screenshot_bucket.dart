import '../../shared/constants/strings.dart';

enum ScreenshotBucket {
  days30('30d', 30, AppStrings.screenshotBucket30),
  days90('90d', 90, AppStrings.screenshotBucket90),
  days365('365d', 365, AppStrings.screenshotBucket365);

  const ScreenshotBucket(this.key, this.days, this.label);

  final String key;
  final int days;
  final String label;

  DateTime cutoffAt(DateTime now) => now.subtract(Duration(days: days));

  static ScreenshotBucket? fromKey(String? key) {
    if (key == null) return null;
    for (final bucket in ScreenshotBucket.values) {
      if (bucket.key == key) return bucket;
    }
    return null;
  }
}
