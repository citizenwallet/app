import 'package:citizenwallet/modals/account/select_account.dart';
import 'package:citizenwallet/modals/wallet/community_picker.dart';
import 'package:citizenwallet/router/utils.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/state/backup/logic.dart';
import 'package:citizenwallet/state/backup/state.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/platform.dart';
import 'package:citizenwallet/widgets/scanner/scanner_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LandingScreen extends StatefulWidget {
  final String uri;
  final String? voucher;
  final String? voucherParams;
  final String? webWallet;
  final String? webWalletAlias;
  final String? receiveParams;
  final String? deepLink;
  final String? deepLinkParams;

  const LandingScreen({
    super.key,
    required this.uri,
    this.voucher,
    this.voucherParams,
    this.webWallet,
    this.webWalletAlias,
    this.receiveParams,
    this.deepLink,
    this.deepLinkParams,
  });

  @override
  LandingScreenState createState() => LandingScreenState();
}

class LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AppLogic _appLogic;
  late VoucherLogic _voucherLogic;
  late BackupLogic _backupLogic;

  final String defaultAlias = dotenv.get('DEFAULT_COMMUNITY_ALIAS');

  @override
  void initState() {
    super.initState();

    _appLogic = AppLogic(context);
    _voucherLogic = VoucherLogic(context);
    _backupLogic = BackupLogic(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here

      onLoad();
    });
  }

  @override
  void didUpdateWidget(LandingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.webWallet != oldWidget.webWallet) {
      onLoad();
    }
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

  void onLoad() async {
    final navigator = GoRouter.of(context);

    _appLogic.loadApp();

    // set up recovery
    await handleAppleRecover();
    await handleAndroidRecover();

    String? address;
    String? alias;

    // load a deep linked wallet from web
    if (widget.webWallet != null) {
      // await handleAndroidBackup();

      (address, alias) = await _appLogic.importWebWallet(
        widget.webWallet!,
        widget.webWalletAlias ?? defaultAlias,
      );
    }

    alias ??= aliasFromUri(widget.uri);
    alias ??= aliasFromReceiveUri(widget.uri);

    // handle voucher redemption
    // pick an appropriate wallet to load
    if (widget.voucher != null &&
        widget.voucherParams != null &&
        address == null) {
      (address, alias) = await handleLoadFromParams(widget.voucherParams,
          overrideAlias: alias);
    }

    // handle receive params
    // pick an appropriate wallet to load
    if (widget.receiveParams != null && address == null) {
      (address, alias) = await handleLoadFromParams(widget.receiveParams,
          overrideAlias: alias);
    }

    // handle deep link
    // pick an appropriate wallet to load
    if (widget.deepLink != null && widget.deepLinkParams != null) {
      (address, alias) = await handleLoadFromParams(widget.deepLinkParams,
          overrideAlias: alias);
    }

    // load the last wallet if there was no deeplink
    if (address == null || alias == null) {
      (address, alias) = await _appLogic.loadLastWallet();
    }

    if (address == null) {
      _appLogic.appLoaded();
      return;
    }

    String params = parseParamsFromWidget(
      voucher: widget.voucher,
      voucherParams: widget.voucherParams,
      receiveParams: widget.receiveParams,
      deepLink: widget.deepLink,
      deepLinkParams: widget.deepLinkParams,
      extra: [
        'alias=${alias ?? defaultAlias}',
      ],
    );

    _appLogic.appLoaded();

    navigator.go('/wallet/$address$params');
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

  /// handleAppleRecover handles the apple recover flow if needed and then returns
  Future<void> handleAppleRecover() async {
    if (!isPlatformApple()) {
      return;
    }

    await _backupLogic.setupApple();
  }

  /// handleAndroidRecover handles the android recovery flow if needed and then returns
  Future<void> handleAndroidRecover() async {
    if (!isPlatformAndroid()) {
      return;
    }

    await _backupLogic.setupAndroid();
  }

  Future<bool> handleAndroidStart() async {
    if (!isPlatformAndroid()) {
      return false;
    }

    await _backupLogic.setupAndroidFromRecovery();

    return _backupLogic.hasAccounts();
  }

  void handleStart() async {
    final navigator = GoRouter.of(context);

    final alias = await showCupertinoModalBottomSheet<String?>(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (modalContext) => const CommunityPickerModal(),
    );

    if (alias == null || alias.isEmpty) {
      return;
    }

    final address = await _appLogic.createWallet(alias);

    if (address == null) {
      return;
    }

    String params = parseParamsFromWidget(extra: [
      'alias=$alias',
    ]);

    navigator.go('/wallet/$address$params');
  }

  void handleRecover() async {
    final navigator = GoRouter.of(context);

    navigator.push('/recovery');
  }

  void handleQRScan() async {
    final navigator = GoRouter.of(context);

    final result = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ScannerModal(
        modalKey: 'import-qr-scanner',
      ),
    );

    if (result == null) {
      return;
    }

    final (voucherParams, receiveParams, deepLinkParams) =
        deepLinkParamsFromUri(result);
    if (voucherParams == null &&
        receiveParams == null &&
        deepLinkParams == null) {
      return;
    }

    final uriAlias = aliasFromUri(result);
    final receiveAlias = aliasFromReceiveUri(result);

    final (address, alias) = await handleLoadFromParams(
      voucherParams ?? receiveParams ?? deepLinkParams,
      overrideAlias: uriAlias ?? receiveAlias,
    );

    if (address == null) {
      return;
    }

    if (alias == null || alias.isEmpty) {
      return;
    }

    final (voucher, deepLink) = deepLinkContentFromUri(result);

    String params = parseParamsFromWidget(
      voucher: voucher,
      voucherParams: voucherParams,
      receiveParams: receiveParams,
      deepLink: deepLink,
      deepLinkParams: deepLinkParams,
      extra: [
        'alias=$alias',
      ],
    );

    navigator.go('/wallet/$address$params');
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    final informationContainerHeight =
        isPlatformApple() ? 600.0 : 812.0; // based on a small device
    final minTopPadding = (height - informationContainerHeight) > 60.0
        ? 60.0
        : (height - informationContainerHeight);

    final width = MediaQuery.of(context).size.width;
    final maxWidth = width > 600 ? 600.0 : width * 0.8;

    final walletLoading =
        context.select((AppState state) => state.walletLoading);
    final appLoading = context.select((AppState state) => state.appLoading);

    final loading = context.select((BackupState state) => state.loading);
    final backupStatus = context.select((BackupState state) => state.status);

    return CupertinoScaffold(
      topRadius: const Radius.circular(40),
      transitionBackgroundColor: Theme.of(context).colors.transparent,
      body: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          child: Flex(
            direction: Axis.vertical,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      top: appLoading ? (height / 2) - 200 : minTopPadding,
                      child: SizedBox(
                        height: 200,
                        width: 200,
                        child: Center(
                            child: SvgPicture.asset(
                          'assets/citizenwallet-only-logo.svg',
                          semanticsLabel: 'Citizen Wallet Icon',
                          height: 200,
                        )),
                      ),
                    ),
                    CustomScrollView(
                      scrollBehavior: const CupertinoScrollBehavior(),
                      slivers: [
                        SliverFillRemaining(
                            child: AnimatedOpacity(
                          opacity: appLoading ? 0 : 1,
                          duration: const Duration(
                            milliseconds: 500,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(height: minTopPadding + 200),
                              const SizedBox(height: 30),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: maxWidth,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.welcomeCitizen,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colors
                                        .text
                                        .resolveFrom(context),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 30),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: maxWidth,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .aWalletForYourCommunity,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colors
                                        .text
                                        .resolveFrom(context),
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 30),
                              if (backupStatus != null)
                                Text(
                                  backupStatus.message,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colors
                                        .text
                                        .resolveFrom(context),
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        )),
                        SliverToBoxAdapter(
                          child: SizedBox(height: minTopPadding),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 20,
                      child: walletLoading || appLoading || loading
                          ? CupertinoActivityIndicator(
                              color: Theme.of(context)
                                  .colors
                                  .subtle
                                  .resolveFrom(context),
                            )
                          : Column(
                              children: [
                                GestureDetector(
                                  onTap: handleQRScan,
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
                                        color: Theme.of(context)
                                            .colors
                                            .primary
                                            .resolveFrom(context),
                                        width: 3,
                                      ),
                                    ),
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 5, 0, 0),
                                    child: Center(
                                      child: Icon(
                                        CupertinoIcons.qrcode_viewfinder,
                                        size: 60,
                                        color: Theme.of(context)
                                            .colors
                                            .primary
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: maxWidth,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .scanFromCommunity,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colors
                                          .text
                                          .resolveFrom(context),
                                      fontSize: 18,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (isPlatformAndroid()) ...[
                                  Container(
                                    height: 1,
                                    width: 200,
                                    color: Theme.of(context)
                                        .colors
                                        .subtle
                                        .resolveFrom(context),
                                  ),
                                  CupertinoButton(
                                    onPressed: handleStart,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: maxWidth,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)!
                                                .browseCommunities,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colors
                                                  .primary
                                                  .resolveFrom(context),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(
                                            width: 10,
                                            height: 44,
                                          ),
                                          Icon(
                                            CupertinoIcons.arrow_right,
                                            color: Theme.of(context)
                                                .colors
                                                .primary
                                                .resolveFrom(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  CupertinoButton(
                                    onPressed: handleRecover,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: maxWidth,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: maxWidth - 40,
                                            ),
                                            child: Text(
                                              AppLocalizations.of(context)!
                                                  .recoverfrombackup,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colors
                                                    .primary
                                                    .resolveFrom(context),
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                            height: 44,
                                          ),
                                          Icon(
                                            CupertinoIcons.arrow_right,
                                            color: Theme.of(context)
                                                .colors
                                                .primary
                                                .resolveFrom(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if (isPlatformApple()) ...[
                                  Container(
                                    height: 1,
                                    width: 200,
                                    color: Theme.of(context)
                                        .colors
                                        .subtle
                                        .resolveFrom(context),
                                  ),
                                  CupertinoButton(
                                    onPressed: handleStart,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: maxWidth,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)!
                                                .browseCommunities,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colors
                                                  .primary
                                                  .resolveFrom(context),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(
                                            width: 10,
                                            height: 44,
                                          ),
                                          Icon(
                                            CupertinoIcons.arrow_right,
                                            color: Theme.of(context)
                                                .colors
                                                .primary
                                                .resolveFrom(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                    )
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
