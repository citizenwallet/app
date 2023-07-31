import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:smartcontracts/external.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class TransferEvent {
  final EthereumAddress from;
  final EthereumAddress to;
  final BigInt value;
  final int? blockNum;
  String? transactionHash;

  TransferEvent(
    this.from,
    this.to,
    this.value, {
    this.blockNum,
    this.transactionHash,
  });
}

Token newToken(int chainId, Web3Client client, String addr) {
  return Token(chainId, client, addr);
}

class Token {
  final int chainId;
  final Web3Client client;
  final String addr;
  late DERC20 contract;
  late DeployedContract rcontract;

  StreamSubscription<FilterEvent>? _sub;

  Token(this.chainId, this.client, this.addr) {
    contract = DERC20(
      address: EthereumAddress.fromHex(addr),
      chainId: chainId,
      client: client,
    );
  }

  Future<void> init() async {
    final abi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/external/DERC20.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'DERC20');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<BigInt> getBalance(String addr) async {
    final balance = await contract.balanceOf(EthereumAddress.fromHex(addr));

    return balance;
  }

  Stream<Transfer> listen(BlockNum fromBlock) {
    return contract.transferEvents(fromBlock: fromBlock);
  }

  Future<List<TransferEvent>> getTransactions(
      String owner, BlockNum fromBlock, BlockNum toBlock) async {
    final event = rcontract.event('Transfer');

    final filter = FilterOptions(
      address: rcontract.address,
      toBlock: toBlock,
      fromBlock: fromBlock,
      topics: [
        [
          bytesToHex(event.signature, padToEvenLength: true, include0x: true),
        ],
        // [
        //   bytesToHex(
        //     hexToBytes(owner),
        //     forcePadLength: 64,
        //     padToEvenLength: true,
        //     include0x: true,
        //   ),
        // ],
      ],
    );

    final events = await client.getLogs(filter);

    final List<TransferEvent> txs = [];

    for (final e in events) {
      final decoded = event.decodeResults(e.topics!, e.data!);

      final from = decoded[0] as EthereumAddress;
      final to = decoded[1] as EthereumAddress;
      final value = decoded[2] as BigInt;

      if (from.hexEip55.toLowerCase() != owner.toLowerCase() ||
          to.hexEip55.toLowerCase() != owner.toLowerCase()) continue;

      txs.add(TransferEvent(
        from,
        to,
        value,
        blockNum: e.blockNum,
        transactionHash: e.transactionHash,
      ));

      print('$from sent $value DERC20 to $to');
    }

    return txs;
  }

  Uint8List transferCallData(String to, BigInt amount) {
    final function = rcontract.function('transfer');

    return function.encodeCall([EthereumAddress.fromHex(to), amount]);
  }

  // void listen(String from) async {
  //   final ev = rcontract.event('Transfer');

  //   final filter = FilterOptions(
  //     address: rcontract.address,
  //     topics: [
  //       [
  //         bytesToHex(ev.signature, forcePadLength: 64, include0x: true),
  //       ],
  //       [
  //         bytesToHex(hexToBytes(from), forcePadLength: 64, include0x: true),
  //       ]
  //     ],
  //   );

  //   _sub = client.events(filter).listen((event) {
  //     final decoded = ev.decodeResults(event.topics!, event.data!);

  //     final from = decoded[0] as EthereumAddress;
  //     final to = decoded[1] as EthereumAddress;
  //     final value = decoded[2] as BigInt;

  //     print('$from sent $value DERC20 to $to');
  //   });
  // }

  void dispose() {
    _sub?.cancel();
  }
}
