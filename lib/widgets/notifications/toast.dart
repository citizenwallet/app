import 'dart:async';

import 'package:citizenwallet/state/notifications/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class Toast extends StatefulWidget {
  final String title;
  final ToastType? display;
  final void Function() onDismiss;

  const Toast({
    super.key,
    required this.title,
    this.display,
    required this.onDismiss,
  });

  @override
  State<Toast> createState() => _ToastState();
}

class _ToastState extends State<Toast> {
  ToastType? _display;
  double _opacity = 0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _display = widget.display;
  }

  @override
  void didUpdateWidget(Toast oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.display != oldWidget.display) {
      if (widget.display != null) {
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
      _display = widget.display;
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
      _display = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_display == null) {
      return const SizedBox();
    }

    final safeBottomPadding = MediaQuery.of(context).padding.bottom;
    final title = widget.title;

    final color = _display == ToastType.error
        ? Theme.of(context).colors.danger.resolveFrom(context)
        : Theme.of(context).colors.success.resolveFrom(context);

    return Positioned(
      bottom: safeBottomPadding + 20,
      left: 0,
      width: MediaQuery.of(context).size.width,
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 250),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 300,
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.9),
                border: Border(
                  bottom: BorderSide(
                    width: 2,
                    color: color.withOpacity(0.5),
                  ),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Theme.of(context)
                                .colors
                                .white
                                .resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    onPressed: widget.onDismiss,
                    minSize: 20,
                    child: Icon(
                      CupertinoIcons.clear,
                      color:
                          Theme.of(context).colors.white.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
