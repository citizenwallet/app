import 'package:citizenwallet/screens/landing/android_pin_code_modal.dart';
import 'package:citizenwallet/screens/landing/android_recovery_modal.dart';
import 'package:citizenwallet/services/encrypted_preferences/apple.dart';
import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:citizenwallet/state/android_pin_code/state.dart';
import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/platform.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/scanner.dart';
import 'package:citizenwallet/widgets/text_input_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  LandingScreenState createState() => LandingScreenState();
}

class LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AppLogic _appLogic;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      _appLogic = AppLogic(context);

      onLoad();
    });
  }

  void onLoad() async {
    final navigator = GoRouter.of(context);

    await handleAppleRecover();
    await handleAndroidRecover();

    final address = await _appLogic.loadLastWallet();

    if (address == null) {
      return;
    }
    navigator.go('/wallet/${address.toLowerCase()}');
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

    const name = 'New wallet';

    final address = await _appLogic.createWallet(name);

    if (address == null) {
      return;
    }

    navigator.go('/wallet/${address.toLowerCase()}');
  }

  void handleImportWallet() async {
    final navigator = GoRouter.of(context);

    await handleAndroidBackup();

    final result = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Scanner(
        modalKey: 'import-qr-scanner',
        confirm: true,
      ),
    );

    if (result == null) {
      return;
    }

    final name = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => const TextInputModal(
        title: 'Account Name',
        placeholder: 'Enter account name',
      ),
    );

    final address = await _appLogic.importWallet(result, name ?? 'New Account');

    if (address == null) {
      return;
    }

    navigator.go('/wallet/$address');
  }

  @override
  Widget build(BuildContext context) {
    final walletLoading =
        context.select((AppState state) => state.walletLoading);

    return CupertinoPageScaffold(
      backgroundColor: ThemeColors.uiBackground.resolveFrom(context),
      child: SafeArea(
        child: Flex(
          direction: Axis.vertical,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 300,
                              width: 300,
                              child: Center(
                                child: Lottie.asset(
                                  'assets/lottie/chat.json',
                                  height: 300,
                                  width: 300,
                                  animate: true,
                                  repeat: true,
                                  // controller: _controller,
                                ),
                              ),
                            ),
                            Text(
                              'Citizen Wallet',
                              style: TextStyle(
                                color: ThemeColors.text.resolveFrom(context),
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            Text(
                              'The wallet for the rest of us',
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
                    child: walletLoading
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
                              // Button(
                              //   text: 'Import a wallet',
                              //   onPressed: handleImportWallet,
                              //   minWidth: 200,
                              //   maxWidth: 200,
                              // )
                            ],
                          ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
