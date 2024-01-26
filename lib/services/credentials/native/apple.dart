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
  Encrypt? _encrypt;

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
    return _encrypt != null;
  }

  @override
  Future<void> setup() async {
    final exists = await _secure.containsKey(
      key: CredentialsServiceInterface.credentialStorageKey,
    );

    Uint8List key;
    if (!exists) {
      key = generateKey(32);

      await _secure.write(
        key: CredentialsServiceInterface.credentialStorageKey,
        value: bytesToHex(key),
      );
    } else {
      final potentialKey = await _secure.read(
        key: CredentialsServiceInterface.credentialStorageKey,
      );

      if (potentialKey == null) {
        throw SourceMissingException();
      }

      key = hexToBytes(potentialKey);
    }

    _encrypt = Encrypt(key);
  }

  @override
  Future<Uint8List> encrypt(Uint8List data) async {
    if (_encrypt == null) {
      throw NotSetupException();
    }

    return _encrypt!.encrypt(data);
  }

  @override
  Future<Uint8List> decrypt(Uint8List data) async {
    if (_encrypt == null) {
      throw NotSetupException();
    }

    return _encrypt!.decrypt(data);
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

    _encrypt = null;
  }
}
