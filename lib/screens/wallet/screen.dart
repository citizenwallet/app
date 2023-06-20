import 'package:citizenwallet/screens/wallet/receive_modal.dart';
import 'package:citizenwallet/screens/wallet/send_modal.dart';
import 'package:citizenwallet/screens/wallet/switch_wallet_modal.dart';
import 'package:citizenwallet/screens/wallet/wallet_scroll_view.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
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
  final ScrollController _scrollController = ScrollController();
  late WalletLogic _logic;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      print('loading again');
      _logic = WalletLogic(context);

      _scrollController.addListener(onScrollUpdate);

      onLoad();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(onScrollUpdate);

    _logic.dispose();

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

  void handleRetry() {
    onLoad();
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

    _logic.updateWalletQR();

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
    final wallet = context.select((WalletState state) => state.wallet);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Flex(
        direction: Axis.vertical,
        children: [
          Header(
            blur: true,
            color: ThemeColors.transparent,
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
            child: WalletScrollView(
              controller: _scrollController,
              handleRefresh: handleRefresh,
              handleSendModal: handleSendModal,
              handleReceive: handleReceive,
              handleTransactionTap: handleTransactionTap,
              handleRetry: handleRetry,
            ),
          ),
        ],
      ),
    );
  }
}
