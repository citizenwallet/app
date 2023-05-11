import 'dart:async';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/utils/base64.dart';
import 'package:dartsv/dartsv.dart';
import 'package:flutter/foundation.dart';
// import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// import 'package:pointycastle/digests/keccak.dart';

import 'package:pointycastle/export.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

const netTimeoutSeconds = 10;
const streamTimeoutSeconds = 10;

const publicKeyHeader = 'x-pubkey';

class UnauthorizedException implements Exception {
  final String message = 'unauthorized';

  UnauthorizedException();
}

class StationRequest {
  final int version = 1;
  final DateTime expiry = DateTime.now();
  final String address;
  final String data;

  StationRequest({
    required this.address,
    required this.data,
  });

  // convert to json
  Map<String, dynamic> toJson() => {
        'version': version,
        'expiry': expiry.toIso8601String(),
        'address': address,
        'data': data,
      };

  // convert to encoded json
  String toEncodedJson() => jsonEncode(toJson());
}

class StationService {
  String baseURL;
  final String address;
  final EthPrivateKey receiverKey;
  String? senderKey;

  StationService({
    required this.baseURL,
    required this.address,
    required this.receiverKey,
  });

  String get privateKeyHex => bytesToHex(receiverKey.privateKey);

  String get publicKeyHex => bytesToHex(receiverKey.encodedPublicKey);

  void setBaseUrl(String url) {
    baseURL = url;
  }

  Uint8List hkdf(var ephPublicKeyUnc, var sharedSecretEcPointUnc) {
    var master = Uint8List.fromList(ephPublicKeyUnc + sharedSecretEcPointUnc);
    var aesKey = Uint8List(32);
    (HKDFKeyDerivator(SHA256Digest())..init(HkdfParameters(master, 32, null)))
        .deriveKey(null, 0, aesKey, 0);
    return aesKey;
  }

  // with help from:
  //  - https://stackoverflow.com/a/75571004/7012894
  //  - https://github.com/twostack/dartsv/tree/master
  String _decodeBody(String body) {
    final encryptedData = base64.decode(body);

    final Ecies ecies = Ecies();

    final SVPrivateKey pk = SVPrivateKey.fromBigInt(receiverKey.privateKeyInt);

    final decrypted = ecies.AESDecrypt(encryptedData, pk);

    final decoded = utf8.decode(decrypted);

    final json = jsonDecode(decoded);

    return base64String.decode(json['data']);
  }

  Future<String> decodeBody(String body) async {
    return await compute<String, String>(_decodeBody, body);
  }

  Future<String> _get({String? url}) async {
    final pubkey = receiverKey.publicKey.getEncoded(true);

    final response = await http.get(
      Uri.parse('$baseURL${url ?? ''}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'X-PubKey': bytesToHex(pubkey),
      },
    ).timeout(const Duration(seconds: netTimeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('error fetching data');
    }

    final body = jsonDecode(response.body);

    if (body['response_type'] != 'secure') {
      throw Exception('error invalid response');
    }

    // final sig = response.headers['X-Signature'];
    senderKey = response.headers[publicKeyHeader];

    return decodeBody(body['secure']);
  }

  Future<dynamic> post({
    String? url,
    required String signature,
    required String body,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseURL${url ?? ''}'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'X-PubKey': bytesToHex(receiverKey.encodedPublicKey),
            'X-Signature': signature,
          },
          body: body,
        )
        .timeout(const Duration(seconds: netTimeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('error sending data');
    }

    return jsonDecode(response.body);
  }

  Future<Chain> hello() async {
    final String response = await _get(url: '/hello');

    return Chain.fromJson(jsonDecode(response));
  }
}
