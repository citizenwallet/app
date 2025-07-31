import 'package:citizenwallet/modals/landing/migration_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class MigrationModalUtils {
  static Future<void> showMigrationModalIfNeeded(BuildContext context) async {
    await showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => const MigrationModal(),
      isDismissible: false,
      enableDrag: false,
    );
  }
} 