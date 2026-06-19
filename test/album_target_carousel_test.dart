import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:album_organizer/shared/constants/organize_mode.dart';
import 'package:album_organizer/shared/theme/app_theme.dart';
import 'package:album_organizer/shared/widgets/album_target_carousel.dart';

void main() {
  testWidgets('delete-only target shows primary selection ring', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AlbumTargetCarousel(
            albums: const [],
            selectedId: OrganizeMode.deleteOnlyTargetId,
            onSelect: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );

    final containerFinder = find.descendant(
      of: find.byKey(const Key('target_delete_only')),
      matching: find.byType(Container),
    ).first;

    final decoration = tester.widget<Container>(containerFinder).decoration! as BoxDecoration;
    final border = decoration.border as Border;

    expect(border.top.width, 3);
    expect(border.top.color, AppTheme.light().colorScheme.primary);
  });
}
