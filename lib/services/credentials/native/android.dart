import 'dart:typed_data';

import 'package:citizenwallet/services/credentials/credentials.dart';
import 'package:citizenwallet/utils/encrypt.dart';
import 'package:credential_manager/credential_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/crypto.dart';

class AndroidCredentialsService extends CredentialsServiceInterface {
  static final AndroidCredentialsService _instance =
      AndroidCredentialsService._internal();

  factory AndroidCredentialsService() {
    return _instance;
  }

  AndroidCredentialsService._internal();

  final CredentialManager _credentials = CredentialManager();
  late FlutterSecureStorage _secure;
  Encrypt? _encrypt;

  _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: true,
      );

  @override
  Future<void> init({CredentialsOptionsInterface? options}) async {
    if (!_credentials.isSupportedPlatform) {
      throw NotSupportedException();
    }

    _secure = FlutterSecureStorage(
      aOptions: _getAndroidOptions(),
    );

    // if supported
    await _credentials.init(preferImmediatelyAvailableCredentials: true);
  }

  @override
  Future<bool> isSetup() async {
    return _encrypt != null;
  }

  @override
  Future<void> setup({String? username}) async {
    try {
      // check if there is an encryption key available
      final credential = await _credentials.getPasswordCredentials();

      if (credential.password == null) {
        throw SourceMissingException();
      }

      _encrypt = Encrypt(hexToBytes(credential.password!));
    } catch (_) {
      // if not, create one
      // generate a random key
      final key = generateKey(32);

      await _credentials.savePasswordCredentials(
        PasswordCredential(
          username:
              username ?? CredentialsServiceInterface.credentialStorageKey,
          password: bytesToHex(key),
        ),
      );

      _encrypt = Encrypt(key);
    }
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
