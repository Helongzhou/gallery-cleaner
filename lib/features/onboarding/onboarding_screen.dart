import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../router/routes.dart';
import '../../shared/constants/strings.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/immersive_system_ui.dart';
import '../../shared/widgets/primary_button.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _pages = [
    (Icons.photo_album_outlined, '选择来源和目标相册', '先选定要整理的来源相册，以及照片要归入的目标相册。'),
    (Icons.swipe_left, '左滑标记删除', '左滑不会立刻删除，照片会进入待删除队列，支持撤销。'),
    (Icons.swipe_right, '右滑归入相册', '右滑将照片加入目标系统相册，已整理的照片默认不再出现。'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, context.statusBarTop + 16, 16, 16),
              child: Text(AppStrings.appTitle, style: Theme.of(context).textTheme.displaySmall),
            ),
          ),
            Expanded(
              child: PageView.builder(
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: context.appPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(page.$1, size: 56, color: context.appPrimary),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          page.$2,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.$3,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => _finish(context, ref),
                    child: Text(AppStrings.skip, style: TextStyle(color: context.appPrimary)),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 140,
                    child: PrimaryButton(
                      label: AppStrings.getStarted,
                      height: 48,
                      onPressed: () => _finish(context, ref),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    await ref.read(settingsRepositoryProvider).setHasSeenOnboarding(true);
    if (context.mounted) context.go(AppRoutes.home);
  }
}
