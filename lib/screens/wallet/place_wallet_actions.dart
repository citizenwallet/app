import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/config/config.dart';
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
import 'package:citizenwallet/widgets/wallet/coin_spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlaceWalletActions extends StatefulWidget {
  final double shrink;
  final bool refreshing;
  final void Function()? handleSendScreen;
  final void Function()? handleReceive;
  final void Function(PluginConfig pluginConfig)? handlePlugin;
  final void Function()? handleCards;
  final void Function()? handleMint;
  final void Function()? handleVouchers;
  final void Function()? handleShowMore;

  const PlaceWalletActions({
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
  State<PlaceWalletActions> createState() => _PlaceWalletActionsState();
}

class _PlaceWalletActionsState extends State<PlaceWalletActions> {
  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final loading = context.select((WalletState state) => state.loading);
    final firstLoad = context.select((WalletState state) => state.firstLoad);
    final wallet = context.select((WalletState state) => state.wallet);
    final config = context.select((WalletState state) => state.config);

    final walletActionsLoading =
        context.select((WalletState state) => state.walletActionsLoading);
    final isWalletReady = context.select((WalletState state) => state.ready);
    final showActionButton = !walletActionsLoading && isWalletReady;
    final actionButton = context.select(selectActionButtonToShow);
    final plugins = wallet?.plugins ?? [];
    final onePlugin = plugins.isNotEmpty ? plugins.first : null;

    final imageSmall = context.select((ProfileState state) => state.imageSmall);
    final username = context.select((ProfileState state) => state.username);

    final withOfflineBanner = config?.online == false;

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
        if (wallet != null)
          Positioned(
            top: withOfflineBanner ? 90 + 20 : 90,
            child: Opacity(
                opacity: progressiveClamp(0, 1, widget.shrink * 2.5),
                child: Stack(
                  children: [
                    ProfileCircle(
                      size: profileCircleSize,
                      imageUrl: imageSmall,
                      borderWidth: 3,
                      borderColor:
                          Theme.of(context).colors.primary.resolveFrom(context),
                      backgroundColor: Theme.of(context)
                          .colors
                          .uiBackgroundAlt
                          .resolveFrom(context),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colors
                              .white
                              .resolveFrom(context),
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 3,
                            color: Theme.of(context)
                                .colors
                                .primary
                                .resolveFrom(context),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.bag,
                            color: Theme.of(context)
                                .colors
                                .primary
                                .resolveFrom(context),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
          ),
        Positioned(
          top: withOfflineBanner
              ? progressiveClamp(90 + 20, 170 + 20, widget.shrink)
              : progressiveClamp(90, 170, widget.shrink),
          child: Opacity(
            opacity: progressiveClamp(0, 1, widget.shrink * 2.5),
            child: Text(
              username.isEmpty
                  ? AppLocalizations.of(context)!.anonymous
                  : '@$username',
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
                      WalletActionButton(
                        key: const Key('products_action_button'),
                        icon: CupertinoIcons.cube_box,
                        buttonSize: buttonSize,
                        buttonIconSize: buttonIconSize,
                        buttonFontSize: buttonFontSize,
                        shrink: widget.shrink,
                        text: AppLocalizations.of(context)!.products,
                        loading: sendLoading,
                        // disabled: blockSending,
                        onPressed: widget.handleSendScreen,
                      ),
                      SizedBox(
                        width: buttonSeparator,
                      ),
                      WalletActionButton(
                        key: const Key('device_action_button'),
                        icon: CupertinoIcons.settings,
                        buttonSize: buttonSize,
                        buttonIconSize: buttonIconSize,
                        buttonFontSize: buttonFontSize,
                        shrink: widget.shrink,
                        text: AppLocalizations.of(context)!.device,
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
                          key: const Key('connect_action_button'),
                          icon: CupertinoIcons.bag,
                          buttonSize: buttonSize,
                          buttonIconSize: buttonIconSize,
                          buttonFontSize: buttonFontSize,
                          shrink: widget.shrink,
                          text: AppLocalizations.of(context)!.place,
                          loading: false,
                          disabled: false,
                          onPressed: widget.handleShowMore,
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
                          customIcon: SvgPicture.network(
                            onePlugin!.icon,
                            semanticsLabel: '${onePlugin.name} icon',
                            height: buttonIconSize,
                            width: buttonIconSize,
                            placeholderBuilder: (_) => Icon(
                              CupertinoIcons.arrow_down,
                              size: buttonIconSize,
                              color: sendLoading
                                  ? Theme.of(context).colors.subtleEmphasis
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
