import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:simple_animations/simple_animations.dart';

class PulsingContainer extends StatelessWidget {
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Widget? child;

  const PulsingContainer({
    super.key,
    this.height,
    this.width,
    this.padding,
    this.borderRadius = 5,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MirrorAnimationBuilder<Color?>(
      builder: (context, value, child) => Container(
        height: height,
        width: width,
        padding: padding,
        decoration: BoxDecoration(
          color: value,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
      tween: ColorTween(
        begin:
            Theme.of(context).colors.subtleSolidEmphasis.resolveFrom(context),
        end: Theme.of(context).colors.subtleSolid.resolveFrom(context),
      ),
      duration: const Duration(milliseconds: 500),
      child: child,
    );
  }
}
