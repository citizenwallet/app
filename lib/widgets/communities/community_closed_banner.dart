import 'dart:async';

import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityClosedBanner extends StatefulWidget {
  final String communityUrl;
  final bool display;

  const CommunityClosedBanner({
    super.key,
    required this.communityUrl,
    this.display = false,
  });

  @override
  State<CommunityClosedBanner> createState() => _CommunityClosedBannerState();
}

class _CommunityClosedBannerState extends State<CommunityClosedBanner> {
  bool _display = false;
  double _opacity = 0;
  double _slideOffset = 100;

  Timer? _showTimer;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    _display = widget.display;
    _opacity = widget.display ? 1 : 0;
    _slideOffset = widget.display ? 0 : 100;
  }

  @override
  void didUpdateWidget(CommunityClosedBanner oldWidget) {
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
        _slideOffset = 0;
      });
    });
  }

  void hide() async {
    setState(() {
      _opacity = 0;
      _slideOffset = 100;
    });

    _showTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 400), () {
      HapticFeedback.lightImpact();

      setState(() {
        _display = false;
      });
    });
  }

  void handleLearnMore() {
    final Uri uri = Uri.parse(widget.communityUrl);
    launchUrl(uri, mode: LaunchMode.inAppWebView);
  }

  @override
  Widget build(BuildContext context) {
    if (!_display) {
      return const SizedBox();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final safeBottomPadding = MediaQuery.of(context).padding.bottom;

    // Calculate height to cover from bottom to just below balance area
    // Leaving approximately 300-350px from top for profile/balance visibility
    final bannerHeight = screenHeight - 300;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 400),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _slideOffset, 0),
          height: bannerHeight,
          padding: EdgeInsets.fromLTRB(20, 40, 20, safeBottomPadding + 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F0), // Pearl white
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.info_circle_fill,
                  size: 60,
                  color: Theme.of(context).colors.primary.resolveFrom(context),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.communityClosed,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    AppLocalizations.of(context)!.communityClosedDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).colors.black.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (widget.communityUrl.isNotEmpty)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    color:
                        Theme.of(context).colors.primary.resolveFrom(context),
                    borderRadius: BorderRadius.circular(25),
                    onPressed: handleLearnMore,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.learnMore,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          CupertinoIcons.arrow_right_circle_fill,
                          color: Theme.of(context).colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
