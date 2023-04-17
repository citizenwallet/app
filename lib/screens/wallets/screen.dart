import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/screens/wallet/transaction_row.dart';
import 'package:citizenwallet/screens/wallets/wallet_header.dart';
import 'package:citizenwallet/screens/wallets/wallet_selection.dart';
import 'package:citizenwallet/state/wallets/logic.dart';
import 'package:citizenwallet/state/wallets/mock_data.dart';
import 'package:citizenwallet/state/wallets/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/text_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class WalletsScreen extends StatefulWidget {
  final String title = 'Citizen Wallet';

  const WalletsScreen({super.key});

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletsScreen> {
  late WalletsLogic _walletLogic;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      _walletLogic = WalletsLogic(context);

      _walletLogic.getWallet(mockWalletId);
      _walletLogic.getTransactions(mockWalletId);
    });
  }

  void handleWalletSelection(BuildContext context) async {
    final wallet = await showCupertinoModalPopup<CWWallet?>(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => WalletSelection(walletLogic: _walletLogic),
    );

    if (wallet != null) {
      _walletLogic.getWallet(wallet.address);
    }
  }

  Future<void> handleRefresh() async {
    _walletLogic.getWallet(mockWalletId);
    _walletLogic.getTransactions(mockWalletId);
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select((WalletsState state) => state.loading);
    final wallet = context.select((WalletsState state) => state.wallet);

    final transactions =
        context.select((WalletsState state) => state.transactions);
    final transactionsLoading =
        context.select((WalletsState state) => state.loadingTransactions);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Flex(
        direction: Axis.vertical,
        children: [
          Header(
            title: widget.title,
            actionButton: CupertinoButton(
              onPressed: () => handleWalletSelection(context),
              child: !loading && wallet != null
                  ? TextBadge(
                      text: wallet.symbol,
                      size: 20,
                      color: ThemeColors.surfaceBackground.resolveFrom(context),
                      textColor: ThemeColors.surfaceText.resolveFrom(context),
                    )
                  : const SizedBox(),
            ),
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
                            wallet: wallet);
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
