import 'package:album_organizer/shared/utils/app_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppText.formatMixed', () {
    test('inserts space between Chinese and Latin', () {
      expect(AppText.formatMixed('当前App截图'), '当前 App 截图');
      expect(AppText.formatMixed('剩余5分钟'), '剩余 5 分钟');
    });

    test('preserves already spaced copy', () {
      expect(AppText.formatMixed('Face ID 验证'), 'Face ID 验证');
    });

    test('strips colloquial particles', () {
      expect(AppText.formatMixed('知道了哦'), '知道了');
    });
  });
}
