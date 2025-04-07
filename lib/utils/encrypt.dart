import 'dart:convert';
import 'dart:math';

import 'package:citizenwallet/utils/uint8.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';

Uint8List generateKey() {
  final random = Random.secure();
  final privateKey = EthPrivateKey.createRandom(random);
  Uint8List key = privateKey.privateKey;

  if (key.length == 33) {
    key = key.sublist(1);
  }

  return key;
}

class EncryptedData {
  final Uint8List data;
  final int nonceLength;
  final int macLength;

  EncryptedData({
    required this.data,
    required this.nonceLength,
    required this.macLength,
  });

  EncryptedData.fromJson(Map<String, dynamic> json)
      : data = base64.decode(json['data']),
        nonceLength = json['nonceLength'],
        macLength = json['macLength'];

  Map<String, dynamic> toJson() => {
        'data': base64.encode(data),
        'nonceLength': nonceLength,
        'macLength': macLength,
      };
}

class Encrypt {
  final List<int> _decryptKey;

  Encrypt(this._decryptKey);

  /// _internalDecrypt decrypts a value using the pin code
  Future<Uint8List> _internalDecrypt(Uint8List value) async {
    // select algorithm
    final algorithm = AesCtr.with256bits(macAlgorithm: Hmac.sha256());

    final secretBox = SecretBox.fromConcatenation(
      value,
      nonceLength: algorithm.nonceLength,
      macLength: algorithm.macAlgorithm.macLength,
    );

    // Parse de pin code into a secret key
    final secretKey = SecretKey(_decryptKey);

    // Decrypt
    final decrypted = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return convertBytesToUint8List(decrypted);
  }

  /// decrypt calls _internalDecrypt on a separate thread
  /// this is done to avoid blocking the main thread
  Future<Uint8List> decrypt(Uint8List value) async {
    return await compute(_internalDecrypt, value);
  }

  // _internalEncrypt encrypts a value using the pin code
  Future<Uint8List> _internalEncrypt(
    Uint8List value,
  ) async {
    // select algorithm
    final algorithm = AesCtr.with256bits(macAlgorithm: Hmac.sha256());

    // Parse de pin code into a secret key
    final secretKey = SecretKey(_decryptKey);

    // Encrypt
    final secretBox = await algorithm.encrypt(
      value,
      secretKey: secretKey,
    );

    final encrypted = secretBox.concatenation();

    return encrypted;
  }

  /// encrypt calls _internalEncrypt on a separate thread
  /// this is done to avoid blocking the main thread
  Future<Uint8List> encrypt(Uint8List value) async {
    return await compute(_internalEncrypt, value);
  }

  /// _internalB64Decrypt decrypts a value using the pin code
  Future<String> _internalB64Decrypt(String value) async {
    // base64 decode the combined data
    final encoded = base64.decode(value);

    // decode the combined data
    final data = EncryptedData.fromJson(jsonDecode(utf8.decode(encoded)));

    // select algorithm
    final algorithm = AesCtr.with256bits(macAlgorithm: Hmac.sha256());

    final secretBox = SecretBox.fromConcatenation(
      data.data,
      nonceLength: data.nonceLength,
      macLength: data.macLength,
    );

    // Parse de pin code into a secret key
    final secretKey = SecretKey(_decryptKey);

    // Decrypt
    final clearText = await algorithm.decryptString(
      secretBox,
      secretKey: secretKey,
    );

    return clearText;
  }

  /// b64Decrypt calls _internalB64Decrypt on a separate thread
  /// this is done to avoid blocking the main thread
  Future<String> b64Decrypt(String value) async {
    return await compute(_internalB64Decrypt, value);
  }

  // _internalB64Encrypt encrypts a value using the pin code
  Future<String> _internalB64Encrypt(
    String value,
  ) async {
    // select algorithm
    final algorithm = AesCtr.with256bits(macAlgorithm: Hmac.sha256());

    // Parse de pin code into a secret key
    final secretKey = SecretKey(_decryptKey);

    // Encrypt
    final secretBox = await algorithm.encryptString(
      value,
      secretKey: secretKey,
    );

    final encrypted = secretBox.concatenation();

    final data = EncryptedData(
      data: encrypted,
      nonceLength: secretBox.nonce.length,
      macLength: secretBox.mac.bytes.length,
    );

    // encode the combined data
    final encoded = utf8.encode(jsonEncode(data));

    // base64 encode the combined data
    final base64Encoded = base64.encode(encoded);

    return base64Encoded;
  }

  /// b64Encrypt calls _internalB64Encrypt on a separate thread
  /// this is done to avoid blocking the main thread
  Future<String> b64Encrypt(String value) async {
    return await compute(_internalB64Encrypt, value);
  }
}
