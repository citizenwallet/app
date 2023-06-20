import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

import 'package:smartcontracts/external.dart';
import 'package:web3dart/web3dart.dart';

StackupEntryPoint newEntryPoint(int chainId, Web3Client client, String addr) {
  return StackupEntryPoint(chainId, client, addr);
}

class StackupEntryPoint {
  final int chainId;
  final Web3Client client;
  final String addr;
  late EntryPoint contract;
  late DeployedContract rcontract;

  // StreamSubscription<TransferSingle>? _sub;

  StackupEntryPoint(this.chainId, this.client, this.addr) {
    contract = EntryPoint(
      address: EthereumAddress.fromHex(addr),
      chainId: chainId,
      client: client,
    );
  }

  Future<void> init() async {
    final abi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/external/EntryPoint.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'EntryPoint');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<BigInt> getNonce(String addr) async {
    final nonce =
        await contract.getNonce(EthereumAddress.fromHex(addr), BigInt.from(0));

    return nonce;
  }

  void dispose() {
    // _sub?.cancel();
  }
}
