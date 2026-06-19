import 'package:flutter/material.dart';

/// Simple 2-column masonry layout without extra dependencies.
class WaterfallGrid extends StatelessWidget {
  const WaterfallGrid({
    super.key,
    required this.itemCount,
    required this.itemHeight,
    required this.itemBuilder,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.padding = EdgeInsets.zero,
  });

  final int itemCount;
  final double Function(int index) itemHeight;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = (constraints.maxWidth - padding.horizontal - crossAxisSpacing) / 2;
        final left = <int>[];
        final right = <int>[];
        var leftHeight = 0.0;
        var rightHeight = 0.0;

        for (var i = 0; i < itemCount; i++) {
          final h = itemHeight(i) + mainAxisSpacing;
          if (leftHeight <= rightHeight) {
            left.add(i);
            leftHeight += h;
          } else {
            right.add(i);
            rightHeight += h;
          }
        }

        return SingleChildScrollView(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (final index in left) ...[
                      SizedBox(
                        width: columnWidth,
                        height: itemHeight(index),
                        child: itemBuilder(context, index),
                      ),
                      SizedBox(height: mainAxisSpacing),
                    ],
                  ],
                ),
              ),
              SizedBox(width: crossAxisSpacing),
              Expanded(
                child: Column(
                  children: [
                    for (final index in right) ...[
                      SizedBox(
                        width: columnWidth,
                        height: itemHeight(index),
                        child: itemBuilder(context, index),
                      ),
                      SizedBox(height: mainAxisSpacing),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
