import 'package:citizenwallet/services/credentials/backup.dart';

export 'native/native.dart' if (dart.library.html) 'web.dart';

class NotFoundException implements Exception {
  final String message = 'not found';

  NotFoundException();
}

abstract class CredentialsOptionsInterface {}

/// CredentialsServiceInterface defines the interface for encrypted preferences
///
/// This is used to store wallet backups and the implementation is platform specific.
abstract class CredentialsServiceInterface {
  final int _version = 3;

  int get version => _version;

  // init the service
  Future<void> init(CredentialsOptionsInterface options);

  // migrate the service
  Future<void> migrate(int version);

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
  Future<BackupWallet?> getWalletBackup(String address, String alias);

  // get wallet backups for alias
  Future<List<BackupWallet>> getWalletBackupsForAlias(String alias);

  // delete wallet backup
  Future<void> deleteWalletBackup(String address, String alias);

  // delete all wallet backups
  Future<void> deleteWalletBackups();
}
