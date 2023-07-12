import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:simple_animations/simple_animations.dart';

class PulsingContainer extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const PulsingContainer({
    super.key,
    this.height = 24,
    this.width = 24,
    this.borderRadius = 5,
  });

  @override
  Widget build(BuildContext context) {
    return MirrorAnimationBuilder<Color?>(
      builder: (context, value, child) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: value,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      tween: ColorTween(
        begin: ThemeColors.subtleEmphasis.resolveFrom(context),
        end: ThemeColors.subtle.resolveFrom(context),
      ),
      duration: const Duration(milliseconds: 500),
    );
  }
}
