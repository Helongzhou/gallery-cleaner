import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:album_organizer/features/swipe/widgets/swipe_header.dart';

void main() {
  testWidgets('swipe header title is horizontally centered', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeHeader(
            title: '仅删除',
            current: 2,
            total: 10,
            onBack: () {},
          ),
        ),
      ),
    );

    final titleFinder = find.byKey(const Key('swipe_header_title'));
    expect(titleFinder, findsOneWidget);

    final titleCenter = tester.getCenter(titleFinder);
    final headerBox = tester.getRect(find.byType(SwipeHeader));
    expect((titleCenter.dx - headerBox.center.dx).abs(), lessThan(2));
  });
}
