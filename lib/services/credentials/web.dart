import 'dart:typed_data';

import 'package:citizenwallet/services/credentials/credentials.dart';

class WebCredentialsService extends CredentialsServiceInterface {
  static final WebCredentialsService _instance =
      WebCredentialsService._internal();

  factory WebCredentialsService() {
    return _instance;
  }

  WebCredentialsService._internal();

  @override
  Future<void> init({CredentialsOptionsInterface? options}) async {}

  @override
  Future<bool> isSetup() async {
    return false;
  }

  @override
  Future<void> setup({String? username}) async {}

  @override
  Future<Uint8List> encrypt(Uint8List data) async {
    return Future.value(Uint8List(0));
  }

  @override
  Future<Uint8List> decrypt(Uint8List data) async {
    return Future.value(Uint8List(0));
  }

  @override
  Future<String?> read(String key) async {
    return null;
  }

  @override
  Future<Map<String, String>> readAll() {
    return Future.value({});
  }

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<bool> containsKey(String key) async {
    return Future.value(false);
  }

  @override
  Future<void> delete(String key) async {}

  @override
  Future<void> deleteCredentials() async {}
}

CredentialsServiceInterface getCredentialsService() {
  return WebCredentialsService();
}
