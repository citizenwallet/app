import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';

/// AppleEncryptedPreferencesOptions
class AppleEncryptedPreferencesOptions implements EncryptedPreferencesOptions {
  final String groupId;

  AppleEncryptedPreferencesOptions({
    required this.groupId,
  });
}

/// WebEncryptedPreferencesService implements an EncryptedPreferencesService for web
class WebEncryptedPreferencesService implements EncryptedPreferencesService {
  static final WebEncryptedPreferencesService _instance =
      WebEncryptedPreferencesService._internal();
  factory WebEncryptedPreferencesService() => _instance;
  WebEncryptedPreferencesService._internal();

  @override
  Future init(EncryptedPreferencesOptions options) async {}

  // handle wallet backups
  // use the prefix as a query to find a wallet backup
  // use the prefix + wallet address as a way to query the backup
  // store the json as a b64 encoded string, reason: we store the name of the wallet
  // key = wb_$wallet_address, value = $name|$privateKey

  // get all wallet backups
  @override
  Future<List<BackupWallet>> getAllWalletBackups() async {
    return [];
  }

  // set wallet backup
  @override
  Future<void> setWalletBackup(BackupWallet backup) async {}

  // get wallet backup
  @override
  Future<BackupWallet?> getWalletBackup(String address) async {
    return null;
  }

  // delete wallet backup
  @override
  Future<void> deleteWalletBackup(String address) async {}

  // delete all wallet backups
  @override
  Future<void> deleteWalletBackups() async {}
}
