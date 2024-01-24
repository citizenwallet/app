import 'package:citizenwallet/services/accounts/accounts.dart';
import 'package:citizenwallet/services/db/db.dart';

class AndroidAccountsOptions implements AccountsOptionsInterface {
  final AccountsDBService accountsDB;

  AndroidAccountsOptions({
    required this.accountsDB,
  });
}

/// AccountsOptions
class AppleAccountsOptions implements AccountsOptionsInterface {
  final String groupId;
  final AccountsDBService accountsDB;

  AppleAccountsOptions({
    required this.groupId,
    required this.accountsDB,
  });
}
