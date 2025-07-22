import 'package:citizenwallet/services/db/backup/accounts.dart';

export 'native/native.dart' if (dart.library.html) 'web.dart';

class NotFoundException implements Exception {
  final String message = 'not found';

  NotFoundException();
}

abstract class AccountsOptionsInterface {}

/// AccountsServiceInterface defines the interface for encrypted preferences
///
/// This is used to store wallet backups and the implementation is platform specific.
abstract class AccountsServiceInterface {
  final int _version = 5;

  int get version => _version;

  // init the service
  Future<void> init(AccountsOptionsInterface options);

  // migrate the service
  Future<void> migrate(int version);

  // handle wallet backups
  // use the prefix as a query to find a wallet backup
  // use the prefix + wallet address as a way to query the backup
  // store the json as a b64 encoded string, reason: we store the name of the wallet
  // key = wb_$wallet_address, value = $name|$privateKey

  // get all accounts
  Future<List<DBAccount>> getAllAccounts();

  // set account
  Future<void> setAccount(DBAccount account);

  // get account
  Future<DBAccount?> getAccount(String address, String alias, [String? accountFactoryAddress]);

  // get accounts for alias
  Future<List<DBAccount>> getAccountsForAlias(String alias);

  // delete account
  Future<void> deleteAccount(String address, String alias);

  // delete all accounts
  Future<void> deleteAllAccounts();

  Future<void> populatePrivateKeysFromEncryptedStorage() async {}

  Future<void> purgePrivateKeysAndAddToEncryptedStorage() async {}
}
