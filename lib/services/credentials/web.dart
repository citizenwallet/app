import 'dart:typed_data';

import 'package:citizenwallet/services/credentials/credentials.dart';

class WebCredentialsService extends CredentialsServiceInterface {
  @override
  Future<void> init({CredentialsOptionsInterface? options}) async {}

  @override
  Future<bool> isSetup() async {
    return false;
  }

  @override
  Future<void> setup() async {}

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
