import 'package:citizenwallet/services/accounts/accounts.dart';
import 'package:citizenwallet/services/accounts/native/android.dart';
import 'package:citizenwallet/services/accounts/native/apple.dart';
import 'package:citizenwallet/utils/platform.dart';

AccountsServiceInterface getAccountsService() {
  return isPlatformApple() ? AppleAccountsService() : AndroidAccountsService();
}
