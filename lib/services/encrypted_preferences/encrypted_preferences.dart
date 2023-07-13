import 'package:citizenwallet/services/encrypted_preferences/android.dart';
import 'package:citizenwallet/services/encrypted_preferences/apple.dart';
import 'package:citizenwallet/services/encrypted_preferences/web.dart';
import 'package:citizenwallet/utils/platform.dart';
import 'package:flutter/foundation.dart';

const String backupPrefix = 'w_bkp_';

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

  String get key => '$backupPrefix${address.toLowerCase()}';
  String get value => '$name|$privateKey';
}

abstract class EncryptedPreferencesOptions {}

/// EncryptedPreferencesService defines the interface for encrypted preferences
///
/// This is used to store wallet backups and the implementation is platform specific.
abstract class EncryptedPreferencesService {
  // init the service
  Future<void> init(EncryptedPreferencesOptions options);

  // handle wallet backups
  // use the prefix as a query to find a wallet backup
  // use the prefix + wallet address as a way to query the backup
  // store the json as a b64 encoded string, reason: we store the name of the wallet
  // key = wb_$wallet_address, value = $name|$privateKey

  // get all wallet backups
  Future<List<BackupWallet>> getAllWalletBackups();

  // set wallet backup
  Future<void> setWalletBackup(BackupWallet backup);

  // get wallet backup
  Future<BackupWallet?> getWalletBackup(String address);

  // delete wallet backup
  Future<void> deleteWalletBackup(String address);

  // delete all wallet backups
  Future<void> deleteWalletBackups();
}

EncryptedPreferencesService getEncryptedPreferencesService() {
  if (kIsWeb) {
    print('EncryptedPreferencesService is not supported on web');
    return WebEncryptedPreferencesService();
  }

  return isPlatformApple()
      ? AppleEncryptedPreferencesService()
      : AndroidEncryptedPreferencesService();
}
