import 'package:citizenwallet/modals/wallet/community_picker.dart';
import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/backup/logic.dart';
import 'package:citizenwallet/state/backup/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/layouts/info_action.dart';
import 'package:citizenwallet/widgets/scanner/scanner_modal.dart';
import 'package:citizenwallet/widgets/text_input_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';

class AccountRecoveryScreen extends StatefulWidget {
  const AccountRecoveryScreen({
    super.key,
  });

  @override
  AccountRecoveryScreenState createState() => AccountRecoveryScreenState();
}

class AccountRecoveryScreenState extends State<AccountRecoveryScreen>
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

      onLoad();
    });
  }

  @override
  void dispose() {
    _backupLogic.resetBackupState();

    super.dispose();
  }

  void onLoad() async {
    final navigator = GoRouter.of(context);

    //

    // navigator.go('/wallet/$address$params');
  }

  void handleConnectAccount() async {
    final navigator = GoRouter.of(context);

    final success = await _backupLogic.connectGoogleDriveAccount();
    if (!success) {
      return;
    }

    navigator.push('/recovery/connected');
  }

  void handleImportAccount() async {
    final navigator = GoRouter.of(context);

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

    navigator.go('/wallet/$address?alias=$alias');
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select((BackupState state) => state.loading);

    final backupStatus = context.select((BackupState state) => state.status);

    return CupertinoScaffold(
      topRadius: const Radius.circular(40),
      transitionBackgroundColor: Theme.of(context).colors.transparent,
      body: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          child: switch (backupStatus) {
            BackupStatus.nobackup => InfoActionLayout(
                title: AppLocalizations.of(context)!.noBackupFound,
                icon: 'assets/icons/cloud-empty.svg',
                loading: loading,
                primaryActionText:
                    AppLocalizations.of(context)!.selectAnotherAccount,
                secondaryActionText:
                    AppLocalizations.of(context)!.recoverIndividualAccount,
                onPrimaryAction: handleConnectAccount,
                onSecondaryAction: handleImportAccount,
              ),
            _ => InfoActionLayout(
                title:
                    AppLocalizations.of(context)!.restoreAllAccountsGoogleDrive,
                icon: 'assets/icons/drive.svg',
                description:
                    AppLocalizations.of(context)!.infoActionLayoutDescription,
                loading: loading,
                primaryActionText:
                    AppLocalizations.of(context)!.connectYourGoogleDriveAccount,
                secondaryActionText: AppLocalizations.of(context)!
                    .recoverIndividualAccountPrivateKey,
                onPrimaryAction: handleConnectAccount,
                onSecondaryAction: handleImportAccount,
              ),
          },
        ),
      ),
    );
  }
}
