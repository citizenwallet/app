import 'dart:convert';
import 'dart:typed_data';

import 'package:citizenwallet/services/wallet/models/qr/qr.dart';
import 'package:citizenwallet/services/wallet/models/signer.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:web3dart/crypto.dart';

class QRTransactionRequest extends QR {
  static const int _version = 1;
  static const String _type = 'qr_tr_req';
  late QRTransactionRequestData data;

  QRTransactionRequest({
    super.version = 1,
    super.type = 'qr_tr_req',
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
    final data = QRTransactionRequestData.fromJson(raw);

    // data is parsed, assign and continue
    this.data = data;
  }

  @override
  Future<bool> verifyData() async {
    final SignatureVerifier verifier = SignatureVerifier(
      data: jsonEncode(data.toJson()),
      signature: signature,
      address: data.address,
      publicKey: data.publicKey,
    );

    final bool verified = await verifier.verify();

    return verified;
  }
}

class QRTransactionRequestData {
  final int chainId;
  final String address;
  final double amount;
  final String message;
  final Uint8List publicKey;

  QRTransactionRequestData({
    required this.chainId,
    required this.address,
    required this.amount,
    this.message = '',
    required this.publicKey,
  });

  factory QRTransactionRequestData.fromJson(Map<String, dynamic> json) {
    return QRTransactionRequestData(
      chainId: json['chainId'],
      address: json['address'],
      amount: json['amount'],
      message: json['message'],
      publicKey: hexToBytes(json['public_key']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chainId': chainId,
      'address': address,
      'amount': amount,
      'message': message,
      'public_key': bytesToHex(publicKey),
    };
  }
}
