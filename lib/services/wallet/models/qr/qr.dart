import 'dart:convert';

import 'package:citizenwallet/services/wallet/models/qr/wallet.dart';
import 'package:citizenwallet/services/wallet/models/signer.dart';

const Map<String, dynamic> emptyRaw = {};

final signatureException = Exception('QR data signature mismatch');

class QR {
  final int _version;
  final String _type;
  Map<String, dynamic> _raw = {};
  String _signature;

  QR({
    required int version,
    required String type,
    Map<String, dynamic> raw = emptyRaw,
    required String signature,
  })  : _version = version,
        _type = type,
        _raw = raw,
        _signature = signature;

  factory QR.fromJson(Map<String, dynamic> json) {
    return QR(
      version: json['version'],
      type: json['type'],
      raw: json['data'],
      signature: json['signature'],
    );
  }

  QRWallet toQRWallet() {
    return QRWallet(
      version: _version,
      type: _type,
      raw: _raw,
      signature: _signature,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': _version,
      'type': _type,
      'data': _raw,
      'signature': _signature,
    };
  }

  int get version => _version;
  String get type => _type;
  Map<String, dynamic> get raw => _raw;
  String get signature => _signature;

  Future<void> generateSignature(Signer signer) async {
    _signature = await signer.sign(jsonEncode(_raw));
  }

  /// mock function when signature verification is not needed
  Future<bool> verifyData() async {
    return true;
  }
}
