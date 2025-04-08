import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/backup/logic.dart';
import 'package:citizenwallet/state/backup/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/layouts/info_action.dart';
import 'package:citizenwallet/widgets/text_input_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        title: AppLocalizations.of(context)!.enterEncryptionKey,
        placeholder: AppLocalizations.of(context)!.encryptionKey,
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
      transitionBackgroundColor: Theme.of(context).colors.transparent,
      body: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          child: InfoActionLayout(
            title: AppLocalizations.of(context)!.decryptBackup,
            icon: 'assets/icons/cloud-found.svg',
            descriptionWidget: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.googleDriveAccount,
                  style: TextStyle(
                    color: Theme.of(context).colors.text.resolveFrom(context),
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
                    color: Theme.of(context).colors.text.resolveFrom(context),
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  AppLocalizations.of(context)!.backupDate,
                  style: TextStyle(
                    color: Theme.of(context).colors.text.resolveFrom(context),
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
                    color: Theme.of(context).colors.text.resolveFrom(context),
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            loading: loading,
            primaryActionErrorText: error && status == BackupStatus.nokey
                ? AppLocalizations.of(context)!.noKeysFoundTryManually
                : null,
            primaryActionText: AppLocalizations.of(context)!
                .getEncryptionKeyFromYourPasswordManager,
            secondaryActionErrorText: error && status == BackupStatus.wrongkey
                ? AppLocalizations.of(context)!.invalidKeyEncryptionKey
                : null,
            secondaryActionText:
                AppLocalizations.of(context)!.enterEncryptionKeyManually,
            onPrimaryAction: handleGetFromPasswordManager,
            onSecondaryAction: handleManualEntry,
          ),
        ),
      ),
    );
  }
}
