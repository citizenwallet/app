import 'dart:convert';

import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
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
class AndroidEncryptedPreferencesService
    implements EncryptedPreferencesService {
  static final AndroidEncryptedPreferencesService _instance =
      AndroidEncryptedPreferencesService._internal();
  factory AndroidEncryptedPreferencesService() => _instance;
  AndroidEncryptedPreferencesService._internal();

  _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: true,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      );

  late FlutterSecureStorage _secure;
  late SharedPreferences _preferences;

  late int pin;

  List<int> get pinCode => pin.toRadixString(16).padLeft(32, '0').codeUnits;

  @override
  Future init(EncryptedPreferencesOptions options) async {
    _secure = FlutterSecureStorage(
      aOptions: _getAndroidOptions(),
    );
    _preferences = await SharedPreferences.getInstance();

    final aOptions = options as AndroidEncryptedPreferencesOptions;

    if (aOptions.fromScratch) {
      // remove all keys
      await _secure.deleteAll();
      await _preferences.clear();
      return;
    }

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

        return;
      }

      // perform the pin code check here and throw if not correct
      final savedHash = _preferences.getString(pinCodeCheckKey);
      if (savedHash != hash) {
        throw Exception('invalid pin code');
      }

      _secure.write(key: pinCodeKey, value: p.toString());
      pin = p;

      return;
    }

    // the intention is to use an existing pin code
    final securedPin = await _secure.read(key: pinCodeKey);
    if (securedPin == null) {
      throw Exception('no pin code set');
    }

    final hash = await _hash(securedPin);

    // check if there is a pin code saved
    final saved = _preferences.containsKey(pinCodeCheckKey);
    if (!saved) {
      // no pin code saved, set the key
      await _preferences.setString(pinCodeCheckKey, hash);

      pin = int.parse(securedPin);
      return;
    }

    // perform the pin code check here and throw if not correct
    final savedHash = _preferences.getString(pinCodeCheckKey);
    if (savedHash != hash) {
      throw Exception('invalid pin code');
    }

    pin = int.parse(securedPin);
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
      if (parsed.length != 2) {
        // invalid backup, consider cleaning up in the future
        continue;
      }

      backups.add(BackupWallet(
        address: k.replaceFirst(backupPrefix, ''),
        privateKey: parsed[1],
        name: parsed[0],
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
  Future<BackupWallet?> getWalletBackup(String address) async {
    final value =
        _preferences.getString('$backupPrefix${address.toLowerCase()}');
    if (value == null) {
      return null;
    }

    final decrypted = await _decrypt(value);
    final parsed = decrypted.split('|');

    return BackupWallet(
      address: address,
      privateKey: parsed[1],
      name: parsed[0],
    );
  }

  // delete wallet backup
  @override
  Future<void> deleteWalletBackup(String address) async {
    final saved =
        _preferences.containsKey('$backupPrefix${address.toLowerCase()}');
    if (saved) {
      await _preferences.remove('$backupPrefix${address.toLowerCase()}');
    }
  }

  // delete all wallet backups
  @override
  Future<void> deleteWalletBackups() async {
    await _preferences.clear();
  }
}
