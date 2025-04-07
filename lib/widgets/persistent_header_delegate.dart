import 'dart:ui';

import 'package:flutter/cupertino.dart';

class PersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double minHeight;
  final bool blur;
  final double sigma;
  final Widget Function(BuildContext context, double shrink) builder;

  PersistentHeaderDelegate({
    required this.expandedHeight,
    this.minHeight = 60,
    this.blur = false,
    this.sigma = 10,
    required this.builder,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight,
      ),
      child: SizedBox.expand(
        child: blur
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: sigma,
                    sigmaY: sigma,
                  ),
                  child: builder(
                      context, (shrinkOffset / expandedHeight).clamp(0, 1)),
                ),
              )
            : builder(context, (shrinkOffset / expandedHeight).clamp(0, 1)),
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
