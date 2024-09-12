import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:smartcontracts/contracts/standards/ERC20.g.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class TransferData {
  final String description;

  TransferData(this.description);

  // from json
  TransferData.fromJson(Map<String, dynamic> json)
      : description = json['description'];

  // to json
  Map<String, dynamic> toJson() => {
        'description': description,
      };
}

class TransferEvent {
  final String hash;
  final String txhash;
  final int tokenId;
  final DateTime createdAt;
  final EthereumAddress from;
  final EthereumAddress to;
  final BigInt value;
  final TransferData? data;
  final String status;

  TransferEvent(
    this.hash,
    this.txhash,
    this.tokenId,
    this.createdAt,
    this.from,
    this.to,
    this.value,
    this.data,
    this.status,
  );

  // instantiate from json
  TransferEvent.fromJson(Map<String, dynamic> json)
      : hash = json['hash'],
        txhash = json['tx_hash'],
        tokenId = json['token_id'],
        createdAt = DateTime.parse(json['created_at']),
        from = EthereumAddress.fromHex(json['from']),
        to = EthereumAddress.fromHex(json['to']),
        value = BigInt.from(json['value']),
        data =
            json['data'] != null ? TransferData.fromJson(json['data']) : null,
        status = json['status'];

  // map to json
  Map<String, dynamic> toJson() => {
        'hash': hash,
        'tx_hash': txhash,
        'token_id': tokenId,
        'created_at': createdAt.toIso8601String(),
        'from': from.hexEip55,
        'to': to.hexEip55,
        'value': value.toInt(),
        'data': data?.toJson(),
        'status': status,
      };
}

class ERC20Contract {
  final int chainId;
  final Web3Client client;
  final String addr;
  late ERC20 contract;
  late DeployedContract rcontract;

  StreamSubscription<FilterEvent>? _sub;

  ERC20Contract(this.chainId, this.client, this.addr) {
    contract = ERC20(
      address: EthereumAddress.fromHex(addr),
      chainId: chainId,
      client: client,
    );
  }

  Future<void> init() async {
    final abi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/standards/ERC20.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'ERC20');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<BigInt> getBalance(String addr) async {
    final balance = await contract.balanceOf(EthereumAddress.fromHex(addr));
    return balance;
  }

  Uint8List transferCallData(String to, BigInt amount) {
    final function = rcontract.function('transfer');
    rcontract.event('Transfer').components;

    return function.encodeCall([EthereumAddress.fromHex(to), amount]);
  }

  Map<String, dynamic> getTransferEventData(
      String from, String to, BigInt amount) {
    final event = rcontract.event('Transfer');
    return {
      "from": from,
      "to": to,
      "topic": bytesToHex(event.signature, include0x: true),
      "value": amount.toString(),
    };
  }

  Uint8List mintCallData(String to, BigInt amount) {
    final function = rcontract.function('mint');

    return function.encodeCall([EthereumAddress.fromHex(to), amount]);
  }

  void dispose() {
    _sub?.cancel();
  }
}
