import 'package:citizenwallet/services/credentials/credentials.dart';

class AndroidCredentialsOptions implements CredentialsOptionsInterface {
  final int? pin;
  final bool fromScratch;

  AndroidCredentialsOptions({
    this.pin,
    this.fromScratch = false,
  });
}

/// CredentialsOptions
class AppleCredentialsOptions implements CredentialsOptionsInterface {
  final String groupId;

  AppleCredentialsOptions({
    required this.groupId,
  });
}
