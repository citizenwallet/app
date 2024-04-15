import 'package:citizenwallet/modals/account/select_account.dart';
import 'package:citizenwallet/modals/wallet/community_picker.dart';
import 'package:citizenwallet/router/utils.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/state/backup/logic.dart';
import 'package:citizenwallet/state/backup/state.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/platform.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/scanner/scanner_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LandingScreen extends StatefulWidget {
  final String? voucher;
  final String? voucherParams;
  final String? webWallet;
  final String? webWalletAlias;
  final String? receiveParams;
  final String? deepLink;
  final String? deepLinkParams;

  const LandingScreen({
    super.key,
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

    if (widget.receiveParams != null) {
      params += '&receiveParams=${widget.receiveParams}';
    }

    if (deepLink != null && widget.deepLinkParams != null) {
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
        widget.webWalletAlias ?? 'app',
      );
    }

    // handle voucher redemption
    // pick an appropriate wallet to load
    if (widget.voucher != null &&
        widget.voucherParams != null &&
        address == null &&
        alias == null) {
      (address, alias) = await handleLoadFromParams(widget.voucherParams);
    }

    // handle voucher redemption
    // pick an appropriate wallet to load
    if (widget.receiveParams != null && address == null && alias == null) {
      (address, alias) = await handleLoadFromParams(widget.receiveParams);
    }

    // handle deep link
    // pick an appropriate wallet to load
    if (widget.deepLink != null && widget.deepLinkParams != null) {
      (address, alias) = await handleLoadFromParams(widget.deepLinkParams);
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
        'alias=${alias ?? 'app'}',
      ],
    );

    _appLogic.appLoaded();

    navigator.go('/wallet/$address$params');
  }

  Future<(String?, String?)> handleLoadFromParams(String? params) async {
    print('params: $params');
    if (params == null) {
      return (null, null);
    }

    final alias = paramsAlias(params);
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

    const alias = "gratitude";

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

  // TODO: remove this
  void handleQRScan() async {
    final navigator = GoRouter.of(context);

    final result = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ScannerModal(
        modalKey: 'import-qr-scanner',
      ),
    );

    print('result: $result');

    if (result == null) {
      return;
    }

    final (voucherParams, receiveParams, deepLinkParams) =
        deepLinkParamsFromUri(result);
    print('voucherParams: $voucherParams');
    print('receiveParams: $receiveParams');
    print('deepLinkParams: $deepLinkParams');
    if (voucherParams == null &&
        receiveParams == null &&
        deepLinkParams == null) {
      return;
    }

    final (address, alias) = await handleLoadFromParams(
        voucherParams ?? receiveParams ?? deepLinkParams);

    print('address: $address');
    print('alias: $alias');

    if (address == null) {
      return;
    }

    if (alias == null || alias.isEmpty) {
      return;
    }

    final (voucher, deepLink) = deepLinkContentFromUri(result);
    print('voucher: $voucher');
    print('deepLink: $deepLink');

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
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width > 600 ? 600.0 : width * 0.8;

    final walletLoading =
        context.select((AppState state) => state.walletLoading);
    final appLoading = context.select((AppState state) => state.appLoading);

    final loading = context.select((BackupState state) => state.loading);
    final backupStatus = context.select((BackupState state) => state.status);

    return CupertinoScaffold(
      topRadius: const Radius.circular(40),
      transitionBackgroundColor: ThemeColors.transparent,
      body: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          child: Flex(
            direction: Axis.vertical,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomScrollView(
                      scrollBehavior: const CupertinoScrollBehavior(),
                      slivers: [
                        SliverFillRemaining(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(height: 40),
                              SizedBox(
                                height: 200,
                                width: 200,
                                child: Center(
                                    child: SvgPicture.asset(
                                  'assets/citizenwallet-only-logo.svg',
                                  semanticsLabel: 'Citizen Wallet Icon',
                                  height: 200,
                                )),
                              ),
                              const SizedBox(height: 30),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: maxWidth,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.welcomeCitizen,
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
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
                                    color:
                                        ThemeColors.text.resolveFrom(context),
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
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              const SizedBox(height: 160),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 20,
                      child: walletLoading || appLoading || loading
                          ? CupertinoActivityIndicator(
                              color: ThemeColors.subtle.resolveFrom(context),
                            )
                          : Column(
                              children: [
                                GestureDetector(
                                  onTap: handleQRScan,
                                  child: Container(
                                    height: 90,
                                    width: 90,
                                    decoration: BoxDecoration(
                                      color: ThemeColors.background
                                          .resolveFrom(context),
                                      borderRadius: BorderRadius.circular(45),
                                      border: Border.all(
                                        color: ThemeColors.primary
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
                                        color: ThemeColors.primary
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
                                      color:
                                          ThemeColors.text.resolveFrom(context),
                                      fontSize: 18,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: maxWidth,
                                  ),
                                  child: Text(
                                    '- ${AppLocalizations.of(context)!.or} -',
                                    style: TextStyle(
                                      color:
                                          ThemeColors.text.resolveFrom(context),
                                      fontSize: 18,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                // Button(
                                //   text: AppLocalizations.of(context)!
                                //       .createNewAccount,
                                //   onPressed: handleStart,
                                //   minWidth: 200,
                                //   maxWidth: 200,
                                // ),
                                if (isPlatformAndroid()) ...[
                                  const SizedBox(height: 30),
                                  Container(
                                    height: 1,
                                    width: 200,
                                    color:
                                        ThemeColors.subtle.resolveFrom(context),
                                  ),
                                  const SizedBox(height: 5),
                                  CupertinoButton(
                                    onPressed: handleRecover,
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .recoverfrombackup,
                                      style: TextStyle(
                                        color: ThemeColors.text
                                            .resolveFrom(context),
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal,
                                        decoration: TextDecoration.underline,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                                if (isPlatformApple()) ...[
                                  const SizedBox(height: 5),
                                  CupertinoButton(
                                    onPressed:
                                        handleStart, // TODO: remove when we auto-top up accounts with Gratitude Token
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
                                              color: ThemeColors.primary
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
                                            color: ThemeColors.primary
                                                .resolveFrom(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // CupertinoButton(
                                  //   onPressed:
                                  //       handleImportWallet, // TODO: remove when we auto-top up accounts with Gratitude Token
                                  //   child: ConstrainedBox(
                                  //     constraints: BoxConstraints(
                                  //       maxWidth: maxWidth,
                                  //     ),
                                  //     child: Text(
                                  //       AppLocalizations.of(context)!
                                  //           .recoverIndividualAccountFromaPrivatekey,
                                  //       style: TextStyle(
                                  //         color: ThemeColors.primary
                                  //             .resolveFrom(context),
                                  //         fontSize: 18,
                                  //         fontWeight: FontWeight.bold,
                                  //       ),
                                  //       maxLines: 2,
                                  //       textAlign: TextAlign.center,
                                  //     ),
                                  //   ),
                                  // ),
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
