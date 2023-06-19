import 'package:citizenwallet/screens/wallet/receive_modal.dart';
import 'package:citizenwallet/screens/wallet/send_modal.dart';
import 'package:citizenwallet/screens/wallet/switch_wallet_modal.dart';
import 'package:citizenwallet/screens/wallet/transaction_row.dart';
import 'package:citizenwallet/screens/wallet/wallet_header.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/ratio.dart';
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
        final total = context.read<WalletState>().transactionsTotal;
        final offset = context.read<WalletState>().transactionsOffset;

        if (offset >= total) {
          return;
        }

        _logic.loadAdditionalTransactions(10);
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
    final width = MediaQuery.of(context).size.width;

    final loading = context.select((WalletState state) => state.loading);
    final wallet = context.select((WalletState state) => state.wallet);

    final transactionsLoading =
        context.select((WalletState state) => state.transactionsLoading);
    final transactions =
        context.select((WalletState state) => state.transactions);

    final formattedBalance = wallet?.formattedBalance ?? '';

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Flex(
        direction: Axis.vertical,
        children: [
          Header(
            color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
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
                                    fontSize: 24,
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
            child: CustomScrollView(
              controller: _scrollController,
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
                  floating: true,
                  delegate: WalletHeader(
                    expandedHeight: 300,
                    minHeight: 180,
                    shrunkenChild: (shrink) => Container(
                      color: ThemeColors.uiBackground.resolveFrom(context),
                      child: Stack(
                        children: [
                          Container(
                            height: progressiveClamp(130, 240, shrink),
                            color: ThemeColors.uiBackgroundAlt
                                .resolveFrom(context),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  wallet?.currencyName ?? 'Token',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.normal,
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                loading && formattedBalance.isEmpty
                                    ? CupertinoActivityIndicator(
                                        color: ThemeColors.subtle
                                            .resolveFrom(context),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            formattedBalance,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.normal,
                                              color: ThemeColors.text
                                                  .resolveFrom(context),
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
                                              wallet?.symbol ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.start,
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: ThemeColors.text
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                const SizedBox(
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            width: width,
                            bottom: 15,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (wallet?.locked == false)
                                  CupertinoButton(
                                    padding: const EdgeInsets.all(5),
                                    onPressed: handleSendModal,
                                    borderRadius: BorderRadius.circular(
                                        progressiveClamp(10, 20, shrink)),
                                    color: ThemeColors.surfacePrimary
                                        .resolveFrom(context),
                                    child: SizedBox(
                                      height: progressiveClamp(54, 80, shrink),
                                      width: progressiveClamp(54, 80, shrink),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            CupertinoIcons.arrow_up,
                                            size: progressiveClamp(
                                                20, 40, shrink),
                                            color: ThemeColors.surfaceText
                                                .resolveFrom(context),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Send',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: ThemeColors.surfaceText
                                                  .resolveFrom(context),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (wallet?.locked == false)
                                  const SizedBox(width: 40),
                                CupertinoButton(
                                  padding: const EdgeInsets.all(5),
                                  onPressed: handleReceive,
                                  borderRadius: BorderRadius.circular(
                                      progressiveClamp(10, 20, shrink)),
                                  color: ThemeColors.surfacePrimary
                                      .resolveFrom(context),
                                  child: SizedBox(
                                    height: progressiveClamp(54, 80, shrink),
                                    width: progressiveClamp(54, 80, shrink),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.arrow_down,
                                          size:
                                              progressiveClamp(20, 40, shrink),
                                          color: ThemeColors.surfaceText
                                              .resolveFrom(context),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Receive',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: ThemeColors.surfaceText
                                                .resolveFrom(context),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    child: Container(
                      color: ThemeColors.uiBackground.resolveFrom(context),
                      child: Stack(
                        children: [
                          Container(
                            height: 240,
                            color: ThemeColors.uiBackgroundAlt
                                .resolveFrom(context),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  wallet?.currencyName ?? 'Token',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.normal,
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                loading && formattedBalance.isEmpty
                                    ? CupertinoActivityIndicator(
                                        color: ThemeColors.subtle
                                            .resolveFrom(context),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            formattedBalance,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.normal,
                                              color: ThemeColors.text
                                                  .resolveFrom(context),
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
                                              wallet?.symbol ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.start,
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: ThemeColors.text
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                const SizedBox(
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            width: width,
                            bottom: 15,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (wallet?.locked == false)
                                  CupertinoButton(
                                    padding: const EdgeInsets.all(5),
                                    onPressed: handleSendModal,
                                    borderRadius: BorderRadius.circular(20),
                                    color: ThemeColors.surfacePrimary
                                        .resolveFrom(context),
                                    child: SizedBox(
                                      height: 80,
                                      width: 80,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            CupertinoIcons.arrow_up,
                                            size: 40,
                                            color: ThemeColors.surfaceText
                                                .resolveFrom(context),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Send',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: ThemeColors.surfaceText
                                                  .resolveFrom(context),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (wallet?.locked == false)
                                  const SizedBox(width: 40),
                                CupertinoButton(
                                  padding: const EdgeInsets.all(5),
                                  onPressed: handleReceive,
                                  borderRadius: BorderRadius.circular(20),
                                  color: ThemeColors.surfacePrimary
                                      .resolveFrom(context),
                                  child: SizedBox(
                                    height: 80,
                                    width: 80,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.arrow_down,
                                          size: 40,
                                          color: ThemeColors.surfaceText
                                              .resolveFrom(context),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Receive',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: ThemeColors.surfaceText
                                                .resolveFrom(context),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
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
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Text(
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
                    child: Center(
                      child: CupertinoActivityIndicator(
                        color: ThemeColors.subtle.resolveFrom(context),
                      ),
                    ),
                  ),
                if (!transactionsLoading && transactions.isEmpty)
                  SliverFillRemaining(
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

                      return Padding(
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
                    child: CupertinoActivityIndicator(
                      color: ThemeColors.subtle.resolveFrom(context),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
