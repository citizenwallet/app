import 'package:citizenwallet/screens/wallet/transaction_row.dart';
import 'package:citizenwallet/screens/wallet/wallet_actions.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/vouchers/selectors.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/strings.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/persistent_header_delegate.dart';
import 'package:citizenwallet/widgets/picker.dart';
import 'package:citizenwallet/widgets/qr/qr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WalletScrollView extends StatefulWidget {
  final ScrollController controller;

  final Future<void> Function() handleRefresh;
  final void Function() handleSendModal;
  final void Function() handleReceive;
  final void Function(PluginConfig pluginConfig)? handlePlugin;
  final void Function()? handleCards;
  final void Function()? handleMint;
  final void Function() handleVouchers;
  final void Function(String) handleTransactionTap;
  final void Function() handleTransactionSendingTap;
  final void Function(String, bool) handleFailedTransactionTap;
  final void Function(String) handleCopy;

  final void Function(String) handleLoad;
  final void Function() handleScrollToTop;

  const WalletScrollView({
    super.key,
    required this.controller,
    required this.handleRefresh,
    required this.handleSendModal,
    required this.handleReceive,
    this.handlePlugin,
    this.handleCards,
    this.handleMint,
    required this.handleVouchers,
    required this.handleTransactionTap,
    required this.handleTransactionSendingTap,
    required this.handleFailedTransactionTap,
    required this.handleCopy,
    required this.handleLoad,
    required this.handleScrollToTop,
  });

  @override
  WalletScrollViewState createState() => WalletScrollViewState();
}

class WalletScrollViewState extends State<WalletScrollView> {
  String _selectedValue = 'Citizen Wallet';
  bool _refreshing = false;

  void handleSelect(String? value) {
    if (value != null) {
      setState(() {
        _selectedValue = value;
      });
    }
  }

  void handleRefreshing(bool value) {
    if (_refreshing == value) {
      return;
    }

    Future.delayed(Duration(milliseconds: value ? 10 : 250), () {
      setState(() {
        _refreshing = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final handleRefresh = widget.handleRefresh;
    final handleSendModal = widget.handleSendModal;
    final handleReceive = widget.handleReceive;
    final handlePlugin = widget.handlePlugin;
    final handleCards = widget.handleCards;
    final handleMint = widget.handleMint;
    final handleVouchers = widget.handleVouchers;
    final handleTransactionTap = widget.handleTransactionTap;
    final handleTransactionSendingTap = widget.handleTransactionSendingTap;
    final handleFailedTransactionTap = widget.handleFailedTransactionTap;
    final handleCopy = widget.handleCopy;
    final handleLoad = widget.handleLoad;

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final size = height > width ? width : (height * 0.3);
    final qrSize = size * 0.65;

    final safePadding = MediaQuery.of(context).padding.top;

    final wallet = context.select((WalletState state) => state.wallet);
    final walletLoading = context.select((WalletState state) => state.loading);
    final config = context.select((WalletState state) => state.config);

    final transactionsLoading =
        context.select((WalletState state) => state.transactionsLoading);
    final returnLoading =
        context.select((VoucherState state) => state.returnLoading);

    final loading = transactionsLoading || returnLoading;

    final hasMore =
        context.select((WalletState state) => state.transactionsHasMore);

    final transactions = context.watch<WalletState>().transactions;

    final vouchers = context.select(selectMappedVoucher);

    final queuedTransactions =
        context.select((WalletState state) => state.transactionSendQueue);

    final inProgressTransaction =
        context.select((WalletState state) => state.inProgressTransaction);

    final blockSending = context.select(selectShouldBlockSending);

    final profiles = context.watch<ProfilesState>().profiles;

    final profileLink =
        context.select((ProfileState state) => state.profileLink);

    final profileLinkLoading =
        context.select((ProfileState state) => state.profileLinkLoading);

    final isExternalWallet = _selectedValue == 'External Wallet';

    final qrData = isExternalWallet ? wallet?.account ?? '' : profileLink;

    return CustomScrollView(
      controller: controller,
      scrollBehavior: const CupertinoScrollBehavior(),
      slivers: [
        CupertinoSliverRefreshControl(
            onRefresh: handleRefresh,
            builder: (
              context,
              mode,
              pulledExtent,
              refreshTriggerPullDistance,
              refreshIndicatorExtent,
            ) {
              handleRefreshing(pulledExtent >= 0.39);

              return SafeArea(
                child: Container(
                  color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
                  padding: const EdgeInsets.fromLTRB(0, 60, 0, 0),
                  child: CupertinoSliverRefreshControl.buildRefreshIndicator(
                    context,
                    mode,
                    pulledExtent,
                    refreshTriggerPullDistance,
                    refreshIndicatorExtent,
                  ),
                ),
              );
            }),
        SliverPersistentHeader(
          pinned: true,
          floating: false,
          delegate: PersistentHeaderDelegate(
            expandedHeight: 400 + safePadding,
            minHeight: 180 + safePadding,
            builder: (context, shrink) => GestureDetector(
              onTap: widget.handleScrollToTop,
              child: WalletActions(
                shrink: shrink,
                refreshing: _refreshing,
                handleSendModal: handleSendModal,
                handleReceive: handleReceive,
                handlePlugin: handlePlugin,
                handleCards: handleCards,
                handleMint: handleMint,
                handleVouchers: handleVouchers,
              ),
            ),
          ),
        ),
        if (queuedTransactions.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: const Text(
                'Unable to send',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (queuedTransactions.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: queuedTransactions.length,
              (context, index) {
                if (wallet == null) {
                  return const SizedBox();
                }

                final transaction = queuedTransactions[index];

                return Container(
                  color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: TransactionRow(
                    key: Key(transaction.id),
                    transaction: transaction,
                    logo: config?.community.logo,
                    wallet: wallet,
                    profiles: profiles,
                    vouchers: vouchers,
                    onTap: (String id) =>
                        handleFailedTransactionTap(id, blockSending),
                    onLoad: handleLoad,
                  ),
                );
              },
            ),
          ),
        if (wallet != null &&
            wallet.doubleBalance == 0.0 &&
            transactions.isEmpty)
          SliverToBoxAdapter(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: walletLoading
                  ? [
                      CupertinoActivityIndicator(
                        color: ThemeColors.subtle.resolveFrom(context),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        AppLocalizations.of(context)!.preparingWallet,
                        style: TextStyle(
                          color: ThemeColors.text.resolveFrom(context),
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ]
                  : [
                      const SizedBox(
                        height: 20,
                      ),
                      AnimatedOpacity(
                        opacity: profileLinkLoading ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: QR(
                          data: qrData,
                          size: qrSize,
                          padding: const EdgeInsets.all(20),
                          logo: isExternalWallet ? null : 'assets/logo.png',
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Chip(
                            isExternalWallet
                                ? formatLongText(qrData, length: 6)
                                : ellipsizeLongText(
                                    qrData.replaceFirst('https://', ''),
                                    startLength: 30,
                                    endLength: 6,
                                  ),
                            onTap: () => handleCopy(qrData),
                            fontSize: 14,
                            color:
                                ThemeColors.subtleEmphasis.resolveFrom(context),
                            textColor:
                                ThemeColors.touchable.resolveFrom(context),
                            suffix: Icon(
                              CupertinoIcons.square_on_square,
                              size: 14,
                              color: ThemeColors.touchable.resolveFrom(context),
                            ),
                            maxWidth: isExternalWallet ? 160 : 290,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Picker(
                            options: [
                              AppLocalizations.of(context)!.citizenWallet,
                              AppLocalizations.of(context)!.externalWallet
                            ],
                            selected: _selectedValue,
                            handleSelect: handleSelect,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ],
            ),
          ),
        if (transactions.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Text(
                AppLocalizations.of(context)!.transactions,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (loading && transactions.isEmpty)
          SliverFillRemaining(
            child: Container(
              color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
              child: Center(
                child: CupertinoActivityIndicator(
                  color: ThemeColors.subtle.resolveFrom(context),
                ),
              ),
            ),
          ),
        if (inProgressTransaction != null && wallet != null)
          SliverToBoxAdapter(
            child: Container(
              color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: TransactionRow(
                key: Key(inProgressTransaction.id),
                transaction: inProgressTransaction,
                logo: config?.community.logo,
                wallet: wallet,
                profiles: profiles,
                vouchers: vouchers,
                onTap: (String id) =>
                    handleFailedTransactionTap(id, blockSending),
                onLoad: handleLoad,
              ),
            ),
          ),
        if (transactions.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: transactions.length,
              (context, index) {
                if (wallet == null) {
                  return const SizedBox();
                }

                final transaction = transactions[index];

                return Container(
                  color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: TransactionRow(
                    key: Key(transaction.id),
                    transaction: transaction,
                    logo: config?.community.logo,
                    wallet: wallet,
                    profiles: profiles,
                    vouchers: vouchers,
                    onTap: handleTransactionTap,
                    onProcessingTap: handleTransactionSendingTap,
                    onLoad: handleLoad,
                  ),
                );
              },
            ),
          ),
        if (transactions.isNotEmpty && wallet != null && !loading)
          SliverToBoxAdapter(
            child: Container(
              color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
              height: (clampDouble(5.0 - transactions.length, 1, 5)) * 100,
              child: null,
            ),
          ),
      ],
    );
  }
}
