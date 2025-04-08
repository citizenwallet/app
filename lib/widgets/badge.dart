import 'package:flutter/cupertino.dart';

class Badge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color iconColor;
  final Color color;

  const Badge({
    super.key,
    required this.icon,
    this.size = 20,
    this.color = CupertinoColors.activeBlue,
    this.iconColor = CupertinoColors.white,
  });

  @override
  Widget build(BuildContext context) {
    final dimensions = size * 1.5;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(
          Radius.circular(dimensions),
        ),
      ),
      height: dimensions,
      width: dimensions,
      child: Center(
        child: Icon(
          icon,
          size: size,
          color: iconColor,
        ),
      ),
    );
  }
}
