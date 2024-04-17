import 'dart:typed_data';

import 'package:web3dart/crypto.dart';

class PaymasterData {
  Uint8List paymasterAndData;
  BigInt preVerificationGas;
  BigInt verificationGasLimit;
  BigInt callGasLimit;
  BigInt nonce;

  PaymasterData({
    required this.paymasterAndData,
    required this.preVerificationGas,
    required this.verificationGasLimit,
    required this.callGasLimit,
    required this.nonce,
  });

  // instantiate from json
  factory PaymasterData.fromJson(Map<String, dynamic> json) {
    final nonce = json['nonce'] != null ? hexToInt(json['nonce']) : BigInt.zero;

    return PaymasterData(
      paymasterAndData: hexToBytes(json['paymasterAndData']),
      preVerificationGas: hexToInt(json['preVerificationGas']),
      verificationGasLimit: hexToInt(json['verificationGasLimit']),
      callGasLimit: hexToInt(json['callGasLimit']),
      nonce: nonce,
    );
  }
}
