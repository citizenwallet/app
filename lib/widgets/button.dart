import 'package:flutter/cupertino.dart';

class Button extends StatelessWidget {
  final String label;
  final double minWidth;
  final double maxWidth;
  final void Function()? onPressed;
  final Color? color;
  final Color? labelColor;
  final Widget? prefix;
  final Widget? suffix;

  const Button({
    super.key,
    this.onPressed,
    this.label = '',
    this.minWidth = 200,
    this.maxWidth = 200,
    this.color = CupertinoColors.activeBlue,
    this.labelColor,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      color: color,
      onPressed: onPressed,
      padding: const EdgeInsets.all(0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth,
          maxWidth: maxWidth,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (prefix != null) prefix!,
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                color: labelColor ?? CupertinoColors.white,
              ),
            ),
            if (suffix != null) suffix!,
          ],
        ),
      ),
    );
  }
}
