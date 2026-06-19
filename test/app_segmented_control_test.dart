import 'package:album_organizer/shared/widgets/app_segmented_control.dart';
import 'package:album_organizer/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('segments stay equal width when selection changes', (tester) async {
    var selected = 'a';

    Future<void> pump() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppSegmentedControl<String>(
                  segments: const [
                    AppSegment(value: 'a', label: '30 天前'),
                    AppSegment(value: 'b', label: '90 天前'),
                    AppSegment(value: 'c', label: '1 年前'),
                  ],
                  selected: selected,
                  onChanged: (value) => setState(() => selected = value),
                );
              },
            ),
          ),
        ),
      );
    }

    await pump();
    final widthsBefore = _segmentWidths(tester);

    await tester.tap(find.text('1 年前'));
    await tester.pumpAndSettle();

    final widthsAfter = _segmentWidths(tester);

    expect(widthsBefore.length, 3);
    expect(widthsAfter.length, 3);
    for (var i = 0; i < 3; i++) {
      expect(widthsAfter[i], closeTo(widthsBefore[i], 0.5));
    }
  });
}

List<double> _segmentWidths(WidgetTester tester) {
  final tiles = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
  return tiles.map((w) => tester.getSize(find.byWidget(w)).width).toList();
}
