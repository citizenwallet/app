import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import 'package:citizenwallet/services/accounts/accounts.dart';
import 'package:citizenwallet/services/accounts/backup.dart';
import 'package:citizenwallet/services/accounts/options.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/credentials/credentials.dart';
import 'package:citizenwallet/services/credentials/native/apple.dart';
import 'package:citizenwallet/services/db/app/db.dart';
import 'package:citizenwallet/services/db/backup/accounts.dart';
import 'package:citizenwallet/services/db/backup/db.dart';
import 'package:citizenwallet/services/wallet/contracts/safe_account.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';

class AppleAccountsService extends AccountsServiceInterface {
  static final AppleAccountsService _instance =
      AppleAccountsService._internal();
  factory AppleAccountsService() => _instance;
  AppleAccountsService._internal();

  final String defaultAlias = dotenv.get('DEFAULT_COMMUNITY_ALIAS');

  final CredentialsServiceInterface _credentials = getCredentialsService();
  late AccountBackupDBService _accountsDB;

  Future<void> _fixSafeAccount(DBAccount account, Config config) async {
    try {
      if (account.accountFactoryAddress !=
          '0x940Cbb155161dc0C4aade27a4826a16Ed8ca0cb2') {
        return;
      }

      final safeAccount = SafeAccount(
        config.chains.values.first.node.chainId,
        config.ethClient,
        account.address.hexEip55,
      );
      await safeAccount.init();

      final calldata = safeAccount.fixFallbackHandlerCallData();

      final (hash, userop) = await prepareUserop(
        config,
        account.address,
        account.privateKey!,
        [account.address.hexEip55],
        [calldata],
        deploy: false,
        accountFactoryAddress: '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
      );

      final txHash = await submitUserop(config, userop, migrationSafe: true);

      if (txHash != null) {
        debugPrint('fixed cw-safe account ${account.address.hexEip55}');
      } else {
        debugPrint(
            'Failed to submit for cw-safe account ${account.address.hexEip55}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error: cw-safe account ${account.address.hexEip55}: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e.toString().contains('contract not whitelisted')) {
        debugPrint(
            'Contract not whitelisted error for account ${account.address.hexEip55}');
      }
    }
  }

  @override
  Future init(AccountsOptionsInterface options) async {
    final appleOptions = options as AppleAccountsOptions;

    await _credentials.init(
      options: AppleCredentialsOptions(
        groupId: appleOptions.groupId,
      ),
    );

    _accountsDB = appleOptions.accountsDB;

    await restoreAccountsFromKeychain();

    // Run migrations on the complete dataset (existing + restored accounts)
    await migrate(super.version);

    await migratePrivateKeysFromOldFormat();
  }

  @override
  Future<void> migrate(int version) async {
    final int oldVersion =
        int.tryParse(await _credentials.read(versionPrefix) ?? '0') ?? 0;

    if (oldVersion == version) {
      return;
    }

    final migrations = {
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
            accountFactoryAddress: '',
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
      5: () async {
        final allAccounts = await _accountsDB.accounts.all();

        for (final account in allAccounts) {
          if (account.accountFactoryAddress.isNotEmpty &&
              account.accountFactoryAddress !=
                  '0x940Cbb155161dc0C4aade27a4826a16Ed8ca0cb2') {
            continue;
          }

          final community = await AppDBService().communities.get(account.alias);
          if (community == null) {
            continue;
          }

          final config = Config.fromJson(community.config);
          String accountFactoryAddress =
              config.community.primaryAccountFactory.address;

          switch (account.alias) {
            case 'gratitude':
              accountFactoryAddress =
                  '0xAE6E18a9Cd26de5C8f89B886283Fc3f0bE5f04DD';
              break;
            case 'bread':
              accountFactoryAddress =
                  '0xAE76B1C6818c1DD81E20ccefD3e72B773068ABc9';
              break;
            case 'wallet.commonshub.brussels':
              accountFactoryAddress =
                  '0x307A9456C4057F7C7438a174EFf3f25fc0eA6e87';
              break;
            case 'wallet.sfluv.org':
              accountFactoryAddress =
                  '0x5e987a6c4bb4239d498E78c34e986acf29c81E8e';
              break;
            default:
              if (account.accountFactoryAddress ==
                  '0x940Cbb155161dc0C4aade27a4826a16Ed8ca0cb2') {
                accountFactoryAddress =
                    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185';
              }
              break;
          }

          final oldAccountId = account.id;
          final oldPrivateKey = await _credentials.read(oldAccountId);

          final updatedAccount = DBAccount(
            alias: account.alias,
            address: account.address,
            name: account.name,
            username: account.username,
            accountFactoryAddress: accountFactoryAddress,
            profile: account.profile,
          );

          final newAccountId = updatedAccount.id;

          // Check if the account actually exists in the database with the expected ID
          final existingAccount = await _accountsDB.accounts.db.query(
            't_accounts',
            where: 'id = ?',
            whereArgs: [oldAccountId],
          );

          if (existingAccount.isNotEmpty) {
            // Delete using the expected ID
            await _accountsDB.accounts.delete(
                account.address, account.alias, account.accountFactoryAddress);
          } else {
            // Try to find by address and alias with empty accountFactoryAddress
            final foundByAddress = await _accountsDB.accounts.db.query(
              't_accounts',
              where: 'address = ? AND alias = ? AND accountFactoryAddress = ""',
              whereArgs: [account.address.hexEip55, account.alias],
            );

            if (foundByAddress.isNotEmpty) {
              final actualId = foundByAddress.first['id'] as String;

              // Delete using the actual ID
              await _accountsDB.accounts.db.delete(
                't_accounts',
                where: 'id = ?',
                whereArgs: [actualId],
              );
            }
          }
          if (account.accountFactoryAddress ==
              '0x940Cbb155161dc0C4aade27a4826a16Ed8ca0cb2') {
            final accountId = account.id;
            await _credentials.write('needs_fixing_$accountId', 'true');
          }

          // Insert the new record
          await _accountsDB.accounts.insert(updatedAccount);

          if (oldPrivateKey != null) {
            await _credentials.write(newAccountId, oldPrivateKey);
            await _credentials.delete(oldAccountId);

            final legacyKeychainKey =
                '${account.address.hexEip55}@${account.alias}';
            if (await _credentials.containsKey(legacyKeychainKey)) {
              await _credentials.delete(legacyKeychainKey);
            }
          }
        }
      },
      6: () async {
        final allAccounts = await _accountsDB.accounts.all();
        final toDelete = <DBAccount>[];

        for (final account in allAccounts) {
          if (account.accountFactoryAddress.isEmpty) {
            toDelete.add(account);
          }
        }

        for (final account in toDelete) {
          final existingAccount = await _accountsDB.accounts.db.query(
            't_accounts',
            where: 'id = ?',
            whereArgs: [account.id],
          );

          if (existingAccount.isNotEmpty) {
            // Delete the account from database using the actual ID
            await _accountsDB.accounts.db.delete(
              't_accounts',
              where: 'id = ?',
              whereArgs: [account.id],
            );
          } else {
            // Try to find by address and alias instead
            final foundByAddress = await _accountsDB.accounts.db.query(
              't_accounts',
              where: 'address = ? AND alias = ? AND accountFactoryAddress = ""',
              whereArgs: [account.address.hexEip55, account.alias],
            );

            if (foundByAddress.isNotEmpty) {
              final actualId = foundByAddress.first['id'] as String;

              // Delete using the actual ID
              await _accountsDB.accounts.db.delete(
                't_accounts',
                where: 'id = ?',
                whereArgs: [actualId],
              );
            }
          }

          // Delete the private key from credentials
          await _credentials.delete(account.id);
        }
      },
    };

    for (int i = oldVersion + 1; i <= version; i++) {
      if (migrations.containsKey(i)) {
        await migrations[i]!();
      }
    }

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

  Future<int> restoreAccountsFromKeychain() async {
    int restoredCount = 0;
    try {
      final allKeychainData = await _credentials.readAll();

      if (allKeychainData.isEmpty) {
        return 0;
      }

      final existingAccounts = await _accountsDB.accounts.all();
      final existingAddresses = existingAccounts
          .map((acc) => acc.address.hexEip55.toLowerCase())
          .toSet();

      final existingAccountIds = existingAccounts.map((acc) => acc.id).toSet();

      if (existingAccounts.length >= (allKeychainData.length - 1)) {
        return 0;
      }

      final allLegacyBackups = await getAllLegacyWalletBackups();

      for (final legacyBackup in allLegacyBackups) {
        final saved = await _credentials.containsKey(legacyBackup.key);
        if (!saved) {
          continue;
        }

        final addressLower = legacyBackup.address.toLowerCase();
        if (existingAddresses.contains(addressLower)) {
          continue;
        }

        try {
          final account = DBAccount(
            alias: legacyBackup.alias,
            address: EthereumAddress.fromHex(legacyBackup.address),
            name: legacyBackup.name,
            accountFactoryAddress: '',
            privateKey: null,
          );

          await _accountsDB.accounts.insert(account);

          final backup = BackupWallet(
            address: legacyBackup.address,
            alias: legacyBackup.alias,
            privateKey: legacyBackup.privateKey,
          );

          await _credentials.write(backup.key, backup.value);
          restoredCount++;
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('Error restoring legacy account: $e');
            debugPrintStack(stackTrace: stackTrace);
          }
        }
      }

      for (final entry in allKeychainData.entries) {
        try {
          final key = entry.key;

          if (_isSystemKey(key) || key.startsWith(backupPrefix)) {
            continue;
          }

          if (!key.contains('@')) {
            continue;
          }

          final parts = key.split('@');
          if (parts.length != 2 && parts.length != 3) {
            continue;
          }

          String accountAddress;
          String factoryAddress;
          String alias;

          if (parts.length == 2) {
            accountAddress = parts[0];
            factoryAddress = '';
            alias = parts[1];
          } else {
            accountAddress = parts[0];
            factoryAddress = parts[1];
            alias = parts[2];
          }

          final potentialAccount = DBAccount(
            alias: alias,
            address: EthereumAddress.fromHex(accountAddress),
            name: await _getProperAccountName(alias, accountAddress),
            accountFactoryAddress: factoryAddress.isEmpty ? '' : factoryAddress,
          );

          if (existingAddresses.contains(accountAddress.toLowerCase()) ||
              existingAccountIds.contains(potentialAccount.id)) {
            continue;
          }

          final account = DBAccount(
            alias: alias,
            address: EthereumAddress.fromHex(accountAddress),
            name: await _getProperAccountName(alias, accountAddress),
            accountFactoryAddress: factoryAddress.isEmpty ? '' : factoryAddress,
            privateKey: null,
          );

          await _accountsDB.accounts.insert(account);

          await _credentials.write(account.id, entry.value);
          restoredCount++;
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('Error processing keychain entry ${entry.key}: $e');
            debugPrintStack(stackTrace: stackTrace);
          }
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error restoring accounts from keychain: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    return restoredCount;
  }

  Future<String> _getProperAccountName(
      String alias, String accountAddress) async {
    try {
      final existingAccount = await _accountsDB.accounts.get(
        EthereumAddress.fromHex(accountAddress),
        alias,
        '',
      );

      if (existingAccount != null && existingAccount.name.isNotEmpty) {
        debugPrint('Using existing account name: ${existingAccount.name}');
        return existingAccount.name;
      }
    } catch (e) {
      debugPrint('Error checking existing account: $e');
    }

    return 'Account';
  }

  bool _isSystemKey(String key) {
    return key.startsWith('credential_storage_key') ||
        key.startsWith('version_') ||
        key.startsWith(versionPrefix) ||
        key.length < 10;
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
  Future<DBAccount?> getAccount(String address, String alias,
      [String accountFactoryAddress = '']) async {
    final account = await _accountsDB.accounts.get(
      EthereumAddress.fromHex(address),
      alias,
      accountFactoryAddress,
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
    final accounts = await _accountsDB.accounts.allForAlias(alias);
    final account =
        accounts.where((acc) => acc.address.hexEip55 == address).firstOrNull;

    if (account != null) {
      await _accountsDB.accounts.delete(
        EthereumAddress.fromHex(address),
        alias,
        account.accountFactoryAddress,
      );

      await _credentials.delete(
        getAccountID(
          EthereumAddress.fromHex(address),
          alias,
          account.accountFactoryAddress,
        ),
      );
    }
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

  Future<void> migratePrivateKeysFromOldFormat() async {
    try {
      final allAccounts = await _accountsDB.accounts.all();

      for (final account in allAccounts) {
        try {
          final currentPrivateKey = await _credentials.read(account.id);
          if (currentPrivateKey != null) {
            continue;
          }

          final oldFormatKey = '${account.address.hexEip55}@${account.alias}';

          final oldPrivateKey = await _credentials.read(oldFormatKey);
          if (oldPrivateKey != null) {
            await _credentials.write(account.id, oldPrivateKey);
            await _credentials.delete(oldFormatKey);
          }
        } catch (e) {
          debugPrint(
              'Error migrating private key for account ${account.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error during private key migration: $e');
    }
  }

  Future<void> purgePrivateKeysAndAddToEncryptedStorage() async {
    final accounts = await _accountsDB.accounts.all();

    for (final account in accounts) {
      final privateKey = await _credentials.read(account.id);
      if (privateKey == null) {
        continue;
      }

      account.privateKey = EthPrivateKey.fromHex(privateKey);
    }

    await _credentials.deleteCredentials();

    for (final account in accounts) {
      if (account.privateKey == null) {
        continue;
      }

      await _credentials.write(
        account.id,
        bytesToHex(account.privateKey!.privateKey),
      );
    }
  }

  @override
  Future<void> fixSafeAccounts() async {
    try {
      final allAccounts = await _accountsDB.accounts.all();

      for (final account in allAccounts) {
        final needsFixingStr =
            await _credentials.read('needs_fixing_${account.id}');
        final needsFixing = needsFixingStr == 'true';
        if (!needsFixing) {
          continue;
        }

        final privateKey = await _credentials.read(account.id);
        if (privateKey == null) {
          continue;
        }

        account.privateKey = EthPrivateKey.fromHex(privateKey);

        final community = await AppDBService().communities.get(account.alias);
        if (community == null) {
          continue;
        }

        final config = Config.fromJson(community.config);

        try {
          await _fixSafeAccount(account, config);

          await _credentials.delete('needs_fixing_${account.id}');
        } catch (e, stackTrace) {
          debugPrint('Stack trace: $stackTrace');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
