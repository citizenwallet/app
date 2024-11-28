import 'dart:convert';

import 'package:citizenwallet/utils/uint8.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class SigAuthConnection {
  final EthereumAddress address;
  final DateTime expiry;
  final String signature;
  final String redirect;

  SigAuthConnection({
    required this.address,
    required this.expiry,
    required this.signature,
    required this.redirect,
  });

  bool get isValid => expiry.isAfter(DateTime.now());

  String get queryParams =>
      'sigAuthAccount=${address.hexEip55}&sigAuthExpiry=${expiry.toIso8601String()}&sigAuthSignature=$signature&sigAuthRedirect=${Uri.encodeComponent(redirect)}';

  @override
  String toString() =>
      'SigAuthConnection(address: ${address.hexEip55}, expiry: $expiry, signature: $signature)';
}

class SigAuthService {
  final EthPrivateKey _credentials;
  final EthereumAddress _address;
  final String _redirect;

  SigAuthService({
    required EthPrivateKey credentials,
    required EthereumAddress address,
    required String redirect,
  })  : _credentials = credentials,
        _address = address,
        _redirect = redirect;

  SigAuthConnection connect({DateTime? expiry}) {
    final expiryDate = expiry ?? DateTime.now().add(const Duration(days: 7));

    final message =
        'Signature auth for ${_address.hexEip55} with expiry ${expiryDate.toIso8601String()} and redirect ${Uri.encodeComponent(_redirect)}';

    final signature = bytesToHex(
      _credentials.signPersonalMessageToUint8List(
        convertBytesToUint8List(utf8.encode(message)),
      ),
      include0x: true,
    );

    return SigAuthConnection(
      address: _address,
      expiry: expiryDate,
      signature: signature,
      redirect: _redirect,
    );
  }
}
