import 'package:citizenwallet/modals/account/select_account.dart';
import 'package:citizenwallet/modals/wallet/community_picker.dart';
import 'package:citizenwallet/modals/wallet/voucher_read.dart';
import 'package:citizenwallet/screens/landing/android_pin_code_modal.dart';
import 'package:citizenwallet/screens/landing/android_recovery_modal.dart';
import 'package:citizenwallet/services/encrypted_preferences/apple.dart';
import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:citizenwallet/state/android_pin_code/state.dart';
import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/platform.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/scanner/scanner_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class LandingScreen extends StatefulWidget {
  final String? voucher;
  final String? voucherParams;
  final String? webWallet;
  final String? webWalletAlias;
  final String? receiveParams;

  const LandingScreen({
    super.key,
    this.voucher,
    this.voucherParams,
    this.webWallet,
    this.webWalletAlias,
    this.receiveParams,
  });

  @override
  LandingScreenState createState() => LandingScreenState();
}

class LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AppLogic _appLogic;
  late VoucherLogic _voucherLogic;

  @override
  void initState() {
    super.initState();

    _appLogic = AppLogic(context);
    _voucherLogic = VoucherLogic(context);

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

  String parseParamsFromWidget({List<String> extra = const []}) {
    String params = '';
    if (widget.voucher != null && widget.voucherParams != null) {
      params += '&voucher=${widget.voucher}';
      params += '&params=${widget.voucherParams}';
    }

    if (widget.receiveParams != null) {
      params += '?receiveParams=${widget.receiveParams}';
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
      await handleAndroidBackup();

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
      (address, alias) = await handleLoadFromVoucher();
    }

    // load the last wallet if there was no deeplink
    if (address == null || alias == null) {
      (address, alias) = await _appLogic.loadLastWallet();
    }

    if (address == null) {
      _appLogic.appLoaded();
      return;
    }

    String params = parseParamsFromWidget(extra: [
      'alias=${alias ?? 'app'}',
    ]);

    _appLogic.appLoaded();

    navigator.go('/wallet/$address$params');
  }

  Future<(String?, String?)> handleLoadFromVoucher() async {
    final voucher = widget.voucher;
    final voucherParams = widget.voucherParams;

    if (voucher == null || voucherParams == null) {
      return (null, null);
    }

    _voucherLogic.pause();

    final alias = _voucherLogic.voucherAlias(voucherParams);
    if (alias == null) {
      _voucherLogic.resume();
      return (null, null);
    }

    final wallets = await _appLogic.loadWalletsFromAlias(alias);

    if (wallets.isEmpty) {
      _voucherLogic.resume();

      final newAddress = await _appLogic.createWallet(alias);

      return (newAddress, alias);
    }

    if (wallets.length == 1) {
      _voucherLogic.resume();
      return (wallets.first.account, alias);
    }

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
      _voucherLogic.resume();
      return (null, null);
    }

    _voucherLogic.resume();
    return (selection.$1, selection.$2);
  }

  /// handleAppleRecover handles the apple recover flow if needed and then returns
  Future<void> handleAppleRecover() async {
    if (!isPlatformApple()) {
      return;
    }

    // on apple devices we can safely init the encrypted preferences without user input
    // icloud keychain manages everything for us
    await getEncryptedPreferencesService().init(
      AppleEncryptedPreferencesOptions(
          groupId: dotenv.get('ENCRYPTED_STORAGE_GROUP_ID')),
    );
  }

  /// handleAndroidRecover handles the android recovery flow if needed and then returns
  Future<void> handleAndroidRecover() async {
    if (!isPlatformAndroid()) {
      return;
    }

    // since shared preferences are backed up by default on android,
    // it should be possible to figure out if there is a backup available
    final isConfigured = _appLogic.androidBackupIsConfigured();
    if (!isConfigured) {
      return;
    }

    // get the pin code stored in android encrypted preferences
    final success = await _appLogic.configureAndroidBackup();
    if (success) {
      return;
    }

    // there is a backup available, ask the user to recover it with their pin code
    await showCupertinoModalPopup<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ChangeNotifierProvider(
        create: (_) => AndroidPinCodeState(),
        child: const AndroidRecoveryModal(),
      ),
    );
  }

  /// handleAndroidBackup handles the android backup flow if needed and then returns
  Future<void> handleAndroidBackup() async {
    if (!isPlatformAndroid()) {
      return;
    }

    // get the pin code stored in android encrypted preferences
    final success = await _appLogic.configureAndroidBackup();
    if (success) {
      return;
    }

    // no backup configured, ask the user to set up a pin code
    await showCupertinoModalPopup<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ChangeNotifierProvider(
        create: (_) => AndroidPinCodeState(),
        child: const AndroidPinCodeModal(),
      ),
    );
  }

  void handleNewWallet() async {
    final navigator = GoRouter.of(context);

    await handleAndroidBackup();

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

  void handleImportWallet() async {
    final navigator = GoRouter.of(context);

    await handleAndroidBackup();

    final result = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ScannerModal(
        modalKey: 'import-qr-scanner',
        confirm: true,
      ),
    );

    if (result == null) {
      return;
    }

    final alias = await showCupertinoModalBottomSheet<String?>(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (modalContext) => const CommunityPickerModal(),
    );

    if (alias == null || alias.isEmpty) {
      return;
    }

    final address = await _appLogic.importWallet(result, alias);

    if (address == null) {
      return;
    }

    String params = parseParamsFromWidget(extra: [
      'alias=$alias',
    ]);

    navigator.go('/wallet/$address$params');
  }

  @override
  Widget build(BuildContext context) {
    final walletLoading =
        context.select((AppState state) => state.walletLoading);
    final appLoading = context.select((AppState state) => state.appLoading);

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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 300,
                                width: 300,
                                child: Center(
                                    child: SvgPicture.asset(
                                  'assets/citizenwallet-logo-simple.svg',
                                  semanticsLabel: 'Citizen Wallet Icon',
                                  height: 300,
                                )),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'A wallet for your community',
                                style: TextStyle(
                                  color: ThemeColors.text.resolveFrom(context),
                                  fontSize: 20,
                                  fontWeight: FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 40,
                      child: walletLoading || appLoading
                          ? CupertinoActivityIndicator(
                              color: ThemeColors.subtle.resolveFrom(context),
                            )
                          : Column(
                              children: [
                                Button(
                                  text: 'New Account',
                                  onPressed: handleNewWallet,
                                  minWidth: 200,
                                  maxWidth: 200,
                                ),
                                const SizedBox(height: 10),
                                CupertinoButton(
                                  onPressed: handleImportWallet,
                                  child: Text(
                                    'Import Account',
                                    style: TextStyle(
                                      color:
                                          ThemeColors.text.resolveFrom(context),
                                      fontSize: 18,
                                      fontWeight: FontWeight.normal,
                                      decoration: TextDecoration.underline,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
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
