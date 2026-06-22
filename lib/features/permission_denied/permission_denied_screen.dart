import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../router/routes.dart';
import '../../shared/constants/strings.dart';

class PermissionDeniedScreen extends ConsumerWidget {
  const PermissionDeniedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 72),
              const SizedBox(height: 16),
              Text(
                AppStrings.permissionDeniedTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                AppStrings.permissionDeniedBody,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => ref.read(photoLibraryServiceProvider).openAppSettings(),
                child: const Text(AppStrings.openSettings),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
    );
  }
}
