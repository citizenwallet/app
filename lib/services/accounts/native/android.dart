import 'package:citizenwallet/services/credentials/credentials.dart';
import 'package:citizenwallet/services/db/backup/db.dart';
import 'package:citizenwallet/utils/encrypt.dart';
import 'package:citizenwallet/services/accounts/options.dart';
import 'package:citizenwallet/services/db/backup/accounts.dart';
import 'package:citizenwallet/services/db/app/db.dart';
import 'package:citizenwallet/services/config/config.dart';

import 'package:citizenwallet/services/accounts/backup.dart';
import 'package:citizenwallet/services/accounts/accounts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

const pinCodeCheckKey = 'cw__pinCodeCheck__';
const pinCodeKey = 'cw__pinCode__';

/// AndroidAccountsService implements an AccountsServiceInterface for Android
class AndroidAccountsService extends AccountsServiceInterface {
  static final AndroidAccountsService _instance =
      AndroidAccountsService._internal();
  factory AndroidAccountsService() => _instance;
  AndroidAccountsService._internal();

  final String defaultAlias = dotenv.get('DEFAULT_COMMUNITY_ALIAS');

  final CredentialsServiceInterface _credentials = getCredentialsService();
  late SharedPreferences _sharedPreferences;
  late AccountBackupDBService _accountsDB;

  @override
  Future init(AccountsOptionsInterface options) async {
    final AndroidAccountsOptions androidOptions =
        options as AndroidAccountsOptions;

    _sharedPreferences = await SharedPreferences.getInstance();
    _accountsDB = androidOptions.accountsDB;

    await _credentials.init();

    await migrate(super.version);
  }

  @override
  Future<void> migrate(int version) async {
    final int oldVersion =
        int.tryParse(_sharedPreferences.getString(versionPrefix) ?? '0') ?? 0;

    if (oldVersion == version) {
      return;
    }

    final migrations = {
      4: () async {
        final allLegacyBackups = await getAllLegacyWalletBackups();

        final toDelete = <String>[];

        for (final legacyBackup in allLegacyBackups) {
          final saved = _sharedPreferences.containsKey(legacyBackup.key);
          if (!saved) {
            continue;
          }

          // write the account data in the accounts table
          final account = DBAccount(
            alias: legacyBackup.alias,
            address: EthereumAddress.fromHex(legacyBackup.address),
            name: legacyBackup.name,
          );

          await _accountsDB.accounts.insert(account);

          // write credentials into Keychain Services
          await _credentials.write(account.id, legacyBackup.privateKey);

          toDelete.add(legacyBackup.key);
        }

        // delete all old keys
        for (final key in toDelete) {
          // delete legacy keys
          final saved = _sharedPreferences.containsKey(
            key,
          );

          if (saved) {
            await _sharedPreferences.remove(
              key,
            );
          }
        }
      },
      5: () async {
        final allAccounts = await _accountsDB.accounts.all();
        
        for (final account in allAccounts) {
          if (account.accountFactoryAddress != null) {
            continue;
          }
          
          final community = await AppDBService().communities.get(account.alias);
          if (community == null) {
            continue;
          }
          
          final config = Config.fromJson(community.config);
          String accountFactoryAddress = config.community.primaryAccountFactory.address;
          
          switch (account.alias) {
            case 'gratitude':
              accountFactoryAddress = '0xAE6E18a9Cd26de5C8f89B886283Fc3f0bE5f04DD';
              break;
            case 'bread':
              accountFactoryAddress = '0xAE76B1C6818c1DD81E20ccefD3e72B773068ABc9';
              break;
            case 'wallet.commonshub.brussels':
              accountFactoryAddress = '0x307A9456C4057F7C7438a174EFf3f25fc0eA6e87';
              break;
            case 'wallet.sfluv.org':
              accountFactoryAddress = '0x5e987a6c4bb4239d498E78c34e986acf29c81E8e';
              break;
            default:
              if (accountFactoryAddress == '0x940Cbb155161dc0C4aade27a4826a16Ed8ca0cb2') {
                accountFactoryAddress = '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185';
              }
              break;
          }
          
          // Create new account with factory address
          final newAccount = DBAccount(
            alias: account.alias,
            address: account.address,
            name: account.name,
            username: account.username,
            accountFactoryAddress: accountFactoryAddress,
            privateKey: account.privateKey,
            profile: account.profile,
          );
          
          // Delete old account and insert new one
          await _accountsDB.accounts.delete(account.address, account.alias, account.accountFactoryAddress);
          await _accountsDB.accounts.insert(newAccount);
          
          final oldKey = getAccountID(account.address, account.alias, account.accountFactoryAddress);
          final newKey = getAccountID(account.address, account.alias, accountFactoryAddress);
          
          final privateKey = await _credentials.read(oldKey);
          if (privateKey != null) {
            await _credentials.write(newKey, privateKey);
            await _credentials.delete(oldKey);
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
    await _sharedPreferences.setString(versionPrefix, version.toString());
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
  Future<DBAccount?> getAccount(String address, String alias, [String? accountFactoryAddress]) async {
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
    await _accountsDB.accounts.delete(
      EthereumAddress.fromHex(address),
      alias,
      null,
    );

    await _credentials.delete(
      getAccountID(
        EthereumAddress.fromHex(address),
        alias,
        null,
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
  Future<List<int>?> pinCode() async {
    final securedPin = await _credentials.read(pinCodeKey);
    if (securedPin == null) {
      return null;
    }

    final pin = int.parse(securedPin);

    return pin.toRadixString(16).padLeft(32, '0').codeUnits;
  }

  Future<List<LegacyBackupWallet>> getAllLegacyWalletBackups() async {
    final allValues = _sharedPreferences.getKeys();
    final keys = allValues.where((key) => key.startsWith(backupPrefix));

    final List<LegacyBackupWallet> backups = [];

    final pin = await pinCode();
    if (pin == null) {
      return [];
    }

    final encrypt = Encrypt(pin);

    for (final k in keys) {
      final value = _sharedPreferences.getString(k);
      if (value == null) {
        continue;
      }

      final decrypted = await encrypt.b64Decrypt((value));

      final parsed = decrypted.split('|');
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

  @override
  Future<void> populatePrivateKeysFromEncryptedStorage() async {
    final allAccounts = await getAllAccounts(); // accounts with private keys

    for (final account in allAccounts) {
      _accountsDB.accounts.update(account);
    }
  }

  @override
  Future<void> purgePrivateKeysAndAddToEncryptedStorage() async {
    final allAccounts = await getAllAccounts(); // accounts with private keys

    for (final account in allAccounts) {
      await _credentials.write(
        account.id,
        bytesToHex(account.privateKey!.privateKey),
      );

      // null private key before updating in DB
      account.privateKey = null;
      await _accountsDB.accounts.update(account);
    }
  }
}
