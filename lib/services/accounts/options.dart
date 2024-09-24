import 'package:citizenwallet/services/accounts/accounts.dart';
import 'package:citizenwallet/services/db/backup/db.dart';

class AndroidAccountsOptions implements AccountsOptionsInterface {
  final AccountBackupDBService accountsDB;

  AndroidAccountsOptions({
    required this.accountsDB,
  });
}

/// AccountsOptions
class AppleAccountsOptions implements AccountsOptionsInterface {
  final String groupId;
  final AccountBackupDBService accountsDB;

  AppleAccountsOptions({
    required this.groupId,
    required this.accountsDB,
  });
}
