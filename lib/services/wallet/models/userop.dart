import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

const String gasFeeErrorMessage =
    'pending ops: replacement op must increase maxFeePerGas and MaxPriorityFeePerGas';
const String invalidBalanceErrorMessage = 'transfer amount exceeds balance';

class NetworkCongestedException implements Exception {
  final String message = 'network congestion';

  NetworkCongestedException();
}

class NetworkInvalidBalanceException implements Exception {
  final String message = 'insufficient balance';

  NetworkInvalidBalanceException();
}

class NetworkUnknownException implements Exception {
  final String message = 'network error';

  NetworkUnknownException();
}

const String zeroAddress = '0x0000000000000000000000000000000000000000';
final BigInt defaultCallGasLimit = BigInt.from(35000);
final BigInt defaultVerificationGasLimit = BigInt.from(70000);
final BigInt defaultPreVerificationGas = BigInt.from(21000);
final BigInt defaultMaxFeePerGas = BigInt.from(21000);
final BigInt defaultMaxPriorityFeePerGas = BigInt.from(21000);
final Uint8List emptyBytes = hexToBytes('0x');
final Uint8List dummySignature = hexToBytes(
    '0x199eeba2a9216ed01f9caded6d1b585fc6b0982a73a85f665081fe17a54a24256176fee7747a58b0b2d7db627f705bcd7e7dd0ede7636372985621c8668637b61b');

class UserOp {
  String sender;
  BigInt nonce;
  Uint8List initCode;
  Uint8List callData;
  BigInt callGasLimit;
  BigInt verificationGasLimit;
  BigInt preVerificationGas;
  BigInt maxFeePerGas;
  BigInt maxPriorityFeePerGas;
  Uint8List paymasterAndData;
  Uint8List signature;

  UserOp({
    required this.sender,
    required this.nonce,
    required this.initCode,
    required this.callData,
    required this.callGasLimit,
    required this.verificationGasLimit,
    required this.preVerificationGas,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    required this.paymasterAndData,
    required this.signature,
  });

  // default user op
  factory UserOp.defaultUserOp() {
    return UserOp(
      sender: zeroAddress,
      nonce: BigInt.zero,
      initCode: emptyBytes,
      callData: emptyBytes,
      callGasLimit: defaultCallGasLimit,
      verificationGasLimit: defaultVerificationGasLimit,
      preVerificationGas: defaultPreVerificationGas,
      maxFeePerGas: defaultMaxFeePerGas,
      maxPriorityFeePerGas: defaultMaxPriorityFeePerGas,
      paymasterAndData: emptyBytes,
      signature: dummySignature,
    );
  }

  // instantiate from json
  factory UserOp.fromJson(Map<String, dynamic> json) {
    return UserOp(
      sender: json['sender'],
      nonce: hexToInt(json['nonce']),
      initCode: hexToBytes(json['initCode']),
      callData: hexToBytes(json['callData']),
      callGasLimit: hexToInt(json['callGasLimit']),
      verificationGasLimit: hexToInt(json['verificationGasLimit']),
      preVerificationGas: hexToInt(json['preVerificationGas']),
      maxFeePerGas: hexToInt(json['maxFeePerGas']),
      maxPriorityFeePerGas: hexToInt(json['maxPriorityFeePerGas']),
      paymasterAndData: hexToBytes(json['paymasterAndData']),
      signature: hexToBytes(json['signature']),
    );
  }

  // convert to json
  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'nonce': bigIntToHex(nonce),
      'initCode': bytesToHex(initCode, include0x: true),
      'callData': bytesToHex(callData, include0x: true),
      'callGasLimit': bigIntToHex(callGasLimit),
      'verificationGasLimit': bigIntToHex(verificationGasLimit),
      'preVerificationGas': bigIntToHex(preVerificationGas),
      'maxFeePerGas': bigIntToHex(maxFeePerGas),
      'maxPriorityFeePerGas': bigIntToHex(maxPriorityFeePerGas),
      'paymasterAndData': bytesToHex(paymasterAndData, include0x: true),
      'signature': bytesToHex(signature, include0x: true),
    };
  }

  // convert to List<dynamic> compatible with smart contracts
  List<dynamic> toParams() {
    return [
      EthereumAddress.fromHex(sender),
      nonce,
      initCode,
      callData,
      callGasLimit,
      verificationGasLimit,
      preVerificationGas,
      maxFeePerGas,
      maxPriorityFeePerGas,
      paymasterAndData,
      signature,
    ];
  }

  // getUserOpHash returns the hash of the user op
  Uint8List getHash(String entrypoint, String chainId) {
    final packed = LengthTrackingByteSink();

    final List<AbiType> encoders = [
      parseAbiType('address'),
      parseAbiType('uint256'),
      parseAbiType('bytes32'),
      parseAbiType('bytes32'),
      parseAbiType('uint256'),
      parseAbiType('uint256'),
      parseAbiType('uint256'),
      parseAbiType('uint256'),
      parseAbiType('uint256'),
      parseAbiType('bytes32'),
    ];

    final List<dynamic> values = [
      EthereumAddress.fromHex(sender),
      nonce,
      keccak256(initCode),
      keccak256(callData),
      callGasLimit,
      verificationGasLimit,
      preVerificationGas,
      maxFeePerGas,
      maxPriorityFeePerGas,
      keccak256(paymasterAndData),
    ];

    for (var i = 0; i < encoders.length; i++) {
      encoders[i].encode(values[i], packed);
    }

    final enc = LengthTrackingByteSink();

    final List<AbiType> encoders1 = [
      parseAbiType('bytes32'),
      parseAbiType('address'),
      parseAbiType('uint256'),
    ];

    final List<dynamic> values1 = [
      keccak256(packed.asBytes()),
      EthereumAddress.fromHex(entrypoint),
      BigInt.parse(chainId),
    ];

    for (var i = 0; i < encoders1.length; i++) {
      encoders1[i].encode(values1[i], enc);
    }

    return keccak256(enc.asBytes());
  }

  // sign signs the user op
  void generateSignature(EthPrivateKey credentials, Uint8List hash) {
    final signature = credentials.signPersonalMessageToUint8List(
      hash,
    );

    this.signature = signature;
  }

  bool isFirst() {
    return nonce == BigInt.zero;
  }
}
