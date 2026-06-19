import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/pending_delete/pending_delete_screen.dart';
import '../features/permission_denied/permission_denied_screen.dart';
import '../features/placeholder/placeholder_tab_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/smart/screenshot_list_screen.dart';
import '../features/smart/smart_screen.dart';
import '../features/summary/summary_screen.dart';
import '../features/swipe/swipe_screen.dart';
import '../models/screenshot_bucket.dart';
import '../providers/providers.dart';
import '../shared/shell/main_shell.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    redirect: (context, state) async {
      final settings = ref.read(settingsRepositoryProvider);
      final hasSeenOnboarding = await settings.hasSeenOnboarding();
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;

      if (!hasSeenOnboarding && !isOnboarding) {
        return AppRoutes.onboarding;
      }
      if (hasSeenOnboarding && isOnboarding) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.permissionDenied,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PermissionDeniedScreen(),
      ),
      GoRoute(
        path: AppRoutes.swipe,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as SwipeRouteArgs?;
          if (extra == null) {
            return const Scaffold(body: Center(child: Text('缺少滑动参数')));
          }
          return SwipeScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.summary,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as SummaryRouteArgs?;
          if (extra == null) {
            return const Scaffold(body: Center(child: Text('缺少摘要参数')));
          }
          return SummaryScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.pendingDelete,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PendingDeleteScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.smart,
            builder: (context, state) => const SmartScreen(),
            routes: [
              GoRoute(
                path: 'screenshots',
                builder: (context, state) {
                  final bucket = ScreenshotBucket.fromKey(state.uri.queryParameters['bucket']);
                  if (bucket == null) {
                    return const Scaffold(body: Center(child: Text('缺少截图筛选参数')));
                  }
                  return ScreenshotListScreen(bucket: bucket);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.shared,
            builder: (context, state) => const PlaceholderTabScreen(
              title: '共享相册',
              icon: Icons.folder_shared_outlined,
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class SwipeRouteArgs {
  const SwipeRouteArgs({
    required this.sessionId,
    required this.sourceAlbumId,
    required this.sourceAlbumName,
    required this.totalCount,
    required this.initialIndex,
    this.targetAlbumId,
    this.targetAlbumName,
    this.deleteOnly = false,
  });

  final String sessionId;
  final String sourceAlbumId;
  final String sourceAlbumName;
  final String? targetAlbumId;
  final String? targetAlbumName;
  final int totalCount;
  final int initialIndex;
  final bool deleteOnly;
}

class SummaryRouteArgs {
  const SummaryRouteArgs({
    required this.sessionId,
    required this.totalProcessed,
    required this.organizedCount,
    required this.pendingDeleteCount,
    this.targetAlbumName,
    this.targetAlbumId,
    this.deleteOnly = false,
  });

  final String sessionId;
  final String? targetAlbumName;
  final String? targetAlbumId;
  final int totalProcessed;
  final int organizedCount;
  final int pendingDeleteCount;
  final bool deleteOnly;
}
