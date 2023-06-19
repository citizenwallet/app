import 'package:citizenwallet/screens/wallet/transaction_row.dart';
import 'package:citizenwallet/screens/wallet/wallet_actions.dart';
import 'package:citizenwallet/screens/wallet/wallet_header.dart';
import 'package:citizenwallet/screens/wallet/wallet_shrunken_actions.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class WalletScrollView extends StatelessWidget {
  final ScrollController controller;

  final Future<void> Function() handleRefresh;
  final void Function() handleSendModal;
  final void Function() handleReceive;
  final void Function(String) handleTransactionTap;

  const WalletScrollView({
    Key? key,
    required this.controller,
    required this.handleRefresh,
    required this.handleSendModal,
    required this.handleReceive,
    required this.handleTransactionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final wallet = context.select((WalletState state) => state.wallet);

    final transactionsLoading =
        context.select((WalletState state) => state.transactionsLoading);
    final transactions =
        context.select((WalletState state) => state.transactions);

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
              Container(
            color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
            child: CupertinoSliverRefreshControl.buildRefreshIndicator(
              context,
              mode,
              pulledExtent,
              refreshTriggerPullDistance,
              refreshIndicatorExtent,
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          floating: false,
          delegate: WalletHeader(
            expandedHeight: 300,
            minHeight: 180,
            shrunkenChild: (shrink) => WalletShrunkenActions(
              shrink: shrink,
              handleSendModal: handleSendModal,
              handleReceive: handleReceive,
            ),
            child: WalletActions(
              handleSendModal: handleSendModal,
              handleReceive: handleReceive,
            ),
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
                  Icon(
                    CupertinoIcons.ellipsis,
                    size: 40,
                    color: ThemeColors.white.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: transactionsLoading && transactions.isEmpty
                ? 0
                : transactions.length,
            (context, index) {
              if (transactionsLoading && transactions.isEmpty) {
                return CupertinoActivityIndicator(
                  color: ThemeColors.subtle.resolveFrom(context),
                );
              }

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
        if (transactionsLoading && transactions.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              color: ThemeColors.uiBackground.resolveFrom(context),
              child: Center(
                child: CupertinoActivityIndicator(
                  color: ThemeColors.subtle.resolveFrom(context),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
