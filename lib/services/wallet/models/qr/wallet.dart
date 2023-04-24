import 'dart:convert';
import 'dart:typed_data';

import 'package:citizenwallet/services/wallet/models/qr/qr.dart';
import 'package:citizenwallet/services/wallet/models/signer.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';

class QRWallet extends QR {
  static const int _version = 1;
  static const QRType _type = QRType.qrWallet;
  late QRWalletData data;

  QRWallet({
    super.version = 1,
    super.type = QRType.qrWallet,
    required super.raw,
    super.signature = hexPadding,
  }) {
    if (super.version != _version) {
      throw Exception('QR version mismatch');
    }
    if (super.type != _type) {
      throw Exception('QR type mismatch');
    }

    // parse data
    final data = QRWalletData.fromJson(raw);

    // data is parsed, assign and continue
    this.data = data;
  }

  /// verifyData verifies the data of the QR code
  @override
  Future<bool> verifyData() async {
    final SignatureVerifier verifier = SignatureVerifier(
      data: jsonEncode(raw),
      signature: signature,
      address: data.address,
      publicKey: data.publicKey,
    );

    final bool verified = await verifier.verify();

    return verified;
  }
}

class QRWalletData {
  final Map<String, dynamic> wallet;
  final String address;
  final Uint8List publicKey;

  QRWalletData({
    required this.wallet,
    required this.address,
    required this.publicKey,
  });

  factory QRWalletData.fromJson(Map<String, dynamic> json) {
    return QRWalletData(
      wallet: json['wallet'],
      address: json['address'],
      publicKey: hexToBytes(json['public_key']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wallet': wallet,
      'address': address,
      'public_key': bytesToHex(publicKey),
    };
  }
}
