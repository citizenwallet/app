import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/settings_row.dart';
import 'package:citizenwallet/widgets/settings_sub_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  final String title = 'Settings';
  final String scanUrl = dotenv.get('SCAN_URL');
  final String scanName = dotenv.get('SCAN_NAME');

  SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  late AppLogic _appLogic;

  bool _protected = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      _appLogic = AppLogic(context);
    });
  }

  void onToggleDarkMode(bool enabled) {
    _appLogic.setDarkMode(enabled);
    HapticFeedback.mediumImpact();
  }

  void handleOpenContract(String address) {
    final Uri url = Uri.parse('${widget.scanUrl}/address/$address');

    launchUrl(url, mode: LaunchMode.inAppWebView);
  }

  void handleOpenAbout() {
    GoRouter.of(context).push('/about');
  }

  void handleToggleProtection(bool enabled) {
    setState(() {
      _protected = enabled;
    });
  }

  void handleLockApp() {
    print('lock');
  }

  void handleAppReset() async {
    print('reset');
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.top;
    final darkMode = context.select((AppState state) => state.darkMode);

    final wallet = context.select((WalletState state) => state.wallet);

    final packageInfo = context.select((AppState state) => state.packageInfo);

    final protected = _protected;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          ListView(
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
            children: [
              SizedBox(
                height: 60 + safePadding,
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Text(
                  'App',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SettingsRow(
                label: 'Dark mode',
                trailing: CupertinoSwitch(
                  value: darkMode,
                  onChanged: onToggleDarkMode,
                ),
              ),
              SettingsRow(
                label: 'About',
                onTap: handleOpenAbout,
              ),
              if (packageInfo != null)
                SettingsSubRow(
                    'Version ${packageInfo.version} (${packageInfo.buildNumber})'),
              // const Padding(
              //   padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
              //   child: Text(
              //     'Security',
              //     style: TextStyle(
              //       fontSize: 22,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
              // SettingsRow(
              //   label: 'App protection',
              //   subLabel:
              //       !protected ? 'We recommend enabling app protection.' : null,
              //   trailing: Row(
              //     children: [
              //       if (!protected)
              //         const Icon(CupertinoIcons.exclamationmark_triangle,
              //             color: ThemeColors.secondary),
              //       if (!protected) const SizedBox(width: 5),
              //       CupertinoSwitch(
              //         value: protected,
              //         onChanged: handleToggleProtection,
              //       ),
              //     ],
              //   ),
              // ),
              // if (protected)
              //   SettingsRow(
              //     label: 'Automatic lock',
              //     subLabel:
              //         'Automatically locks the app whenever it is closed.',
              //     trailing: CupertinoSwitch(
              //       value: false,
              //       onChanged: onToggleDarkMode,
              //     ),
              //   ),
              // if (protected)
              //   SettingsRow(
              //     label: 'On send',
              //     subLabel: 'Ask for authentication every time you send.',
              //     trailing: CupertinoSwitch(
              //       value: false,
              //       onChanged: onToggleDarkMode,
              //     ),
              //   ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SettingsRow(
                label: 'View on ${widget.scanName}',
                onTap: wallet != null
                    ? () => handleOpenContract(wallet.account)
                    : null,
              ),
              SettingsRow(
                label: 'Wallets',
                subLabel:
                    "All your wallets are automatically backed up to your device's keychain and synced to the cloud.",
                trailing: Icon(
                  CupertinoIcons.cloud,
                  color: ThemeColors.subtleEmphasis.resolveFrom(context),
                ),
              ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Padding(
              //       padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
              //       child: Button(
              //         text: 'Lock app',
              //         suffix: const Padding(
              //           padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
              //           child: Icon(
              //             CupertinoIcons.lock,
              //             color: ThemeColors.black,
              //           ),
              //         ),
              //         minWidth: 160,
              //         maxWidth: 160,
              //         onPressed: handleLockApp,
              //       ),
              //     ),
              //   ],
              // ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 40, 0, 10),
                child: Text(
                  'Danger Zone',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
                    child: Button(
                      text: 'Clear data & backups',
                      minWidth: 220,
                      maxWidth: 220,
                      color: CupertinoColors.systemRed,
                      onPressed: handleAppReset,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Header(
            blur: true,
            transparent: true,
            title: widget.title,
          ),
        ],
      ),
    );
  }
}
