import 'dart:ui';

import 'package:flutter/cupertino.dart';

class BlurryChild extends StatelessWidget {
  final Widget child;
  final double intensity;

  const BlurryChild({
    Key? key,
    required this.child,
    this.intensity = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        blendMode: BlendMode.srcOver,
        filter: ImageFilter.blur(
          sigmaX: intensity,
          sigmaY: intensity,
        ),
        child: child,
      ),
    );
  }
}
