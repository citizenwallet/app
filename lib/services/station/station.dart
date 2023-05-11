import 'dart:async';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/utils/base64.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:convert/convert.dart';
import 'package:dartsv/dartsv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pointycastle/export.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

const netTimeoutSeconds = 10;
const streamTimeoutSeconds = 10;

const publicKeyHeaderKey = 'x-pubkey';
const signatureKeyHeaderKey = 'x-signature';

class UnauthorizedException implements Exception {
  final String message = 'unauthorized';

  UnauthorizedException();
}

class StationRequest {
  final int version = 1;
  DateTime expiry = DateTime.now();
  final String address;
  final String data;

  StationRequest({
    required this.address,
    required this.data,
  });

  // from json
  StationRequest.fromJson(Map<String, dynamic> json)
      : expiry = DateTime.parse(json['expiry']),
        address = json['address'],
        data = base64String.decode(json['data']);

  // convert to json
  Map<String, dynamic> toJson() => {
        'version': version,
        'expiry': expiry.toIso8601String(),
        'address': address,
        'data': base64String.encode(data),
      };

  // convert to encoded json
  String toEncodedJson() => jsonEncode(toJson());
}

class VerificationRequest {
  StationRequest decrypted;
  String encodedSignature;
  String senderKey;

  VerificationRequest({
    required this.decrypted,
    required this.encodedSignature,
    required this.senderKey,
  });
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
  StationRequest _decryptBody(String body) {
    // base64 decode the body
    final encryptedData = base64.decode(body);

    // instantiate the dart ecies library
    final Ecies ecies = Ecies();

    // extract the private key in a usable format for the library
    final SVPrivateKey pk = SVPrivateKey.fromBigInt(receiverKey.privateKeyInt);

    // decrypt the decoded body
    final decrypted = ecies.AESDecrypt(encryptedData, pk);

    // decode the decrypted data
    final decoded = utf8.decode(decrypted);

    print(decoded.length);

    // json decode
    final json = jsonDecode(decoded);

    // create a station request from the json
    final sreq = StationRequest.fromJson(json);

    // pass the data to the caller
    return sreq;
  }

  Future<StationRequest> decryptBody(String body) async {
    return await compute<String, StationRequest>(_decryptBody, body);
  }

  // verify the signature of the response
  Future<bool> _verifySignature(
    VerificationRequest args,
  ) async {
    final StationRequest decrypted = args.decrypted;
    final String encodedSignature = args.encodedSignature;
    final String senderKey = args.senderKey;

    // check the expiry
    if (decrypted.expiry.isBefore(DateTime.now())) {
      return false;
    }

    final signature = hexToBytes(encodedSignature);

    // https://github.com/simolus3/web3dart/issues/207#issue-1021153710
    final v = signature.elementAt(0);
    final r = bytesToInt(signature.getRange(1, 33).toList());
    final s = bytesToInt(signature.getRange(33, 65).toList());
    final msg = MsgSignature(
      r,
      s,
      v,
    );

    final encodedReq = decrypted.toEncodedJson();

    final messageHash =
        keccak256(convertBytesToUint8List(utf8.encode(encodedReq)));

    final publicKey = ecRecover(messageHash, msg);

    // the address in the header must match the address derived from the signature
    final address = bytesToHex(publicKeyToAddress(publicKey), include0x: true);
    if (address.toLowerCase() != decrypted.address.toLowerCase()) {
      return false;
    }

    final isValid = isValidSignature(messageHash, msg, publicKey);

    return isValid;
  }

  Future<bool> verifySignature(
    StationRequest decrypted,
    String encodedSignature,
    String senderKey,
  ) async {
    return await compute<VerificationRequest, bool>(
      _verifySignature,
      VerificationRequest(
        decrypted: decrypted,
        encodedSignature: encodedSignature,
        senderKey: senderKey,
      ),
    );
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

    final decrypted = await decryptBody(body['secure']);

    final sig = response.headers[signatureKeyHeaderKey];
    if (sig == null) {
      throw Exception('error missing signature');
    }

    final headerPubKey = response.headers[publicKeyHeaderKey];
    if (headerPubKey == null) {
      throw Exception('error missing send key');
    }

    final isVerified = await verifySignature(decrypted, sig, headerPubKey);
    if (!isVerified) {
      throw Exception('error invalid signature');
    }

    senderKey = headerPubKey;

    return decrypted.data;
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
