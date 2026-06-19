import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_pressable.dart';

class RadarScanButton extends StatefulWidget {
  const RadarScanButton({
    super.key,
    required this.scanning,
    required this.onTap,
  });

  final bool scanning;
  final VoidCallback? onTap;

  @override
  State<RadarScanButton> createState() => _RadarScanButtonState();
}

class _RadarScanButtonState extends State<RadarScanButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    if (widget.scanning) _controller.repeat();
  }

  @override
  void didUpdateWidget(RadarScanButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scanning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.scanning && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: widget.onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.appSurfaceContainerHigh.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        child: RotationTransition(
          turns: _controller,
          child: Icon(Icons.radar, color: context.appPrimary, size: 22),
        ),
      ),
    );
  }
}
