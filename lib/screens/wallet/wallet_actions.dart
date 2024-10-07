import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/ratio.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/wallet/action_button.dart';
import 'package:citizenwallet/widgets/wallet/coin_spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WalletActions extends StatefulWidget {
  final double shrink;
  final bool refreshing;

  final void Function()? handleSendScreen;
  final void Function()? handleReceive;
  final void Function(PluginConfig pluginConfig)? handlePlugin; // move
  final void Function()? handleCards;
  final void Function()? handleMint;
  final void Function()? handleVouchers; // move
  final void Function()? handleShowMore;

  const WalletActions({
    super.key,
    this.shrink = 0,
    this.refreshing = false,
    this.handleSendScreen,
    this.handleReceive,
    this.handlePlugin,
    this.handleCards,
    this.handleMint,
    this.handleVouchers,
    this.handleShowMore,
  });

  @override
  State<WalletActions> createState() => _WalletActionsState();
}

class _WalletActionsState extends State<WalletActions> {
  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final loading = context.select((WalletState state) => state.loading);
    final firstLoad = context.select((WalletState state) => state.firstLoad);
    final wallet = context.select((WalletState state) => state.wallet);
    final config = context.select((WalletState state) => state.config);

    final withOfflineBanner = config!.online == false;

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

    final showVouchers =
        context.select(selectShowVouchers) && widget.handleSendScreen != null;

    final showMinter = context.select(selectShowMinter);

    final showPlugins =
        context.select(selectShowPlugins) && widget.handlePlugin != null;

    int pluginsCount = wallet!.plugins.length;
    PluginConfig? onePlugin = pluginsCount < 1 ? null : wallet.plugins[0];

    int actionItemsCount = (showVouchers ? 1 : 0) +
        (showMinter ? 1 : 0) +
        (showPlugins ? pluginsCount : 0);

    final isIncreasing = newBalance > balance;

    final coinSize = progressiveClamp(2, 70, widget.shrink);
    const coinNameSize = 20.0;

    final buttonSeparator = (1 - widget.shrink) < 0.7
        ? 10.0
        : progressiveClamp(10, 40, widget.shrink);

    final buttonBarHeight = (1 - widget.shrink) < 0.7
        ? 60.0
        : progressiveClamp(40, 120, widget.shrink);
    final buttonSize = (1 - widget.shrink) < 0.7 ? 60.0 : 80.0;
    final buttonIconSize = (1 - widget.shrink) < 0.7 ? 20.0 : 40.0;
    final buttonFontSize = (1 - widget.shrink) < 0.7
        ? 12.0
        : progressiveClamp(10, 14, widget.shrink);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 0,
          bottom: withOfflineBanner ? 60 - 20 : 60,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: withOfflineBanner ? 60 - 20 : 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
                  Theme.of(context)
                      .colors
                      .uiBackgroundAlt
                      .resolveFrom(context)
                      .withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        if (wallet != null)
          Positioned(
            top: withOfflineBanner ? 90 + 20 : 90,
            child: Opacity(
              opacity: progressiveClamp(0, 1, widget.shrink * 2.5),
              child: CoinSpinner(
                key: Key('${wallet.alias}-spinner'),
                size: coinSize,
                logo: wallet.currencyLogo,
                spin: widget.refreshing || hasPending,
              ),
            ),
          ),
        Positioned(
          top: withOfflineBanner
              ? progressiveClamp(90 + 20, 170 + 20, widget.shrink)
              : progressiveClamp(90, 170, widget.shrink),
          child: Opacity(
            opacity: progressiveClamp(0, 1, widget.shrink * 2.5),
            child: Text(
              wallet?.currencyName ?? 'Token',
              style: TextStyle(
                fontSize: coinNameSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colors.subtleText.resolveFrom(context),
              ),
            ),
          ),
        ),
        Positioned(
          top: withOfflineBanner
              ? progressiveClamp(90 + 20, 210 + 20, widget.shrink * 2)
              : progressiveClamp(90, 210, widget.shrink * 2),
          child: loading && formattedBalance.isEmpty
              ? CupertinoActivityIndicator(
                  color: Theme.of(context).colors.subtle.resolveFrom(context),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if ((1 - widget.shrink) < 0.7 && wallet != null) ...[
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
                        fontSize: (1 - widget.shrink) < 0.6
                            ? 32
                            : progressiveClamp(12, 48, widget.shrink),
                        fontWeight: FontWeight.bold,
                        color: hasPending
                            ? isIncreasing
                                ? Theme.of(context)
                                    .colors
                                    .primary
                                    .resolveFrom(context)
                                : Theme.of(context)
                                    .colors
                                    .secondary
                                    .resolveFrom(context)
                            : Theme.of(context)
                                .colors
                                .text
                                .resolveFrom(context),
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
                          fontSize: (1 - widget.shrink) < 0.6
                              ? 18
                              : progressiveClamp(8, 18, widget.shrink),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colors
                              .text
                              .resolveFrom(context),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        Positioned(
          top: withOfflineBanner
              ? progressiveClamp(140 + 20, 280 + 20, widget.shrink * 2)
              : progressiveClamp(140, 280, widget.shrink * 2),
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  height: buttonBarHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (wallet!.locked == false &&
                          (!loading || !firstLoad) &&
                          widget.handleSendScreen != null)
                        WalletActionButton(
                          key: const Key('send_action_button'),
                          icon: CupertinoIcons.arrow_up,
                          buttonSize: buttonSize,
                          buttonIconSize: buttonIconSize,
                          buttonFontSize: buttonFontSize,
                          shrink: widget.shrink,
                          text: sendLoading
                              ? AppLocalizations.of(context)!.sending
                              : AppLocalizations.of(context)!.send,
                          loading: sendLoading,
                          disabled: blockSending,
                          onPressed: widget.handleSendScreen,
                        ),
                      if ((!loading || !firstLoad) &&
                          widget.handleReceive != null) ...[
                        SizedBox(
                          width: buttonSeparator,
                        ),
                        WalletActionButton(
                          key: const Key('receive_action_button'),
                          icon: CupertinoIcons.arrow_down,
                          buttonSize: buttonSize,
                          buttonIconSize: buttonIconSize,
                          buttonFontSize: buttonFontSize,
                          shrink: widget.shrink,
                          text: AppLocalizations.of(context)!.receive,
                          loading: sendLoading,
                          disabled: sendLoading,
                          onPressed: widget.handleReceive,
                        ),
                      ],
                      if (actionItemsCount > 0)
                        SizedBox(
                          width: buttonSeparator,
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                        width: actionItemsCount > 1 ? buttonSize : 0,
                        child: actionItemsCount > 1
                            ? WalletActionButton(
                                key: const Key('more_action_button'),
                                icon: CupertinoIcons.ellipsis,
                                buttonSize: buttonSize,
                                buttonIconSize: buttonIconSize,
                                buttonFontSize: buttonFontSize,
                                shrink: widget.shrink,
                                text: AppLocalizations.of(context)!.more,
                                loading: sendLoading,
                                disabled: sendLoading,
                                onPressed: widget.handleShowMore,
                                alt: true,
                              )
                            : const SizedBox.shrink(),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                        width: showVouchers && actionItemsCount == 1
                            ? buttonSize
                            : 0,
                        child: showVouchers && actionItemsCount == 1
                            ? WalletActionButton(
                                key: const Key('vouchers_action_button'),
                                icon: CupertinoIcons.ticket,
                                buttonSize: buttonSize,
                                buttonIconSize: buttonIconSize,
                                buttonFontSize: buttonFontSize,
                                shrink: widget.shrink,
                                text: AppLocalizations.of(context)!.vouchers,
                                alt: true,
                                disabled: sendLoading,
                                onPressed: widget.handleVouchers,
                              )
                            : const SizedBox.shrink(),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                        width: showMinter && actionItemsCount == 1
                            ? buttonSize
                            : 0,
                        child: showMinter && actionItemsCount == 1
                            ? WalletActionButton(
                                key: const Key('minter_action_button'),
                                icon: CupertinoIcons.hammer,
                                buttonSize: buttonSize,
                                buttonIconSize: buttonIconSize,
                                buttonFontSize: buttonFontSize,
                                shrink: widget.shrink,
                                text: AppLocalizations.of(context)!.mint,
                                alt: true,
                                disabled: sendLoading,
                                onPressed: widget.handleMint,
                              )
                            : const SizedBox.shrink(),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                        width: showPlugins &&
                                pluginsCount == 1 &&
                                actionItemsCount == 1
                            ? buttonSize
                            : 0,
                        child: showPlugins &&
                                pluginsCount == 1 &&
                                actionItemsCount == 1
                            ? WalletActionButton(
                                key: const Key('plugin_action_button'),
                                customIcon: SvgPicture.network(
                                  onePlugin!.icon,
                                  semanticsLabel: '${onePlugin.name} icon',
                                  height: buttonIconSize,
                                  width: buttonIconSize,
                                  placeholderBuilder: (_) => Icon(
                                    CupertinoIcons.arrow_down,
                                    size: buttonIconSize,
                                    color: sendLoading
                                        ? Theme.of(context)
                                            .colors
                                            .subtleEmphasis
                                        : Theme.of(context).colors.black,
                                  ),
                                ),
                                buttonSize: buttonSize,
                                buttonIconSize: buttonIconSize,
                                buttonFontSize: buttonFontSize,
                                shrink: widget.shrink,
                                text: onePlugin.name,
                                alt: true,
                                loading: sendLoading,
                                disabled: sendLoading,
                                onPressed: () =>
                                    widget.handlePlugin!(onePlugin),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
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
