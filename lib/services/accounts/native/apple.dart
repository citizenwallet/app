import 'package:citizenwallet/services/accounts/backup.dart';
import 'package:citizenwallet/services/accounts/accounts.dart';
import 'package:citizenwallet/services/accounts/options.dart';
import 'package:citizenwallet/services/accounts/utils.dart';
import 'package:citizenwallet/services/db/accounts.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

/// AppleAccountsService implements an AccountsServiceInterface for iOS and macOS
class AppleAccountsService extends AccountsServiceInterface {
  static final AppleAccountsService _instance =
      AppleAccountsService._internal();
  factory AppleAccountsService() => _instance;
  AppleAccountsService._internal();

  IOSOptions _getIOSOptions(String groupId) => IOSOptions(
        groupId: groupId,
        accessibility: KeychainAccessibility.unlocked,
        synchronizable: true,
      );

  MacOsOptions _getMacOsOptions(String groupId) => MacOsOptions(
        groupId: groupId,
        accessibility: KeychainAccessibility.unlocked,
        synchronizable: true,
      );

  late FlutterSecureStorage _preferences;
  late AccountsDBService _accountsDB;

  @override
  Future init(AccountsOptionsInterface options) async {
    final appleOptions = options as AppleAccountsOptions;
    _preferences = FlutterSecureStorage(
      iOptions: _getIOSOptions(appleOptions.groupId),
      mOptions: _getMacOsOptions(appleOptions.groupId),
    );

    _accountsDB = appleOptions.accountsDB;

    await migrate(super.version);
  }

  @override
  Future<void> migrate(int version) async {
    final int oldVersion =
        int.tryParse(await _preferences.read(key: versionPrefix) ?? '0') ?? 0;

    if (oldVersion == version) {
      return;
    }

    final migrations = {
      1: () async {
        // coming from the old version, migrate all keys and delete the old ones
        // all or nothing, first write all the new ones, then delete all the old ones
        final allBackups = await getAllLegacyWalletBackups();

        for (final backup in allBackups) {
          // await setAccount(backup);
          final saved = await _preferences.containsKey(key: backup.legacyKey2);
          if (saved) {
            await _preferences.delete(key: backup.legacyKey2);
          }

          await _preferences.write(
            key: backup.legacyKey2,
            value: backup.value,
          );
        }

        // delete all old keys
        for (final backup in allBackups) {
          // legacy delete
          final saved = await _preferences.containsKey(
            key: backup.legacyKey,
          );
          if (saved) {
            await _preferences.delete(key: backup.legacyKey);
          }
        }
      },
      2: () async {
        final allBackups = await getAllLegacyWalletBackups();

        for (final backup in allBackups) {
          final saved = await _preferences.containsKey(key: backup.key);
          if (saved) {
            await _preferences.delete(key: backup.key);
          }

          await _preferences.write(
            key: backup.key,
            value: backup.value,
          );
        }

        // delete all old keys
        for (final backup in allBackups) {
          // delete legacy keys
          final saved = await _preferences.containsKey(
            key: backup.legacyKey2,
          );

          if (saved) {
            await _preferences.delete(
              key: backup.legacyKey2,
            );
          }
        }
      },
      3: () async {
        final allBackups = await getAllLegacyWalletBackups();

        final toDelete = <String>[];

        for (final backup in allBackups) {
          bool saved = await _preferences.containsKey(key: backup.key);
          if (!saved) {
            continue;
          }

          final account = await getLegacyAccountAddress(backup);
          if (account == null) {
            continue;
          }

          final newBackup = LegacyBackupWallet(
            address: account.hexEip55,
            privateKey: backup.privateKey,
            name: backup.name,
            alias: backup.alias,
          );

          await _preferences.write(
            key: newBackup.key,
            value: newBackup.value,
          );

          toDelete.add(backup.key);
        }

        // delete all old keys
        for (final backup in allBackups) {
          if (!toDelete.contains(backup.key)) {
            continue;
          }

          // delete legacy keys
          final saved = await _preferences.containsKey(
            key: backup.key,
          );

          if (saved) {
            await _preferences.delete(
              key: backup.key,
            );
          }
        }
      },
      4: () async {
        final allLegacyBackups = await getAllLegacyWalletBackups();

        final toDelete = <String>[];

        for (final legacyBackup in allLegacyBackups) {
          final saved = await _preferences.containsKey(key: legacyBackup.key);
          if (!saved) {
            continue;
          }

          // write the account data in the accounts table
          final DBAccount account = DBAccount(
            alias: legacyBackup.alias,
            address: EthereumAddress.fromHex(legacyBackup.address),
            name: legacyBackup.name,
          );

          await _accountsDB.accounts.insert(account);

          // write credentials into Keychain Services
          final backup = BackupWallet(
            address: legacyBackup.address,
            alias: legacyBackup.alias,
            privateKey: legacyBackup.privateKey,
          );

          await _preferences.write(
            key: backup.key,
            value: backup.value,
          );

          toDelete.add(legacyBackup.key);
        }

        // delete all old keys
        for (final key in toDelete) {
          // delete legacy keys
          final saved = await _preferences.containsKey(
            key: key,
          );

          if (saved) {
            await _preferences.delete(
              key: key,
            );
          }
        }
      },
    };

    // run all migrations
    for (var i = oldVersion + 1; i <= version; i++) {
      if (migrations.containsKey(i)) {
        await migrations[i]!();
      }
    }

    // after success, we can update the version
    await _preferences.write(key: versionPrefix, value: version.toString());
  }

  // handle wallet backups
  // use the prefix as a query to find a wallet backup
  // use the prefix + wallet address as a way to query the backup
  // store the json as a b64 encoded string, reason: we store the name of the wallet
  // key = wb_$wallet_address, value = $name|$privateKey

  // get all wallet backups
  @override
  Future<List<DBAccount>> getAllAccounts() async {
    final List<DBAccount> accounts = await _accountsDB.accounts.all();

    for (final account in accounts) {
      final privateKey = await _preferences.read(key: account.id);
      if (privateKey == null) {
        continue;
      }

      account.privateKey = EthPrivateKey.fromHex(privateKey);
    }

    return accounts;
  }

  // set wallet backup
  @override
  Future<void> setAccount(DBAccount account) async {
    await _accountsDB.accounts.insert(account);

    if (account.privateKey == null) {
      return;
    }

    await _preferences.write(
      key: account.id,
      value: bytesToHex(account.privateKey!.privateKey),
    );
  }

  // get wallet backup
  @override
  Future<DBAccount?> getAccount(String address, String alias) async {
    final account = await _accountsDB.accounts.get(
      EthereumAddress.fromHex(address),
      alias,
    );

    if (account == null) {
      return null;
    }

    final privateKey = await _preferences.read(key: account.id);
    if (privateKey == null) {
      return account;
    }

    account.privateKey = EthPrivateKey.fromHex(privateKey);

    return account;
  }

  // get wallet backups for alias
  @override
  Future<List<DBAccount>> getAccountsForAlias(String alias) async {
    return _accountsDB.accounts.allForAlias(alias);
  }

  // delete wallet backup
  @override
  Future<void> deleteAccount(String address, String alias) async {
    await _accountsDB.accounts.delete(
      EthereumAddress.fromHex(address),
      alias,
    );

    await _preferences.delete(
      key: getAccountID(
        EthereumAddress.fromHex(address),
        alias,
      ),
    );
  }

  // delete all wallet backups
  @override
  Future<void> deleteAllAccounts() async {
    await _accountsDB.accounts.deleteAll();

    await _preferences.deleteAll();
  }

  // legacy methods
  Future<List<LegacyBackupWallet>> getAllLegacyWalletBackups() async {
    final allValues = await _preferences.readAll();
    final keys = allValues.keys.where((key) => key.startsWith(backupPrefix));

    final List<LegacyBackupWallet> backups = [];

    for (final k in keys) {
      final parsed = allValues[k]!.split('|');
      if (parsed.length < 2) {
        // invalid backup, consider cleaning up in the future
        continue;
      }

      if (parsed.length == 3) {
        backups.add(LegacyBackupWallet(
          address: k.replaceFirst(backupPrefix, ''),
          privateKey: parsed[1],
          name: parsed[0],
          alias: parsed[2],
        ));
        continue;
      }

      if (parsed.length == 4) {
        backups.add(LegacyBackupWallet(
          name: parsed[0],
          address: parsed[1],
          privateKey: parsed[2],
          alias: parsed[3],
        ));
        continue;
      }

      backups.add(LegacyBackupWallet(
        address: k.replaceFirst(backupPrefix, ''),
        privateKey: parsed[1],
        name: parsed[0],
        alias: 'app',
      ));
    }

    backups.sort((a, b) => a.name.compareTo(b.name));

    return backups;
  }
}
