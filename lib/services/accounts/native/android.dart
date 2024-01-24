import 'package:citizenwallet/utils/encrypt.dart';
import 'package:citizenwallet/services/accounts/options.dart';
import 'package:citizenwallet/services/db/accounts.dart';
import 'package:citizenwallet/services/db/db.dart';

import 'package:citizenwallet/services/accounts/backup.dart';
import 'package:citizenwallet/services/accounts/accounts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: true,
      );

  late FlutterSecureStorage _preferences;
  // late CredentialManager _credentials;
  late SharedPreferences _sharedPreferences;
  late AccountsDBService _accountsDB;

  // late Encrypt _encrypt;

  @override
  Future init(AccountsOptionsInterface options) async {
    final AndroidAccountsOptions androidOptions =
        options as AndroidAccountsOptions;

    _preferences = FlutterSecureStorage(
      aOptions: _getAndroidOptions(),
    );

    // _credentials = CredentialManager();

    // if (_credentials.isSupportedPlatform) {
    //   // if supported
    //   await _credentials.init(preferImmediatelyAvailableCredentials: true);
    // }

    _sharedPreferences = await SharedPreferences.getInstance();
    _accountsDB = androidOptions.accountsDB;

    // try {
    //   // check if there is an encryption key available
    //   final credential = await _credentials.getPasswordCredentials();
    // } catch (e) {
    //   // if not, create one
    //   // generate a random key
    //   final key = generateKey(32);

    //   await _credentials.savePasswordCredentials(
    //     PasswordCredential(
    //       username: credentialStorageKey,
    //       password: bytesToHex(key),
    //     ),
    //   );
    // }

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
          await _preferences.write(
              key: account.id, value: legacyBackup.privateKey);

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
  Future<List<int>?> pinCode() async {
    final securedPin = await _preferences.read(key: pinCodeKey);
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
        alias: 'app',
      ));
    }

    backups.sort((a, b) => a.name.compareTo(b.name));

    return backups;
  }
}
