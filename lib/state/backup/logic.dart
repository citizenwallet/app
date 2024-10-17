import 'package:citizenwallet/services/accounts/accounts.dart';
import 'package:citizenwallet/services/accounts/options.dart';
import 'package:citizenwallet/services/backup/backup.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/config/service.dart';
import 'package:citizenwallet/services/credentials/credentials.dart';
import 'package:citizenwallet/services/db/app/db.dart';
import 'package:citizenwallet/services/db/backup/db.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/state/backup/state.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/notifications/state.dart';
import 'package:citizenwallet/state/theme/logic.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

class BackupLogic {
  final BackupState _state;
  final ThemeLogic _theme = ThemeLogic();
  final CredentialsServiceInterface _credentials = getCredentialsService();
  final AccountsServiceInterface _accounts = getAccountsService();
  final PreferencesService _preferences = PreferencesService();
  final NotificationsLogic _notifications;
  final ConfigService _config = ConfigService();
  final AppDBService _appDBService = AppDBService();

  final AccountBackupDBService _accountsDB = AccountBackupDBService();

  BackupLogic(
    BuildContext context,
  )   : _state = context.read<BackupState>(),
        _notifications = NotificationsLogic(context);

  Future<void> setupAndroid() async {
    try {
      await _accountsDB.init('accounts');

      await _accounts.init(AndroidAccountsOptions(
        accountsDB: AccountBackupDBService(),
      ));
    } catch (_) {}
  }

  Future<void> setupApple() async {
    try {
      await _accountsDB.init('accounts');

      // on apple devices we can safely init the encrypted preferences without user input
      // icloud keychain manages everything for us
      await getAccountsService().init(
        AppleAccountsOptions(
          groupId: dotenv.get('ENCRYPTED_STORAGE_GROUP_ID'),
          accountsDB: AccountBackupDBService(),
        ),
      );
    } catch (_) {}
  }

  Future<bool> hasAccounts() async {
    try {
      _state.checkRecoverRequest();
      await _accountsDB.init('accounts');

      // get all local accounts
      final accounts = await _accountsDB.accounts.all();

      _state.checkRecoverSuccess();

      return accounts.isNotEmpty;
    } catch (_) {}

    _state.checkRecoverError();

    return false;
  }

  Future<bool> connectGoogleDriveAccount() async {
    try {
      _state.backupRequest();

      final BackupServiceInterface backupService = getBackupService();

      final username = await backupService.init();

      assert(username != null);

      final (_, lastBackup) =
          await backupService.backupExists(_accountsDB.name);

      if (lastBackup == null) {
        throw BackupNotFoundException();
      }

      // set the last backup time
      await _preferences.setLastBackupTime(lastBackup.toIso8601String());
      //set the last backup name
      await _preferences.setLastBackupName(username!);

      _state.backupSuccess(lastBackup, username);

      return true;
    } on BackupNotFoundException {
      _state.setStatus(BackupStatus.nobackup);
    } catch (_) {}

    _state.backupError();

    return false;
  }

  Future<(String?, String?)> decryptFromPasswordManager({
    String? manualKey,
  }) async {
    try {
      _state.decryptRequest();

      await delay(const Duration(milliseconds: 500));

      final BackupServiceInterface backupService = getBackupService();

      String? username;
      if (manualKey != null) {
        username = await backupService.init();

        await _credentials.manualSetup(
          username: username,
          manualKey: manualKey,
          saveKey: false,
        );

        final isSetup = await _credentials.isSetup();

        assert(isSetup);

        _state.setStatus(BackupStatus.restore);

        assert(username != null);

        // this will downlaod, decrypt and replace any current db in place
        await backupService.download(
          _accountsDB.name,
          _accountsDB.path,
        );

        await _credentials.manualSetup(
          username: username,
          manualKey: manualKey,
          saveKey: true,
        );

        _state.setStatus(BackupStatus.success);
      } else {
        await _credentials.setup(createKeyIfMissing: false);

        final isSetup = await _credentials.isSetup();

        assert(isSetup);

        username = await backupService.init();

        _state.setStatus(BackupStatus.restore);

        assert(username != null);

        // this will downlaod, decrypt and replace any current db in place
        await backupService.download(
          _accountsDB.name,
          _accountsDB.path,
        );

        _state.setStatus(BackupStatus.success);
      }

      // instantiate the db again
      await _accountsDB.init('accounts');

      final backupTime = DateTime.now();

      // set the last backup time
      await _preferences.setLastBackupTime(backupTime.toIso8601String());

      // see if there are wallets that were recovered
      final accounts = await _accountsDB.accounts.all();

      assert(accounts.isNotEmpty);

      // final config = await _config.getConfig(accounts.first.alias);

      final community = await _appDBService.communities.get(accounts.first.alias);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);

      _theme.changeTheme(communityConfig.community.theme);

      // set up the first wallet as the default, this will allow the app to start normally
      _preferences.setLastAlias(accounts.first.alias);
      _preferences.setLastWallet(accounts.first.address.hexEip55);

      _state.decryptSuccess(backupTime, username);

      return (
        accounts.first.alias,
        accounts.first.address.hexEip55,
      );
    } on SourceMissingException {
      _state.decryptError(status: BackupStatus.nokey);
      return (null, null);
    } catch (_) {
      if (manualKey != null) {
        _state.decryptError(status: BackupStatus.wrongkey);
      } else {
        _state.decryptError();
      }
    }

    return (null, null);
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

      _state.backupSuccess(backupTime, username);

      // see if there are wallets that were recovered
      final accounts = await _accountsDB.accounts.all();
      if (accounts.isEmpty) {
        return;
      }

      // final config = await _config.getConfig(accounts.first.alias);

       final community =
          await _appDBService.communities.get(accounts.first.alias);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);

      _theme.changeTheme(communityConfig.community.theme);

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
    } catch (_) {
      _notifications.toastShow(
        'Unable to recover backup.',
        type: ToastType.error,
      );

      _state.backupError();
    }
  }

  Future<void> backupAndroid({
    Future<bool?> Function()? handleConfirmReplace,
    bool merge = true,
  }) async {
    try {
      _state.backupRequest();

      final BackupServiceInterface backupService = getBackupService();

      final username = await backupService.init();

      await _credentials.setup(username: username);

      int amountRemoteAccounts = 0;

      final (fileId, _) = await backupService.backupExists(_accountsDB.name);
      if (fileId != null && merge) {
        // there is already a backup, merge theme
        final remoteDBName = '${_accountsDB.name}.remote';

        await backupService.download(
          _accountsDB.name,
          '${_accountsDB.path}.remote.db',
        );

        final remoteDB = AccountBackupDBService.newInstance();

        await remoteDB.init(remoteDBName);

        final remoteAccounts = await remoteDB.accounts.all();

        amountRemoteAccounts = remoteAccounts.length;

        for (final account in remoteAccounts) {
          await _accountsDB.accounts.insert(account);
        }

        await remoteDB.deleteDB();
      }

      await _accounts.populatePrivateKeysFromEncryptedStorage();
      
      // this will upload, encrypt and replace any current backup in place
      await backupService.upload(
        _accountsDB.path,
        _accountsDB.name,
      );

      await _accounts.purgePrivateKeysAndAddToEncryptedStorage();
      
      // TODO: upload app data as well
      // final accounts = await _accountsDB.accounts.all();

      // for (final account in accounts) {

      // }

      final backupTime = DateTime.now();

      await _preferences.setLastBackupTime(backupTime.toIso8601String());

      _state.backupSuccess(backupTime, username);

      String message = 'Backup successful.';
      if (amountRemoteAccounts > 0) {
        message =
            'Backup successful. $amountRemoteAccounts ${amountRemoteAccounts == 1 ? 'account' : 'accounts'} merged.';
      }

      _notifications.toastShow(
        message,
        type: ToastType.success,
      );
    } on SecretBoxAuthenticationError {
      // handle wrong encryption key
      if (handleConfirmReplace != null) {
        final confirm = await handleConfirmReplace();

        if (confirm == true) {
          await backupAndroid(
            handleConfirmReplace: handleConfirmReplace,
            merge: false,
          );
        }
      }
      _state.backupError();
    } catch (_) {
      _notifications.toastShow(
        'Unable to backup.',
        type: ToastType.error,
      );

      _state.backupError();
    }
  }

  Future<void> checkStatus() async {
    try {
      final isSetup = await _credentials.isSetup();

      _state.setE2E(isSetup);
    } catch (_) {
      _state.setE2E(false);
    }
  }

  void resetBackupState() {
    _state.resetState();
  }
}
