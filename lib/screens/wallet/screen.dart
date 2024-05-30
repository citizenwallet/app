import 'package:citizenwallet/modals/account/select_account.dart';
import 'package:citizenwallet/modals/profile/profile.dart';
import 'package:citizenwallet/modals/wallet/send.dart';
import 'package:citizenwallet/router/utils.dart';
import 'package:citizenwallet/screens/wallet/wallet_scroll_view.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/scanner/scanner_modal.dart';
import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  late AppLogic _appLogic;
  late WalletLogic _logic;
  late ProfileLogic _profileLogic;
  late ProfilesLogic _profilesLogic;
  late VoucherLogic _voucherLogic;

  String? _address;
  String? _alias;
  String? _voucher;
  String? _voucherParams;
  String? _receiveParams;
  String? _deepLink;
  String? _deepLinkParams;

  @override
  void initState() {
    super.initState();

    _address = widget.address;
    _alias = widget.alias;
    _voucher = widget.voucher;
    _voucherParams = widget.voucherParams;
    _receiveParams = widget.receiveParams;
    _deepLink = widget.deepLink;
    _deepLinkParams = widget.deepLinkParams;

    _notificationsLogic = NotificationsLogic(context);
    _appLogic = AppLogic(context);
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
      _address = widget.address;
      _alias = widget.alias;
      _voucher = widget.voucher;
      _voucherParams = widget.voucherParams;
      _receiveParams = widget.receiveParams;
      _deepLink = widget.deepLink;
      _deepLinkParams = widget.deepLinkParams;

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
    if (_address == null || _alias == null) {
      return;
    }

    await _logic.openWallet(
      _address,
      _alias,
      (bool hasChanged) async {
        if (hasChanged) _profileLogic.loadProfile();
        await _profileLogic.loadProfileLink();
        await _logic.loadTransactions();
        await _voucherLogic.fetchVouchers();
      },
    );

    _notificationsLogic.init();

    if (_voucher != null && _voucherParams != null) {
      await handleLoadFromVoucher();
    }

    if (_receiveParams != null) {
      await handleSendModal(receiveParams: _receiveParams);
    }

    if (_deepLink != null && _deepLinkParams != null) {
      await handleLoadDeepLink();
    }
  }

  Future<void> handleLoadDeepLink({
    String? aliasOverride,
    String? deepLinkOverride,
    String? deepLinkParamsOverride,
  }) async {
    final alias = aliasOverride ?? _alias;
    final deepLink = deepLinkOverride ?? _deepLink;
    final deepLinkParams = deepLinkParamsOverride ?? _deepLinkParams;

    if (deepLink == null || deepLinkParams == null || _alias == null) {
      return;
    }

    final params = decodeParams(deepLinkParams);

    if (!super.mounted) {
      return;
    }

    switch (deepLink) {
      case 'plugin':
        final pluginConfig = await _logic.getPluginConfig(alias!, params);
        if (pluginConfig == null) {
          return;
        }
        await handlePlugin(pluginConfig);
        break;
      default:
        _logic.pauseFetching();
        _profilesLogic.pause();
        _voucherLogic.pause();

        final navigator = GoRouter.of(context);

        await navigator.push('/wallet/$_address/deeplink', extra: {
          'wallet': _logic.wallet,
          'deepLink': deepLink,
          'deepLinkParams': deepLinkParams,
        });

        _logic.resumeFetching();
        _profilesLogic.resume();
        _voucherLogic.resume();
        break;
    }
  }

  Future<void> handleLoadFromVoucher({
    String? voucherOverride,
    String? voucherParamsOverride,
  }) async {
    final voucher = voucherOverride ?? _voucher;
    final voucherParams = voucherParamsOverride ?? _voucherParams;

    if (voucher == null || voucherParams == null) {
      return;
    }

    final navigator = GoRouter.of(context);

    final address = await _voucherLogic.readVoucher(voucher, voucherParams);
    if (address == null) {
      return;
    }

    if (!super.mounted) {
      return;
    }

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await navigator.push('/wallet/$_address/voucher', extra: {
      'address': address,
      'logic': _logic,
    });

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();

    navigator.go('/wallet/$_address');
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

    if (!super.mounted) {
      return;
    }

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

      final navigator = GoRouter.of(context);

      await navigator.push('/wallet/$_address/send', extra: {
        'walletLogic': _logic,
        'profilesLogic': _profilesLogic,
        'id': id,
      });
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

    final navigator = GoRouter.of(context);

    await navigator.push('/wallet/$_address/send', extra: {
      'walletLogic': _logic,
      'profilesLogic': _profilesLogic,
      'receiveParams': receiveParams,
    });

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleReceive() async {
    HapticFeedback.heavyImpact();

    final navigator = GoRouter.of(context);

    navigator.push('/wallet/$_address/receive', extra: {
      'logic': _logic,
    });
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

        final navigator = GoRouter.of(context);

        navigator.push('/wallet/$_address/webview', extra: {
          'url': uri,
          'redirectUrl': redirect,
          'customScheme': customScheme,
        });

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

    // await CupertinoScaffold.showCupertinoModalBottomSheet(
    //   context: context,
    //   expand: true,
    //   useRootNavigator: true,
    //   builder: (_) => CupertinoScaffold(
    //     topRadius: const Radius.circular(40),
    //     transitionBackgroundColor: ThemeColors.transparent,
    //     body: CardsScreen(
    //       walletLogic: _logic,
    //     ),
    //   ),
    // );

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

    final navigator = GoRouter.of(context);

    navigator.push('/wallet/$_address/mint', extra: {
      'walletLogic': _logic,
      'profilesLogic': _profilesLogic,
      'receiveParams': receiveParams,
    });

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleVouchers() async {
    HapticFeedback.heavyImpact();

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    final navigator = GoRouter.of(context);

    await navigator.push('/wallet/$_address/vouchers');

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
      '/wallet/${_address!}/transactions/$transactionId',
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

  void handleOpenAccountSwitcher() async {
    final navigator = GoRouter.of(context);

    final newRoute = await navigator
        .push<String>('/wallet/${_address!}/account?alias=$_alias');

    if (newRoute == null) {
      return;
    }

    navigator.replace(newRoute);

    await delay(const Duration(milliseconds: 250));

    onLoad();
  }

  String? paramsAlias(String compressedParams) {
    String params;
    try {
      params = decodeParams(compressedParams);
    } catch (_) {
      // support the old format with compressed params
      params = decompress(compressedParams);
    }

    final uri = Uri(query: params);

    return uri.queryParameters['alias'];
  }

  Future<(String?, String?)> handleLoadFromParams(
    String? params, {
    String? overrideAlias,
  }) async {
    if (params == null) {
      return (null, null);
    }

    String? alias = overrideAlias ?? paramsAlias(params);
    if (alias == null) {
      return (null, null);
    }

    if (alias == _alias) {
      return (_address, alias);
    }

    final wallets = await _appLogic.loadWalletsFromAlias(alias);

    if (wallets.isEmpty) {
      final newAddress = await _appLogic.createWallet(alias);

      return (newAddress, alias);
    }

    if (wallets.length == 1) {
      return (wallets.first.account, alias);
    }

    if (!mounted) return (null, null);
    final selection = await showCupertinoModalBottomSheet<(String?, String?)?>(
      context: context,
      expand: true,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      builder: (modalContext) => SelectAccountModal(
        title: 'Select Account',
        wallets: wallets,
      ),
    );

    if (selection == null || selection.$1 == null || selection.$2 == null) {
      return (null, null);
    }

    return (selection.$1, selection.$2);
  }

  String parseParamsFromWidget({
    List<String> extra = const [],
    String? voucher,
    String? voucherParams,
    String? receiveParams,
    String? deepLink,
    String? deepLinkParams,
  }) {
    String params = '';
    if (voucher != null && voucherParams != null) {
      params += '&voucher=$voucher';
      params += '&params=$voucherParams';
    }

    if (receiveParams != null) {
      params += '&receiveParams=$receiveParams';
    }

    if (deepLink != null && deepLinkParams != null) {
      params += '&dl=$deepLink';
      params += '&$deepLink=$deepLinkParams';
    }

    if (extra.isNotEmpty) {
      params += '&${extra.join('&')}';
    }

    return params.replaceFirst('&', '?');
  }

  void handleQRScan() async {
    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    final result = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ScannerModal(
        modalKey: 'wallet-qr-scanner',
      ),
    );

    if (result == null) {
      _logic.resumeFetching();
      _profilesLogic.resume();
      _voucherLogic.resume();
      return;
    }

    final (voucherParams, receiveParams, deepLinkParams) =
        deepLinkParamsFromUri(result);
    if (voucherParams == null &&
        receiveParams == null &&
        deepLinkParams == null) {
      _logic.resumeFetching();
      _profilesLogic.resume();
      _voucherLogic.resume();
      return;
    }

    final uriAlias = aliasFromUri(result);
    final receiveAlias = aliasFromReceiveUri(result);

    final (address, alias) = await handleLoadFromParams(
      voucherParams ?? receiveParams ?? deepLinkParams,
      overrideAlias: uriAlias ?? receiveAlias,
    );

    if (address == null) {
      _logic.resumeFetching();
      _profilesLogic.resume();
      _voucherLogic.resume();
      return;
    }

    if (alias == null || alias.isEmpty) {
      _logic.resumeFetching();
      _profilesLogic.resume();
      _voucherLogic.resume();
      return;
    }

    final (voucher, deepLink) = deepLinkContentFromUri(result);

    if (alias != _alias) {
      _address = address;
      _alias = alias;
      _voucher = voucher;
      _voucherParams = voucherParams;
      _receiveParams = receiveParams;
      _deepLink = deepLink;
      _deepLinkParams = deepLinkParams;

      onLoad();
      return;
    }

    if (voucher != null && voucherParams != null) {
      await handleLoadFromVoucher(
        voucherOverride: voucher,
        voucherParamsOverride: voucherParams,
      );
    }

    if (receiveParams != null) {
      await handleSendModal(receiveParams: receiveParams);
    }

    if (deepLink != null && deepLinkParams != null) {
      await handleLoadDeepLink(
        aliasOverride: alias,
        deepLinkOverride: deepLink,
        deepLinkParamsOverride: deepLinkParams,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.select((WalletState state) => state.wallet);

    final cleaningUp = context.select((WalletState state) => state.cleaningUp);
    final firstLoad = context.select((WalletState state) => state.firstLoad);
    final loading = context.select((WalletState state) => state.loading);

    final imageSmall = context.select((ProfileState state) => state.imageSmall);
    final username = context.select((ProfileState state) => state.username);

    final hasNoProfile = imageSmall == '' && username == '';

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
                      AppLocalizations.of(context)!.loading,
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
                  handleFailedTransactionTap: handleFailedTransaction,
                  handleCopy: handleCopy,
                  handleLoad: handleLoad,
                  handleScrollToTop: handleScrollToTop,
                ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ThemeColors.uiBackgroundAlt
                        .resolveFrom(context)
                        .withOpacity(0.0),
                    ThemeColors.uiBackgroundAlt.resolveFrom(context),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: handleQRScan,
                  child: Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: ThemeColors.background.resolveFrom(context),
                      borderRadius: BorderRadius.circular(45),
                      border: Border.all(
                        color: ThemeColors.primary.resolveFrom(context),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeColors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 5), // changes position of shadow
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.qrcode_viewfinder,
                        size: 60,
                        color: ThemeColors.primary.resolveFrom(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: handleScrollToTop,
            child: SafeArea(
              child: Header(
                transparent: true,
                color: ThemeColors.transparent,
                title: '',
                actionButton: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    cleaningUp || wallet == null
                        ? const PulsingContainer(
                            height: 42,
                            width: 42,
                            borderRadius: 21,
                          )
                        : Stack(
                            children: [
                              GestureDetector(
                                onTap: handleOpenAccountSwitcher,
                                child: ProfileCircle(
                                  size: 42,
                                  imageUrl: imageSmall,
                                  borderWidth: 2,
                                  borderColor:
                                      ThemeColors.primary.resolveFrom(context),
                                  backgroundColor: ThemeColors.uiBackgroundAlt
                                      .resolveFrom(context),
                                ),
                              ),
                              if (hasNoProfile && !loading)
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
