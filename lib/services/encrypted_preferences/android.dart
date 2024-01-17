import 'dart:convert';

import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptography/cryptography.dart';

const pinCodeCheckKey = 'cw__pinCodeCheck__';
const pinCodeKey = 'cw__pinCode__';

class AndroidEncryptedPreferencesOptions
    implements EncryptedPreferencesOptions {
  final int? pin;
  final bool fromScratch;

  AndroidEncryptedPreferencesOptions({
    this.pin,
    this.fromScratch = false,
  });

  // string
  @override
  String toString() {
    return 'AndroidEncryptedPreferencesOptions{pin: $pin, fromScratch: $fromScratch}';
  }
}

class EncryptedData {
  final Uint8List data;
  final int nonceLength;
  final int macLength;

  EncryptedData({
    required this.data,
    required this.nonceLength,
    required this.macLength,
  });

  EncryptedData.fromJson(Map<String, dynamic> json)
      : data = base64.decode(json['data']),
        nonceLength = json['nonceLength'],
        macLength = json['macLength'];

  Map<String, dynamic> toJson() => {
        'data': base64.encode(data),
        'nonceLength': nonceLength,
        'macLength': macLength,
      };
}

/// AndroidEncryptedPreferencesService implements an EncryptedPreferencesService for Android
class AndroidEncryptedPreferencesService extends EncryptedPreferencesService {
  static final AndroidEncryptedPreferencesService _instance =
      AndroidEncryptedPreferencesService._internal();
  factory AndroidEncryptedPreferencesService() => _instance;
  AndroidEncryptedPreferencesService._internal();

  _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: false,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      );

  late FlutterSecureStorage _secure;
  late SharedPreferences _preferences;
  final PreferencesService _prefs = PreferencesService();

  late int pin;

  List<int> get pinCode => pin.toRadixString(16).padLeft(32, '0').codeUnits;

  @override
  Future init(EncryptedPreferencesOptions options) async {
    _secure = FlutterSecureStorage(
      aOptions: _getAndroidOptions(),
    );
    _preferences = _prefs.instance;

    final aOptions = options as AndroidEncryptedPreferencesOptions;

    print('AndroidEncryptedPreferencesService.init');
    print(aOptions);

    print('from scratch?');

    if (aOptions.fromScratch) {
      // remove all keys
      await _secure.deleteAll();
      await _preferences.clear();
      return;
    }

    print('pin?');

    if (aOptions.pin != null) {
      // the intention is to set a pin code

      // pin should be verified and then set
      final p = aOptions.pin!;

      final hash = await _hash(p.toString());

      // check if there is a pin code saved
      final saved = _preferences.containsKey(pinCodeCheckKey);
      if (!saved) {
        // no pin code saved, set the key
        await _preferences.setString(pinCodeCheckKey, hash);

        _secure.write(key: pinCodeKey, value: p.toString());
        pin = p;

        await migrate(super.version);

        return;
      }

      // perform the pin code check here and throw if not correct
      final savedHash = _preferences.getString(pinCodeCheckKey);
      if (savedHash != hash) {
        throw Exception('invalid pin code');
      }

      _secure.write(key: pinCodeKey, value: p.toString());
      pin = p;

      await migrate(super.version);

      return;
    }

    // the intention is to use an existing pin code
    final potentialPins = await _secure.readAll();
    final securedPin = potentialPins[pinCodeKey];
    if (securedPin == null) {
      throw Exception('no pin code set');
    }

    final hash = await _hash(securedPin);

    print('saved pin?');

    // check if there is a pin code saved
    final saved = _preferences.containsKey(pinCodeCheckKey);
    if (!saved) {
      // no pin code saved, set the key
      await _preferences.setString(pinCodeCheckKey, hash);

      pin = int.parse(securedPin);

      await migrate(super.version);

      return;
    }

    // perform the pin code check here and throw if not correct
    final savedHash = _preferences.getString(pinCodeCheckKey);
    if (savedHash != hash) {
      throw Exception('invalid pin code');
    }

    pin = int.parse(securedPin);

    await migrate(super.version);
  }

  @override
  Future<void> migrate(int version) async {
    final int oldVersion = _preferences.getInt(versionPrefix) ?? 0;

    if (oldVersion == version) {
      return;
    }

    final migrations = {
      1: () async {
        final allBackups = await getAllWalletBackups();

        for (final backup in allBackups) {
          final saved = _preferences.containsKey(backup.legacyKey2);
          if (saved) {
            await _preferences.remove(backup.legacyKey2);
          }

          await _preferences.setString(
            backup.legacyKey2,
            await _encrypt(backup.value),
          );
        }

        // delete all old keys
        for (final backup in allBackups) {
          // legacy delete
          final saved = _preferences.containsKey(backup.legacyKey);
          if (saved) {
            await _preferences.remove(backup.legacyKey);
          }
        }
      },
      2: () async {
        final allBackups = await getAllWalletBackups();

        for (final backup in allBackups) {
          final saved = _preferences.containsKey(backup.key);
          if (saved) {
            await _preferences.remove(backup.key);
          }

          await _preferences.setString(
            backup.key,
            await _encrypt(backup.value),
          );
        }

        // delete all old keys
        for (final backup in allBackups) {
          // delete legacy keys
          final saved = _preferences.containsKey(
            backup.legacyKey2,
          );
          if (saved) {
            await _preferences.remove(
              backup.legacyKey2,
            );
          }
        }
      },
      3: () async {
        final allBackups = await getAllWalletBackups();

        final toDelete = <String>[];

        for (final backup in allBackups) {
          final saved = _preferences.containsKey(backup.key);
          if (!saved) {
            continue;
          }

          final account = await getLegacyAccountAddress(backup);
          if (account == null) {
            continue;
          }

          final newBackup = BackupWallet(
            address: account.hexEip55,
            privateKey: backup.privateKey,
            name: backup.name,
            alias: backup.alias,
          );

          await _preferences.setString(
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
          final saved = _preferences.containsKey(
            backup.key,
          );

          if (saved) {
            await _preferences.remove(
              backup.key,
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

    print('migrated from $oldVersion to $version');

    // after success, we can update the version
    await _preferences.setInt(versionPrefix, version);
  }

  /// _internalHash hashes a value using the pin code
  Future<String> _internalHash(String value) async {
    // select algorithm
    final algorithm = Sha256();

    // Hash
    final hash = await algorithm.hash(utf8.encode(value));

    return base64.encode(hash.bytes);
  }

  /// _hash calls _internalHash on a separate thread
  Future<String> _hash(String value) async {
    return await compute(_internalHash, value);
  }

  /// _internalDecrypt decrypts a value using the pin code
  Future<String> _internalDecrypt(String value) async {
    // base64 decode the combined data
    final encoded = base64.decode(value);

    // decode the combined data
    final data = EncryptedData.fromJson(jsonDecode(utf8.decode(encoded)));

    // select algorithm
    final algorithm = AesCtr.with256bits(macAlgorithm: Hmac.sha256());

    final secretBox = SecretBox.fromConcatenation(
      data.data,
      nonceLength: data.nonceLength,
      macLength: data.macLength,
    );

    // Parse de pin code into a secret key
    final secretKey = SecretKey(pinCode);

    // Decrypt
    final clearText = await algorithm.decryptString(
      secretBox,
      secretKey: secretKey,
    );

    return clearText;
  }

  /// _decrypt calls _internalDecrypt on a separate thread
  /// this is done to avoid blocking the main thread
  Future<String> _decrypt(String value) async {
    return await compute(_internalDecrypt, value);
  }

  // _internalEncrypt encrypts a value using the pin code
  Future<String> _internalEncrypt(String value) async {
    // select algorithm
    final algorithm = AesCtr.with256bits(macAlgorithm: Hmac.sha256());

    // Parse de pin code into a secret key
    final secretKey = SecretKey(pinCode);

    // Encrypt
    final secretBox = await algorithm.encryptString(
      value,
      secretKey: secretKey,
    );

    final encrypted = secretBox.concatenation();

    final data = EncryptedData(
      data: encrypted,
      nonceLength: secretBox.nonce.length,
      macLength: secretBox.mac.bytes.length,
    );

    // encode the combined data
    final encoded = utf8.encode(jsonEncode(data));

    // base64 encode the combined data
    final base64Encoded = base64.encode(encoded);

    return base64Encoded;
  }

  /// _encrypt calls _internalEncrypt on a separate thread
  /// this is done to avoid blocking the main thread
  Future<String> _encrypt(String value) async {
    return await compute(_internalEncrypt, value);
  }

  // handle wallet backups
  // use the prefix as a query to find a wallet backup
  // use the prefix + wallet address as a way to query the backup
  // store the json as a b64 encoded string, reason: we store the name of the wallet
  // key = wb_$wallet_address, value = $name|$privateKey

  // get all wallet backups
  @override
  Future<List<BackupWallet>> getAllWalletBackups() async {
    final allValues = _preferences.getKeys();
    final keys = allValues.where((key) => key.startsWith(backupPrefix));

    final List<BackupWallet> backups = [];

    for (final k in keys) {
      final value = _preferences.getString(k);
      if (value == null) {
        continue;
      }

      final decrypted = await _decrypt(value);

      final parsed = decrypted.split('|');
      if (parsed.length < 2) {
        // invalid backup, consider cleaning up in the future
        continue;
      }

      if (parsed.length == 3) {
        backups.add(BackupWallet(
          address: k.replaceFirst(backupPrefix, ''),
          privateKey: parsed[1],
          name: parsed[0],
          alias: parsed[2],
        ));
        continue;
      }

      if (parsed.length == 4) {
        backups.add(BackupWallet(
          name: parsed[0],
          address: parsed[1],
          privateKey: parsed[2],
          alias: parsed[3],
        ));
        continue;
      }

      backups.add(BackupWallet(
        address: k.replaceFirst(backupPrefix, ''),
        privateKey: parsed[1],
        name: parsed[0],
        alias: 'app',
      ));
    }

    backups.sort((a, b) => a.name.compareTo(b.name));

    return backups;
  }

  // set wallet backup
  @override
  Future<void> setWalletBackup(BackupWallet backup) async {
    final saved = _preferences.containsKey(backup.key);
    if (saved) {
      await _preferences.remove(backup.key);
    }

    await _preferences.setString(
      backup.key,
      await _encrypt(backup.value),
    );
  }

  // get wallet backup
  @override
  Future<BackupWallet?> getWalletBackup(String address, String alias) async {
    final wallets = await getAllWalletBackups();

    return wallets.firstWhereOrNull(
      (w) => w.address == address && w.alias == alias,
    );
  }

  // get wallet backups for alias
  @override
  Future<List<BackupWallet>> getWalletBackupsForAlias(String alias) async {
    final wallets = await getAllWalletBackups();

    return wallets.where((w) => w.alias == alias).toList();
  }

  // delete wallet backup
  @override
  Future<void> deleteWalletBackup(String address, String alias) async {
    final wallets = await getAllWalletBackups();

    final wallet = wallets.firstWhereOrNull(
      (w) => w.address == address && w.alias == alias,
    );

    if (wallet == null) {
      return;
    }

    await _preferences.remove(wallet.key);
  }

  // delete all wallet backups
  @override
  Future<void> deleteWalletBackups() async {
    await _preferences.clear();
  }
}
