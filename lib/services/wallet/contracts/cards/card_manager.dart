import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:citizenwallet/services/wallet/contracts/cards/interface.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class CardManagerContract implements AbstractCardManagerContract {
  final int chainId;
  final Web3Client client;
  final String addr;
  late DeployedContract rcontract;

  CardManagerContract(this.chainId, this.client, this.addr);

  @override
  EthereumAddress get address => rcontract.address;

  @override
  Future<void> init() async {
    final rawAbi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/external/CardFactory.abi.json');

    final cabi = ContractAbi.fromJson(rawAbi, 'CardManager');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Map<String, EthereumAddress> addressCache = {};

  @override
  Future<Uint8List> getCardHash(String serial, {bool local = true}) async {
    BigInt bigIntSerial = BigInt.parse(serial, radix: 16);

    if (local) {
      return keccak256EncodePacked(
        [bigIntSerial, EthereumAddress.fromHex(addr)],
        ['uint256', 'address'],
      );
    }

    final function = rcontract.function('getCardHash');

    final result = await client.call(
      contract: rcontract,
      function: function,
      params: [bigIntSerial],
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
      params: [hash],
    );

    final address = result[0] as EthereumAddress;

    addressCache[hexHash] = address;

    return address;
  }

  @override
  Future<Uint8List> createAccountInitCode(Uint8List hash) async {
    final function = rcontract.function('createCard');

    final callData = function.encodeCall([hash]);

    return hexToBytes('$addr${bytesToHex(callData)}');
  }

  @override
  Uint8List createAccountCallData(Uint8List hash) {
    final function = rcontract.function('createCard');

    final callData = function.encodeCall([hash]);

    return callData;
  }

  @override
  Uint8List withdrawCallData(
      Uint8List hash, String token, String to, BigInt amount) {
    final function = rcontract.function('withdraw');

    return function.encodeCall([
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
