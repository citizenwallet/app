import 'dart:convert';

import 'package:citizenwallet/services/wallet/models/qr/transaction_request.dart';
import 'package:citizenwallet/services/wallet/models/qr/wallet.dart';
import 'package:citizenwallet/services/wallet/models/signer.dart';
import 'package:citizenwallet/services/wallet/utils.dart';

const Map<String, dynamic> emptyRaw = {};

final signatureException = Exception('QR data signature mismatch');

enum QRType {
  qr('qr'),
  qrWallet('qr_wallet'),
  qrTransactionRequest('qr_tr_req');

  const QRType(this.value);
  final String value;
}

class QR {
  final int _version;
  final QRType _type;
  Map<String, dynamic> _raw = {};
  String _signature;

  QR({
    required int version,
    required QRType type,
    Map<String, dynamic> raw = emptyRaw,
    required String signature,
  })  : _version = version,
        _type = type,
        _raw = raw,
        _signature = signature;

  factory QR.fromJson(Map<String, dynamic> json) {
    return QR(
      version: json['version'],
      type: QRType.values.firstWhere(
        (element) => element.value == json['type'],
      ),
      raw: json['data'],
      signature: json['signature'],
    );
  }

  factory QR.fromCompressedJson(String compressed) {
    final Map<String, dynamic> json = jsonDecode(decompress(compressed));

    return QR(
      version: json['version'],
      type: QRType.values.firstWhere(
        (element) => element.value == json['type'],
      ),
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

  QRTransactionRequest toQRTransactionRequest() {
    return QRTransactionRequest(
      version: _version,
      type: _type,
      raw: _raw,
      signature: _signature,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': _version,
      'type': _type.value,
      'data': _raw,
      'signature': _signature,
    };
  }

  String toCompressedJson() {
    final Map<String, dynamic> json = {
      'version': _version,
      'type': _type.value,
      'data': _raw,
      'signature': _signature,
    };

    return compress(jsonEncode(json));
  }

  int get version => _version;
  QRType get type => _type;
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
