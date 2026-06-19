import 'package:flutter/material.dart';

import '../constants/strings.dart';

class LimitedAccessBanner extends StatelessWidget {
  const LimitedAccessBanner({
    super.key,
    required this.onAddMore,
  });

  final VoidCallback onAddMore;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: const Text(AppStrings.limitedAccessHint),
      leading: const Icon(Icons.photo_library_outlined),
      actions: [
        TextButton(
          onPressed: onAddMore,
          child: const Text(AppStrings.addMorePhotos),
        ),
      ],
    );
  }
}
