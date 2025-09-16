import 'package:citizenwallet/modals/landing/migration_modal.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class MigrationModalUtils {
  static Future<void> showMigrationModalIfNeeded(BuildContext context) async {
    final preferences = PreferencesService();
    final appState = context.read<AppState>();

    if (!appState.migrationRequired) {
      return;
    }

    final dismissalCount = preferences.migrationModalDismissalCount;
    if (dismissalCount >= 3) {
      return;
    }

    await showCupertinoModalBottomSheet(
      context: context,
      topRadius: const Radius.circular(40),
      useRootNavigator: true,
      builder: (context) => const MigrationModal(),
      isDismissible: false,
      enableDrag: false,
    );
  }

  static Future<void> showMigrationModal(BuildContext context,
      {bool isWalletScreen = false}) async {
    // Always show the modal when manually triggered from the migrate button
    await showCupertinoModalBottomSheet(
      context: context,
      topRadius: const Radius.circular(40),
      useRootNavigator: true,
      builder: (context) => MigrationModal(isWalletScreen: isWalletScreen),
      isDismissible: false,
      enableDrag: false,
    );
  }
}
