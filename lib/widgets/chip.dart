import 'dart:async';

import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class Chip extends StatefulWidget {
  final Color color;
  final Color textColor;
  final String text;
  final Widget? suffix;
  final double maxWidth;
  final double borderRadius;
  final double fontSize;

  final void Function()? onTap;

  const Chip(
    this.text, {
    super.key,
    this.color = ThemeColors.surfacePrimary,
    this.textColor = CupertinoColors.black,
    this.suffix,
    this.maxWidth = 300,
    this.borderRadius = 15,
    this.onTap,
    this.fontSize = 18,
  });

  @override
  ChipState createState() => ChipState();
}

class ChipState extends State<Chip> {
  bool _tapped = false;

  Timer? _timer;

  void handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();

      HapticFeedback.heavyImpact();

      setState(() {
        _tapped = true;
      });

      _timer = Timer(const Duration(milliseconds: 1000), () {
        setState(() {
          _tapped = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.onTap != null
              ? Border.all(
                  color: _tapped
                      ? ThemeColors.primary.resolveFrom(context)
                      : widget.color,
                  width: 1,
                )
              : null,
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
                widget.text,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.normal,
                  color: widget.textColor,
                ),
              ),
            ),
            if (widget.suffix != null) ...[
              const SizedBox(width: 5),
              widget.suffix!,
            ],
          ],
        ),
      ),
    );
  }
}
