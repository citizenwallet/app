import 'package:citizenwallet/services/credentials/backup.dart';
import 'package:citizenwallet/services/credentials/credentials.dart';

/// WebCredentialsOptions
class WebCredentialsOptions implements CredentialsOptionsInterface {
  final String groupId;

  WebCredentialsOptions({
    required this.groupId,
  });
}

/// WebCredentialsService implements an CredentialsServiceInterface for web
class WebCredentialsService extends CredentialsServiceInterface {
  static final WebCredentialsService _instance =
      WebCredentialsService._internal();
  factory WebCredentialsService() => _instance;
  WebCredentialsService._internal();

  @override
  Future init(CredentialsOptionsInterface options) async {
    await migrate(super.version);
  }

  @override
  Future<void> migrate(int version) async {}

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
  Future<BackupWallet?> getWalletBackup(String address, String alias) async {
    return null;
  }

  // get wallet backups for alias
  @override
  Future<List<BackupWallet>> getWalletBackupsForAlias(String alias) async {
    return [];
  }

  // delete wallet backup
  @override
  Future<void> deleteWalletBackup(String address, String alias) async {}

  // delete all wallet backups
  @override
  Future<void> deleteWalletBackups() async {}
}

CredentialsServiceInterface getCredentialsService() {
  return WebCredentialsService();
}
