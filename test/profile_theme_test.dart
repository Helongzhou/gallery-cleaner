import 'package:album_organizer/features/profile/profile_screen.dart';
import 'package:album_organizer/models/theme_preference.dart';
import 'package:album_organizer/providers/providers.dart';
import 'package:album_organizer/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stub_repositories.dart';

void main() {
  testWidgets('profile theme segment updates theme preference', (tester) async {
    final settings = StubSettingsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => settings),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('深色'), findsOneWidget);

    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();

    expect(await settings.getThemePreference(), ThemePreference.dark);
  });
}
