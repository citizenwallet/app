import 'dart:convert';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:flutter/foundation.dart';

import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

/// Signer loads a wallet from a json file and signs messages
class Signer {
  late EthPrivateKey _privateKey;

  Signer(this._privateKey);

  Signer.fromWalletFile(
    String walletFile,
    String password,
  ) {
    Wallet wallet = Wallet.fromJson(walletFile, password);

    _privateKey = wallet.privateKey;
  }

  EthPrivateKey get privateKey => _privateKey;

  String _sign(String data) {
    final signature =
        _privateKey.signToEcSignature(convertStringToUint8List(data));

    final msgsignature = Signature.fromMsgSignature(signature);

    final strsignature = jsonEncode(msgsignature.toJson());

    return bytesToHex(strsignature.codeUnits, include0x: true);
  }

  /// signs a message with the wallet's private key
  /// returns the signature as a hex string
  Future<String> sign(String data) {
    return compute(_sign, data);
  }
}

/// Extends the MsgSignature class from web3dart to allow for json conversion
class Signature extends MsgSignature {
  Signature(super.r, super.s, super.v);

  // construct Signature from MsgSignature
  factory Signature.fromMsgSignature(MsgSignature msgSignature) {
    return Signature(
      msgSignature.r,
      msgSignature.s,
      msgSignature.v,
    );
  }

  // construct Signature from json
  factory Signature.fromJson(Map<String, dynamic> json) {
    return Signature(
      BigInt.parse(json['r']),
      BigInt.parse(json['s']),
      json['v'],
    );
  }

  // convert Signature to json
  Map<String, dynamic> toJson() {
    return {
      'r': r.toString(),
      's': s.toString(),
      'v': v,
    };
  }
}

class SignatureVerifier {
  final String data;
  final String signature;
  final String address;
  final Uint8List publicKey;

  SignatureVerifier({
    required this.data,
    required this.signature,
    required this.address,
    required this.publicKey,
  });

  /// verify the signature of data with the public key in an isolate
  Future<bool> verify() async {
    return await compute(verifySignature, this);
  }
}

/// verify the signature of data with the public key.
/// verify the public key matches the address
bool verifySignature(SignatureVerifier verifier) {
  try {
    final recoveredAddress =
        bytesToHex(publicKeyToAddress(verifier.publicKey), include0x: true);

    if (recoveredAddress.toLowerCase() != verifier.address.toLowerCase()) {
      // at a minimum, the address must match the public key
      return false;
    }

    final sig = hexToBytes(verifier.signature);

    final decodedsig = jsonDecode(utf8.decode(sig));

    return isValidSignature(
      keccak256(convertStringToUint8List(verifier.data)),
      Signature.fromJson(decodedsig),
      convertBytesToUint8List(verifier.publicKey),
    );
  } catch (e) {
    print(e);
  }

  return false;
}
