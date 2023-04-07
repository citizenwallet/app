import 'package:flutter/cupertino.dart';

class WalletHeader extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final Widget child;
  final Widget shrunkenChild;

  WalletHeader({
    required this.expandedHeight,
    required this.child,
    required this.shrunkenChild,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: shrinkOffset == 0 ? child : shrunkenChild,
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
