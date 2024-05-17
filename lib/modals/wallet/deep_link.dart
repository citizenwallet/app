import 'dart:async';

import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/deep_link/logic.dart';
import 'package:citizenwallet/state/deep_link/state.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DeepLinkModal extends StatefulWidget {
  final WalletService wallet;

  final String deepLink;
  final String deepLinkParams;

  const DeepLinkModal({
    super.key,
    required this.wallet,
    required this.deepLink,
    required this.deepLinkParams,
  });

  @override
  DeepLinkModalState createState() => DeepLinkModalState();
}

class DeepLinkModalState extends State<DeepLinkModal> {
  late DeepLinkLogic _logic;

  String? customDeepLinkInterface;

  @override
  void initState() {
    super.initState();

    _logic = DeepLinkLogic(context, widget.wallet);

    // post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      onLoad();
    });
  }

  @override
  void dispose() {
    //

    super.dispose();
  }

  void onLoad() async {
    switch (widget.deepLink) {
      case 'faucet-v1':
        // handle loading of metadata
        customDeepLinkInterface = widget.deepLink;
        _logic.faucetV1Metadata(widget.deepLinkParams);
        break;
      default:
        break;
    }
  }

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    GoRouter.of(context).pop();
  }

  void handleDeepLink() async {
    final navigator = GoRouter.of(context);

    switch (widget.deepLink) {
      case 'faucet-v1':
        await _logic.faucetV1Redeem(widget.deepLinkParams);
        break;
      default:
        break;
    }

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.select((WalletState state) => state.wallet);

    final deepLink = context.select((DeepLinkState state) => state.deepLink);

    final loading = context.select((DeepLinkState state) => state.loading);

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final size = height > width ? width : height;
    final scannerSize = size * 0.88;

    final faucetAmount =
        context.select((DeepLinkState state) => state.faucetAmount);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 0, right: 0, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Header(
                  title: deepLink?.title ??
                      AppLocalizations.of(context)!.invalidlink,
                  actionButton: CupertinoButton(
                    padding: const EdgeInsets.all(5),
                    onPressed: () => handleDismiss(context),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: ThemeColors.touchable.resolveFrom(context),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (wallet != null)
                      switch (customDeepLinkInterface) {
                        'faucet-v1' => Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: ListView(
                              controller: ModalScrollController.of(context),
                              physics: const ScrollPhysics(
                                  parent: BouncingScrollPhysics()),
                              scrollDirection: Axis.vertical,
                              children: [
                                const SizedBox(height: 60),
                                SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: Center(
                                    child: CoinLogo(
                                      size: 160,
                                      logo: wallet.currencyLogo,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 60),
                                Text(
                                  '${fromUnit(faucetAmount, decimals: wallet.decimalDigits)} ${wallet.symbol}',
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        _ => Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: ListView(
                              controller: ModalScrollController.of(context),
                              physics: const ScrollPhysics(
                                  parent: BouncingScrollPhysics()),
                              scrollDirection: Axis.vertical,
                              children: [
                                const SizedBox(height: 60),
                                SizedBox(
                                  height: 240,
                                  width: 240,
                                  child: Center(
                                    child: SvgPicture.asset(
                                      deepLink?.icon ??
                                          'assets/icons/missing.svg',
                                      semanticsLabel: deepLink?.icon != null
                                          ? 'Deep link icon'
                                          : 'Missing icon',
                                      height: 300,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 60),
                                Text(
                                  deepLink?.description ??
                                      AppLocalizations.of(context)!
                                          .unabltohandlelink,
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 20,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                      },
                    Positioned(
                      bottom: 40,
                      child: !loading
                          ? Button(
                              text: deepLink?.action ??
                                  AppLocalizations.of(context)!.dismiss,
                              onPressed: deepLink != null
                                  ? handleDeepLink
                                  : () => handleDismiss(context),
                              minWidth: 200,
                              maxWidth: 200,
                            )
                          : CupertinoActivityIndicator(
                              color: ThemeColors.subtle.resolveFrom(context),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
