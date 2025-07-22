import 'package:citizenwallet/services/accounts/accounts.dart';
import 'package:citizenwallet/services/db/backup/accounts.dart';

/// WebAccountsOptions
class WebAccountsOptions implements AccountsOptionsInterface {
  final String groupId;

  WebAccountsOptions({
    required this.groupId,
  });
}

/// WebAccountsService implements an AccountsServiceInterface for web
class WebAccountsService extends AccountsServiceInterface {
  static final WebAccountsService _instance = WebAccountsService._internal();
  factory WebAccountsService() => _instance;
  WebAccountsService._internal();

  @override
  Future init(AccountsOptionsInterface options) async {
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
  Future<List<DBAccount>> getAllAccounts() async {
    return [];
  }

  // set wallet backup
  @override
  Future<void> setAccount(DBAccount backup) async {}

  // get wallet backup
  @override
  Future<DBAccount?> getAccount(String address, String alias, [String? accountFactoryAddress]) async {
    return null;
  }

  // get wallet backups for alias
  @override
  Future<List<DBAccount>> getAccountsForAlias(String alias) async {
    return [];
  }

  // delete wallet backup
  @override
  Future<void> deleteAccount(String address, String alias) async {}

  // delete all wallet backups
  @override
  Future<void> deleteAllAccounts() async {}
}

AccountsServiceInterface getAccountsService() {
  return WebAccountsService();
}
