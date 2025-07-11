// import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:citizenwallet/modals/account/select_account.dart';
import 'package:citizenwallet/modals/profile/edit.dart';
import 'package:citizenwallet/modals/profile/profile.dart';
import 'package:citizenwallet/router/utils.dart';
import 'package:citizenwallet/screens/wallet/more_actions_sheet.dart';
import 'package:citizenwallet/screens/wallet/wallet_scroll_view.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/engine/events.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/notifications/state.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/state/wallet_connect/logic.dart';
import 'package:citizenwallet/state/wallet_connect/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/qr.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/scanner/scanner_modal.dart';
import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:citizenwallet/widgets/wallet_connect_sessions_modal.dart';
import 'package:citizenwallet/widgets/webview/connected_webview_modal.dart';
import 'package:citizenwallet/widgets/webview/webview_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:citizenwallet/widgets/communities/offline_banner.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'dart:async';

class WalletScreen extends StatefulWidget {
  final WalletLogic wallet;
  final String? address;
  final String? alias;
  final String? voucher;
  final String? voucherParams;
  final String? receiveParams;
  final String? deepLink;
  final String? deepLinkParams;
  final String? sendToURL;

  const WalletScreen(
    this.address,
    this.alias,
    this.wallet, {
    this.voucher,
    this.voucherParams,
    this.receiveParams,
    this.deepLink,
    this.deepLinkParams,
    this.sendToURL,
    super.key,
  });

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  late NotificationsLogic _notificationsLogic;
  late AppLogic _appLogic;
  late WalletLogic _logic;
  late ProfileLogic _profileLogic;
  late ProfilesLogic _profilesLogic;
  late VoucherLogic _voucherLogic;
  final WalletKitLogic _walletKitLogic = WalletKitLogic();

  String? _address;
  String? _alias;
  String? _voucher;
  String? _voucherParams;
  String? _receiveParams;
  String? _deepLink;
  String? _deepLinkParams;
  String? _sendToURL;
  Config? _config;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _address = widget.address;
    _alias = widget.alias;
    _voucher = widget.voucher;
    _voucherParams = widget.voucherParams;
    _receiveParams = widget.receiveParams;
    _deepLink = widget.deepLink;
    _deepLinkParams = widget.deepLinkParams;
    _sendToURL = widget.sendToURL;
    _notificationsLogic = NotificationsLogic(context);
    _appLogic = AppLogic(context);
    _logic = widget.wallet;
    _profileLogic = ProfileLogic(context);
    _profilesLogic = ProfilesLogic(context);
    _voucherLogic = VoucherLogic(context);

    WidgetsBinding.instance.addObserver(_profilesLogic);
    WidgetsBinding.instance.addObserver(_voucherLogic);
    WidgetsBinding.instance.addObserver(_walletKitLogic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    WidgetsBinding.instance.removeObserver(_walletKitLogic);
    WidgetsBinding.instance.removeObserver(this);

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

    _walletKitLogic.setContext(context);

    await _logic.openWallet(
      _address!,
      _alias!,
      (bool hasChanged) async {
        _logic.requestWalletActions();
        await _logic.loadTransactions();

        final online = _logic.isOnline;

        if (hasChanged) _profileLogic.loadProfile(online: online);
        _voucherLogic.fetchVouchers();
        await _profileLogic.loadProfileLink();
        await _logic.evaluateWalletActions();
      },
    );

    try {
      await _walletKitLogic.initialize();
      await _walletKitLogic.registerWallet(_address!);

      await _walletKitLogic.restoreSessions();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing WalletKit: $e');
    }

    _notificationsLogic.init();

    if (_voucher != null && _voucherParams != null) {
      await handleLoadFromVoucher();
    }

    if (_receiveParams != null) {
      await handleSendScreen(receiveParams: _receiveParams);
    }

    if (_sendToURL != null) {
      await handleSendScreen(sendToURL: _sendToURL);
    }

    if (_deepLink != null && _deepLinkParams != null) {
      await handleLoadDeepLink();
    }
  }

  Future<void> handleDisconnect() async {
    try {
      final sessions = _walletKitLogic.connectClient?.getActiveSessions();
      if (sessions != null && sessions.isNotEmpty) {
        if (!mounted) return;

        await showCupertinoModalPopup(
          context: context,
          builder: (context) => WalletConnectSessionsModal(
            onDisconnect: (topic) async {
              await _walletKitLogic.disconnectSession(
                topic: topic,
                reason:
                    Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
              );

              if (mounted) {
                _notificationsLogic.toastShow(
                  'Successfully disconnected from session',
                  type: ToastType.success,
                );

                final remainingSessions =
                    _walletKitLogic.connectClient?.getActiveSessions();
                if (remainingSessions == null || remainingSessions.isEmpty) {
                  Navigator.of(context).pop();
                }

                setState(() {});
              }
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _notificationsLogic.toastShow(
          'Failed to disconnect from session',
          type: ToastType.error,
        );
      }
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
      case 'onboarding':
        break;
      default:
        _profileLogic.pause();
        _profilesLogic.pause();
        _voucherLogic.pause();

        final navigator = GoRouter.of(context);

        await navigator.push('/wallet/$_address/deeplink', extra: {
          'wallet': _logic.wallet,
          'deepLink': deepLink,
          'deepLinkParams': deepLinkParams,
        });

        _profileLogic.resume();
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

    _profileLogic.pause();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await navigator.push('/wallet/$_address/voucher', extra: {
      'address': address,
      'logic': _logic,
    });

    _profileLogic.resume();
    _profilesLogic.resume();
    _voucherLogic.resume();

    navigator.go('/wallet/$_address');
  }

  void handleFailedTransaction(String id, bool blockSending) async {
    _profileLogic.pause();
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
                  child: Text(
                    AppLocalizations.of(context)!.retry,
                    style: TextStyle(
                      color:
                          Theme.of(context).colors.primary.resolveFrom(context),
                    ),
                  ),
                ),
              if (!blockSending)
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(dialogContext).pop('edit');
                  },
                  child: Text(
                    AppLocalizations.of(context)!.edit,
                    style: TextStyle(
                      color:
                          Theme.of(context).colors.primary.resolveFrom(context),
                    ),
                  ),
                ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(dialogContext).pop('delete');
                },
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  color: Theme.of(context).colors.primary.resolveFrom(context),
                ),
              ),
            ),
          );
        });

    if (!super.mounted) {
      return;
    }

    if (option == null) {
      _profileLogic.resume();
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

      final addr = _logic.addressController.value.text;
      if (addr.isEmpty) {
        return;
      }

      _logic.updateAddress(override: true);
      _profilesLogic.getProfile(addr);

      await navigator.push('/wallet/$_address/send/$addr', extra: {
        'walletLogic': _logic,
        'profilesLogic': _profilesLogic,
      });

      _logic.clearInputControllers();
      _profilesLogic.clearSearch(notify: false);
    }

    if (option == 'delete') {
      _logic.removeQueuedTransaction(id);
    }

    _profileLogic.resume();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  Future<void> handleRefresh() async {
    await _logic.loadTransactions();

    HapticFeedback.heavyImpact();
  }

  void handleDisplayWalletQR(BuildContext context) async {
    _logic.updateWalletQR();

    _profileLogic.pause();
    _profilesLogic.pause();
    _voucherLogic.pause();

    final wallet = context.read<WalletState>().wallet;

    if (wallet == null) {
      _profileLogic.resume();
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

    _profileLogic.resume();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  Future<void> handleSendScreen({
    String? receiveParams,
    String? sendToURL,
  }) async {
    HapticFeedback.heavyImpact();

    _profileLogic.pause();
    _profilesLogic.pause();
    _voucherLogic.pause();

    if (receiveParams != null) {
      final hex = await _logic.updateFromCapture(
        '/#/?alias=${_logic.wallet.alias}&receiveParams=$receiveParams',
      );

      if (hex == null) {
        _profileLogic.resume();
        _profilesLogic.resume();
        _voucherLogic.resume();
        return;
      }

      if (!super.mounted) {
        _profileLogic.resume();
        _profilesLogic.resume();
        _voucherLogic.resume();
        return;
      }

      _profilesLogic.getProfile(hex);

      final navigator = GoRouter.of(context);

      await navigator.push('/wallet/$_address/send/$hex', extra: {
        'walletLogic': _logic,
        'profilesLogic': _profilesLogic,
      });

      _logic.clearInputControllers();
      _profilesLogic.clearSearch(notify: false);

      _profileLogic.resume();
      _profilesLogic.resume();
      _voucherLogic.resume();

      return;
    }

    if (!super.mounted) {
      _profileLogic.resume();
      _profilesLogic.resume();
      _voucherLogic.resume();
      return;
    }

    final navigator = GoRouter.of(context);

    await navigator.push('/wallet/$_address/send', extra: {
      'walletLogic': _logic,
      'profilesLogic': _profilesLogic,
      'voucherLogic': _voucherLogic,
      'sendToURL': sendToURL,
    });

    _profileLogic.resume();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleReceive() async {
    HapticFeedback.heavyImpact();

    final navigator = GoRouter.of(context);

    navigator.push('/wallet/$_address/receive', extra: {
      'logic': _logic,
      'profilesLogic': _profilesLogic,
    });
  }

  Future<void> handlePlugin(PluginConfig pluginConfig) async {
    HapticFeedback.heavyImpact();

    final (uri, customScheme, redirect) =
        await _logic.constructPluginUri(pluginConfig);
    if (uri == null || redirect == null) {
      return;
    }

    if (pluginConfig.signature) {
      await showCupertinoModalPopup<String?>(
        context: context,
        barrierDismissible: true,
        builder: (_) => ConnectedWebViewModal(
          modalKey: 'connected-webview',
          url: uri.toString(),
          redirectUrl: "https://app.citizenwallet.xyz",
          walletLogic: _logic,
          profilesLogic: _profilesLogic,
        ),
      );
      return;
    }

    switch (pluginConfig.launchMode) {
      case PluginLaunchMode.webview:
        _profileLogic.pause();
        _profilesLogic.pause();
        _voucherLogic.pause();

        await showCupertinoModalPopup<String?>(
          context: context,
          barrierDismissible: true,
          builder: (_) => WebViewModal(
            modalKey: 'plugin-webview',
            url: uri,
            redirectUrl: redirect,
            customScheme: customScheme,
          ),
        );

        _profileLogic.resume();
        _profilesLogic.resume();
        _voucherLogic.resume();
        break;
      default:
        _logic.launchPluginUrl(uri);
        break;
    }
  }

  void handleProfileEdit() async {
    _profileLogic.pause();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await showCupertinoModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      topRadius: const Radius.circular(40),
      builder: (context) => const EditProfileModal(),
    );

    _profileLogic.resume();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleCards() async {
    HapticFeedback.heavyImpact();

    _profileLogic.pause();
    _profilesLogic.pause();
    _voucherLogic.pause();

    // await CupertinoScaffold.showCupertinoModalBottomSheet(
    //   context: context,
    //   expand: true,
    //   useRootNavigator: true,
    //   builder: (_) => CupertinoScaffold(
    //     topRadius: const Radius.circular(40),
    //     transitionBackgroundColor: Theme.of(context).colors.transparent,
    //     body: CardsScreen(
    //       walletLogic: _logic,
    //     ),
    //   ),
    // );

    await _voucherLogic.fetchVouchers();

    _profileLogic.resume();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  Future<void> handleMint({String? receiveParams}) async {
    HapticFeedback.heavyImpact();

    _profileLogic.pause();
    _profilesLogic.pause();
    _voucherLogic.pause();

    final navigator = GoRouter.of(context);

    await navigator.push('/wallet/$_address/mint', extra: {
      'walletLogic': _logic,
      'profilesLogic': _profilesLogic,
      'voucherLogic': _voucherLogic,
      'receiveParams': receiveParams,
    });

    _profileLogic.resume();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleVouchers() async {
    HapticFeedback.heavyImpact();

    _profileLogic.pause();
    _profilesLogic.pause();
    _voucherLogic.pause();

    final navigator = GoRouter.of(context);

    await navigator.push('/wallet/$_address/vouchers', extra: {
      'walletLogic': _logic,
      'profilesLogic': _profilesLogic,
    });

    await _voucherLogic.fetchVouchers();

    _profileLogic.resume();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleCopy(String value) {
    Clipboard.setData(ClipboardData(text: value));

    HapticFeedback.heavyImpact();
  }

  void handleTransactionTap(String transactionId) async {
    HapticFeedback.lightImpact();

    _profileLogic.pause();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await GoRouter.of(context).push<bool?>(
      '/wallet/${_address!}/transactions/$transactionId',
      extra: {
        'logic': _logic,
        'profilesLogic': _profilesLogic,
      },
    );

    _profileLogic.resume();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleLoad(String address) async {
    _profilesLogic.loadProfile(address);
    _voucherLogic.updateVoucher(address);
  }

  void handleOpenAccountSwitcher() async {
    final navigator = GoRouter.of(context);

    _logic.pauseFetching();

    final args = await navigator
        .push<(String, String)?>('/wallet/${_address!}/accounts?alias=$_alias');

    if (args == null) {
      _logic.resumeFetching();
      return;
    }

    final (address, alias) = args;

    if (address == _address && alias == _alias) {
      _logic.resumeFetching();
      return;
    }

    _profileLogic.pause();
    _logic.pauseFetching();
    _profileLogic.clearProfileLink();
    _profileLogic.resetAll();

    _address = address;
    _alias = alias;

    final newRoute = '/wallet/$address?alias=$alias';

    navigator.replace(newRoute);
  }

  String? paramsAlias(String compressedParams) {
    String params;
    try {
      params = decodeParams(compressedParams);
    } catch (_) {
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
    _profileLogic.pause();
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
      _profileLogic.resume();
      _profilesLogic.resume();
      _voucherLogic.resume();
      return;
    }

    if (result.startsWith('wc:')) {
      try {
        if (_walletKitLogic.connectClient == null) {
          await _walletKitLogic.initialize();
        }

        await _walletKitLogic.registerWallet(_address!);
        await _walletKitLogic.pairWithDapp(result);
        await _walletKitLogic.approveSession();

        _profileLogic.resume();
        _profilesLogic.resume();
        _voucherLogic.resume();
        return;
      } catch (e) {
        _profileLogic.resume();
        _profilesLogic.resume();
        _voucherLogic.resume();
        return;
      }
    }

    final format = parseQRFormat(result);
    if (format == QRFormat.url) {
      final redirectUrl = 'https://app.citizenwallet.xyz';
      final pluginUrl = '$redirectUrl/#/?dl=plugin';
      final connection = _logic.connection;

      String url = '$result?${connection.queryParams}';
      if (result.startsWith(pluginUrl)) {
        final resultUri = Uri.parse(result);
        final uri = Uri.parse(resultUri.fragment);

        final params = uri.queryParameters['plugin'];
        final alias = uri.queryParameters['alias'];
        if (params == null || alias == null) {
          _profileLogic.resume();
          _profilesLogic.resume();
          _voucherLogic.resume();
          return;
        }

        final pluginConfig = await _logic.getPluginConfig(alias, params);
        if (pluginConfig == null) {
          _profileLogic.resume();
          _profilesLogic.resume();
          _voucherLogic.resume();
          return;
        }

        url =
            '${pluginConfig.url}${pluginConfig.url.contains('?') ? '&' : '?'}${connection.queryParams}';
      }

      if (!super.mounted) {
        _profileLogic.resume();
        _profilesLogic.resume();
        _voucherLogic.resume();
        return;
      }

      await showCupertinoModalPopup<String?>(
        context: context,
        barrierDismissible: true,
        builder: (_) => ConnectedWebViewModal(
          modalKey: 'connected-webview',
          url: url,
          redirectUrl: redirectUrl,
          walletLogic: _logic,
          profilesLogic: _profilesLogic,
        ),
      );

      _profileLogic.resume();
      _profilesLogic.resume();
      _voucherLogic.resume();
      return;
    }

    final (voucherParams, receiveParams, deepLinkParams) =
        deepLinkParamsFromUri(result);

    final parsedQRData = parseQRCode(result);

    if (voucherParams == null &&
        receiveParams == null &&
        deepLinkParams == null &&
        parsedQRData.address.isEmpty) {
      _profileLogic.resume();
      _profilesLogic.resume();
      _voucherLogic.resume();
      return;
    }

    String? loadedAddress;
    String? loadedAlias;
    final uriAlias = aliasFromUri(result);
    final receiveAlias = aliasFromReceiveUri(result);

    if (voucherParams != null || receiveParams != null || deepLinkParams != null) {
      final (address, alias) = await handleLoadFromParams(
        voucherParams ?? receiveParams ?? deepLinkParams ?? parsedQRData.alias,
        overrideAlias: uriAlias ?? receiveAlias ?? parsedQRData.alias,
      );
      loadedAddress = address;
      loadedAlias = alias;
    } else {
      loadedAddress = parsedQRData.address;
      loadedAlias = _alias;
    }

    if (loadedAddress == null) {
      _profileLogic.resume();
      _profilesLogic.resume();
      _voucherLogic.resume();
      return;
    }

    if (loadedAlias == null || loadedAlias.isEmpty) {
      _profileLogic.resume();
      _profilesLogic.resume();
      _voucherLogic.resume();
      return;
    }

    final (voucher, deepLink) = deepLinkContentFromUri(result);

    if (loadedAlias != _alias) {
      _address = loadedAddress;
      _alias = loadedAlias;
      _voucher = voucher;
      _voucherParams = voucherParams;
      _receiveParams = receiveParams;
      _deepLink = deepLink;
      _deepLinkParams = deepLinkParams;
      _sendToURL = result;

      onLoad();
      return;
    }

    if (voucher != null && voucherParams != null) {
      await handleLoadFromVoucher(
        voucherOverride: voucher,
        voucherParamsOverride: voucherParams,
      );
      return;
    }

    if (deepLink != null && deepLinkParams != null) {
      await handleLoadDeepLink(
        aliasOverride: loadedAlias,
        deepLinkOverride: deepLink,
        deepLinkParamsOverride: deepLinkParams,
      );
      return;
    }

    await handleSendScreen(sendToURL: result);
  }

  void handleShowMore() async {
    HapticFeedback.heavyImpact();
    final selection =
        await showCupertinoModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      topRadius: const Radius.circular(40),
      builder: (context) => MoreActionsSheet(
        handleSendScreen: handleSendScreen,
        handlePlugin: handlePlugin,
        handleMint: handleMint,
        handleVouchers: handleVouchers,
      ),
    );

    if (selection == null) {
      return;
    }

    final action = selection['action'];
    final pluginConfig = selection['pluginConfig'];

    switch (action) {
      case ActionButtonType.vouchers:
        handleVouchers();
        break;
      case ActionButtonType.minter:
        handleMint();
        break;
      case ActionButtonType.plugins:
        handlePlugin(pluginConfig);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.select((WalletState state) => state.wallet);

    final eventServiceState =
        context.select((WalletState state) => state.eventServiceState);

    final eventServiceIntentionalDisconnect = context
        .select((WalletState state) => state.eventServiceIntentionalDisconnect);

    final isOffline = eventServiceState == EventServiceState.error ||
        eventServiceState == EventServiceState.connecting;

    final showOfflineBanner = isOffline && !eventServiceIntentionalDisconnect;

    final cleaningUp = context.select((WalletState state) => state.cleaningUp);
    final config = context.select((WalletState state) => state.config);
    final hasActiveSessions =
        context.select((WalletConnectState state) => state.hasActiveSessions);

    final isInitialized =
        context.select((WalletConnectState state) => state.isInitialized);

    final scanQrDisabledColor =
        Theme.of(context).colors.primary.withOpacity(0.5);

    return CupertinoPageScaffold(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            WalletScrollView(
              controller: _scrollController,
              handleRefresh: handleRefresh,
              handleProfileEdit: handleProfileEdit,
              handleSendScreen: handleSendScreen,
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
              handleShowMore: handleShowMore,
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
                      Theme.of(context)
                          .colors
                          .uiBackgroundAlt
                          .resolveFrom(context)
                          .withOpacity(0.0),
                      Theme.of(context)
                          .colors
                          .uiBackgroundAlt
                          .resolveFrom(context),
                    ],
                  ),
                ),
              ),
            ),
            // Positioned(
            //   bottom: 60,
            //   left: 0,
            //   right: 0,
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: config?.online == false ? () => () : handleQRScan,
                      child: Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colors
                              .background
                              .resolveFrom(context),
                          borderRadius: BorderRadius.circular(45),
                          border: Border.all(
                            color: config?.online == false
                                ? scanQrDisabledColor
                                : Theme.of(context).colors.surfacePrimary,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colors
                                  .black
                                  .withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 7,
                              offset: const Offset(
                                  0, 5), // changes position of shadow
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.qrcode_viewfinder,
                            size: 60,
                            color: config?.online == false
                                ? scanQrDisabledColor
                                : Theme.of(context).colors.surfacePrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              // isOffline ? 40 : 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: handleScrollToTop,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: isOffline ? 45 : 15,
                    ),
                    // config?.online == false ? 40 : 0),
                    child: Header(
                      transparent: true,
                      color: Theme.of(context).colors.surfacePrimary,
                      title: '',
                      actionButton: Row(
                        children: [
                          cleaningUp || wallet == null
                              ? const PulsingContainer(
                                  height: 24,
                                  width: 24,
                                  borderRadius: 21,
                                )
                              : SizedBox(
                                  width: MediaQuery.of(context).size.width - 32,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      (hasActiveSessions == true &&
                                              isInitialized == true)
                                          ? GestureDetector(
                                              onTap: handleDisconnect,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(20),
                                                child: Icon(
                                                  CupertinoIcons.link,
                                                  size: 24,
                                                  color: Theme.of(context)
                                                      .colors
                                                      .primary
                                                      .resolveFrom(context),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                      GestureDetector(
                                        onTap: handleOpenAccountSwitcher,
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: SvgPicture.asset(
                                            'assets/icons/switch_accounts.svg',
                                            semanticsLabel: 'switch accounts',
                                            height: 24,
                                            width: 24,
                                            colorFilter: ColorFilter.mode(
                                              Theme.of(context)
                                                  .colors
                                                  .primary
                                                  .resolveFrom(context),
                                              BlendMode.srcIn,
                                            ),
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
              ),
            ),
            OfflineBanner(
              communityUrl: config?.community.url ?? '',
              display: isOffline,
              loading: eventServiceState == EventServiceState.connecting,
            ),
          ],
        ),
      ),
    );
  }
}
