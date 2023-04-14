import 'package:citizenwallet/screens/wallets/transaction_row.dart';
import 'package:citizenwallet/screens/wallets/wallet_header.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
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

  void onLoad() async {
    await _logic.openWallet();

    await _logic.loadTransactions();
  }

  Future<void> handleRefresh() async {
    await _logic.sendTransaction(100);
    await _logic.loadTransactions();
  }

  void onChanged(bool enabled) {
    // _appLogic.setDarkMode(enabled);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select((WalletState state) => state.loading);
    final wallet = context.select((WalletState state) => state.wallet);

    final transactionsLoading =
        context.select((WalletState state) => state.transactionsLoading);
    final transactions =
        context.select((WalletState state) => state.transactions);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Flex(
        direction: Axis.vertical,
        children: [
          Header(
            title: wallet?.name ?? 'Wallet',
            subTitle: wallet?.symbol,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: CustomScrollView(
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: handleRefresh,
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    floating: true,
                    delegate: WalletHeader(
                      expandedHeight: 140,
                      shrunkenChild: Container(
                        color: ThemeColors.uiBackground.resolveFrom(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Balance',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            loading
                                ? CupertinoActivityIndicator(
                                    key: const Key(
                                        'wallet-balance-shrunken-loading'),
                                    color:
                                        ThemeColors.subtle.resolveFrom(context),
                                  )
                                : Text(
                                    wallet != null
                                        ? wallet.formattedBalance
                                        : '',
                                    key: const Key('wallet-balance-shrunken'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      child: Container(
                        color: ThemeColors.uiBackground.resolveFrom(context),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                              child: Text(
                                'Balance',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                              child: loading
                                  ? CupertinoActivityIndicator(
                                      key: const Key('wallet-balance-loading'),
                                      color: ThemeColors.subtle
                                          .resolveFrom(context),
                                    )
                                  : Text(
                                      wallet != null
                                          ? wallet.formattedBalance
                                          : '',
                                      key: const Key('wallet-balance'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                            ),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                              child: Text(
                                'Transactions',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
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
                      childCount: transactionsLoading ? 0 : transactions.length,
                      (context, index) {
                        if (transactionsLoading) {
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
