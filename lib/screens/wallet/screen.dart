import 'package:citizenwallet/screens/wallet/transaction_row.dart';
import 'package:citizenwallet/screens/wallets/wallet_header.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class WalletScreen extends StatefulWidget {
  final String title = 'Wallet';

  const WalletScreen({super.key});

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  late WalletLogic _logic;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      _logic = WalletLogic(context);

      onLoad();
    });
  }

  @override
  void dispose() {
    _logic.dispose();

    super.dispose();
  }

  void onLoad() async {
    await _logic.openWallet();

    await _logic.loadTransactions();
  }

  Future<void> handleRefresh() async {
    await _logic.loadTransactions();
  }

  void onChanged(bool enabled) {
    // _appLogic.setDarkMode(enabled);
    HapticFeedback.mediumImpact();
  }

  void handleSend() async {
    final sendLoading = context.read<WalletState>().transactionSendLoading;

    if (sendLoading) {
      return;
    }

    await _logic.sendTransaction(100);
  }

  void handleReceive() async {
    // final sendLoading = context.read<WalletState>().transactionSendLoading;

    // if (sendLoading) {
    //   return;
    // }

    // await _logic.sendTransaction(100);
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select((WalletState state) => state.loading);
    final wallet = context.select((WalletState state) => state.wallet);

    final transactionsLoading =
        context.select((WalletState state) => state.transactionsLoading);
    final transactions =
        context.select((WalletState state) => state.transactions);

    final sendLoading =
        context.select((WalletState state) => state.transactionSendLoading);

    final formattedBalance = wallet?.formattedBalance ?? '';

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Flex(
        direction: Axis.vertical,
        children: [
          Header(
            title: wallet?.name ?? 'Wallet',
            // subTitle: wallet?.symbol,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomScrollView(
                    slivers: [
                      CupertinoSliverRefreshControl(
                        onRefresh: handleRefresh,
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        floating: true,
                        delegate: WalletHeader(
                          expandedHeight: 80,
                          minHeight: 40,
                          shrunkenChild: Container(
                            color:
                                ThemeColors.uiBackground.resolveFrom(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Balance',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                loading && formattedBalance.isEmpty
                                    ? CupertinoActivityIndicator(
                                        key: const Key(
                                            'wallet-balance-shrunken-loading'),
                                        color: ThemeColors.subtle
                                            .resolveFrom(context),
                                      )
                                    : Text(
                                        formattedBalance,
                                        key: const Key(
                                            'wallet-balance-shrunken'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          child: Container(
                            color:
                                ThemeColors.uiBackground.resolveFrom(context),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                  child: Text(
                                    'Balance',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 10, 0, 0),
                                  child: loading && formattedBalance.isEmpty
                                      ? CupertinoActivityIndicator(
                                          key: const Key(
                                              'wallet-balance-loading'),
                                          color: ThemeColors.subtle
                                              .resolveFrom(context),
                                        )
                                      : Text(
                                          formattedBalance,
                                          key: const Key('wallet-balance'),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          childCount: 1,
                          (context, index) {
                            return const Padding(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                              child: Text(
                                'Transactions',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (transactionsLoading && transactions.isEmpty)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            childCount: 1,
                            (context, index) {
                              return CupertinoActivityIndicator(
                                color: ThemeColors.subtle.resolveFrom(context),
                              );
                            },
                          ),
                        ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          childCount:
                              transactionsLoading && transactions.isEmpty
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

                            return TransactionRow(
                              key: Key(transaction.id),
                              transaction: transaction,
                              wallet: wallet,
                            );
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 60,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Button(
                          text: 'Send',
                          maxWidth: 140,
                          minWidth: 140,
                          onPressed: () {
                            handleSend();
                          },
                          prefix: const SizedBox(width: 20),
                          suffix: SizedBox(
                            width: 40,
                            child: !sendLoading
                                ? const Icon(CupertinoIcons.up_arrow)
                                : CupertinoActivityIndicator(
                                    color: ThemeColors.background
                                        .resolveFrom(context),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Button(
                          text: 'Receive',
                          maxWidth: 140,
                          minWidth: 140,
                          onPressed: () {
                            handleReceive();
                          },
                          prefix: const SizedBox(width: 15),
                          suffix: SizedBox(
                            width: 40,
                            child: !sendLoading
                                ? const Icon(CupertinoIcons.down_arrow)
                                : CupertinoActivityIndicator(
                                    color: ThemeColors.background
                                        .resolveFrom(context),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
