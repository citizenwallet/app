import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _backupPrefix = 'w_bkp_';

class NotFoundException implements Exception {
  final String message = 'not found';

  NotFoundException();
}

class BackupWallet {
  final String address;
  final String privateKey;
  final String name;

  BackupWallet({
    required this.address,
    required this.privateKey,
    required this.name,
  });

  BackupWallet.fromJson(Map<String, dynamic> json)
      : address = json['address'],
        privateKey = json['privateKey'],
        name = json['name'];

  Map<String, dynamic> toJson() => {
        'address': address,
        'privateKey': privateKey,
        'name': name,
      };

  String get key => '$_backupPrefix${address.toLowerCase()}';
  String get value => '$name|$privateKey';
}

class EncryptedPreferencesService {
  static final EncryptedPreferencesService _instance =
      EncryptedPreferencesService._internal();
  factory EncryptedPreferencesService() => _instance;
  EncryptedPreferencesService._internal();

  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      );

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

  Future init(String groupId) async {
    _preferences = FlutterSecureStorage(
      iOptions: _getIOSOptions(groupId),
      aOptions: _getAndroidOptions(),
      mOptions: _getMacOsOptions(groupId),
    );
  }

  // handle wallet backups
  // use the prefix as a query to find a wallet backup
  // use the prefix + wallet address as a way to query the backup
  // store the json as a b64 encoded string, reason: we store the name of the wallet
  // key = wb_$wallet_address, value = $name|$privateKey

  // get all wallet backups
  Future<List<BackupWallet>> getAllWalletBackups() async {
    final allValues = await _preferences.readAll();
    final keys = allValues.keys.where((key) => key.startsWith(_backupPrefix));

    final List<BackupWallet> backups = [];

    for (final k in keys) {
      final parsed = allValues[k]!.split('|');
      if (parsed.length != 2) {
        // invalid backup, consider cleaning up in the future
        continue;
      }

      backups.add(BackupWallet(
        address: k.replaceFirst(_backupPrefix, ''),
        privateKey: parsed[1],
        name: parsed[0],
      ));
    }

    backups.sort((a, b) => a.name.compareTo(b.name));

    return backups;
  }

  // set wallet backup
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
  Future<BackupWallet?> getWalletBackup(String address) async {
    final value =
        await _preferences.read(key: '$_backupPrefix${address.toLowerCase()}');
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
  Future<void> deleteWalletBackup(String address) async {
    final saved = await _preferences.containsKey(
        key: '$_backupPrefix${address.toLowerCase()}');
    if (saved) {
      await _preferences.delete(key: '$_backupPrefix${address.toLowerCase()}');
    }
  }
}
