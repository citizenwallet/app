import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptedPreferencesService {
  static final EncryptedPreferencesService _instance =
      EncryptedPreferencesService._internal();
  factory EncryptedPreferencesService() => _instance;
  EncryptedPreferencesService._internal();

  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  IOSOptions _getIOSOptions() => const IOSOptions(
        accessibility: KeychainAccessibility.unlocked,
      );

  MacOsOptions _getMacOsOptions() => const MacOsOptions(
        accessibility: KeychainAccessibility.unlocked,
      );

  late FlutterSecureStorage _preferences;

  Future init() async {
    _preferences = FlutterSecureStorage(
      iOptions: _getIOSOptions(),
      aOptions: _getAndroidOptions(),
      mOptions: _getMacOsOptions(),
    );
  }

  Future<String?> getString(String key) async {
    return _preferences.read(key: key);
  }

  Future<void> setWalletPassword(String address, String password) async {
    final savedValue =
        await _preferences.read(key: 'w_${address.toLowerCase()}');
    if (savedValue != null) {
      await _preferences.delete(key: 'w_${address.toLowerCase()}');
    }

    await _preferences.write(
        key: 'w_${address.toLowerCase()}', value: password);
  }

  // get wallet password
  Future<String?> getWalletPassword(String address) async {
    return _preferences.read(key: 'w_${address.toLowerCase()}');
  }
}
