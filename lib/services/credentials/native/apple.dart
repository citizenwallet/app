import 'dart:typed_data';

import 'package:citizenwallet/services/credentials/credentials.dart';
import 'package:citizenwallet/utils/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/crypto.dart';

class AppleCredentialsOptions implements CredentialsOptionsInterface {
  final String groupId;

  AppleCredentialsOptions({
    required this.groupId,
  });
}

class AppleCredentialsService extends CredentialsServiceInterface {
  static final AppleCredentialsService _instance =
      AppleCredentialsService._internal();

  factory AppleCredentialsService() {
    return _instance;
  }

  AppleCredentialsService._internal();

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

  late FlutterSecureStorage _secure;

  @override
  Future<void> init({CredentialsOptionsInterface? options}) async {
    if (options == null) {
      throw Exception('No options provided');
    }

    final appleOptions = options as AppleCredentialsOptions;
    _secure = FlutterSecureStorage(
      iOptions: _getIOSOptions(appleOptions.groupId),
      mOptions: _getMacOsOptions(appleOptions.groupId),
    );
  }

  @override
  Future<bool> isSetup() async {
    final key = await _secure.read(
      key: CredentialsServiceInterface.credentialStorageKey,
    );

    return key != null;
  }

  @override
  Future<void> setup({
    String?
        username, // for the sake of respecting the interface. iCloud allows us to control what gets put in the keychain and it's app + account based already.
    createKeyIfMissing,
  }) async {
    final exists = await _secure.containsKey(
      key: CredentialsServiceInterface
          .credentialStorageKey, // just use the app specific key so that it's predictable
    );

    Uint8List key;
    if (!exists) {
      key = generateKey();

      await _secure.write(
        key: CredentialsServiceInterface.credentialStorageKey,
        value: bytesToHex(key),
      );
    }
  }

  @override
  Future<void> manualSetup({
    String? username,
    required String manualKey,
    bool saveKey = false,
  }) async {
    await _secure.write(
      key: CredentialsServiceInterface.credentialStorageKey,
      value: manualKey,
    );
  }

  @override
  Future<Uint8List> encrypt(Uint8List data) async {
    final key = await _secure.read(
      key: CredentialsServiceInterface.credentialStorageKey,
    );

    if (key == null) {
      throw NotSetupException();
    }

    final encrypt = Encrypt(hexToBytes(key));

    return encrypt.encrypt(data);
  }

  @override
  Future<Uint8List> decrypt(Uint8List data) async {
    final key = await _secure.read(
      key: CredentialsServiceInterface.credentialStorageKey,
    );

    if (key == null) {
      throw NotSetupException();
    }

    final encrypt = Encrypt(hexToBytes(key));

    return encrypt.decrypt(data);
  }

  @override
  Future<String?> read(String key) {
    return _secure.read(key: key);
  }

  @override
  Future<Map<String, String>> readAll() {
    return _secure.readAll();
  }

  @override
  Future<void> write(String key, String value) {
    return _secure.write(key: key, value: value);
  }

  @override
  Future<bool> containsKey(String key) {
    return _secure.containsKey(key: key);
  }

  @override
  Future<void> delete(String key) {
    return _secure.delete(key: key);
  }

  @override
  Future<void> deleteCredentials() async {
    await _secure.deleteAll();
  }
}
