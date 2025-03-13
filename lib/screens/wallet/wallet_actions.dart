import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/engine/events.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/ratio.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/wallet/action_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WalletActions extends StatefulWidget {
  final double shrink;
  final bool refreshing;
  final void Function()? handleProfileEdit;
  final void Function()? handleSendScreen;
  final void Function()? handleReceive;
  final void Function(PluginConfig pluginConfig)? handlePlugin;
  final void Function()? handleCards;
  final void Function()? handleMint;
  final void Function()? handleVouchers;
  final void Function()? handleShowMore;

  const WalletActions({
    super.key,
    this.shrink = 0,
    this.refreshing = false,
    this.handleProfileEdit,
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
    final eventServiceState =
        context.select((WalletState state) => state.eventServiceState);
    final wallet = context.select((WalletState state) => state.wallet);

    final walletActionsLoading =
        context.select((WalletState state) => state.walletActionsLoading);
    final isWalletReady = context.select((WalletState state) => state.ready);
    final showActionButton = !walletActionsLoading && isWalletReady;
    final actionButton = context.select(selectActionButtonToShow);
    final plugins = context.select(selectVisiblePlugins);
    final onePlugin = plugins.isNotEmpty ? plugins.first : null;

    final imageSmall = context.select((ProfileState state) => state.imageSmall);
    final username = context.select((ProfileState state) => state.username);

    final withOfflineBanner =
        eventServiceState != EventServiceState.connected &&
            eventServiceState != EventServiceState.disconnected;

    final blockSending = context.select(selectShouldBlockSending) ||
        loading ||
        firstLoad ||
        widget.handleSendScreen == null;
    final sendLoading = context.read<WalletState>().transactionSendLoading;

    final blockReceive =
        loading || firstLoad || widget.handleReceive == null || sendLoading;

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

    final isIncreasing = newBalance > balance;

    final width = MediaQuery.of(context).size.width;

    final profileBackgroundHeight = (1 - widget.shrink) < 0.9
        ? 0.0
        : progressiveClamp(0, 226, widget.shrink);
    final profileCircleSize = progressiveClamp(2, 65, widget.shrink);
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
        Positioned(
          top: withOfflineBanner ? 60 + 20 : 60,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colors
                  .primary
                  .resolveFrom(context)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            height: profileBackgroundHeight,
            width: width * 0.9,
          ),
        ),
        if (wallet != null)
          Positioned(
            top: withOfflineBanner ? 90 + 20 : 90,
            child: Opacity(
              opacity: progressiveClamp(0, 1, widget.shrink * 2.5),
              child: GestureDetector(
                onTap: widget.handleProfileEdit,
                child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color:
                              Theme.of(context).colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                      borderRadius:
                          BorderRadius.circular(profileCircleSize / 2),
                    ),
                    child: ProfileCircle(
                      size: profileCircleSize,
                      imageUrl: imageSmall,
                      borderWidth: 3,
                      borderColor:
                          Theme.of(context).colors.primary.resolveFrom(context),
                      backgroundColor: Theme.of(context)
                          .colors
                          .uiBackgroundAlt
                          .resolveFrom(context),
                    )),
              ),
            ),
          ),
        Positioned(
          top: withOfflineBanner
              ? progressiveClamp(90 + 20, 170 + 20, widget.shrink)
              : progressiveClamp(90, 170, widget.shrink),
          child: GestureDetector(
            onTap: widget.handleProfileEdit,
            child: Opacity(
              opacity: progressiveClamp(0, 1, widget.shrink * 2.5),
              child: Text(
                username.isEmpty ? '' : '@$username',
                style: TextStyle(
                  fontSize: coinNameSize,
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).colors.subtleSolid.resolveFrom(context),
                ),
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
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        0,
                        0,
                        0,
                      ),
                      child: CoinLogo(
                        size: (1 - widget.shrink) < 0.6
                            ? 32
                            : progressiveClamp(12, 48, widget.shrink),
                        logo: wallet?.currencyLogo,
                      ),
                    ),
                  ],
                ),
        ),
        Positioned(
          top: withOfflineBanner
              ? progressiveClamp(160 + 20, 300 + 20, widget.shrink * 2)
              : progressiveClamp(160, 300, widget.shrink * 2),
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
                        disabled: blockReceive,
                        onPressed: widget.handleReceive,
                      ),
                      SizedBox(
                        width: buttonSeparator,
                      ),
                      if (!showActionButton || actionButton == null) ...[
                        WalletActionButton(
                          icon: null,
                          buttonSize: buttonSize,
                          buttonIconSize: buttonIconSize,
                          buttonFontSize: buttonFontSize,
                          shrink: widget.shrink,
                          text: '',
                          loading: false,
                          disabled: true,
                          onPressed: () => {},
                          alt: true,
                        ),
                      ],
                      if (showActionButton &&
                          actionButton?.buttonType ==
                              ActionButtonType.more) ...[
                        WalletActionButton(
                          key: const Key('more_action_button'),
                          icon: CupertinoIcons.ellipsis,
                          buttonSize: buttonSize,
                          buttonIconSize: buttonIconSize,
                          buttonFontSize: buttonFontSize,
                          shrink: widget.shrink,
                          text: AppLocalizations.of(context)!.more,
                          loading: false,
                          disabled: false,
                          onPressed: widget.handleShowMore,
                          alt: true,
                        ),
                      ],
                      if (showActionButton &&
                          actionButton?.buttonType ==
                              ActionButtonType.vouchers) ...[
                        WalletActionButton(
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
                        ),
                      ],
                      if (showActionButton &&
                          actionButton?.buttonType ==
                              ActionButtonType.minter) ...[
                        WalletActionButton(
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
                        ),
                      ],
                      if (showActionButton &&
                          actionButton?.buttonType ==
                              ActionButtonType.plugins) ...[
                        WalletActionButton(
                          key: const Key('plugin_action_button'),
                          customIcon: onePlugin!.icon != null
                              ? SvgPicture.network(
                                  onePlugin.icon!,
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
                                )
                              : null,
                          buttonSize: buttonSize,
                          buttonIconSize: buttonIconSize,
                          buttonFontSize: buttonFontSize,
                          shrink: widget.shrink,
                          text: onePlugin.name,
                          alt: true,
                          loading: sendLoading,
                          disabled: sendLoading,
                          onPressed: () => widget.handlePlugin!(onePlugin),
                        )
                      ],
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
