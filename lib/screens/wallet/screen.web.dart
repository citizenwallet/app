import 'dart:convert';

import 'package:citizenwallet/modals/profile/profile.dart';
import 'package:citizenwallet/modals/wallet/receive_modal.dart';
import 'package:citizenwallet/modals/wallet/send_modal.dart';
import 'package:citizenwallet/modals/wallet/voucher_read_modal.dart';
import 'package:citizenwallet/screens/wallet/wallet_scroll_view.dart';
import 'package:citizenwallet/services/wallet/models/qr/qr.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/share_modal.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/crypto.dart';

class BurnerWalletScreen extends StatefulWidget {
  final String encoded;
  final WalletLogic wallet;
  final String alias;
  final String? voucher;
  final String? voucherParams;

  const BurnerWalletScreen(
    this.encoded,
    this.wallet, {
    super.key,
    this.alias = 'global',
    this.voucher,
    this.voucherParams,
  });

  @override
  BurnerWalletScreenState createState() => BurnerWalletScreenState();
}

class BurnerWalletScreenState extends State<BurnerWalletScreen> {
  // QRWallet? _wallet;

  final ScrollController _scrollController = ScrollController();
  late WalletLogic _logic;
  late ProfileLogic _profileLogic;
  late ProfilesLogic _profilesLogic;
  late VoucherLogic _voucherLogic;

  late String _password;

  @override
  void initState() {
    super.initState();

    _logic = widget.wallet;
    _profileLogic = ProfileLogic(context);
    _profilesLogic = ProfilesLogic(context);
    _voucherLogic = VoucherLogic(context);

    WidgetsBinding.instance.addObserver(_logic);
    WidgetsBinding.instance.addObserver(_profilesLogic);
    WidgetsBinding.instance.addObserver(_voucherLogic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here

      _scrollController.addListener(onScrollUpdate);

      onLoad();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_logic);
    WidgetsBinding.instance.removeObserver(_profilesLogic);
    WidgetsBinding.instance.removeObserver(_voucherLogic);

    _profilesLogic.dispose();
    _voucherLogic.dispose();

    _scrollController.removeListener(onScrollUpdate);

    super.dispose();
  }

  void onScrollUpdate() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
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
      widget.alias,
      () async {
        _profileLogic.loadProfile();
        await _logic.loadTransactions();
        await _voucherLogic.fetchVouchers();
      },
    );

    if (!ok) {
      onLoad(retry: true);
      return;
    }

    if (widget.voucher != null && widget.voucherParams != null) {
      await handleLoadFromVoucher();
    }
  }

  Future<void> handleLoadFromVoucher() async {
    final voucher = widget.voucher;
    final voucherParams = widget.voucherParams;

    if (voucher == null || voucherParams == null) {
      return;
    }

    final navigator = GoRouter.of(context);

    final address = await _voucherLogic.readVoucher(voucher, voucherParams);
    if (address == null) {
      return;
    }

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await CupertinoScaffold.showCupertinoModalBottomSheet<String?>(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (modalContext) => VoucherReadModal(
        address: address,
      ),
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();

    navigator.go('/wallet/${widget.encoded}');
  }

  void handleFailedTransaction(String id) async {
    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

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
      _profilesLogic.resume();
      _voucherLogic.resume();
      return;
    }

    if (option == 'retry') {
      _logic.retryTransaction(id);
    }

    if (option == 'edit') {
      _logic.prepareEditQueuedTransaction(id);

      HapticFeedback.lightImpact();

      await CupertinoScaffold.showCupertinoModalBottomSheet(
        context: context,
        expand: true,
        useRootNavigator: true,
        builder: (_) => SendModal(
          walletLogic: _logic,
          profilesLogic: _profilesLogic,
          id: id,
        ),
      );
    }

    if (option == 'delete') {
      _logic.removeQueuedTransaction(id);
    }

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  Future<void> handleRefresh() async {
    await _logic.loadTransactions();

    HapticFeedback.heavyImpact();
  }

  void handleDisplayWalletQR(BuildContext context) async {
    _logic.updateWalletQR();

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    final wallet = context.read<WalletState>().wallet;

    if (wallet == null) {
      _logic.resumeFetching();
      _profilesLogic.resume();
      _voucherLogic.resume();
      return;
    }

    await CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (modalContext) => ProfileModal(
        account: wallet.account,
      ),
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleDisplayWalletExport(BuildContext context) async {
    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (modalContext) => ShareModal(
        title: 'Share Citizen Wallet',
        copyLabel: '---------',
        onCopyPrivateKey: handleCopyWalletPrivateKey,
      ),
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
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
    _profilesLogic.pause();
    _voucherLogic.pause();

    await CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (_) => ReceiveModal(
        logic: _logic,
      ),
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleSendModal() async {
    HapticFeedback.lightImpact();

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (_) => SendModal(
        walletLogic: _logic,
        profilesLogic: _profilesLogic,
      ),
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
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
    _profilesLogic.pause();
    _voucherLogic.pause();

    await GoRouter.of(context).push(
      '/wallet/${widget.encoded}/transactions/$transactionId',
      extra: {
        'logic': _logic,
        'profilesLogic': _profilesLogic,
      },
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleLoad(String address) async {
    _profilesLogic.loadProfile(address);
    _voucherLogic.updateVoucher(address);
  }

  void handleTestNav() async {
    GoRouter.of(context).go('/?test=1');
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.top;
    final wallet = context.select((WalletState state) => state.wallet);

    final firstLoad = context.select((WalletState state) => state.firstLoad);
    final loading = context.select((WalletState state) => state.loading);

    final imageSmall = context.select((ProfileState state) => state.imageSmall);
    final username = context.select((ProfileState state) => state.username);

    final hasNoProfile = imageSmall == '' && username == '';

    return CupertinoScaffold(
      topRadius: const Radius.circular(40),
      transitionBackgroundColor: ThemeColors.transparent,
      body: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              (firstLoad && loading) || wallet == null
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
                      // handleReceive: handleTestNav,
                      handleTransactionTap: handleTransactionTap,
                      handleFailedTransactionTap: handleFailedTransaction,
                      handleCopyWalletQR: handleCopyAccount,
                      handleLoad: handleLoad,
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
                actionButton: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!firstLoad && wallet != null)
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
                      onPressed: (firstLoad || wallet == null)
                          ? null
                          : () => handleDisplayWalletQR(context),
                      child: wallet == null
                          ? const PulsingContainer(
                              height: 30,
                              width: 30,
                              borderRadius: 15,
                            )
                          : Stack(
                              children: [
                                ProfileCircle(
                                  size: 30,
                                  imageUrl: imageSmall,
                                  borderColor: ThemeColors.subtle,
                                ),
                                if (hasNoProfile)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      height: 10,
                                      width: 10,
                                      decoration: BoxDecoration(
                                        color: ThemeColors.danger
                                            .resolveFrom(context),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
