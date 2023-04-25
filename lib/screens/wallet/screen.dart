import 'package:citizenwallet/screens/wallet/password_modal.dart';
import 'package:citizenwallet/screens/wallet/receive_modal.dart';
import 'package:citizenwallet/screens/wallet/send_modal.dart';
import 'package:citizenwallet/screens/wallet/switch_wallet_modal.dart';
import 'package:citizenwallet/screens/wallet/transaction_row.dart';
import 'package:citizenwallet/screens/wallets/wallet_header.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
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
    if (widget.address == null) {
      return;
    }

    final navigator = GoRouter.of(context);

    final password = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PasswordModal(
        address: widget.address!,
        logic: _logic,
      ),
    );

    if (password == null) {
      navigator.go('/');
      return;
    }

    await _logic.openWallet(
      widget.address!,
      password,
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

    await showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => SwitchWalletModal(
        logic: _logic,
      ),
    );

    await _logic.loadTransactions();
  }

  void handleDisplayWalletQR(BuildContext context) async {
    final sendLoading = context.read<WalletState>().transactionSendLoading;

    if (sendLoading) {
      return;
    }

    _logic.updateWalletQR();

    await showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => QRModal(
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
    HapticFeedback.lightImpact();

    GoRouter.of(context).push('/wallets/transactions/$transactionId');
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
            actionButton: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  onPressed: () => handleSwitchWalletModal(context),
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    color: ThemeColors.primary.resolveFrom(context),
                  ),
                ),
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
                              onTap: handleTransactionTap,
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
                        CupertinoButton(
                          padding: const EdgeInsets.all(5),
                          onPressed: handleSendModal,
                          borderRadius: BorderRadius.circular(25),
                          color: ThemeColors.primary.resolveFrom(context),
                          child: Icon(
                            CupertinoIcons.arrow_up,
                            color: ThemeColors.touchable.resolveFrom(context),
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
                            color: ThemeColors.touchable.resolveFrom(context),
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
