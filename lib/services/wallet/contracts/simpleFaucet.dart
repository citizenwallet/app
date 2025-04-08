import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:smartcontracts/contracts/apps/SimpleFaucet.g.dart';
import 'package:web3dart/web3dart.dart';

class SimpleFaucetContract {
  final int chainId;
  final Web3Client client;
  final String addr;
  late SimpleFaucet contract;
  late DeployedContract rcontract;

  SimpleFaucetContract(this.chainId, this.client, this.addr) {
    contract = SimpleFaucet(
      address: EthereumAddress.fromHex(addr),
      chainId: chainId,
      client: client,
    );
  }

  Future<void> init() async {
    final abi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/apps/SimpleFaucet.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'SimpleFaucet');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Uint8List redeemCallData() {
    final function = rcontract.function('redeem');

    return function.encodeCall([]);
  }

  Future<BigInt> getAmount() async {
    return contract.amount();
  }

  void dispose() {
    //
  }
}
