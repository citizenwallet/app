import 'dart:math' as math;
import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';

class ProgressCircle extends StatelessWidget {
  final double progress;
  final double size;

  const ProgressCircle({
    super.key,
    required this.progress,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MyPainter(
        context,
        progress: progress,
      ),
      size: Size(size, size),
    );
  }
}

// This is the Painter class
class MyPainter extends CustomPainter {
  final BuildContext context;
  final double progress;

  MyPainter(this.context, {this.progress = 0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = ThemeColors.surfaceSubtle.resolveFrom(context);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.height / 2, size.width / 2),
        height: size.height,
        width: size.width,
      ),
      math.pi * 1.5,
      (math.pi / 180) * (360 * progress),
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
