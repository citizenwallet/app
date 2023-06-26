import 'package:citizenwallet/screens/wallet/receive_modal.dart';
import 'package:citizenwallet/screens/wallet/send_modal.dart';
import 'package:citizenwallet/screens/wallet/wallet_scroll_view.dart';
import 'package:citizenwallet/services/wallet/models/qr/qr.dart';
import 'package:citizenwallet/services/wallet/models/qr/wallet.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/export_private_modal.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/qr_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/crypto.dart';

class BurnerWalletScreen extends StatefulWidget {
  final String encoded;

  const BurnerWalletScreen(
    this.encoded, {
    super.key,
  });

  @override
  BurnerWalletScreenState createState() => BurnerWalletScreenState();
}

class BurnerWalletScreenState extends State<BurnerWalletScreen> {
  QRWallet? _wallet;

  final ScrollController _scrollController = ScrollController();
  late WalletLogic _logic;

  late String _password;

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

  void onLoad({bool? retry}) async {
    final navigator = GoRouter.of(context);
    await delay(const Duration(milliseconds: 250));
    try {
      _password = dotenv.get('WEB_BURNER_PASSWORD');

      _wallet = QR.fromCompressedJson(widget.encoded).toQRWallet();
    } catch (e) {
      // something is wrong with the encoding
      print(e);

      // try and reset preferences so we don't end up in a loop
      await _logic.resetWalletPreferences();

      // go back to the home screen
      navigator.go('/');
      return;
    }

    if (_wallet == null) {
      return;
    }

    if (_password.isEmpty) {
      return;
    }

    await delay(const Duration(milliseconds: 250));

    final ok = await _logic.openWalletFromQR(
      widget.encoded,
      _wallet!,
      _password,
    );

    if (!ok) {
      onLoad(retry: true);
      return;
    }

    await _logic.loadTransactions();
  }

  void handleFailedTransaction(String id) async {
    final option = await showCupertinoModalPopup<String?>(
        context: context,
        builder: (BuildContext dialogContext) {
          return CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.of(dialogContext).pop('retry');
                },
                child: const Text('Retry'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(dialogContext).pop('edit');
                },
                child: const Text('Edit'),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(dialogContext).pop('delete');
                },
                child: const Text('Delete'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
          );
        });

    if (option == null) {
      return;
    }

    if (option == 'retry') {
      _logic.retryTransaction(id);
    }

    if (option == 'edit') {
      _logic.prepareEditQueuedTransaction(id);

      HapticFeedback.lightImpact();

      await showCupertinoModalPopup(
        context: context,
        barrierDismissible: true,
        builder: (_) => SendModal(
          logic: _logic,
          id: id,
        ),
      );
    }

    if (option == 'delete') {
      _logic.removeQueuedTransaction(id);
    }
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
        externalLink:
            '${dotenv.get('SCAN_URL')}/address/${modalContext.select((WalletState state) => state.walletQR)}',
      ),
    );
  }

  void handleDisplayWalletExport(BuildContext context) async {
    await showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => ExportPrivateModal(
        title: 'Export Wallet',
        copyLabel: '---------',
        onCopy: handleCopyWalletPrivateKey,
      ),
    );
  }

  void handleCopyWalletPrivateKey() {
    final privateKey = _logic.privateKey;

    if (privateKey == null) {
      return;
    }

    Clipboard.setData(ClipboardData(text: bytesToHex(privateKey.privateKey)));

    HapticFeedback.heavyImpact();
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
        '/wallet/${widget.encoded}/transactions/$transactionId',
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
            titleWidget: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        wallet?.name ?? 'Locked',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.text.resolveFrom(context),
                        ),
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
                  onPressed: () => handleDisplayWalletExport(context),
                  child: Icon(
                    CupertinoIcons.share,
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
            child: WalletScrollView(
              controller: _scrollController,
              handleRefresh: handleRefresh,
              handleSendModal: handleSendModal,
              handleReceive: handleReceive,
              handleTransactionTap: handleTransactionTap,
              handleFailedTransactionTap: handleFailedTransaction,
            ),
          ),
        ],
      ),
    );
  }
}
