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

class WalletActions extends StatelessWidget {
  final ScrollController controller = ScrollController();

  final double shrink;
  final bool refreshing;

  final void Function()? handleSendModal;
  final void Function()? handleReceive;
  final void Function(String url)? handlePlugin;
  final void Function()? handleCards;
  final void Function()? handleVouchers;

  WalletActions({
    super.key,
    this.shrink = 0,
    this.refreshing = false,
    this.handleSendModal,
    this.handleReceive,
    this.handlePlugin,
    this.handleCards,
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
    final coinNameSize = progressiveClamp(10, 22, shrink);

    final buttonOffset =
        (1 - shrink) < 0.6 ? 90.0 : progressiveClamp(90, 110, shrink);

    final buttonSize =
        (1 - shrink) < 0.6 ? 60.0 : progressiveClamp(50, 80, shrink);
    final buttonIconSize =
        (1 - shrink) < 0.6 ? 30.0 : progressiveClamp(18, 40, shrink);
    final buttonFontSize =
        (1 - shrink) < 0.6 ? 12.0 : progressiveClamp(10, 14, shrink);

    return Stack(
      children: [
        SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
              border: Border(
                bottom: BorderSide(
                  color: ThemeColors.subtle.resolveFrom(context),
                ),
              ),
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
                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          width: width,
          bottom: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  height: buttonSize + 10,
                  child: ListView(
                    controller: controller,
                    physics:
                        const ScrollPhysics(parent: BouncingScrollPhysics()),
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
                          onPressed: blockSending ? () => () : handleSendModal,
                          borderRadius: BorderRadius.circular(
                              progressiveClamp(14, 20, shrink)),
                          color:
                              ThemeColors.surfacePrimary.resolveFrom(context),
                          child: SizedBox(
                            height: buttonSize,
                            width: buttonSize,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.arrow_up,
                                  size: buttonIconSize,
                                  color: blockSending
                                      ? ThemeColors.subtleEmphasis
                                      : ThemeColors.black,
                                ),
                                Text(
                                  sendLoading ? 'Sending' : 'Send',
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
                      if (wallet?.locked == false) const SizedBox(width: 40),
                      if ((!loading || !firstLoad) && handleReceive != null)
                        CupertinoButton(
                          padding: const EdgeInsets.all(5),
                          onPressed: sendLoading ? () => () : handleReceive,
                          borderRadius: BorderRadius.circular(
                              progressiveClamp(14, 20, shrink)),
                          color:
                              ThemeColors.surfacePrimary.resolveFrom(context),
                          child: SizedBox(
                            height: buttonSize,
                            width: buttonSize,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.arrow_down,
                                  size: buttonIconSize,
                                  color: sendLoading
                                      ? ThemeColors.subtleEmphasis
                                      : ThemeColors.black,
                                ),
                                Text(
                                  'Receive',
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
                          onPressed: sendLoading ? () => () : handleVouchers,
                          borderRadius: BorderRadius.circular(
                              progressiveClamp(14, 20, shrink)),
                          color: ThemeColors.background.resolveFrom(context),
                          child: SizedBox(
                            height: buttonSize,
                            width: buttonSize,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.ticket,
                                  size: buttonIconSize,
                                  color: sendLoading
                                      ? ThemeColors.subtleEmphasis
                                      : ThemeColors.text.resolveFrom(context),
                                ),
                                Text(
                                  'Vouchers',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: sendLoading
                                        ? ThemeColors.subtleEmphasis
                                        : ThemeColors.text.resolveFrom(context),
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
                                      : () => handlePlugin!(plugin.url),
                                  borderRadius: BorderRadius.circular(
                                      progressiveClamp(14, 20, shrink)),
                                  color: ThemeColors.background
                                      .resolveFrom(context),
                                  child: SizedBox(
                                    height: buttonSize,
                                    width: buttonSize,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SvgPicture.network(
                                          plugin.icon,
                                          semanticsLabel: '${plugin.name} icon',
                                          height: buttonIconSize,
                                          width: buttonIconSize,
                                          placeholderBuilder: (_) => Icon(
                                            CupertinoIcons.arrow_down,
                                            size: buttonIconSize,
                                            color: sendLoading
                                                ? ThemeColors.subtleEmphasis
                                                : ThemeColors.black,
                                          ),
                                        ),
                                        Text(
                                          plugin.name,
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
                              ),
                            )
                            .toList()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          width: width,
          bottom: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: buttonSize + 10,
                width: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[
                      ThemeColors.uiBackgroundAltTransparent50
                          .resolveFrom(context),
                      ThemeColors.uiBackgroundAltTransparent
                          .resolveFrom(context),
                    ], // Gradient from https://learnui.design/tools/gradient-generator.html
                    tileMode: TileMode.mirror,
                  ),
                ),
              ),
              Container(
                height: buttonSize + 10,
                width: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: <Color>[
                      ThemeColors.uiBackgroundAltTransparent50
                          .resolveFrom(context),
                      ThemeColors.uiBackgroundAltTransparent
                          .resolveFrom(context),
                    ], // Gradient from https://learnui.design/tools/gradient-generator.html
                    tileMode: TileMode.mirror,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
