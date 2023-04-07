import 'package:flutter/cupertino.dart';

class TextBadge extends StatelessWidget {
  final String text;
  final double size;
  final Color textColor;
  final Color color;

  const TextBadge({
    super.key,
    required this.text,
    this.size = 20,
    this.color = CupertinoColors.activeBlue,
    this.textColor = CupertinoColors.white,
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
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: size,
          ),
        ),
      ),
    );
  }
}
