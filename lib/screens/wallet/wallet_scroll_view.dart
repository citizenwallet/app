import 'package:citizenwallet/screens/wallet/transaction_row.dart';
import 'package:citizenwallet/screens/wallet/wallet_actions.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
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

  const WalletScrollView({
    Key? key,
    required this.controller,
    required this.handleRefresh,
    required this.handleSendModal,
    required this.handleReceive,
    required this.handleTransactionTap,
    required this.handleFailedTransactionTap,
    required this.handleCopyWalletQR,
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
    final hasMore =
        context.select((WalletState state) => state.transactionsHasMore);

    final transactions = context.watch<WalletState>().transactions;

    final queuedTransactions =
        context.select((WalletState state) => state.transactionSendQueue);

    final blockSending = context.select(selectShouldBlockSending);

    if (wallet != null && wallet.doubleBalance == 0.0 && transactions.isEmpty) {
      // TODO: clean this up
      return CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: PersistentHeaderDelegate(
              expandedHeight: 300 + safePadding,
              minHeight: 180 + safePadding,
              builder: (context, shrink) => WalletActions(
                shrink: shrink,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                      wallet.account,
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
      physics: const AlwaysScrollableScrollPhysics(),
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
              color: ThemeColors.uiBackground.resolveFrom(context),
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
                  color: ThemeColors.uiBackground.resolveFrom(context),
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: TransactionRow(
                    key: Key(transaction.id),
                    transaction: transaction,
                    wallet: wallet,
                    onTap: blockSending ? null : handleFailedTransactionTap,
                  ),
                );
              },
            ),
          ),
        SliverToBoxAdapter(
          child: Container(
            color: ThemeColors.uiBackground.resolveFrom(context),
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
        if (transactionsLoading && transactions.isEmpty)
          SliverFillRemaining(
            child: Container(
              color: ThemeColors.uiBackground.resolveFrom(context),
              child: Center(
                child: CupertinoActivityIndicator(
                  color: ThemeColors.subtle.resolveFrom(context),
                ),
              ),
            ),
          ),
        if (!transactionsLoading && transactions.isEmpty)
          SliverFillRemaining(
            child: Container(
              color: ThemeColors.uiBackground.resolveFrom(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/empty_pockets.svg',
                    semanticsLabel: 'empty pockets icon',
                    height: 300,
                    width: 300,
                    colorFilter: ColorFilter.mode(
                      ThemeColors.text.resolveFrom(context),
                      BlendMode.srcIn,
                    ),
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
                  color: ThemeColors.uiBackground.resolveFrom(context),
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: TransactionRow(
                    key: Key(transaction.id),
                    transaction: transaction,
                    wallet: wallet,
                    onTap: handleTransactionTap,
                  ),
                );
              },
            ),
          ),
        // if (transactions.isNotEmpty && wallet != null)
        //   SliverToBoxAdapter(
        //     child: Container(
        //       color: ThemeColors.uiBackground.resolveFrom(context),
        //       height: (clampDouble(5.0 - transactions.length, 1, 5)) * 100,
        //       child: transactionsLoading
        //           ? Container(
        //               color: ThemeColors.uiBackground.resolveFrom(context),
        //               padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        //               child: TransactionRow(
        //                 key: const Key('loading'),
        //                 transaction: CWTransaction.empty(),
        //                 wallet: wallet,
        //                 loading: true,
        //               ),
        //             )
        //           : null,
        //     ),
        //   ),
        if (transactions.isNotEmpty &&
            wallet != null &&
            transactionsLoading &&
            hasMore)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: 10,
              (context, index) {
                return Container(
                  color: ThemeColors.uiBackground.resolveFrom(context),
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: SkeletonTransactionRow(
                    key: Key('loading-$index'),
                  ),
                );
              },
            ),
          ),
        if (transactions.isNotEmpty && wallet != null && !transactionsLoading)
          SliverToBoxAdapter(
            child: Container(
              color: ThemeColors.uiBackground.resolveFrom(context),
              height: (clampDouble(5.0 - transactions.length, 1, 5)) * 100,
              child: hasMore
                  ? null
                  : Center(
                      child: SvgPicture.asset(
                        'assets/icons/empty_roll.svg',
                        semanticsLabel: 'empty roll icon',
                        height: 100,
                        width: 100,
                        colorFilter: ColorFilter.mode(
                          ThemeColors.text.resolveFrom(context),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}
