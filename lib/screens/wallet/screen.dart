import 'package:citizenwallet/modals/profile/profile.dart';
import 'package:citizenwallet/modals/vouchers/screen.dart';
import 'package:citizenwallet/modals/wallet/deep_link.dart';
import 'package:citizenwallet/modals/wallet/receive.dart';
import 'package:citizenwallet/modals/wallet/send.dart';
import 'package:citizenwallet/modals/wallet/sending.dart';
import 'package:citizenwallet/modals/wallet/voucher_read.dart';
import 'package:citizenwallet/screens/cards/screen.dart';
import 'package:citizenwallet/screens/wallet/wallet_scroll_view.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/deep_link/state.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/webview_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class WalletScreen extends StatefulWidget {
  final WalletLogic wallet;
  final String? address;
  final String? alias;
  final String? voucher;
  final String? voucherParams;
  final String? receiveParams;
  final String? deepLink;
  final String? deepLinkParams;

  const WalletScreen(
    this.address,
    this.alias,
    this.wallet, {
    this.voucher,
    this.voucherParams,
    this.receiveParams,
    this.deepLink,
    this.deepLinkParams,
    super.key,
  });

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  final ScrollController _scrollController = ScrollController();
  late NotificationsLogic _notificationsLogic;
  late WalletLogic _logic;
  late ProfileLogic _profileLogic;
  late ProfilesLogic _profilesLogic;
  late VoucherLogic _voucherLogic;

  @override
  void initState() {
    super.initState();

    _notificationsLogic = NotificationsLogic(context);
    _logic = widget.wallet;
    _profileLogic = ProfileLogic(context);
    _profilesLogic = ProfilesLogic(context);
    _voucherLogic = VoucherLogic(context);

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
    _logic.pauseFetching();

    _scrollController.removeListener(onScrollUpdate);

    WidgetsBinding.instance.removeObserver(_profilesLogic);
    WidgetsBinding.instance.removeObserver(_voucherLogic);

    _profilesLogic.dispose();
    _voucherLogic.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(WalletScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.address != widget.address) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onLoad();
      });
    }
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

  void handleScrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void onLoad() async {
    if (widget.address == null || widget.alias == null) {
      return;
    }

    await _logic.openWallet(
      widget.address,
      widget.alias,
      (bool hasChanged) async {
        if (hasChanged) _profileLogic.loadProfile();
        await _profileLogic.loadProfileLink();
        await _logic.loadTransactions();
        await _voucherLogic.fetchVouchers();
      },
    );

    _notificationsLogic.init();

    if (widget.voucher != null && widget.voucherParams != null) {
      await handleLoadFromVoucher();
    }

    if (widget.receiveParams != null) {
      await handleSendModal(receiveParams: widget.receiveParams);
    }

    if (widget.deepLink != null && widget.deepLinkParams != null) {
      await handleLoadDeepLink();
    }
  }

  Future<void> handleLoadDeepLink() async {
    final deepLink = widget.deepLink;
    final deepLinkParams = widget.deepLinkParams;

    if (deepLink == null || deepLinkParams == null || widget.alias == null) {
      return;
    }

    final params = decodeParams(deepLinkParams);

    switch (deepLink) {
      case 'plugin':
        final pluginConfig =
            await _logic.getPluginConfig(widget.alias!, params);
        if (pluginConfig == null) {
          return;
        }
        await handlePlugin(pluginConfig);
        break;
      default:
        _logic.pauseFetching();
        _profilesLogic.pause();
        _voucherLogic.pause();

        await CupertinoScaffold.showCupertinoModalBottomSheet<String?>(
          context: context,
          expand: true,
          useRootNavigator: true,
          builder: (modalContext) => ChangeNotifierProvider(
            create: (_) => DeepLinkState(deepLink),
            child: DeepLinkModal(
              wallet: _logic.wallet,
              deepLink: deepLink,
              deepLinkParams: params,
            ),
          ),
        );

        _logic.resumeFetching();
        _profilesLogic.resume();
        _voucherLogic.resume();
        break;
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
        logic: _logic,
      ),
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();

    navigator.go('/wallet/${widget.address}');
  }

  void handleFailedTransaction(String id, bool blockSending) async {
    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    final option = await showCupertinoModalPopup<String?>(
        context: context,
        builder: (BuildContext dialogContext) {
          return CupertinoActionSheet(
            actions: [
              if (!blockSending)
                CupertinoActionSheetAction(
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.of(dialogContext).pop('retry');
                  },
                  child: const Text('Retry'),
                ),
              if (!blockSending)
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
    // temporarily disabled until we move the account screen back
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
        readonly: true,
        keepLink: true,
      ),
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  Future<void> handleSendModal({String? receiveParams}) async {
    HapticFeedback.heavyImpact();

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await CupertinoScaffold.showCupertinoModalBottomSheet<bool?>(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (_) => SendModal(
        walletLogic: _logic,
        profilesLogic: _profilesLogic,
        receiveParams: receiveParams,
      ),
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleReceive() async {
    HapticFeedback.heavyImpact();

    await CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (_) => ReceiveModal(
        logic: _logic,
      ),
    );
  }

  Future<void> handlePlugin(PluginConfig pluginConfig) async {
    HapticFeedback.heavyImpact();

    final (uri, customScheme, redirect) =
        await _logic.constructPluginUri(pluginConfig);
    if (uri == null || redirect == null) {
      return;
    }

    switch (pluginConfig.launchMode) {
      case PluginLaunchMode.webview:
        _logic.pauseFetching();
        _profilesLogic.pause();
        _voucherLogic.pause();

        await CupertinoScaffold.showCupertinoModalBottomSheet(
          context: context,
          expand: true,
          useRootNavigator: true,
          builder: (_) => WebViewModal(
            url: uri,
            redirectUrl: redirect,
            customScheme: customScheme,
          ),
        );

        _logic.resumeFetching();
        _profilesLogic.resume();
        _voucherLogic.resume();
        break;
      default:
        _logic.launchPluginUrl(uri);
        break;
    }
  }

  void handleCards() async {
    HapticFeedback.heavyImpact();

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (_) => CupertinoScaffold(
        topRadius: const Radius.circular(40),
        transitionBackgroundColor: ThemeColors.transparent,
        body: CardsScreen(
          walletLogic: _logic,
        ),
      ),
    );

    await _voucherLogic.fetchVouchers();

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  Future<void> handleMint({String? receiveParams}) async {
    HapticFeedback.heavyImpact();

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await CupertinoScaffold.showCupertinoModalBottomSheet<bool?>(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (_) => SendModal(
        walletLogic: _logic,
        profilesLogic: _profilesLogic,
        receiveParams: receiveParams,
        isMinting: true,
      ),
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleVouchers() async {
    HapticFeedback.heavyImpact();

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (_) => CupertinoScaffold(
        topRadius: const Radius.circular(40),
        transitionBackgroundColor: ThemeColors.transparent,
        body: const VouchersModal(),
      ),
    );

    await _voucherLogic.fetchVouchers();

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleCopy(String value) {
    Clipboard.setData(ClipboardData(text: value));

    HapticFeedback.heavyImpact();
  }

  void handleTransactionTap(String transactionId) async {
    HapticFeedback.lightImpact();

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await GoRouter.of(context).push<bool?>(
      '/wallet/${widget.address!}/transactions/$transactionId',
      extra: {
        'logic': _logic,
        'profilesLogic': _profilesLogic,
      },
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleTransactionSendingTap() async {
    CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (_) => const SendingModal(),
    );
  }

  void handleLoad(String address) async {
    _profilesLogic.loadProfile(address);
    _voucherLogic.updateVoucher(address);
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.select((WalletState state) => state.wallet);

    final blockSending = context.select(selectShouldBlockSending);

    final cleaningUp = context.select((WalletState state) => state.cleaningUp);
    final firstLoad = context.select((WalletState state) => state.firstLoad);
    final loading = context.select((WalletState state) => state.loading);

    final config = context.select((WalletState s) => s.config);

    final walletNamePrefix = config?.token.symbol ?? 'Citizen';

    final walletName = wallet?.name ?? '$walletNamePrefix Wallet';

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          (firstLoad && loading) || wallet == null || cleaningUp
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
                  handlePlugin: handlePlugin,
                  handleCards: handleCards,
                  handleMint: handleMint,
                  handleVouchers: handleVouchers,
                  handleTransactionTap: handleTransactionTap,
                  handleTransactionSendingTap: handleTransactionSendingTap,
                  handleFailedTransactionTap: handleFailedTransaction,
                  handleCopy: handleCopy,
                  handleLoad: handleLoad,
                  handleScrollToTop: handleScrollToTop,
                ),
          GestureDetector(
            onTap: handleScrollToTop,
            child: Container(
              color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
              child: SafeArea(
                child: Header(
                  transparent: true,
                  color: ThemeColors.transparent,
                  title: walletName,
                  actionButton: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!blockSending)
                        CupertinoButton(
                          padding: const EdgeInsets.all(5),
                          onPressed: (firstLoad || wallet == null)
                              ? null
                              : handleSendModal,
                          child: Icon(
                            CupertinoIcons.qrcode,
                            color: ThemeColors.primary.resolveFrom(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
