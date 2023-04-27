import 'package:flutter/cupertino.dart';

class Chip extends StatelessWidget {
  final Color color;
  final Color textColor;
  final String text;
  final Widget? suffix;

  const Chip(
    this.text, {
    super.key,
    this.color = CupertinoColors.activeBlue,
    this.textColor = CupertinoColors.white,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: color,
      ),
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Row(
        children: [
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: textColor,
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 5),
            suffix!,
          ],
        ],
      ),
    );
  }
}
