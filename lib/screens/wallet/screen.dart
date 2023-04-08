import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/screens/wallet/wallet_header.dart';
import 'package:citizenwallet/screens/wallet/wallet_selection.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/mock_data.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/text_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class WalletScreen extends StatefulWidget {
  final String title = 'Wallet name';

  const WalletScreen({super.key});

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  late WalletLogic _walletLogic;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      _walletLogic = WalletLogic(context);

      _walletLogic.getWallet(mockWalletId);
      _walletLogic.getTransactions(mockWalletId);
    });
  }

  void handleWalletSelection(BuildContext context) async {
    final wallet = await showCupertinoModalPopup<Wallet?>(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => WalletSelection(walletLogic: _walletLogic),
    );

    if (wallet != null) {
      _walletLogic.getWallet(wallet.id);
    }
  }

  Future<void> handleRefresh() async {
    _walletLogic.getWallet(mockWalletId);
    _walletLogic.getTransactions(mockWalletId);
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select((WalletState state) => state.loading);
    final wallet = context.select((WalletState state) => state.wallet);

    final transactions =
        context.select((WalletState state) => state.transactions);
    final transactionsLoading =
        context.select((WalletState state) => state.loadingTransactions);

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
                        final date = transaction.date;

                        return Container(
                          margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                          padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                          decoration: BoxDecoration(
                            color: ThemeColors.background.resolveFrom(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: ThemeColors.subtle.resolveFrom(context),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  NumberFormat.currency(
                                          name: wallet.name,
                                          symbol: wallet.symbol,
                                          decimalDigits: 2)
                                      .format(transaction.amount),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
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
