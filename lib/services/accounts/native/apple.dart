import 'package:citizenwallet/services/accounts/backup.dart';
import 'package:citizenwallet/services/accounts/accounts.dart';
import 'package:citizenwallet/services/accounts/options.dart';
import 'package:citizenwallet/services/accounts/utils.dart';
import 'package:citizenwallet/services/credentials/credentials.dart';
import 'package:citizenwallet/services/credentials/native/apple.dart';
import 'package:citizenwallet/services/db/backup/accounts.dart';
import 'package:citizenwallet/services/db/backup/db.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

/// AppleAccountsService implements an AccountsServiceInterface for iOS and macOS
class AppleAccountsService extends AccountsServiceInterface {
  static final AppleAccountsService _instance =
      AppleAccountsService._internal();
  factory AppleAccountsService() => _instance;
  AppleAccountsService._internal();

  final String defaultAlias = dotenv.get('DEFAULT_COMMUNITY_ALIAS');

  final CredentialsServiceInterface _credentials = getCredentialsService();
  late AccountBackupDBService _accountsDB;

  @override
  Future init(AccountsOptionsInterface options) async {
    final appleOptions = options as AppleAccountsOptions;

    await _credentials.init(
      options: AppleCredentialsOptions(
        groupId: appleOptions.groupId,
      ),
    );

    _accountsDB = appleOptions.accountsDB;

    await migrate(super.version);
  }

  @override
  Future<void> migrate(int version) async {
    final int oldVersion =
        int.tryParse(await _credentials.read(versionPrefix) ?? '0') ?? 0;

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
          final saved = await _credentials.containsKey(backup.legacyKey2);
          if (saved) {
            await _credentials.delete(backup.legacyKey2);
          }

          await _credentials.write(
            backup.legacyKey2,
            backup.value,
          );
        }

        // delete all old keys
        for (final backup in allBackups) {
          // legacy delete
          final saved = await _credentials.containsKey(
            backup.legacyKey,
          );
          if (saved) {
            await _credentials.delete(backup.legacyKey);
          }
        }
      },
      2: () async {
        final allBackups = await getAllLegacyWalletBackups();

        for (final backup in allBackups) {
          final saved = await _credentials.containsKey(backup.key);
          if (saved) {
            await _credentials.delete(backup.key);
          }

          await _credentials.write(
            backup.key,
            backup.value,
          );
        }

        // delete all old keys
        for (final backup in allBackups) {
          // delete legacy keys
          final saved = await _credentials.containsKey(
            backup.legacyKey2,
          );

          if (saved) {
            await _credentials.delete(
              backup.legacyKey2,
            );
          }
        }
      },
      3: () async {
        final allBackups = await getAllLegacyWalletBackups();

        final toDelete = <String>[];

        for (final backup in allBackups) {
          bool saved = await _credentials.containsKey(backup.key);
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

          await _credentials.write(
            newBackup.key,
            newBackup.value,
          );

          toDelete.add(backup.key);
        }

        // delete all old keys
        for (final backup in allBackups) {
          if (!toDelete.contains(backup.key)) {
            continue;
          }

          // delete legacy keys
          final saved = await _credentials.containsKey(
            backup.key,
          );

          if (saved) {
            await _credentials.delete(
              backup.key,
            );
          }
        }
      },
      4: () async {
        final allLegacyBackups = await getAllLegacyWalletBackups();

        final toDelete = <String>[];

        for (final legacyBackup in allLegacyBackups) {
          final saved = await _credentials.containsKey(legacyBackup.key);
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

          await _credentials.write(
            backup.key,
            backup.value,
          );

          toDelete.add(legacyBackup.key);
        }

        // delete all old keys
        for (final key in toDelete) {
          // delete legacy keys
          final saved = await _credentials.containsKey(
            key,
          );

          if (saved) {
            await _credentials.delete(
              key,
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
    await _credentials.write(versionPrefix, version.toString());
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
      final privateKey = await _credentials.read(account.id);
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

    await _credentials.write(
      account.id,
      bytesToHex(account.privateKey!.privateKey),
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

    final privateKey = await _credentials.read(account.id);
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

    await _credentials.delete(
      getAccountID(
        EthereumAddress.fromHex(address),
        alias,
      ),
    );
  }

  // delete all wallet backups
  @override
  Future<void> deleteAllAccounts() async {
    await _accountsDB.accounts.deleteAll();

    await _credentials.deleteCredentials();
  }

  // legacy methods
  Future<List<LegacyBackupWallet>> getAllLegacyWalletBackups() async {
    final allValues = await _credentials.readAll();
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
        alias: defaultAlias,
      ));
    }

    backups.sort((a, b) => a.name.compareTo(b.name));

    return backups;
  }
}
