import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';

class WebLandingScreen extends StatefulWidget {
  final String? voucher;
  final String? voucherParams;
  final String? alias;
  final String? receiveParams;
  final String? deepLink;
  final String? deepLinkParams;

  const WebLandingScreen({
    super.key,
    this.voucher,
    this.voucherParams,
    this.alias,
    this.receiveParams,
    this.deepLink,
    this.deepLinkParams,
  });

  @override
  WebLandingScreenState createState() => WebLandingScreenState();
}

class WebLandingScreenState extends State<WebLandingScreen>
    with TickerProviderStateMixin {
  late AppLogic _appLogic;

  @override
  void initState() {
    super.initState();

    _appLogic = AppLogic(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here

      onLoad();
    });
  }

  String parseParamsFromWidget() {
    String params = '';
    if (widget.voucher != null && widget.voucherParams != null) {
      params += '&voucher=${widget.voucher}';
      params += '&params=${widget.voucherParams}';
    }

    if (widget.alias != null) {
      params += '&alias=${widget.alias}';
    }

    if (widget.receiveParams != null) {
      params += '&receiveParams=${widget.receiveParams}';
    }

    if (widget.deepLink != null && widget.deepLinkParams != null) {
      params += '&dl=${widget.deepLink}';
      params += '&${widget.deepLink}=${widget.deepLinkParams}';
    }

    return params.replaceFirst('&', '?');
  }

  void onLoad() async {
    final navigator = GoRouter.of(context);

    await delay(const Duration(milliseconds: 0));

    final lastEncodedWallet = await _appLogic.getLastEncodedWallet();

    if (lastEncodedWallet != null) {
      navigator.go('/wallet/$lastEncodedWallet${parseParamsFromWidget()}');
      return;
    }

    final wallet = await _appLogic.createWebWallet();

    if (wallet == null) {
      return;
    }

    navigator.go('/wallet/$wallet${parseParamsFromWidget()}');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor:
          Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
      child: SafeArea(
        child: Flex(
          direction: Axis.vertical,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomScrollView(
                    scrollBehavior: const CupertinoScrollBehavior(),
                    slivers: [
                      SliverFillRemaining(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 300,
                              width: 300,
                              child: Center(
                                child: Lottie.asset(
                                  'assets/lottie/chat.json',
                                  height: 300,
                                  width: 300,
                                  animate: true,
                                  repeat: true,
                                  // controller: _controller,
                                ),
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)!.citizenWallet,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colors
                                    .text
                                    .resolveFrom(context),
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            Text(
                              AppLocalizations.of(context)!
                                  .aWalletForYourCommunity,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colors
                                    .text
                                    .resolveFrom(context),
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 60),
                            CupertinoActivityIndicator(
                              color: Theme.of(context)
                                  .colors
                                  .subtle
                                  .resolveFrom(context),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              AppLocalizations.of(context)!.openingYourWallet,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colors
                                    .text
                                    .resolveFrom(context),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
