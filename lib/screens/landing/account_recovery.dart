import 'package:citizenwallet/modals/wallet/community_picker.dart';
import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/backup/logic.dart';
import 'package:citizenwallet/state/backup/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/layouts/info_action.dart';
import 'package:citizenwallet/widgets/scanner/scanner_modal.dart';
import 'package:citizenwallet/widgets/text_input_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

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
      transitionBackgroundColor: ThemeColors.transparent,
      body: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          child: switch (backupStatus) {
            BackupStatus.nobackup => InfoActionLayout(
                title: 'No backup found',
                icon: 'assets/icons/cloud-empty.svg',
                loading: loading,
                primaryActionText: 'Select another account',
                secondaryActionText:
                    'Recover individual account from a private key',
                onPrimaryAction: handleConnectAccount,
                onSecondaryAction: handleImportAccount,
              ),
            _ => InfoActionLayout(
                title: 'Restore all accounts from Google Drive',
                icon: 'assets/icons/drive.svg',
                description:
                    'You will be asked to log in to your Google account. We will only request access to this app\'s folder in your Google Drive.',
                loading: loading,
                primaryActionText: 'Connect your Google Drive Account',
                secondaryActionText:
                    'Recover individual account from a private key',
                onPrimaryAction: handleConnectAccount,
                onSecondaryAction: handleImportAccount,
              ),
          },
        ),
      ),
    );
  }
}
