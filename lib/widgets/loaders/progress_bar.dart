import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:simple_animations/simple_animations.dart';

class ProgressBar extends StatelessWidget {
  final double value;
  final double? height;
  final double width;
  final Color? color;
  final Color? backgroundColor;
  final double borderRadius;
  final Widget? child;

  const ProgressBar(
    this.value, {
    Key? key,
    this.height = 20,
    this.width = 200,
    this.color,
    this.backgroundColor,
    this.borderRadius = 10,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = value * width;

    return Stack(
      children: [
        Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: ThemeColors.uiBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
        MirrorAnimationBuilder<Color?>(
          builder: (context, value, child) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: height,
            width: clampDouble(progress, 0, width),
            decoration: BoxDecoration(
              color: value,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child,
          ),
          tween: ColorTween(
            begin: ThemeColors.surfacePrimary.resolveFrom(context),
            end: ThemeColors.primary.resolveFrom(context),
          ),
          duration: const Duration(milliseconds: 750),
        ),
      ],
    );
  }
}
