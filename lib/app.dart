import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_provider.dart';
import 'shared/constants/strings.dart';
import 'router/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/utils/immersive_system_ui.dart';

class AlbumOrganizerApp extends ConsumerWidget {
  const AlbumOrganizerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: AppStrings.appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: ImmersiveSystemUi.overlayStyle(brightness),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
