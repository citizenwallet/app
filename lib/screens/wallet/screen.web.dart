import 'dart:convert';

import 'package:citizenwallet/screens/wallet/receive_modal.dart';
import 'package:citizenwallet/screens/wallet/send_modal.dart';
import 'package:citizenwallet/screens/wallet/wallet_scroll_view.dart';
import 'package:citizenwallet/services/wallet/models/qr/qr.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/share_modal.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/qr_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
  // QRWallet? _wallet;

  final ScrollController _scrollController = ScrollController();
  late WalletLogic _logic;

  late String _password;

  @override
  void initState() {
    super.initState();

    _logic = WalletLogic(context);

    WidgetsBinding.instance.addObserver(_logic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here

      _scrollController.addListener(onScrollUpdate);

      onLoad();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_logic);

    _logic.dispose();

    _scrollController.removeListener(onScrollUpdate);

    super.dispose();
  }

  void onScrollUpdate() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 140) {
      final hasMore = context.read<WalletState>().transactionsHasMore;
      final transactionsLoading =
          context.read<WalletState>().transactionsLoading;

      if (!hasMore || transactionsLoading) {
        return;
      }

      _logic.loadAdditionalTransactions(10);
    }
  }

  void onLoad({bool? retry}) async {
    final navigator = GoRouter.of(context);
    await delay(const Duration(milliseconds: 350));
    try {
      _password = dotenv.get('WEB_BURNER_PASSWORD');

      if (!widget.encoded.startsWith('v2-')) {
        // old format, convert
        final converted =
            QR.fromCompressedJson(widget.encoded).toQRWallet().data.wallet;

        final encoded = jsonEncode(converted);

        navigator.go('/wallet/v2-${base64Encode(encoded.codeUnits)}');
      }
      // _wallet = QR.fromCompressedJson(widget.encoded).toQRWallet();
    } catch (exception, stackTrace) {
      // something is wrong with the encoding
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );

      // try and reset preferences so we don't end up in a loop
      await _logic.resetWalletPreferences();

      // go back to the home screen
      navigator.go('/');
      return;
    }

    if (_password.isEmpty) {
      return;
    }

    final ok = await _logic.openWalletFromURL(
      widget.encoded,
      _password,
    );

    if (!ok) {
      onLoad(retry: true);
      return;
    }

    await _logic.loadTransactions();
  }

  void handleFailedTransaction(String id) async {
    _logic.pauseFetching();

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
      _logic.resumeFetching();
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

    _logic.resumeFetching();
  }

  Future<void> handleRefresh() async {
    await _logic.loadTransactions();

    HapticFeedback.heavyImpact();
  }

  void handleDisplayWalletQR(BuildContext context) async {
    _logic.pauseFetching();

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

    _logic.resumeFetching();
  }

  void handleDisplayWalletExport(BuildContext context) async {
    _logic.pauseFetching();

    await showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => ShareModal(
        title: 'Share Citizen Wallet',
        copyLabel: '---------',
        onCopyPrivateKey: handleCopyWalletPrivateKey,
      ),
    );

    _logic.resumeFetching();
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
    HapticFeedback.lightImpact();

    _logic.pauseFetching();

    await showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (_) => ReceiveModal(
        logic: _logic,
      ),
    );

    _logic.resumeFetching();
  }

  void handleSendModal() async {
    HapticFeedback.lightImpact();

    _logic.pauseFetching();

    await showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (_) => SendModal(
        logic: _logic,
      ),
    );

    _logic.resumeFetching();
  }

  void handleCopyWalletQR() {
    _logic.copyWalletQRToClipboard();

    HapticFeedback.heavyImpact();
  }

  void handleCopyAccount() {
    _logic.copyWalletAccount();

    HapticFeedback.heavyImpact();
  }

  void handleTransactionTap(String transactionId) async {
    HapticFeedback.lightImpact();

    _logic.pauseFetching();

    await GoRouter.of(context).push(
        '/wallet/${widget.encoded}/transactions/$transactionId',
        extra: {'logic': _logic});

    _logic.resumeFetching();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.top;
    final wallet = context.select((WalletState state) => state.wallet);

    final loading = context.select((WalletState state) => state.loading);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          loading || wallet == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(
                      color: ThemeColors.subtle.resolveFrom(context),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      'Loading',
                      style: TextStyle(
                        color: ThemeColors.text.resolveFrom(context),
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                )
              : WalletScrollView(
                  controller: _scrollController,
                  handleRefresh: handleRefresh,
                  handleSendModal: handleSendModal,
                  handleReceive: handleReceive,
                  handleTransactionTap: handleTransactionTap,
                  handleFailedTransactionTap: handleFailedTransaction,
                  handleCopyWalletQR: handleCopyAccount,
                ),
          Header(
            safePadding: safePadding,
            transparent: true,
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
                        'Citizen Wallet',
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
            actionButton: loading
                ? null
                : Row(
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
        ],
      ),
    );
  }
}
