import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rxdart/rxdart.dart';

import 'package:smartcontracts/contracts/standards/ERC20.g.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class TransferEvent {
  final String hash;
  final String txhash;
  final int tokenId;
  final DateTime createdAt;
  final EthereumAddress from;
  final EthereumAddress to;
  final BigInt value;
  final Uint8List data;
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
        data = json['data'] != null
            ? Uint8List.fromList(json['data'].codeUnits)
            : Uint8List(0),
        status = json['status'];

  // map to json
  Map<String, dynamic> toJson() => {
        'hash': hash,
        'tx_hash': txhash,
        'token_id': tokenId,
        'created_at': createdAt.toIso8601String(),
        'from': from.hex,
        'to': to.hex,
        'value': value.toInt(),
        'data': data.isNotEmpty ? String.fromCharCodes(data) : null,
        'status': status,
      };
}

ERC20Contract newERC20Contract(int chainId, Web3Client client, String addr) {
  return ERC20Contract(chainId, client, addr);
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

  Stream<Transfer> listen(BlockNum fromBlock, EthereumAddress owner) {
    final event = rcontract.event('Transfer');

    final filter1 = FilterOptions(
      fromBlock: fromBlock,
      address: EthereumAddress.fromHex(addr),
      topics: [
        [bytesToHex(event.signature, padToEvenLength: true, include0x: true)],
        [bytesToHex(owner.addressBytes, forcePadLength: 64, include0x: true)],
      ],
    );

    final filter2 = FilterOptions(
      fromBlock: fromBlock,
      address: EthereumAddress.fromHex(addr),
      topics: [
        [bytesToHex(event.signature, padToEvenLength: true, include0x: true)],
        [],
        [bytesToHex(owner.addressBytes, forcePadLength: 64, include0x: true)],
      ],
    );

    return MergeStream([client.events(filter1), client.events(filter2)])
        .map((FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );

      return Transfer(
        decoded,
        result,
      );
    });

    // return contract.transferEvents(fromBlock: fromBlock);
  }

  Uint8List transferCallData(String to, BigInt amount) {
    final function = rcontract.function('transfer');

    return function.encodeCall([EthereumAddress.fromHex(to), amount]);
  }

  void dispose() {
    _sub?.cancel();
  }
}
