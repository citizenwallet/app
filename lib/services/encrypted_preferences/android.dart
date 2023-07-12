import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AndroidEncryptedPreferencesService implements an EncryptedPreferencesService for Android
class AndroidEncryptedPreferencesService
    implements EncryptedPreferencesService {
  static final AndroidEncryptedPreferencesService _instance =
      AndroidEncryptedPreferencesService._internal();
  factory AndroidEncryptedPreferencesService() => _instance;
  AndroidEncryptedPreferencesService._internal();

  late SharedPreferences _preferences;

  @override
  Future init() async {}

  // handle wallet backups
  // use the prefix as a query to find a wallet backup
  // use the prefix + wallet address as a way to query the backup
  // store the json as a b64 encoded string, reason: we store the name of the wallet
  // key = wb_$wallet_address, value = $name|$privateKey

  // get all wallet backups
  @override
  Future<List<BackupWallet>> getAllWalletBackups() async {
    throw UnimplementedError();
  }

  // set wallet backup
  @override
  Future<void> setWalletBackup(BackupWallet backup) async {
    throw UnimplementedError();
  }

  // get wallet backup
  @override
  Future<BackupWallet?> getWalletBackup(String address) async {
    throw UnimplementedError();
  }

  // delete wallet backup
  @override
  Future<void> deleteWalletBackup(String address) async {
    throw UnimplementedError();
  }

  // delete all wallet backups
  @override
  Future<void> deleteWalletBackups() async {
    throw UnimplementedError();
  }
}
