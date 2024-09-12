import 'dart:async';

import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OfflineBanner extends StatefulWidget {
  final bool display;

  const OfflineBanner({
    super.key,
    this.display = false,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _display = false;
  double _opacity = 0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _display = widget.display;
  }

  @override
  void didUpdateWidget(OfflineBanner oldWidget) {
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

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 250),
      child: Container(
        height: 45 + safeTopPadding,
        padding: EdgeInsets.fromLTRB(0, safeTopPadding, 0, 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colors.danger.resolveFrom(context),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20), // Adjust as needed
            bottomRight: Radius.circular(20), // Adjust as needed
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                         AppLocalizations.of(context)!.communityCurrentlyOffline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context).colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        CupertinoIcons.info,
                        color:
                            Theme.of(context).colors.white.resolveFrom(context),
                        size: 18,
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
