import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:citizenwallet/services/wallet/contracts/cards/interface.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class SafeCardManagerContract implements AbstractCardManagerContract {
  final Uint8List id;
  final int chainId;
  final Web3Client client;
  final String addr;
  late DeployedContract rcontract;

  SafeCardManagerContract(this.id, this.chainId, this.client, this.addr);

  @override
  EthereumAddress get address => rcontract.address;

  @override
  Future<void> init() async {
    final rawAbi = await rootBundle
        .loadString('packages/contractforge/abi/CardManagerModule.json');

    final cabi = ContractAbi.fromJson(rawAbi, 'CardManagerModule');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Map<String, EthereumAddress> addressCache = {};

  @override
  Future<Uint8List> getCardHash(String serial, {bool local = true}) async {
    Uint8List serialHash = keccak256(convertStringToUint8List(serial));

    if (local) {
      return keccak256EncodePacked(
        [id, serialHash, EthereumAddress.fromHex(addr)],
        ['bytes32', 'bytes32', 'address'],
      );
    }

    final function = rcontract.function('getCardHash');

    final result = await client.call(
      contract: rcontract,
      function: function,
      params: [id, serialHash],
    );

    return result[0];
  }

  @override
  Future<EthereumAddress> getCardAddress(Uint8List hash) async {
    final hexHash = bytesToHex(hash);
    if (addressCache.containsKey(hexHash)) {
      return addressCache[hexHash]!;
    }

    final function = rcontract.function('getCardAddress');

    final result = await client.call(
      contract: rcontract,
      function: function,
      params: [id, hash],
    );

    final address = result[0] as EthereumAddress;

    addressCache[hexHash] = address;

    return address;
  }

  @override
  Future<Uint8List> createAccountInitCode(Uint8List hash) async {
    final function = rcontract.function('createCard');

    final callData = function.encodeCall([id, hash]);

    return hexToBytes('$addr${bytesToHex(callData)}');
  }

  @override
  Uint8List createAccountCallData(Uint8List hash) {
    final function = rcontract.function('createCard');

    final callData = function.encodeCall([id, hash]);

    return callData;
  }

  @override
  Uint8List withdrawCallData(
      Uint8List hash, String token, String to, BigInt amount) {
    final function = rcontract.function('withdraw');

    return function.encodeCall([
      id,
      hash,
      EthereumAddress.fromHex(token),
      EthereumAddress.fromHex(to),
      amount
    ]);
  }
}

Uint8List encodePacked(dynamic value, [String? type]) {
  if (type == 'uint256') {
    // Encode uint256
    var bytes = Uint8List(32);
    var byteData = ByteData.sublistView(bytes);
    byteData.setUint64(24, value.toInt()); // setting the last 8 bytes (uint64)
    return bytes;
  } else if (type == 'address') {
    // Encode address
    return value.addressBytes;
  } else if (type == 'bytes32') {
    // Encode bytes32
    if (value is Uint8List && value.length == 32) {
      return value;
    } else if (value is String &&
        value.length == 66 &&
        value.startsWith('0x')) {
      return hexToBytes(value.substring(2));
    } else {
      throw Exception("Invalid bytes32 value");
    }
  } else {
    throw Exception("Type not supported for encoding");
  }
}

Uint8List keccak256EncodePacked(List<dynamic> values, List<String> types) {
  assert(values.length == types.length);

  BytesBuilder builder = BytesBuilder();
  for (int i = 0; i < values.length; i++) {
    builder.add(encodePacked(values[i], types[i]));
  }
  return keccak256(builder.toBytes());
}
