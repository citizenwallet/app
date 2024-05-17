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
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WalletActions extends StatelessWidget {
  final ScrollController controller = ScrollController();

  final double shrink;
  final bool refreshing;

  final void Function()? handleSendModal;
  final void Function()? handleReceive;
  final void Function(PluginConfig pluginConfig)? handlePlugin;
  final void Function()? handleCards;
  final void Function()? handleMint;
  final void Function()? handleVouchers;

  WalletActions({
    super.key,
    this.shrink = 0,
    this.refreshing = false,
    this.handleSendModal,
    this.handleReceive,
    this.handlePlugin,
    this.handleCards,
    this.handleMint,
    this.handleVouchers,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final loading = context.select((WalletState state) => state.loading);
    final firstLoad = context.select((WalletState state) => state.firstLoad);
    final wallet = context.select((WalletState state) => state.wallet);

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
        handleSendModal != null;

    final isIncreasing = newBalance > balance;

    final coinSize = progressiveClamp(2, 80, shrink);
    final coinNameSize = progressiveClamp(10, 20, shrink);

    final buttonOffset =
        (1 - shrink) < 0.6 ? 90.0 : progressiveClamp(90, 110, shrink);

    final buttonSize =
        (1 - shrink) < 0.6 ? 60.0 : progressiveClamp(40, 80, shrink);
    final buttonIconSize =
        (1 - shrink) < 0.6 ? 30.0 : progressiveClamp(18, 40, shrink);
    final buttonFontSize =
        (1 - shrink) < 0.6 ? 12.0 : progressiveClamp(10, 14, shrink);

    return Stack(
      children: [
        SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 60,
                ),
                if ((1 - shrink) > 0.7 && wallet != null)
                  CoinSpinner(
                    key: Key('${wallet.alias}-spinner'),
                    size: coinSize,
                    logo: wallet.currencyLogo,
                    spin: refreshing || hasPending,
                  ),
                if ((1 - shrink) > 0.8)
                  const SizedBox(
                    height: 10,
                  ),
                if ((1 - shrink) > 0.8)
                  Text(
                    wallet?.currencyName ?? 'Token',
                    style: TextStyle(
                      fontSize: coinNameSize,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.subtleText.resolveFrom(context),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if ((1 - shrink) < 0.7 && wallet != null) ...[
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
                                  : progressiveClamp(12, 48, shrink),
                              fontWeight: FontWeight.bold,
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
                              0,
                            ),
                            child: Text(
                              wallet?.symbol ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: (1 - shrink) < 0.6
                                    ? 18
                                    : progressiveClamp(8, 18, shrink),
                                fontWeight: FontWeight.bold,
                                color: ThemeColors.text.resolveFrom(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: buttonSize + 10,
                        child: ListView(
                          controller: controller,
                          physics: const ScrollPhysics(
                              parent: BouncingScrollPhysics()),
                          scrollDirection: Axis.horizontal,
                          children: [
                            SizedBox(
                              width: (width / 2) - buttonOffset,
                            ),
                            if (wallet?.locked == false &&
                                (!loading || !firstLoad) &&
                                handleSendModal != null)
                              CupertinoButton(
                                padding: const EdgeInsets.all(5),
                                onPressed:
                                    blockSending ? () => () : handleSendModal,
                                borderRadius: BorderRadius.circular(
                                    progressiveClamp(14, 20, shrink)),
                                color: ThemeColors.surfacePrimary
                                    .resolveFrom(context),
                                child: SizedBox(
                                  height: buttonSize,
                                  width: buttonSize,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.arrow_up,
                                        size: buttonIconSize,
                                        color: blockSending
                                            ? ThemeColors.subtleEmphasis
                                            : ThemeColors.black,
                                      ),
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
                                ),
                              ),
                            if (wallet?.locked == false)
                              const SizedBox(width: 40),
                            if ((!loading || !firstLoad) &&
                                handleReceive != null)
                              CupertinoButton(
                                padding: const EdgeInsets.all(5),
                                onPressed:
                                    sendLoading ? () => () : handleReceive,
                                borderRadius: BorderRadius.circular(
                                    progressiveClamp(14, 20, shrink)),
                                color: ThemeColors.surfacePrimary
                                    .resolveFrom(context),
                                child: SizedBox(
                                  height: buttonSize,
                                  width: buttonSize,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.arrow_down,
                                        size: buttonIconSize,
                                        color: sendLoading
                                            ? ThemeColors.subtleEmphasis
                                            : ThemeColors.black,
                                      ),
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
                                ),
                              ),
                            if (!kIsWeb &&
                                wallet?.locked == false &&
                                wallet?.minter == true)
                              const SizedBox(width: 40),
                            if (!kIsWeb &&
                                wallet?.locked == false &&
                                wallet?.minter == true)
                              CupertinoButton(
                                padding: const EdgeInsets.all(5),
                                onPressed: sendLoading ? () => () : handleMint,
                                borderRadius: BorderRadius.circular(
                                    progressiveClamp(14, 20, shrink)),
                                color:
                                    ThemeColors.background.resolveFrom(context),
                                child: SizedBox(
                                  height: buttonSize,
                                  width: buttonSize,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.hammer,
                                        size: buttonIconSize,
                                        color: sendLoading
                                            ? ThemeColors.subtleEmphasis
                                            : ThemeColors.text
                                                .resolveFrom(context),
                                      ),
                                      Text(
                                        AppLocalizations.of(context)!.mint,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: sendLoading
                                              ? ThemeColors.subtleEmphasis
                                              : ThemeColors.text
                                                  .resolveFrom(context),
                                          fontSize: buttonFontSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (!kIsWeb && wallet?.locked == false)
                              const SizedBox(width: 40),
                            // if (!kIsWeb &&
                            //     wallet?.locked == false &&
                            //     (!loading || !firstLoad) &&
                            //     handleSendModal != null &&
                            //     handleCards != null)
                            //   CupertinoButton(
                            //     padding: const EdgeInsets.all(5),
                            //     onPressed: sendLoading ? () => () : handleCards,
                            //     borderRadius: BorderRadius.circular(
                            //         progressiveClamp(14, 20, shrink)),
                            //     color: ThemeColors.background.resolveFrom(context),
                            //     child: SizedBox(
                            //       height: buttonSize,
                            //       width: buttonSize,
                            //       child: Column(
                            //         mainAxisAlignment: MainAxisAlignment.center,
                            //         crossAxisAlignment: CrossAxisAlignment.center,
                            //         children: [
                            //           Icon(
                            //             CupertinoIcons.creditcard,
                            //             size: buttonIconSize,
                            //             color: sendLoading
                            //                 ? ThemeColors.subtleEmphasis
                            //                 : ThemeColors.text.resolveFrom(context),
                            //           ),
                            //           const SizedBox(width: 10),
                            //           Text(
                            //             'Cards',
                            //             style: TextStyle(
                            //               fontWeight: FontWeight.bold,
                            //               color: sendLoading
                            //                   ? ThemeColors.subtleEmphasis
                            //                   : ThemeColors.text.resolveFrom(context),
                            //               fontSize: buttonFontSize,
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ),
                            // if (wallet?.locked == false) const SizedBox(width: 40),
                            if (showVouchers)
                              CupertinoButton(
                                padding: const EdgeInsets.all(5),
                                onPressed:
                                    sendLoading ? () => () : handleVouchers,
                                borderRadius: BorderRadius.circular(
                                    progressiveClamp(14, 20, shrink)),
                                color:
                                    ThemeColors.background.resolveFrom(context),
                                child: SizedBox(
                                  height: buttonSize,
                                  width: buttonSize,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.ticket,
                                        size: buttonIconSize,
                                        color: sendLoading
                                            ? ThemeColors.subtleEmphasis
                                            : ThemeColors.text
                                                .resolveFrom(context),
                                      ),
                                      Text(
                                        AppLocalizations.of(context)!.vouchers,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: sendLoading
                                              ? ThemeColors.subtleEmphasis
                                              : ThemeColors.text
                                                  .resolveFrom(context),
                                          fontSize: buttonFontSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (showVouchers) const SizedBox(width: 40),
                            if ((!loading || !firstLoad) &&
                                handlePlugin != null &&
                                wallet != null)
                              ...(wallet.plugins
                                  .map(
                                    (plugin) => Container(
                                      margin: const EdgeInsets.only(right: 40),
                                      child: CupertinoButton(
                                        padding: const EdgeInsets.all(5),
                                        onPressed: sendLoading
                                            ? () => ()
                                            : () => handlePlugin!(plugin),
                                        borderRadius: BorderRadius.circular(
                                            progressiveClamp(14, 20, shrink)),
                                        color: ThemeColors.background
                                            .resolveFrom(context),
                                        child: Container(
                                          height: buttonSize,
                                          width: buttonSize,
                                          padding: const EdgeInsets.all(5),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SvgPicture.network(
                                                plugin.icon,
                                                semanticsLabel:
                                                    '${plugin.name} icon',
                                                height: buttonIconSize,
                                                width: buttonIconSize,
                                                placeholderBuilder: (_) => Icon(
                                                  CupertinoIcons.arrow_down,
                                                  size: buttonIconSize,
                                                  color: sendLoading
                                                      ? ThemeColors
                                                          .subtleEmphasis
                                                      : ThemeColors.black,
                                                ),
                                              ),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  plugin.name,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: sendLoading
                                                        ? ThemeColors
                                                            .subtleEmphasis
                                                        : ThemeColors.text
                                                            .resolveFrom(
                                                                context),
                                                    fontSize: buttonFontSize,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList()),
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
      ],
    );
  }
}
