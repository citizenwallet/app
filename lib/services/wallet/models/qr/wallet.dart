import 'dart:convert';
import 'dart:typed_data';

import 'package:citizenwallet/services/wallet/models/qr/qr.dart';
import 'package:citizenwallet/services/wallet/models/signer.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';

class QRWallet extends QR {
  static const int _version = 1;
  static const String _type = 'qr_wallet';
  late QRWalletData data;

  QRWallet({
    required super.version,
    required super.type,
    required super.raw,
    required super.signature,
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

  @override
  Future<bool> verifyData() async {
    final SignatureVerifier verifier = SignatureVerifier(
      data: jsonEncode(data.toJson()),
      signature: signature,
      publicKey: data.publicKey,
    );

    final bool verified = await verifier.verify();

    return verified;
  }
}

class QRWalletData {
  final Map<String, dynamic> wallet;
  final int chainId;
  final String address;
  final Uint8List publicKey;

  QRWalletData({
    required this.wallet,
    required this.chainId,
    required this.address,
    required this.publicKey,
  });

  factory QRWalletData.fromJson(Map<String, dynamic> json) {
    return QRWalletData(
      wallet: json['wallet'],
      chainId: json['chainId'],
      address: json['address'],
      publicKey: hexToBytes(json['public_key']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wallet': wallet,
      'chainId': chainId,
      'address': address,
      'public_key': bytesToHex(publicKey),
    };
  }
}
