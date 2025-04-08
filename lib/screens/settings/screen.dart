import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/state/backup/logic.dart';
import 'package:citizenwallet/state/backup/state.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/notifications/state.dart';
import 'package:citizenwallet/state/theme/logic.dart';
import 'package:citizenwallet/state/theme/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/platform.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/confirm_modal.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/settings/settings_row.dart';
import 'package:citizenwallet/widgets/settings_sub_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final ThemeLogic _themeLogic = ThemeLogic();
  late AppLogic _appLogic;
  late NotificationsLogic _notificationsLogic;
  late BackupLogic _backupLogic;

  final double _kItemExtent = 32.0;

  //int _selectedLanguage = 0;

  bool _protected = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      _appLogic = AppLogic(context);
      _notificationsLogic = NotificationsLogic(context);
      _backupLogic = BackupLogic(context);

      onLoad();
    });
  }

  void onLoad() async {
    _notificationsLogic.checkPushPermissions();

    _backupLogic.checkStatus();
  }

  void onToggleDarkMode(bool enabled) {
    _themeLogic.setDarkMode(enabled);
    HapticFeedback.mediumImpact();
  }

  void handleTogglePushNotifications(bool enabled) {
    _notificationsLogic.togglePushNotifications();
  }

  void onToggleMuted(bool enabled) {
    _appLogic.setMuted(!enabled);
    HapticFeedback.mediumImpact();
  }

  void handleOpenContract(String scanUrl, String address) {
    final Uri url = Uri.parse('$scanUrl/address/$address');

    launchUrl(url, mode: LaunchMode.inAppWebView);
  }

  void handleOpenAbout() {
    GoRouter.of(context).push('/about');
  }

  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        // The Bottom margin is provided to align the popup above the system navigation bar.
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        // Provide a background color for the popup.
        color: CupertinoColors.systemBackground.resolveFrom(context),
        // Use a SafeArea widget to avoid system overlaps.
        child: SafeArea(
          top: false,
          child: child,
        ),
      ),
    );
  }

  void handleLanguage(int selectedLanguage) {
    _showDialog(
      CupertinoPicker(
        magnification: 1.22,
        squeeze: 1.2,
        useMagnifier: true,
        itemExtent: _kItemExtent,
        // This sets the initial item.
        scrollController: FixedExtentScrollController(
          initialItem: selectedLanguage,
        ),
        // This is called when selected item is changed.
        onSelectedItemChanged: (int selectedItem) async {
          _appLogic.setLanguageCode(selectedItem);
        },
        children: List<Widget>.generate(languageOptions.length, (int index) {
          return Center(child: Text(languageOptions[index].name));
        }),
      ),
    );
  }

  void handleOpenBackup() {
    GoRouter.of(context).push('/backup');
  }

  void handleAppleBackup() {
    print('icloud backup');
  }

  void handleAndroidBackup() {
    _backupLogic.backupAndroid(
      handleConfirmReplace: () => showCupertinoModalPopup<bool?>(
        context: context,
        barrierDismissible: true,
        builder: (modalContext) => ConfirmModal(
          title: AppLocalizations.of(context)!.replaceExistingBackup,
          details: [
            AppLocalizations.of(context)!.androidBackupTexlineOne,
            AppLocalizations.of(context)!.androidBackupTexlineTwo,
          ],
          confirmText: AppLocalizations.of(context)!.replace,
        ),
      ),
    );
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
    final navigator = GoRouter.of(context);

    final confirm = await showCupertinoModalPopup<bool?>(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => ConfirmModal(
        title: AppLocalizations.of(context)!.clearDataAndBackups,
        details: [
          AppLocalizations.of(context)!.appResetTexlineOne,
          AppLocalizations.of(context)!.appResetTexlineTwo,
        ],
        confirmText: AppLocalizations.of(context)!.delete,
      ),
    );

    if (confirm == true) {
      await _appLogic.clearDataAndBackups();

      navigator.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.top;
    final darkMode = context.select((ThemeState state) => state.darkMode);
    final muted = context.select((AppState state) => state.muted);

    final push = context.select((NotificationsState state) => state.push);

    final wallet = context.select((WalletState state) => state.wallet);

    final config = context.select((WalletState state) => state.config);

    final packageInfo = context.select((AppState state) => state.packageInfo);

    final protected = _protected;

    final loading = context.select((BackupState state) => state.loading);
    final lastBackup = context.select((BackupState state) => state.lastBackup);
    final e2eEnabled = context.select((BackupState state) => state.e2eEnabled);

    final selectedLanguage =
        context.select((AppState state) => state.selectedLanguage);

    var appText = AppLocalizations.of(context)!.settingsScrApp;

    return CupertinoPageScaffold(
      backgroundColor:
          Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
      child: GestureDetector(
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Text(
                    appText,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // SettingsRow(
                //   label: AppLocalizations.of(context)!.darkMode,
                //   icon: 'assets/icons/dark-mode.svg',
                //   trailing: CupertinoSwitch(
                //     value: darkMode,
                //     onChanged: onToggleDarkMode,
                //   ),
                // ),
                SettingsRow(
                    label: AppLocalizations.of(context)!.language,
                    icon: 'assets/icons/language-svgrepo-com.svg',
                    iconColor:
                        Theme.of(context).colors.text.resolveFrom(context),
                    onTap: () => {handleLanguage(selectedLanguage)},
                    trailing: Row(
                      children: [
                        Text(
                          languageOptions[selectedLanguage].name,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colors
                                .subtleSolidEmphasis
                                .resolveFrom(context),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        )
                      ],
                    )),
                SettingsRow(
                  label: AppLocalizations.of(context)!.about,
                  icon: 'assets/icons/docs.svg',
                  onTap: handleOpenAbout,
                ),
                if (packageInfo != null)
                  SettingsSubRow(AppLocalizations.of(context)!
                      .varsion(packageInfo.version, packageInfo.buildNumber)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Text(
                    AppLocalizations.of(context)!.notifications,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SettingsRow(
                  label: AppLocalizations.of(context)!.pushNotifications,
                  icon: 'assets/icons/notification_bell.svg',
                  trailing: CupertinoSwitch(
                    value: push,
                    onChanged: handleTogglePushNotifications,
                  ),
                ),
                SettingsRow(
                  label: AppLocalizations.of(context)!.inappsounds,
                  icon: 'assets/icons/sound.svg',
                  trailing: CupertinoSwitch(
                    value: !muted,
                    onChanged: onToggleMuted,
                  ),
                ),
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
                //             color: Theme.of(context).colors.secondary),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Text(
                    AppLocalizations.of(context)!.account,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (config != null)
                  SettingsRow(
                    label:
                        AppLocalizations.of(context)!.viewOn(config.scan.name),
                    icon: 'assets/icons/website.svg',
                    onTap: wallet != null
                        ? () =>
                            handleOpenContract(config.scan.url, wallet.account)
                        : null,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Text(
                    AppLocalizations.of(context)!.backup,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPlatformAndroid())
                  SettingsRow(
                    label: AppLocalizations.of(context)!.endToEndEncryption,
                    icon: 'assets/icons/key.svg',
                    subLabel:
                        AppLocalizations.of(context)!.endToEndEncryptionSub,
                    trailing: CupertinoSwitch(
                      value: e2eEnabled,
                      onChanged: null,
                    ),
                  ),
                SettingsRow(
                  label: AppLocalizations.of(context)!.accounts,
                  icon: 'assets/icons/users.svg',
                  subLabel: isPlatformApple()
                      ? AppLocalizations.of(context)!.accountsSubLableOne
                      : lastBackup != null
                          ? AppLocalizations.of(context)!
                              .accountsSubLableLastBackUp(DateFormat.yMMMd()
                                  .add_Hm()
                                  .format(lastBackup.toLocal()))
                          : AppLocalizations.of(context)!
                              .accountsSubLableLastBackUpSecond,
                  trailing: isPlatformApple()
                      ? Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.auto,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colors
                                    .subtleSolidEmphasis
                                    .resolveFrom(context),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Icon(
                              CupertinoIcons.cloud,
                              color: Theme.of(context)
                                  .colors
                                  .surfacePrimary
                                  .resolveFrom(context),
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: loading ? null : handleAndroidBackup,
                          child: Container(
                            decoration: BoxDecoration(
                              color: !loading
                                  ? Theme.of(context)
                                      .colors
                                      .surfacePrimary
                                      .resolveFrom(context)
                                  : Theme.of(context)
                                      .colors
                                      .surfacePrimary
                                      .resolveFrom(context)
                                      .withOpacity(0.7),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.backup,
                                  style: TextStyle(
                                    color: Theme.of(context).colors.white,
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                if (!loading)
                                  Icon(
                                    CupertinoIcons.cloud_upload,
                                    color: Theme.of(context).colors.white,
                                  ),
                                if (loading)
                                  CupertinoActivityIndicator(
                                    color: Theme.of(context)
                                        .colors
                                        .subtle
                                        .resolveFrom(context),
                                  ),
                              ],
                            ),
                          ),
                        ),
                ),
                // SettingsRow( // TODO: implement app data backup
                //   label: 'App data',
                //   icon: isPlatformApple()
                //       ? 'assets/icons/icloud.svg'
                //       : 'assets/icons/drive.svg',
                //   subLabel: lastBackup != null
                //       ? "Your transaction list, vouchers, contacts and other app data that is stored locally. Last backup: ${DateFormat.yMMMd().add_Hm().format(lastBackup.toLocal())}."
                //       : "Your transaction list, vouchers, contacts and other app data that is stored locally.",
                //   trailing: GestureDetector(
                //     onTap: loading
                //         ? null
                //         : isPlatformApple()
                //             ? handleAppleBackup
                //             : handleAndroidBackup,
                //     child: Container(
                //       decoration: BoxDecoration(
                //         color: !loading
                //             ? Theme.of(context).colors.surfacePrimary.resolveFrom(context)
                //             : Theme.of(context).colors.surfacePrimary
                //                 .resolveFrom(context)
                //                 .withOpacity(0.7),
                //         borderRadius: BorderRadius.circular(5),
                //       ),
                //       padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                //       child: Row(
                //         mainAxisAlignment: MainAxisAlignment.center,
                //         crossAxisAlignment: CrossAxisAlignment.center,
                //         children: [
                //           const Text(
                //             'Backup',
                //             style: TextStyle(
                //               color: Theme.of(context).colors.white,
                //             ),
                //           ),
                //           const SizedBox(
                //             width: 10,
                //           ),
                //           if (!loading)
                //             const Icon(
                //               CupertinoIcons.cloud_upload,
                //               color: Theme.of(context).colors.white,
                //             ),
                //           if (loading)
                //             CupertinoActivityIndicator(
                //               color: Theme.of(context).colors.subtle.resolveFrom(context),
                //             ),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
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
                //             color: Theme.of(context).colors.black,
                //           ),
                //         ),
                //         minWidth: 160,
                //         maxWidth: 160,
                //         onPressed: handleLockApp,
                //       ),
                //     ),
                //   ],
                // ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 40, 0, 10),
                  child: Text(
                    AppLocalizations.of(context)!.dangerZone,
                    style: const TextStyle(
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
                        text: AppLocalizations.of(context)!.clearDataAndBackups,
                        minWidth: 220,
                        maxWidth: 220,
                        color: CupertinoColors.systemRed,
                        onPressed: handleAppReset,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 60,
                ),
              ],
            ),
            Header(
              blur: true,
              transparent: true,
              showBackButton: true,
              title: AppLocalizations.of(context)!.settings,
              safePadding: safePadding,
            ),
          ],
        ),
      ),
    );
  }
}
