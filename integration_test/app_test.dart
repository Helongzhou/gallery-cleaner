import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:album_organizer/app.dart';
import 'package:album_organizer/providers/providers.dart';
import 'package:album_organizer/services/database/app_database.dart';
import 'package:album_organizer/services/settings_repository.dart';
import 'package:album_organizer/shared/constants/strings.dart';
import 'package:album_organizer/testing/fake_photo_library_service.dart';
import 'package:album_organizer/testing/integration_doubles.dart';

import '../test/test_helpers.dart';

Future<void> pauseForDemo([Duration duration = const Duration(seconds: 2)]) async {
  await IntegrationTestWidgetsFlutterBinding.instance.delayed(duration);
}

Future<void> _pumpTestApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        photoLibraryServiceProvider.overrideWithValue(FakePhotoLibraryService()),
        settingsRepositoryProvider.overrideWith((ref) => IntegrationSettingsRepository()),
        organizeRepositoryProvider.overrideWith((ref) => IntegrationOrganizeRepository()),
        sessionServiceProvider.overrideWith((ref) => IntegrationSessionService()),
      ],
      child: const AlbumOrganizerApp(),
    ),
  );
  await pumpUntilFound(tester, find.text('来源相册'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final settings = SettingsRepository(AppDatabase.instance);
    await settings.setHasSeenOnboarding(true);
  });

  testWidgets('P0 smoke: home and delete-only swipe', (tester) async {
    await _pumpTestApp(tester);
    await pauseForDemo();

    expect(find.text('来源相册'), findsOneWidget);
    expect(find.text('相库'), findsOneWidget);
    expect(find.byKey(const Key('home_start_organize')), findsOneWidget);
    expect(find.text(AppStrings.startOrganize), findsOneWidget);
    await pauseForDemo();

    await tester.tap(find.byKey(const Key('target_delete_only')));
    await tester.pump(const Duration(milliseconds: 200));
    await pauseForDemo();

    await tester.tap(find.byKey(const Key('home_start_organize')));
    await pumpUntilFound(tester, find.byKey(const Key('swipe_header_title')));
    await pauseForDemo(const Duration(seconds: 3));

    expect(find.byKey(const Key('swipe_header_title')), findsOneWidget);
    expect(find.text('仅删除模式：左滑标记删除'), findsOneWidget);
  });
}
