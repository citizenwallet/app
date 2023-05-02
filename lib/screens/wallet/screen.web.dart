import 'package:citizenwallet/screens/wallet/receive_modal.dart';
import 'package:citizenwallet/screens/wallet/send_modal.dart';
import 'package:citizenwallet/screens/wallet/transaction_row.dart';
import 'package:citizenwallet/screens/wallet/wallet_header.dart';
import 'package:citizenwallet/services/wallet/models/qr/qr.dart';
import 'package:citizenwallet/services/wallet/models/qr/wallet.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/qr_modal.dart';
import 'package:citizenwallet/widgets/text_input_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class BurnerWalletScreen extends StatefulWidget {
  final String qr;

  const BurnerWalletScreen(
    this.qr, {
    super.key,
  });

  @override
  BurnerWalletScreenState createState() => BurnerWalletScreenState();
}

class BurnerWalletScreenState extends State<BurnerWalletScreen> {
  QRWallet? _wallet;

  final ScrollController _scrollController = ScrollController();
  late WalletLogic _logic;

  String? _password;

  @override
  void initState() {
    super.initState();

    try {
      _wallet = QR.fromCompressedJson(widget.qr).toQRWallet();
    } catch (e) {
      print(e);
    }

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

        _logic.loadAdditionalTransactions(transactions.length);
      }
    }
  }

  void onLoad({bool? retry}) async {
    if (_wallet == null) {
      return;
    }

    final navigator = GoRouter.of(context);

    _password = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: false,
      builder: (modalContext) => TextInputModal(
        title: 'Unlock',
        placeholder: 'Enter wallet password',
        secure: true,
        retry: retry ?? false,
      ),
    );

    if (_password == null || _password!.isEmpty) {
      return;
    }

    await delay(const Duration(milliseconds: 250));

    final ok = await _logic.openWalletFromQR(
      _wallet!,
      _password!,
    );

    if (!ok) {
      onLoad(retry: true);
      return;
    }

    await _logic.loadTransactions();
  }

  Future<void> handleRefresh() async {
    await _logic.loadTransactions();

    HapticFeedback.heavyImpact();
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
    if (_wallet == null) {
      return;
    }

    HapticFeedback.lightImpact();

    GoRouter.of(context).push(
        '/wallet/${widget.qr}/transactions/$transactionId',
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
            titleWidget: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        wallet?.name ?? '...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.text.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Chip(
                        formatHexAddress(wallet?.address ?? zeroHexValue),
                        color: ThemeColors.subtleEmphasis.resolveFrom(context),
                        textColor: ThemeColors.touchable.resolveFrom(context),
                      ),
                    ],
                  ),
                ),
              ],
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
                  if (loading && wallet == null)
                    Positioned(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 200,
                            width: 200,
                            child: Center(
                              child: Lottie.asset(
                                'assets/lottie/piggie_bank.json',
                                height: 200,
                                width: 200,
                                animate: true,
                                repeat: true,
                                // controller: _controller,
                              ),
                            ),
                          ),
                        ],
                      ),
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
