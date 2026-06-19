import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:album_organizer/features/pending_delete/pending_delete_screen.dart';
import 'package:album_organizer/providers/providers.dart';
import 'package:album_organizer/router/routes.dart';
import 'package:album_organizer/shared/constants/strings.dart';
import 'package:album_organizer/testing/fake_photo_library_service.dart';

import 'stub_repositories.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('pending delete cancel returns home when stack cannot pop', (tester) async {
    final overrides = [
      photoLibraryServiceProvider.overrideWithValue(FakePhotoLibraryService()),
      organizeRepositoryProvider.overrideWith((ref) => StubOrganizeRepository()),
    ];

    final router = GoRouter(
      initialLocation: AppRoutes.pendingDelete,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text(AppStrings.appTitle)),
          ),
        ),
        GoRoute(
          path: AppRoutes.pendingDelete,
          builder: (context, state) => const PendingDeleteScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpUntilFound(tester, find.text(AppStrings.pendingDelete));

    await tester.tap(find.byKey(const Key('pending_delete_cancel')));
    await pumpUntilGone(tester, find.byType(PendingDeleteScreen));

    expect(router.state.uri.path, AppRoutes.home);
  });
}
