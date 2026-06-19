import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

class FootprintPin extends StatelessWidget {
  const FootprintPin({super.key, this.count, this.single = false});

  final int? count;
  final bool single;

  @override
  Widget build(BuildContext context) {
    final isCluster = count != null && count! > 1;
    final size = isCluster ? 44.0 : 32.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: isCluster
          ? Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            )
          : const Icon(Icons.location_on, color: Colors.white, size: 18),
    );
  }
}
