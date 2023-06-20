import 'package:flutter/cupertino.dart';

class PersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double minHeight;
  final Widget Function(BuildContext context, double shrink) builder;

  PersistentHeaderDelegate({
    required this.expandedHeight,
    this.minHeight = 60,
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
          child: builder(context, (shrinkOffset / expandedHeight).clamp(0, 1))),
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
