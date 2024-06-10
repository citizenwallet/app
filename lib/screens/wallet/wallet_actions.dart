import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/ratio.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/wallet/action_button.dart';
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

  final void Function()? handleSendScreen;
  final void Function()? handleReceive;
  final void Function(PluginConfig pluginConfig)? handlePlugin;
  final void Function()? handleCards;
  final void Function()? handleMint;
  final void Function()? handleVouchers;

  WalletActions({
    super.key,
    this.shrink = 0,
    this.refreshing = false,
    this.handleSendScreen,
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
        handleSendScreen != null;

    final isIncreasing = newBalance > balance;

    final coinSize = progressiveClamp(2, 70, shrink);
    final coinNameSize = progressiveClamp(10, 20, shrink);

    final buttonOffset =
        (1 - shrink) < 0.4 ? 20.0 : progressiveClamp(20, 80, shrink);
    final buttonSeparator =
        (1 - shrink) < 0.4 ? 10.0 : progressiveClamp(10, 40, shrink);

    final buttonBarHeight =
        (1 - shrink) < 0.4 ? 60.0 : progressiveClamp(40, 120, shrink);
    final buttonSize =
        (1 - shrink) < 0.4 ? 60.0 : progressiveClamp(40, 80, shrink);
    final buttonIconSize =
        (1 - shrink) < 0.4 ? 30.0 : progressiveClamp(18, 40, shrink);
    final buttonFontSize =
        (1 - shrink) < 0.4 ? 12.0 : progressiveClamp(10, 14, shrink);

    return Stack(
      children: [
        Positioned(
          top: 0,
          bottom: 60,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ThemeColors.uiBackgroundAlt.resolveFrom(context),
                  ThemeColors.uiBackgroundAlt
                      .resolveFrom(context)
                      .withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: ThemeColors.transparent.resolveFrom(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 90,
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
                                    : ThemeColors.secondary.resolveFrom(context)
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
                      height: buttonBarHeight,
                      child: ListView(
                        controller: controller,
                        physics: const ScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        scrollDirection: Axis.horizontal,
                        children: [
                          SizedBox(
                            width: buttonOffset,
                          ),
                          if (wallet?.locked == false &&
                              (!loading || !firstLoad) &&
                              handleSendScreen != null)
                            WalletActionButton(
                              icon: CupertinoIcons.arrow_up,
                              buttonSize: buttonSize,
                              buttonIconSize: buttonIconSize,
                              buttonFontSize: buttonFontSize,
                              shrink: shrink,
                              text: sendLoading
                                  ? AppLocalizations.of(context)!.sending
                                  : AppLocalizations.of(context)!.send,
                              loading: sendLoading,
                              disabled: blockSending,
                              onPressed: handleSendScreen,
                            ),
                          if (wallet?.locked == false)
                            SizedBox(width: buttonSeparator),
                          if ((!loading || !firstLoad) && handleReceive != null)
                            WalletActionButton(
                              icon: CupertinoIcons.arrow_down,
                              buttonSize: buttonSize,
                              buttonIconSize: buttonIconSize,
                              buttonFontSize: buttonFontSize,
                              shrink: shrink,
                              text: AppLocalizations.of(context)!.receive,
                              loading: sendLoading,
                              disabled: sendLoading,
                              onPressed: handleReceive,
                            ),
                          if (!kIsWeb &&
                              wallet?.locked == false &&
                              wallet?.minter == true)
                            SizedBox(width: buttonSeparator),
                          if (!kIsWeb &&
                              wallet?.locked == false &&
                              wallet?.minter == true)
                            WalletActionButton(
                              icon: CupertinoIcons.hammer,
                              buttonSize: buttonSize,
                              buttonIconSize: buttonIconSize,
                              buttonFontSize: buttonFontSize,
                              shrink: shrink,
                              text: AppLocalizations.of(context)!.mint,
                              alt: true,
                              disabled: sendLoading,
                              onPressed: handleMint,
                            ),
                          if (!kIsWeb && wallet?.locked == false)
                            SizedBox(width: buttonSeparator),
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
                            WalletActionButton(
                              icon: CupertinoIcons.ticket,
                              buttonSize: buttonSize,
                              buttonIconSize: buttonIconSize,
                              buttonFontSize: buttonFontSize,
                              shrink: shrink,
                              text: AppLocalizations.of(context)!.vouchers,
                              alt: true,
                              disabled: sendLoading,
                              onPressed: handleVouchers,
                            ),
                          if (showVouchers) SizedBox(width: buttonSeparator),
                          if ((!loading || !firstLoad) &&
                              handlePlugin != null &&
                              wallet != null)
                            ...(wallet.plugins
                                .map(
                                  (plugin) => WalletActionButton(
                                    customIcon: SvgPicture.network(
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
                                    buttonSize: buttonSize,
                                    buttonIconSize: buttonIconSize,
                                    buttonFontSize: buttonFontSize,
                                    margin:
                                        EdgeInsets.only(right: buttonSeparator),
                                    shrink: shrink,
                                    text: plugin.name,
                                    alt: true,
                                    loading: sendLoading,
                                    disabled: sendLoading,
                                    onPressed: () => handlePlugin!(plugin),
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
      ],
    );
  }
}
