import 'package:citizenwallet/screens/wallet/wallet_actions_more.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/ratio.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/wallet/coin_spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WalletActions extends StatelessWidget {
  final ScrollController controller = ScrollController();

  final double shrink;
  final bool refreshing;

  final void Function()? handleSendPush;
  final void Function()? handleReceivePush;
  final void Function(PluginConfig pluginConfig)? handlePlugin;
  final void Function()? handleCards;
  final void Function()? handleMint;
  final void Function()? handleVouchers;

  WalletActions({
    super.key,
    this.shrink = 0,
    this.refreshing = false,
    this.handleSendPush,
    this.handleReceivePush,
    this.handlePlugin,
    this.handleCards,
    this.handleMint,
    this.handleVouchers,
  });

  bool _showAdditionalButtons = false;
  void handleOpenAbout() {
    _showAdditionalButtons = !_showAdditionalButtons;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final loading = context.select((WalletState state) => state.loading);
    final firstLoad = context.select((WalletState state) => state.firstLoad);
    final wallet = context.select((WalletState state) => state.wallet);
    final clickedOnMore =
        context.select((WalletState state) => state.clickedOnMore);

    final blockSending = context.select(selectShouldBlockSending);
    final sendLoading = context.read<WalletState>().transactionSendLoading;

    final hasPending = context.select(selectHasProcessingTransactions);
    final newBalance = context.select(selectWalletBalance);

    final formattedBalance = formatAmount(
      double.parse(fromDoubleUnit(
        '${newBalance > 0 ? newBalance : 0.0}',
        decimals: wallet?.decimalDigits ?? 2,
      )),
      decimalDigits: 2,
    );

    final balance = wallet != null ? double.parse(wallet.balance) : 0.0;

    final showVouchers = !kIsWeb &&
        wallet?.locked == false &&
        (!loading || !firstLoad) &&
        wallet?.doubleBalance != 0.0 &&
        handleSendPush != null;

    final isIncreasing = newBalance > balance;

    final coinSize = progressiveClamp(2, 80, shrink);
    final coinNameSize = progressiveClamp(10, 22, shrink);

    final buttonOffset =
        (1 - shrink) < 0.6 ? 90.0 : progressiveClamp(90, 110, shrink);

    final buttonSize =
        (1 - shrink) < 0.6 ? 60.0 : progressiveClamp(50, 80, shrink);
    final buttonIconSize =
        (1 - shrink) < 0.6 ? 30.0 : progressiveClamp(18, 40, shrink);
    final buttonFontSize =
        (1 - shrink) < 0.6 ? 12.0 : progressiveClamp(10, 14, shrink);

    void handleClick(String value) {
      switch (value) {
        case 'Logout':
          break;
        case 'Settings':
          break;
      }
    }

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            decoration: BoxDecoration(
              color: ThemeColors.background.resolveFrom(context),
              // border: Border(
              //   bottom: BorderSide(
              //     color: ThemeColors.subtle.resolveFrom(context),
              //   ),
              // ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if ((1 - shrink) > 0.6 && wallet != null)
                  CoinSpinner(
                    key: Key('${wallet.alias}-spinner'),
                    size: coinSize,
                    logo: wallet.currencyLogo,
                    spin: refreshing || hasPending,
                  ),
                if ((1 - shrink) > 0.75)
                  const SizedBox(
                    height: 10,
                  ),
                if ((1 - shrink) > 0.75)
                  Text(
                    wallet?.currencyName ?? 'Token',
                    style: TextStyle(
                      fontSize: coinNameSize,
                      fontWeight: FontWeight.normal,
                      color: ThemeColors.text.resolveFrom(context),
                    ),
                  ),
                if ((1 - shrink) == 1)
                  const SizedBox(
                    height: 5,
                  ),
                loading && formattedBalance.isEmpty
                    ? CupertinoActivityIndicator(
                        color: ThemeColors.subtle.resolveFrom(context),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if ((1 - shrink) < 0.6 && wallet != null) ...[
                            CoinLogo(
                              size: 40,
                              logo: wallet.currencyLogo,
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            formattedBalance,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: (1 - shrink) < 0.6
                                  ? 32
                                  : progressiveClamp(12, 40, shrink),
                              fontWeight: FontWeight.normal,
                              color: hasPending
                                  ? isIncreasing
                                      ? ThemeColors.primary.resolveFrom(context)
                                      : ThemeColors.secondary
                                          .resolveFrom(context)
                                  : ThemeColors.text.resolveFrom(context),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              0,
                              0,
                              0,
                              3,
                            ),
                            child: Text(
                              wallet?.symbol ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: (1 - shrink) < 0.6
                                    ? 22
                                    : progressiveClamp(8, 22, shrink),
                                fontWeight: FontWeight.bold,
                                color: ThemeColors.text.resolveFrom(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                Positioned(
                  width: width,
                  bottom: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if ((1 - shrink) < 0.6 && wallet != null) ...[
                        Expanded(
                          child: SizedBox(
                            height: buttonSize + 38,
                            child: ListView(
                              controller: controller,
                              physics: const ScrollPhysics(
                                  parent: BouncingScrollPhysics()),
                              scrollDirection: Axis.horizontal,
                              children: [
                                // SizedBox(
                                //   width: (width / 5) - (buttonOffset / 2),
                                // ),
                                const SizedBox(
                                  width: 20,
                                ),
                                if (wallet?.locked == false &&
                                    (!loading || !firstLoad) &&
                                    handleSendPush != null)
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CupertinoButton(
                                        padding: const EdgeInsets.all(5),
                                        onPressed: blockSending
                                            ? () => ()
                                            : handleSendPush,
                                        borderRadius: BorderRadius.circular(50),
                                        color: ThemeColors.surfacePrimary
                                            .resolveFrom(context),
                                        child: SizedBox(
                                          height: 40,
                                          width: 100,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    sendLoading
                                                        ? AppLocalizations.of(
                                                                context)!
                                                            .sending
                                                        : AppLocalizations.of(
                                                                context)!
                                                            .send,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: blockSending
                                                          ? ThemeColors
                                                              .subtleEmphasis
                                                          : ThemeColors.white,
                                                      fontSize: buttonFontSize,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Icon(
                                                    CupertinoIcons.arrow_up,
                                                    size: 20,
                                                    color: blockSending
                                                        ? ThemeColors
                                                            .subtleEmphasis
                                                        : ThemeColors.white,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (wallet?.locked == false)
                                  const SizedBox(width: 10),
                                if ((!loading || !firstLoad) &&
                                    handleReceivePush != null)
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CupertinoButton(
                                        padding: const EdgeInsets.all(5),
                                        onPressed: blockSending
                                            ? () => ()
                                            : handleSendPush,
                                        borderRadius: BorderRadius.circular(50),
                                        color: ThemeColors.surfacePrimary
                                            .resolveFrom(context),
                                        child: SizedBox(
                                          height: 40,
                                          width: 100,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .receive,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: sendLoading
                                                          ? ThemeColors
                                                              .subtleEmphasis
                                                          : ThemeColors.white,
                                                      fontSize: buttonFontSize,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Icon(
                                                    CupertinoIcons.arrow_down,
                                                    size: 20,
                                                    color: sendLoading
                                                        ? ThemeColors
                                                            .subtleEmphasis
                                                        : ThemeColors.white,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CupertinoButton(
                                      padding: const EdgeInsets.all(5),
                                      onPressed: () {
                                        context
                                            .read<WalletState>()
                                            .setClickedOnMore(); //shanuka
                                      },
                                      borderRadius: BorderRadius.circular(50),
                                      color: ThemeColors.subtleEmphasis
                                          .resolveFrom(context),
                                      child: SizedBox(
                                        height: 40,
                                        width: 100,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  AppLocalizations.of(context)!
                                                      .more,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: ThemeColors
                                                        .surfacePrimary
                                                        .resolveFrom(context),
                                                    fontSize: buttonFontSize,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Icon(
                                                  CupertinoIcons.ellipsis,
                                                  size: 20,
                                                  color: ThemeColors
                                                      .surfacePrimary
                                                      .resolveFrom(context),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      if ((1 - shrink) > 0.6 && wallet != null) ...[
                        Expanded(
                          child: SizedBox(
                            height: buttonSize + 38,
                            child: ListView(
                              controller: controller,
                              physics: const ScrollPhysics(
                                  parent: BouncingScrollPhysics()),
                              scrollDirection: Axis.horizontal,
                              children: [
                                SizedBox(
                                  width: (width / 3) - (buttonOffset / 2),
                                ),
                                if (wallet?.locked == false &&
                                    (!loading || !firstLoad) &&
                                    handleSendPush != null)
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CupertinoButton(
                                        padding: const EdgeInsets.all(5),
                                        onPressed: blockSending
                                            ? () => ()
                                            : handleSendPush,
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        color: ThemeColors.surfacePrimary
                                            .resolveFrom(context),
                                        child: SizedBox(
                                          height: 50,
                                          width: 50,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                CupertinoIcons.arrow_up,
                                                size: 30,
                                                color: blockSending
                                                    ? ThemeColors.subtleEmphasis
                                                    : ThemeColors.white,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 11),
                                      Text(
                                        sendLoading
                                            ? AppLocalizations.of(context)!
                                                .sending
                                            : AppLocalizations.of(context)!
                                                .send,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: blockSending
                                              ? ThemeColors.subtleEmphasis
                                              : ThemeColors.black,
                                          fontSize: buttonFontSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (wallet?.locked == false)
                                  const SizedBox(width: 40),
                                if ((!loading || !firstLoad) &&
                                    handleReceivePush != null)
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CupertinoButton(
                                        padding: const EdgeInsets.all(5),
                                        onPressed: sendLoading
                                            ? () => ()
                                            : handleReceivePush,
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        color: ThemeColors.surfacePrimary
                                            .resolveFrom(context),
                                        child: SizedBox(
                                          height: 50,
                                          width: 50,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                CupertinoIcons.arrow_down,
                                                size: 30,
                                                color: sendLoading
                                                    ? ThemeColors.subtleEmphasis
                                                    : ThemeColors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 11),
                                      Text(
                                        AppLocalizations.of(context)!.receive,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: sendLoading
                                              ? ThemeColors.subtleEmphasis
                                              : ThemeColors.black,
                                          fontSize: buttonFontSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(width: 40),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CupertinoButton(
                                      padding: const EdgeInsets.all(5),
                                      borderRadius: BorderRadius.circular(100),
                                      color: ThemeColors.uiBackground
                                          .resolveFrom(context),
                                      onPressed: () {
                                        context
                                            .read<WalletState>()
                                            .setClickedOnMore(); //shanuka
                                      },
                                      child: SizedBox(
                                        height: 50,
                                        width: 50,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              CupertinoIcons.ellipsis,
                                              size: 50,
                                              color: sendLoading
                                                  ? ThemeColors.subtleEmphasis
                                                  : ThemeColors.surfacePrimary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 11),
                                    Text(
                                      AppLocalizations.of(context)!.more,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: sendLoading
                                            ? ThemeColors.subtleEmphasis
                                            : ThemeColors.black,
                                        fontSize: buttonFontSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 11),
                      ]
                    ],
                  ),
                ),
                Container(
                  color: ThemeColors.black,
                  child: SizedBox(
                    height: clickedOnMore ? 180 : 0,
                    child: WalletActionsMore(
                      shrink: shrink,
                      refreshing: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
