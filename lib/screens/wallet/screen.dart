import 'package:citizenwallet/screens/profile/screen.dart';
import 'package:citizenwallet/screens/wallet/receive_modal.dart';
import 'package:citizenwallet/screens/wallet/send_modal.dart';
import 'package:citizenwallet/screens/wallet/switch_wallet_modal.dart';
import 'package:citizenwallet/screens/wallet/wallet_scroll_view.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class WalletScreen extends StatefulWidget {
  final String title = 'Account';
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
    _scrollController.removeListener(onScrollUpdate);

    WidgetsBinding.instance.removeObserver(_logic);

    _logic.dispose();

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

  void onLoad() async {
    if (widget.address == null) {
      return;
    }

    await _logic.openWallet(
      widget.address!,
    );

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

      await CupertinoScaffold.showCupertinoModalBottomSheet(
        context: context,
        expand: true,
        useRootNavigator: true,
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

  void handleSwitchWalletModal(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final navigator = GoRouter.of(context);

    _logic.pauseFetching();

    final address =
        await CupertinoScaffold.showCupertinoModalBottomSheet<String?>(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (modalContext) => SwitchWalletModal(
        logic: _logic,
        currentAddress: widget.address,
      ),
    );

    _logic.resumeFetching();

    if (address == null) {
      return;
    }

    _logic.cleanupWalletService();
    _logic.cleanupWalletState();

    navigator.go('/wallet/${address.toLowerCase()}');
  }

  void handleDisplayWalletQR(BuildContext context) async {
    _logic.updateWalletQR();

    _logic.pauseFetching();

    await CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (modalContext) => ProfileScreen(
        logic: _logic,
      ),
    );

    _logic.resumeFetching();
  }

  void handleReceive() async {
    HapticFeedback.lightImpact();

    _logic.pauseFetching();

    await CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (_) => ReceiveModal(
        logic: _logic,
      ),
    );

    _logic.resumeFetching();
  }

  void handleSendModal() async {
    HapticFeedback.lightImpact();

    _logic.pauseFetching();

    await CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
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
      '/wallet/${widget.address!}/transactions/$transactionId',
      extra: {'logic': _logic},
    );

    _logic.resumeFetching();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.select((WalletState state) => state.wallet);

    final firstLoad = context.select((WalletState state) => state.firstLoad);
    final loading = context.select((WalletState state) => state.loading);

    final transactionSendLoading =
        context.select((WalletState state) => state.transactionSendLoading);

    return GestureDetector(
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
                  handleTransactionTap: handleTransactionTap,
                  handleFailedTransactionTap: handleFailedTransaction,
                  handleCopyWalletQR: handleCopyAccount,
                ),
          SafeArea(
            child: Header(
              transparent: true,
              color: ThemeColors.transparent,
              titleWidget: CupertinoButton(
                padding: const EdgeInsets.all(5),
                onPressed: transactionSendLoading
                    ? null
                    : () => handleSwitchWalletModal(context),
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
                                    wallet?.name ?? 'Account',
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
                        color: transactionSendLoading
                            ? ThemeColors.subtle.resolveFrom(context)
                            : ThemeColors.primary.resolveFrom(context),
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
                    child: const ProfileCircle(
                      size: 30,
                      imageUrl: 'assets/icons/profile.svg',
                      backgroundColor: ThemeColors.white,
                      borderColor: ThemeColors.subtle,
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
