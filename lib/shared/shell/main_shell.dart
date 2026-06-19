import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/library_tab_state.dart';
import '../../router/routes.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/primary_button.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.smart)) return 1;
    if (location.startsWith(AppRoutes.footprints) || location.startsWith(AppRoutes.shared)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final tabIndex = _indexForLocation(location);
    final libraryState = ref.watch(libraryTabStateProvider);
    final showCta = tabIndex == 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCta)
            GlassContainer(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.2))),
              child: PrimaryButton(
                key: const Key('home_start_organize'),
                label: libraryState.buttonLabel,
                icon: libraryState.canStart ? Icons.auto_awesome : null,
                onPressed: libraryState.canStart ? libraryState.onStart : null,
              ),
            ),
          NavigationBar(
            selectedIndex: tabIndex,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go(AppRoutes.home);
                case 1:
                  context.go(AppRoutes.smart);
                case 2:
                  context.go(AppRoutes.footprints);
                case 3:
                  context.go(AppRoutes.profile);
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.photo_library_outlined),
                selectedIcon: Icon(Icons.photo_library),
                label: '相库',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: '智能',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: '足迹',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: '我的',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
