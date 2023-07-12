import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AppleEncryptedPreferencesService implements an EncryptedPreferencesService for iOS and macOS
class AppleEncryptedPreferencesService implements EncryptedPreferencesService {
  static final AppleEncryptedPreferencesService _instance =
      AppleEncryptedPreferencesService._internal();
  factory AppleEncryptedPreferencesService() => _instance;
  AppleEncryptedPreferencesService._internal();

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

  late FlutterSecureStorage _preferences;

  @override
  Future init() async {
    final groupId = dotenv.get(
      'ENCRYPTED_STORAGE_GROUP_ID',
    );

    print(groupId);

    _preferences = FlutterSecureStorage(
      iOptions: _getIOSOptions(groupId),
      mOptions: _getMacOsOptions(groupId),
    );
  }

  // handle wallet backups
  // use the prefix as a query to find a wallet backup
  // use the prefix + wallet address as a way to query the backup
  // store the json as a b64 encoded string, reason: we store the name of the wallet
  // key = wb_$wallet_address, value = $name|$privateKey

  // get all wallet backups
  @override
  Future<List<BackupWallet>> getAllWalletBackups() async {
    final allValues = await _preferences.readAll();
    final keys = allValues.keys.where((key) => key.startsWith(backupPrefix));

    final List<BackupWallet> backups = [];

    for (final k in keys) {
      final parsed = allValues[k]!.split('|');
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
    final saved = await _preferences.containsKey(key: backup.key);
    if (saved) {
      await _preferences.delete(key: backup.key);
    }

    await _preferences.write(
      key: backup.key,
      value: backup.value,
    );
  }

  // get wallet backup
  @override
  Future<BackupWallet?> getWalletBackup(String address) async {
    final value =
        await _preferences.read(key: '$backupPrefix${address.toLowerCase()}');
    if (value == null) {
      return null;
    }

    final parsed = value.split('|');

    return BackupWallet(
      address: address,
      privateKey: parsed[1],
      name: parsed[0],
    );
  }

  // delete wallet backup
  @override
  Future<void> deleteWalletBackup(String address) async {
    final saved = await _preferences.containsKey(
        key: '$backupPrefix${address.toLowerCase()}');
    if (saved) {
      await _preferences.delete(key: '$backupPrefix${address.toLowerCase()}');
    }
  }

  // delete all wallet backups
  @override
  Future<void> deleteWalletBackups() async {
    await _preferences.deleteAll();
  }
}
