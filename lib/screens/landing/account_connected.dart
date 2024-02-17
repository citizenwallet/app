import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/backup/logic.dart';
import 'package:citizenwallet/state/backup/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/layouts/info_action.dart';
import 'package:citizenwallet/widgets/text_input_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class AccountConnectedScreen extends StatefulWidget {
  const AccountConnectedScreen({
    super.key,
  });

  @override
  AccountConnectedScreenState createState() => AccountConnectedScreenState();
}

class AccountConnectedScreenState extends State<AccountConnectedScreen>
    with TickerProviderStateMixin {
  late AppLogic _appLogic;
  late BackupLogic _backupLogic;

  @override
  void initState() {
    super.initState();

    _appLogic = AppLogic(context);
    _backupLogic = BackupLogic(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
    });
  }

  void handleGetFromPasswordManager() async {
    final navigator = GoRouter.of(context);

    final (alias, address) = await _backupLogic.decryptFromPasswordManager();
    if (alias == null || address == null) {
      return;
    }

    navigator.go('/wallet/$address?alias=$alias');
  }

  void handleManualEntry() async {
    final navigator = GoRouter.of(context);

    final newKey = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => TextInputModal(
        title: 'Enter encryption key',
        placeholder: 'Encryption key',
        secure: true,
      ),
    );

    if (newKey == null || newKey.isEmpty) {
      return;
    }

    final (alias, address) = await _backupLogic.decryptFromPasswordManager(
      manualKey: newKey,
    );
    if (alias == null || address == null) {
      return;
    }

    navigator.go('/wallet/$address?alias=$alias');
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select((BackupState state) => state.loading);

    final accountName =
        context.select((BackupState state) => state.accountName);
    final lastBackup = context.select((BackupState state) => state.lastBackup);

    final status = context.select((BackupState state) => state.status);
    final error = context.select((BackupState state) => state.error);

    return CupertinoScaffold(
      topRadius: const Radius.circular(40),
      transitionBackgroundColor: ThemeColors.transparent,
      body: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          child: InfoActionLayout(
            title: 'Decrypt backup',
            icon: 'assets/icons/cloud-found.svg',
            descriptionWidget: Column(
              children: [
                Text(
                  'Google Drive account: ',
                  style: TextStyle(
                    color: ThemeColors.text.resolveFrom(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  accountName ?? '',
                  style: TextStyle(
                    color: ThemeColors.text.resolveFrom(context),
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  'Backup date: ',
                  style: TextStyle(
                    color: ThemeColors.text.resolveFrom(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  DateFormat.yMMMd()
                      .add_Hm()
                      .format(lastBackup ?? DateTime.now()),
                  style: TextStyle(
                    color: ThemeColors.text.resolveFrom(context),
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            loading: loading,
            primaryActionErrorText: error && status == BackupStatus.nokey
                ? 'No keys found, try entering manually.'
                : null,
            primaryActionText: 'Get encryption key from your Password Manager',
            secondaryActionErrorText: error && status == BackupStatus.wrongkey
                ? 'Invalid key encryption key.'
                : null,
            secondaryActionText: 'Enter encryption key manually',
            onPrimaryAction: handleGetFromPasswordManager,
            onSecondaryAction: handleManualEntry,
          ),
        ),
      ),
    );
  }
}
