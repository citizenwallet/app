import 'dart:async';

import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class NotificationBanner extends StatefulWidget {
  final String title;
  final bool display;
  final void Function() onDismiss;

  const NotificationBanner({
    super.key,
    required this.title,
    this.display = false,
    required this.onDismiss,
  });

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner> {
  bool _display = false;
  double _opacity = 0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _display = widget.display;
  }

  @override
  void didUpdateWidget(NotificationBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.display != oldWidget.display) {
      if (widget.display) {
        show();
      } else {
        hide();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  void show() async {
    setState(() {
      _display = true;
    });

    await delay(const Duration(milliseconds: 50));

    HapticFeedback.heavyImpact();

    setState(() {
      _opacity = 1;
    });

    hideLater();
  }

  void hideLater() {
    _timer?.cancel();

    _timer = Timer(const Duration(seconds: 5), () {
      widget.onDismiss();
    });
  }

  void hide() async {
    setState(() {
      _opacity = 0;
    });

    await delay(const Duration(milliseconds: 250));

    HapticFeedback.lightImpact();

    setState(() {
      _display = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_display) {
      return const SizedBox();
    }

    final safeTopPadding = MediaQuery.of(context).padding.top;
    final title = widget.title;

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 250),
      child: Container(
        height: 30 + safeTopPadding,
        padding: EdgeInsets.fromLTRB(0, safeTopPadding, 0, 5),
        decoration: BoxDecoration(
          color: ThemeColors.surfacePrimary.resolveFrom(context),
          border: Border(
            bottom: BorderSide(
              width: 1,
              color: ThemeColors.uiBackgroundAlt.darkColor,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.text,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              onPressed: widget.onDismiss,
              minSize: 20,
              child: const Icon(
                CupertinoIcons.clear,
                color: ThemeColors.text,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
