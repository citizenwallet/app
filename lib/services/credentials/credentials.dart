import 'dart:typed_data';

export 'native/native.dart' if (dart.library.html) 'web.dart';

class NotSupportedException implements Exception {
  final String message = 'credentials not supported';

  NotSupportedException();
}

class SourceMissingException implements Exception {
  final String message = 'credentials source missing';

  SourceMissingException();
}

class NotSetupException implements Exception {
  final String message = 'credentials not set up';

  NotSetupException();
}

abstract class CredentialsOptionsInterface {}

abstract class CredentialsServiceInterface {
  static const credentialStorageKey = 'app@cw';

  Future<void> init({CredentialsOptionsInterface? options});

  Future<bool> isSetup();

  Future<void> setup();

  Future<Uint8List> encrypt(Uint8List data);

  Future<Uint8List> decrypt(Uint8List data);

  Future<String?> read(String key);

  Future<Map<String, String>> readAll();

  Future<void> write(String key, String value);

  Future<bool> containsKey(String key);

  Future<void> delete(String key);

  Future<void> deleteCredentials();
}
