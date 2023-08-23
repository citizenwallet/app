import 'package:citizenwallet/screens/wallet/transaction_row.dart';
import 'package:citizenwallet/screens/wallet/wallet_actions.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/vouchers/selectors.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/persistent_header_delegate.dart';
import 'package:citizenwallet/widgets/skeleton/transaction_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';

class WalletScrollView extends StatelessWidget {
  final ScrollController controller;

  final Future<void> Function() handleRefresh;
  final void Function() handleSendModal;
  final void Function() handleReceive;
  final void Function(String) handleTransactionTap;
  final void Function(String) handleFailedTransactionTap;
  final void Function() handleCopyWalletQR;

  final void Function(String) handleLoad;

  const WalletScrollView({
    Key? key,
    required this.controller,
    required this.handleRefresh,
    required this.handleSendModal,
    required this.handleReceive,
    required this.handleTransactionTap,
    required this.handleFailedTransactionTap,
    required this.handleCopyWalletQR,
    required this.handleLoad,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final size = height > width ? width : height;
    final qrSize = size * 0.7;

    final safePadding = MediaQuery.of(context).padding.top;

    final wallet = context.select((WalletState state) => state.wallet);

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

    final blockSending = context.select(selectShouldBlockSending);

    final profiles = context.watch<ProfilesState>().profiles;

    if (wallet != null &&
        wallet.doubleBalance == 0.0 &&
        transactions.isEmpty &&
        !loading) {
      return CustomScrollView(
        controller: controller,
        scrollBehavior: const CupertinoScrollBehavior(),
        slivers: [
          SliverFillRemaining(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  wallet.currencyName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.normal,
                    color: ThemeColors.text.resolveFrom(context),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '0.00',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.normal,
                        color: ThemeColors.text.resolveFrom(context),
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
                        wallet.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 22,
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
                Text(
                  'Ready to receive tokens',
                  style: TextStyle(
                    color: ThemeColors.text.resolveFrom(context),
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: ThemeColors.white.resolveFrom(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: PrettyQr(
                    data: wallet.account,
                    size: qrSize,
                    roundEdges: false,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      onTap: handleCopyWalletQR,
                      formatHexAddress(wallet.account),
                      color: ThemeColors.subtleEmphasis.resolveFrom(context),
                      textColor: ThemeColors.touchable.resolveFrom(context),
                      suffix: Icon(
                        CupertinoIcons.square_on_square,
                        size: 14,
                        color: ThemeColors.touchable.resolveFrom(context),
                      ),
                      borderRadius: 15,
                      maxWidth: 180,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

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
          ) =>
              SafeArea(
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
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          floating: false,
          delegate: PersistentHeaderDelegate(
            expandedHeight: 300 + safePadding,
            minHeight: 180 + safePadding,
            builder: (context, shrink) => WalletActions(
              shrink: shrink,
              handleSendModal: handleSendModal,
              handleReceive: handleReceive,
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
                    wallet: wallet,
                    profiles: profiles,
                    vouchers: vouchers,
                    onTap: blockSending ? null : handleFailedTransactionTap,
                    onLoad: handleLoad,
                  ),
                );
              },
            ),
          ),
        SliverToBoxAdapter(
          child: Container(
            color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: const Text(
              'Transactions',
              style: TextStyle(
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
        if (!loading && transactions.isEmpty)
          SliverFillRemaining(
            child: Container(
              color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/empty_pockets.svg',
                    semanticsLabel: 'empty pockets icon',
                    height: 250,
                    width: 250,
                  ),
                ],
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
                    wallet: wallet,
                    profiles: profiles,
                    vouchers: vouchers,
                    onTap: handleTransactionTap,
                    onLoad: handleLoad,
                  ),
                );
              },
            ),
          ),
        if (transactions.isNotEmpty && wallet != null && loading && hasMore)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: 10,
              (context, index) {
                return Container(
                  color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: SkeletonTransactionRow(
                    key: Key('loading-$index'),
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
