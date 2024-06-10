import 'package:citizenwallet/modals/wallet/deep_link.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/deep_link/state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:universal_html/html.dart' as html;

import 'package:citizenwallet/modals/save/save.dart';
import 'package:citizenwallet/modals/onboarding/onboarding.dart';
import 'package:citizenwallet/modals/wallet/voucher_read.dart';
import 'package:citizenwallet/screens/wallet/wallet_scroll_view.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/modals/save/share.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class BurnerWalletScreen extends StatefulWidget {
  final String encoded;
  final WalletLogic wallet;
  String alias = dotenv.get('DEFAULT_COMMUNITY_ALIAS');
  final String? voucher;
  final String? voucherParams;
  final String? receiveParams;
  final String? deepLink;
  final String? deepLinkParams;

  BurnerWalletScreen(
    this.encoded,
    this.wallet, {
    super.key,
    required this.alias,
    this.voucher,
    this.voucherParams,
    this.receiveParams,
    this.deepLink,
    this.deepLinkParams,
  });

  @override
  BurnerWalletScreenState createState() => BurnerWalletScreenState();
}

class BurnerWalletScreenState extends State<BurnerWalletScreen> {
  final PreferencesService _preferences = PreferencesService();

  final ScrollController _scrollController = ScrollController();
  late WalletLogic _logic;
  late ProfileLogic _profileLogic;
  late ProfilesLogic _profilesLogic;
  late VoucherLogic _voucherLogic;

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

  void handleScrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void onLoad({bool? retry}) async {
    final navigator = GoRouter.of(context);
    await delay(const Duration(milliseconds: 350));

    final (ok, stop) = await _logic.openWalletFromURL(
      widget.encoded,
      loadAdditionalData: () async {
        await _profileLogic.loadProfileLink();
        await _logic.loadTransactions();
        await _voucherLogic.fetchVouchers();
      },
      goBackHome: () {
        navigator.go('/');
      },
    );

    if (stop) {
      return;
    }

    if (!ok) {
      onLoad(retry: true);
      return;
    }

    final firstLaunch = _preferences.firstLaunch;

    if (firstLaunch) {
      // await handleOnboarding();
      await _preferences.setFirstLaunch(false);

      // check if ios web
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // we have a wallet, go to the wallet screen
        // (this is a workaround for the native install banner
        navigator.go('/wallet/${widget.encoded}?alias=${widget.alias}');

        // reload the page now that we have a wallet
        // fixes issue with the wrong link being used in native install banners
        html.window.location.reload();
        return;
      }
    }

    if (widget.voucher != null && widget.voucherParams != null) {
      await handleLoadFromVoucher();
    }

    if (widget.receiveParams != null) {
      await handleSendScreen(receiveParams: widget.receiveParams);
    }

    if (widget.deepLink != null && widget.deepLinkParams != null) {
      await handleLoadDeepLink();
    }

    navigator.go('/wallet/${widget.encoded}?alias=${widget.alias}');
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

  Future<void> handlePlugin(PluginConfig pluginConfig) async {
    HapticFeedback.heavyImpact();

    final (uri, _, redirect) = await _logic.constructPluginUri(pluginConfig);
    if (uri == null || redirect == null) {
      return;
    }

    _logic.launchPluginUrl(uri);
  }

  Future<void> handleLoadFromVoucher() async {
    final voucher = widget.voucher;
    final voucherParams = widget.voucherParams;

    if (voucher == null || voucherParams == null) {
      return;
    }

    final address = await _voucherLogic.readVoucher(voucher, voucherParams);
    if (address == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await showCupertinoModalBottomSheet<String?>(
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

      // await showCupertinoModalBottomSheet(
      //   context: context,
      //   expand: true,
      //   useRootNavigator: true,
      //   builder: (_) => SendModal(
      //     walletLogic: _logic,
      //     profilesLogic: _profilesLogic,
      //     id: id,
      //   ),
      // );
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

  Future<void> handleSendScreen({String? receiveParams}) async {
    HapticFeedback.heavyImpact();

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    // await showCupertinoModalBottomSheet<bool?>(
    //   context: context,
    //   expand: true,
    //   useRootNavigator: true,
    //   builder: (_) => SendModal(
    //     walletLogic: _logic,
    //     profilesLogic: _profilesLogic,
    //     receiveParams: receiveParams,
    //   ),
    // );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleReceive() async {
    HapticFeedback.heavyImpact();

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    // await showCupertinoModalBottomSheet(
    //   context: context,
    //   expand: true,
    //   useRootNavigator: true,
    //   builder: (_) => ReceiveModal(
    //     logic: _logic,
    //   ),
    // );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleVouchers() async {
    HapticFeedback.heavyImpact();

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    // await CupertinoScaffold.showCupertinoModalBottomSheet(
    //   context: context,
    //   expand: true,
    //   useRootNavigator: true,
    //   builder: (_) => CupertinoScaffold(
    //     topRadius: const Radius.circular(40),
    //     transitionBackgroundColor: ThemeColors.transparent,
    //     body: const VouchersModal(),
    //   ),
    // );

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

  void handleSaveWallet() async {
    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (modalContext) => const SaveModal(),
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleShareWallet(String walletName) async {
    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (modalContext) => ShareModal(title: 'Share $walletName'),
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  Future<void> handleOnboarding() async {
    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (modalContext) => const OnboardingModal(),
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.top;
    final wallet = context.select((WalletState state) => state.wallet);

    final firstLoad = context.select((WalletState state) => state.firstLoad);
    final loading = context.select((WalletState state) => state.loading);

    final config = context.select((WalletState s) => s.config);

    final walletNamePrefix = config?.token.symbol ?? 'Citizen';

    final walletName = '$walletNamePrefix Wallet';

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
                      handleSendScreen: handleSendScreen,
                      handleReceive: handleReceive,
                      handleVouchers: handleVouchers,
                      handleTransactionTap: handleTransactionTap,
                      handleFailedTransactionTap: handleFailedTransaction,
                      handleCopy: handleCopy,
                      handleLoad: handleLoad,
                      handleScrollToTop: handleScrollToTop,
                    ),
              GestureDetector(
                onTap: handleScrollToTop,
                child: Header(
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
                              walletName,
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
                          padding: const EdgeInsets.fromLTRB(5, 5, 20, 5),
                          onPressed: () => handleShareWallet(walletName),
                          child: SvgPicture.asset(
                            'assets/icons/share.svg',
                            height: 28,
                            width: 28,
                            colorFilter: ColorFilter.mode(
                              ThemeColors.primary.resolveFrom(context),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      if (!firstLoad && wallet != null)
                        CupertinoButton(
                          padding: const EdgeInsets.all(5),
                          onPressed: handleSaveWallet,
                          child: SvgPicture.asset(
                            'assets/icons/bookmark.svg',
                            height: 30,
                            width: 30,
                            colorFilter: ColorFilter.mode(
                              ThemeColors.primary.resolveFrom(context),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
