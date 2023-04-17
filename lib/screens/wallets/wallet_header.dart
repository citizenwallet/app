import 'package:flutter/cupertino.dart';

class WalletHeader extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double minHeight;
  final Widget child;
  final Widget shrunkenChild;

  WalletHeader({
    required this.expandedHeight,
    this.minHeight = 60,
    required this.child,
    required this.shrunkenChild,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    if (shrinkOffset == 0) {
      return SizedBox.expand(child: child);
    }

    if (shrinkOffset == expandedHeight) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minHeight,
        ),
        child: SizedBox.expand(child: shrunkenChild),
      );
    }

    return AnimatedOpacity(
      opacity: (shrinkOffset / expandedHeight).clamp(0, 1),
      duration: Duration.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minHeight,
        ),
        child: SizedBox.expand(child: shrunkenChild),
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
