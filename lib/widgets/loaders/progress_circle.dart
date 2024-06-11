import 'dart:math' as math;
import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';

class ProgressCircle extends StatefulWidget {
  final double size;
  final double progress;
  final Color? color;
  final Color? trackColor;
  final Widget? successChild;

  const ProgressCircle({
    super.key,
    this.size = 50,
    required this.progress,
    this.color,
    this.trackColor,
    this.successChild,
  });

  @override
  State<ProgressCircle> createState() => _ProgressCircleState();
}

class _ProgressCircleState extends State<ProgressCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // Adjust duration as needed
      vsync: this,
    );

    _animation =
        Tween<double>(begin: 0, end: widget.progress).animate(_controller)
          ..addListener(() {
            setState(() {});
          });

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ProgressCircle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.progress != oldWidget.progress) {
      _animation = Tween<double>(begin: _animation.value, end: widget.progress)
          .animate(_controller);
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          painter: MyPainter(
            context,
            progress: _animation.value,
            color: widget.color,
            trackColor: widget.trackColor,
          ),
          size: Size(
            widget.size,
            widget.size,
          ),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _animation.value == 1 ? 1 : 0,
          child: widget.successChild ?? const SizedBox(),
        ),
      ],
    );
  }
}

// This is the Painter class
class MyPainter extends CustomPainter {
  final BuildContext context;
  final double progress;
  final Color? color;
  final Color? trackColor;

  MyPainter(
    this.context, {
    this.progress = 0,
    this.color,
    this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = trackColor ?? ThemeColors.subtle.resolveFrom(context)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw the grey outline
    canvas.drawCircle(center, radius, paint);

    // Change the color and draw the filled part
    paint.color = color ?? ThemeColors.primary.resolveFrom(context);
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
