import 'package:album_organizer/features/footprints/widgets/footprint_poster.dart';
import 'package:album_organizer/shared/constants/strings.dart';
import 'package:album_organizer/shared/theme/app_colors.dart';
import 'package:album_organizer/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('footprint poster uses light theme colors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(
            child: FootprintPosterCard(cityCount: 3, momentCount: 42),
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.appTitle), findsOneWidget);
    expect(find.text('已点亮 3 个城市'), findsOneWidget);

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(FootprintPosterCard),
        matching: find.byType(Container).first,
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    final gradient = decoration.gradient as LinearGradient;
    expect(gradient.colors.first, AppColors.surfaceContainerLowest);
  });

  testWidgets('footprint poster uses dark theme colors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: FootprintPosterCard(cityCount: 1, momentCount: 5),
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(FootprintPosterCard),
        matching: find.byType(Container).first,
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    final gradient = decoration.gradient as LinearGradient;
    expect(gradient.colors.last, const Color(0xFF131313));
  });
}
