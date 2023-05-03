import 'package:citizenwallet/screens/wallet/receive_modal.dart';
import 'package:citizenwallet/screens/wallet/send_modal.dart';
import 'package:citizenwallet/screens/wallet/switch_wallet_modal.dart';
import 'package:citizenwallet/screens/wallet/transaction_row.dart';
import 'package:citizenwallet/screens/wallet/wallet_header.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/qr_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class WalletScreen extends StatefulWidget {
  final String title = 'Wallet';
  final String? address;

  const WalletScreen(this.address, {super.key});

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  final ScrollController _scrollController = ScrollController();
  late WalletLogic _logic;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      _logic = WalletLogic(context);

      _scrollController.addListener(onScrollUpdate);

      onLoad();
    });
  }

  @override
  void dispose() {
    _logic.dispose();

    _scrollController.removeListener(onScrollUpdate);

    super.dispose();
  }

  void onScrollUpdate() {
    if (_scrollController.position.atEdge) {
      bool isTop = _scrollController.position.pixels == 0;
      if (!isTop) {
        final transactions = context.read<WalletState>().transactions;

        if (transactions.isEmpty) {
          return;
        }

        if (transactions.last.blockNumber == 0) {
          return;
        }

        _logic.loadAdditionalTransactions(transactions.last.blockNumber + 1);
      }
    }
  }

  void onLoad() async {
    if (widget.address == null) {
      return;
    }

    final navigator = GoRouter.of(context);

    final address = _logic.lastWallet;

    if (widget.address! == 'last' && address != null) {
      _logic.dispose();

      navigator.push('/wallet/${address.toLowerCase()}');
      return;
    }

    await _logic.openWallet(
      widget.address!,
    );

    await _logic.loadTransactions();
  }

  Future<void> handleRefresh() async {
    await _logic.loadTransactions();

    HapticFeedback.heavyImpact();
  }

  void handleSwitchWalletModal(BuildContext context) async {
    final sendLoading = context.read<WalletState>().transactionSendLoading;

    if (sendLoading) {
      return;
    }

    HapticFeedback.mediumImpact();

    final navigator = GoRouter.of(context);

    final address = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => SwitchWalletModal(
        logic: _logic,
        currentAddress: widget.address,
      ),
    );

    if (address == null) {
      return;
    }

    _logic.dispose();

    navigator.push('/wallet/${address.toLowerCase()}');
  }

  void handleDisplayWalletQR(BuildContext context) async {
    final sendLoading = context.read<WalletState>().transactionSendLoading;

    if (sendLoading) {
      return;
    }

    _logic.updateWalletQR(onlyHex: true);

    await showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => QRModal(
        title: 'Share address',
        qrCode: modalContext.select((WalletState state) => state.walletQR),
        copyLabel: modalContext
            .select((WalletState state) => formatHexAddress(state.walletQR)),
        onCopy: handleCopyWalletQR,
      ),
    );
  }

  void handleReceive() async {
    final sendLoading = context.read<WalletState>().transactionSendLoading;

    if (sendLoading) {
      return;
    }

    HapticFeedback.lightImpact();

    await showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (_) => ReceiveModal(
        logic: _logic,
      ),
    );
  }

  void handleSendModal() async {
    final sendLoading = context.read<WalletState>().transactionSendLoading;

    if (sendLoading) {
      return;
    }

    HapticFeedback.lightImpact();

    await showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (_) => SendModal(
        logic: _logic,
      ),
    );
  }

  void handleCopyWalletQR() {
    _logic.copyWalletQRToClipboard();

    HapticFeedback.heavyImpact();
  }

  void handleTransactionTap(String transactionId) {
    HapticFeedback.lightImpact();

    GoRouter.of(context).push(
        '/wallet/${widget.address!}/transactions/$transactionId',
        extra: {'logic': _logic});
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
            titleWidget: CupertinoButton(
              padding: const EdgeInsets.all(5),
              onPressed: () => handleSwitchWalletModal(context),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: ThemeColors.surfaceSubtle.resolveFrom(context),
                ),
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  wallet?.name ?? 'Wallet',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Icon(
                      CupertinoIcons.chevron_down,
                      color: ThemeColors.primary.resolveFrom(context),
                    ),
                  ],
                ),
              ),
            ),
            actionButton: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  onPressed: () => handleDisplayWalletQR(context),
                  child: Icon(
                    CupertinoIcons.qrcode,
                    color: ThemeColors.primary.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomScrollView(
                    controller: _scrollController,
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
                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                        '$formattedBalance (${wallet?.currencyName})',
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
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Balance',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Chip(
                                        formatHexAddress(
                                            wallet?.address ?? zeroHexValue),
                                        color: ThemeColors.subtleEmphasis
                                            .resolveFrom(context),
                                        textColor: ThemeColors.touchable
                                            .resolveFrom(context),
                                        maxWidth: 150,
                                      ),
                                    ],
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
                                          '$formattedBalance (${wallet?.currencyName})',
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
                              onTap: handleTransactionTap,
                            );
                          },
                        ),
                      ),
                      if (transactionsLoading && transactions.isNotEmpty)
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
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 60,
                        ),
                      ),
                    ],
                  ),
                  if (wallet != null)
                    Positioned(
                      bottom: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (!wallet.locked)
                            CupertinoButton(
                              padding: const EdgeInsets.all(5),
                              onPressed: handleSendModal,
                              borderRadius: BorderRadius.circular(25),
                              color: ThemeColors.primary.resolveFrom(context),
                              child: Icon(
                                CupertinoIcons.arrow_up,
                                color: ThemeColors.white.resolveFrom(context),
                              ),
                            ),
                          const SizedBox(width: 20),
                          CupertinoButton(
                            padding: const EdgeInsets.all(5),
                            onPressed: handleReceive,
                            borderRadius: BorderRadius.circular(25),
                            color: ThemeColors.primary.resolveFrom(context),
                            child: Icon(
                              CupertinoIcons.arrow_down,
                              color: ThemeColors.white.resolveFrom(context),
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
