import 'dart:async';

import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter/cupertino.dart';

class SecureChip extends StatefulWidget {
  final Color color;
  final Color textColor;
  final String text;
  final Widget? suffix;
  final double maxWidth;
  final double borderRadius;

  const SecureChip(
    this.text, {
    super.key,
    this.color = CupertinoColors.activeBlue,
    this.textColor = CupertinoColors.white,
    this.suffix,
    this.maxWidth = 150,
    this.borderRadius = 15,
  });

  @override
  SecureChipState createState() => SecureChipState();
}

class SecureChipState extends State<SecureChip> {
  bool _revealed = false;

  Timer? _timer;

  void handleToggle() {
    setState(() {
      _revealed = !_revealed;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _revealed
                ? Theme.of(context).colors.secondary.resolveFrom(context)
                : widget.color,
            width: 1,
          ),
          color: widget.color,
        ),
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
        ),
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                _revealed
                    ? widget.text
                    : widget.text.replaceAll(RegExp(r'.'), '-'),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  letterSpacing: 4,
                  fontWeight: FontWeight.normal,
                  color: widget.textColor,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              _revealed
                  ? CupertinoIcons.eye_fill
                  : CupertinoIcons.eye_slash_fill,
              size: 14,
              color: Theme.of(context).colors.touchable.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }
}
