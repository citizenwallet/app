import 'dart:async';

import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class OfflineBanner extends StatefulWidget {
  final String communityUrl;
  final bool display;
  final bool loading;

  const OfflineBanner({
    super.key,
    required this.communityUrl,
    this.display = false,
    this.loading = false,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _display = false;
  double _opacity = 0;

  Timer? _showTimer;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    _display = widget.display;
    _opacity = widget.display ? 1 : 0;
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
    _showTimer?.cancel();
    _hideTimer?.cancel();

    super.dispose();
  }

  void show() async {
    setState(() {
      _display = true;
    });

    _hideTimer?.cancel();
    _showTimer = Timer(const Duration(milliseconds: 50), () {
      HapticFeedback.heavyImpact();

      setState(() {
        _opacity = 1;
      });
    });
  }

  void hide() async {
    setState(() {
      _opacity = 0;
    });

    _showTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 250), () {
      HapticFeedback.lightImpact();

      setState(() {
        _display = false;
      });
    });
  }

  void handleCommunityInfo() {
    final Uri uri = Uri.parse(widget.communityUrl);

    launchUrl(uri, mode: LaunchMode.inAppWebView);
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 45 + safeTopPadding,
        padding: EdgeInsets.fromLTRB(0, safeTopPadding, 0, 0),
        decoration: BoxDecoration(
          color: widget.loading
              ? Theme.of(context).colors.primary.resolveFrom(context)
              : Theme.of(context).colors.danger.resolveFrom(context),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
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
                        widget.loading
                            ? '${AppLocalizations.of(context)!.connecting}...'
                            : AppLocalizations.of(context)!
                                .communityCurrentlyOffline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context).colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!widget.loading)
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          onPressed: handleCommunityInfo,
                          minSize: 20,
                          child: Icon(
                            CupertinoIcons.info,
                            color: Theme.of(context).colors.white,
                          ),
                        )
                      else
                        const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        ),
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
