import 'package:flutter_test/flutter_test.dart';

import 'package:album_organizer/shared/constants/strings.dart';

void main() {
  test('app strings are defined', () {
    expect(AppStrings.appTitle, '相册主理人');
    expect(AppStrings.startOrganize, '开始整理');
  });
}
