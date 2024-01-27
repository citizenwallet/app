import 'package:citizenwallet/services/backup/backup.dart';
import 'package:citizenwallet/services/credentials/credentials.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/state/backup/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class BackupLogic {
  final BackupState _state;
  final CredentialsServiceInterface _credentials = getCredentialsService();

  final AccountsDBService _accountsDB = AccountsDBService();

  BackupLogic(BuildContext context) : _state = context.read<BackupState>();

  Future<void> backupAndroid() async {
    try {
      _state.backupRequest();

      final BackupServiceInterface backupService = getBackupService();

      final username = await backupService.init();

      await _credentials.setup(username: username);

      await backupService.upload(
        _accountsDB.path,
        _accountsDB.name,
      );

      _state.backupSuccess(DateTime.now());
    } catch (exception, stackTrace) {
      print(exception);
      print(stackTrace);
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );

      _state.backupError();
    }
  }
}
