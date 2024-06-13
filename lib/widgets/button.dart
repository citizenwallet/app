import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter/cupertino.dart';

class Button extends StatelessWidget {
  final String text;
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
    this.text = '',
    this.minWidth = 200,
    this.maxWidth = 200,
    this.color,
    this.labelColor,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      color:
          color ?? Theme.of(context).colors.surfacePrimary.resolveFrom(context),
      borderRadius: BorderRadius.circular(minWidth / 2),
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth,
          maxWidth: maxWidth,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (prefix != null) prefix!,
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: labelColor ?? CupertinoColors.black,
                ),
              ),
            ),
            if (suffix != null) suffix!,
          ],
        ),
      ),
    );
  }
}
