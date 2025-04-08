import 'package:citizenwallet/services/credentials/credentials.dart';
import 'package:citizenwallet/services/credentials/native/android.dart';
import 'package:citizenwallet/services/credentials/native/apple.dart';
import 'package:citizenwallet/utils/platform.dart';

CredentialsServiceInterface getCredentialsService() {
  return isPlatformApple()
      ? AppleCredentialsService()
      : AndroidCredentialsService();
}
