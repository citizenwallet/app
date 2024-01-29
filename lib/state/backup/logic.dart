import 'package:citizenwallet/services/accounts/accounts.dart';
import 'package:citizenwallet/services/accounts/options.dart';
import 'package:citizenwallet/services/backup/backup.dart';
import 'package:citizenwallet/services/credentials/credentials.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/state/backup/state.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/notifications/state.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class BackupLogic {
  final BackupState _state;
  final CredentialsServiceInterface _credentials = getCredentialsService();
  final AccountsServiceInterface _accounts = getAccountsService();
  final PreferencesService _preferences = PreferencesService();
  final NotificationsLogic _notifications;

  final AccountsDBService _accountsDB = AccountsDBService();

  BackupLogic(
    BuildContext context,
  )   : _state = context.read<BackupState>(),
        _notifications = NotificationsLogic(context);

  Future<void> setupAndroid() async {
    try {
      await _accountsDB.init('accounts');

      await _accounts.init(AndroidAccountsOptions(
        accountsDB: AccountsDBService(),
      ));
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> setupApple() async {
    try {
      await _accountsDB.init('accounts');

      // on apple devices we can safely init the encrypted preferences without user input
      // icloud keychain manages everything for us
      await getAccountsService().init(
        AppleAccountsOptions(
          groupId: dotenv.get('ENCRYPTED_STORAGE_GROUP_ID'),
          accountsDB: AccountsDBService(),
        ),
      );
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> hasAccounts() async {
    try {
      _state.checkRecoverRequest();
      await _accountsDB.init('accounts');

      // get all local accounts
      final accounts = await _accountsDB.accounts.all();

      _state.checkRecoverSuccess();

      return accounts.isNotEmpty;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.checkRecoverError();

    return false;
  }

  /// This is intended to run on first launch.
  ///
  /// It will try to recover the accounts from the backup
  /// and replace the local db with the backup.
  Future<void> setupAndroidFromRecovery() async {
    try {
      _state.backupRequest();
      _state.setStatus(BackupStatus.account);

      final BackupServiceInterface backupService = getBackupService();

      // instantiate the backup service, this will trigger a login
      final username = await backupService.init();

      _state.setStatus(BackupStatus.e2e);

      // set up the credentials service for e2e
      await _credentials.setup(username: username);

      _state.setStatus(BackupStatus.restore);

      // this will downlaod, decrypt and replace any current db in place
      await backupService.download(
        _accountsDB.name,
        _accountsDB.path,
      );

      // TODO: download app data as well
      // final accounts = await _accountsDB.accounts.all();

      // for (final account in accounts) {

      // }

      _state.setStatus(BackupStatus.success);

      // instantiate the db again
      await _accountsDB.init('accounts');

      final backupTime = DateTime.now();

      // set the last backup time
      await _preferences.setLastBackupTime(backupTime.toIso8601String());

      _state.backupSuccess(backupTime);

      // see if there are wallets that were recovered
      final accounts = await _accountsDB.accounts.all();
      if (accounts.isEmpty) {
        return;
      }

      // set up the first wallet as the default, this will allow the app to start normally
      _preferences.setLastAlias(accounts.first.alias);
      _preferences.setLastWallet(accounts.first.address.hexEip55);
    } on BackupNotFoundException {
      _state.setStatus(BackupStatus.nobackup);
      _state.backupError();
    } on SecretBoxAuthenticationError {
      // handle wrong encryption key
      _notifications.toastShow(
        'Unable to recover backup: invalid decryption key.',
        type: ToastType.error,
      );
    } catch (exception, stackTrace) {
      _notifications.toastShow(
        'Unable to recover backup.',
        type: ToastType.error,
      );

      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );

      _state.backupError();
    }
  }

  Future<void> backupAndroid() async {
    try {
      _state.backupRequest();

      final BackupServiceInterface backupService = getBackupService();

      final username = await backupService.init();

      await _credentials.setup(username: username);

      // this will upload, encrypt and replace any current backup in place
      await backupService.upload(
        _accountsDB.path,
        _accountsDB.name,
      );

      // TODO: upload app data as well
      // final accounts = await _accountsDB.accounts.all();

      // for (final account in accounts) {

      // }

      final backupTime = DateTime.now();

      await _preferences.setLastBackupTime(backupTime.toIso8601String());

      _state.backupSuccess(backupTime);
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );

      _state.backupError();
    }
  }

  Future<void> checkE2E() async {
    try {
      final isSetup = await _credentials.isSetup();

      _state.setE2E(isSetup);
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );

      _state.setE2E(false);
    }
  }
}
