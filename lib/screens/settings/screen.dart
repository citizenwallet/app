import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/state/backup/logic.dart';
import 'package:citizenwallet/state/backup/state.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/notifications/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
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

class SettingsScreen extends StatefulWidget {
  final String title = 'Settings';

  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  late AppLogic _appLogic;
  late NotificationsLogic _notificationsLogic;
  late BackupLogic _backupLogic;

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
    _appLogic.setDarkMode(enabled);
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
        builder: (modalContext) => const ConfirmModal(
          title: 'Replace existing backup',
          details: [
            'There is already a backup on your Google Drive account from different credentials.',
            'Are you sure you want to replace it?',
          ],
          confirmText: 'Replace',
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
      builder: (modalContext) => const ConfirmModal(
        title: 'Clear data & backups',
        details: [
          'Are you sure you want to delete everything?',
          'This action cannot be undone.',
        ],
        confirmText: 'Delete',
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
    final darkMode = context.select((AppState state) => state.darkMode);
    final muted = context.select((AppState state) => state.muted);

    final push = context.select((NotificationsState state) => state.push);

    final wallet = context.select((WalletState state) => state.wallet);

    final config = context.select((WalletState state) => state.config);

    final packageInfo = context.select((AppState state) => state.packageInfo);

    final protected = _protected;

    final loading = context.select((BackupState state) => state.loading);
    final lastBackup = context.select((BackupState state) => state.lastBackup);
    final e2eEnabled = context.select((BackupState state) => state.e2eEnabled);

    return CupertinoPageScaffold(
      backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
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
                  icon: 'assets/icons/dark-mode.svg',
                  trailing: CupertinoSwitch(
                    value: darkMode,
                    onChanged: onToggleDarkMode,
                  ),
                ),
                SettingsRow(
                  label: 'About',
                  icon: 'assets/icons/docs.svg',
                  onTap: handleOpenAbout,
                ),
                if (packageInfo != null)
                  SettingsSubRow(
                      'Version ${packageInfo.version} (${packageInfo.buildNumber})'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SettingsRow(
                  label: 'Push Notifications',
                  icon: 'assets/icons/notification_bell.svg',
                  trailing: CupertinoSwitch(
                    value: push,
                    onChanged: handleTogglePushNotifications,
                  ),
                ),
                SettingsRow(
                  label: 'In-app sounds',
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
                if (config != null)
                  SettingsRow(
                    label: 'View on ${config.scan.name}',
                    icon: 'assets/icons/website.svg',
                    onTap: wallet != null
                        ? () =>
                            handleOpenContract(config.scan.url, wallet.account)
                        : null,
                  ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Text(
                    'Backup',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPlatformAndroid())
                  SettingsRow(
                    label: 'End-to-end encryption',
                    icon: 'assets/icons/key.svg',
                    subLabel: 'Backups are always end-to-end encrypted.',
                    trailing: CupertinoSwitch(
                      value: e2eEnabled,
                      onChanged: null,
                    ),
                  ),
                SettingsRow(
                  label: 'Accounts',
                  icon: 'assets/icons/users.svg',
                  subLabel: isPlatformApple()
                      ? "All your accounts are automatically backed up to your device's keychain and synced with your iCloud keychain."
                      : lastBackup != null
                          ? "Your accounts are backed up to your Google Drive account. Last backup: ${DateFormat.yMMMd().add_Hm().format(lastBackup.toLocal())}."
                          : "Back up your accounts to your Google Drive account.",
                  trailing: isPlatformApple()
                      ? Row(
                          children: [
                            Text(
                              'auto',
                              style: TextStyle(
                                color: ThemeColors.subtleSolidEmphasis
                                    .resolveFrom(context),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Icon(
                              CupertinoIcons.cloud,
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context),
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: loading ? null : handleAndroidBackup,
                          child: Container(
                            decoration: BoxDecoration(
                              color: !loading
                                  ? ThemeColors.surfacePrimary
                                      .resolveFrom(context)
                                  : ThemeColors.surfacePrimary
                                      .resolveFrom(context)
                                      .withOpacity(0.7),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Backup',
                                  style: TextStyle(
                                    color: ThemeColors.white,
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                if (!loading)
                                  const Icon(
                                    CupertinoIcons.cloud_upload,
                                    color: ThemeColors.white,
                                  ),
                                if (loading)
                                  CupertinoActivityIndicator(
                                    color:
                                        ThemeColors.subtle.resolveFrom(context),
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
                //             ? ThemeColors.surfacePrimary.resolveFrom(context)
                //             : ThemeColors.surfacePrimary
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
                //               color: ThemeColors.white,
                //             ),
                //           ),
                //           const SizedBox(
                //             width: 10,
                //           ),
                //           if (!loading)
                //             const Icon(
                //               CupertinoIcons.cloud_upload,
                //               color: ThemeColors.white,
                //             ),
                //           if (loading)
                //             CupertinoActivityIndicator(
                //               color: ThemeColors.subtle.resolveFrom(context),
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
                const SizedBox(
                  height: 60,
                ),
              ],
            ),
            Header(
              blur: true,
              transparent: true,
              showBackButton: true,
              title: widget.title,
              safePadding: safePadding,
            ),
          ],
        ),
      ),
    );
  }
}
