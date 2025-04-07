import 'dart:typed_data';

import 'package:citizenwallet/services/credentials/credentials.dart';
import 'package:citizenwallet/utils/encrypt.dart';
import 'package:convert/convert.dart';
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
    final key = await _secure.read(
        key: CredentialsServiceInterface.credentialStorageKey);

    return key != null;
  }

  @override
  Future<void> setup({
    String? username,
    String? manualKey,
    createKeyIfMissing = true,
  }) async {
    Uint8List key;

    try {
      // check if there is an encryption key available
      final credential = await _credentials.getCredentials();

      if (credential.passwordCredential == null) {
        // this error should be handled differently, the credential is incompatible with the current setup
        throw SourceMissingException();
      }

      if (credential.passwordCredential!.password == null) {
        throw SourceMissingException();
      }

      key = hexToBytes(credential.passwordCredential!.password!);
    } catch (_) {
      if (!createKeyIfMissing) {
        throw SourceMissingException();
      }
      // if not, create one
      // generate a random key
      key = generateKey();

      await _credentials.savePasswordCredentials(
        PasswordCredential(
          username: username ??
              CredentialsServiceInterface
                  .credentialStorageKey, // since users select credentials themselves, it makes sense to use something that is familiar to them
          password: bytesToHex(key),
        ),
      );
    }

    await _secure.write(
      key: CredentialsServiceInterface
          .credentialStorageKey, // internally, we don't care about the username, we need someething predictable
      value: bytesToHex(key),
    );
  }

  @override
  Future<void> manualSetup({
    String? username,
    required String manualKey,
    bool saveKey = false,
  }) async {
    if (saveKey) {
      await _credentials.savePasswordCredentials(
        PasswordCredential(
          username: username ??
              CredentialsServiceInterface
                  .credentialStorageKey, // since users select credentials themselves, it makes sense to use something that is familiar to them
          password: manualKey,
        ),
      );
    }

    await _secure.write(
      key: CredentialsServiceInterface
          .credentialStorageKey, // internally, we don't care about the username, we need someething predictable
      value: manualKey,
    );
  }

  @override
  Future<Uint8List> encrypt(Uint8List data) async {
    final key = await _secure.read(
        key: CredentialsServiceInterface.credentialStorageKey);

    if (key == null) {
      throw NotSetupException();
    }

    final encrypt = Encrypt(hexToBytes(key));

    return encrypt.encrypt(data);
  }

  @override
  Future<Uint8List> decrypt(Uint8List data) async {
    final key = await _secure.read(
        key: CredentialsServiceInterface.credentialStorageKey);

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
