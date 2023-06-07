import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:smartcontracts/external.dart';
import 'package:web3dart/web3dart.dart';

SimpleAccount newSimpleAccount(int chainId, Web3Client client, String addr) {
  return SimpleAccount(chainId, client, addr);
}

class SimpleAccount {
  final int chainId;
  final Web3Client client;
  final String addr;
  late DERC20 contract;
  late DeployedContract rcontract;

  // StreamSubscription<TransferSingle>? _sub;

  SimpleAccount(this.chainId, this.client, this.addr) {
    contract = DERC20(
      address: EthereumAddress.fromHex(addr),
      chainId: chainId,
      client: client,
    );
  }

  Future<void> init() async {
    final abi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/external/SimpleAccount.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'SimpleAccount');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<BigInt> getBalance(String addr) async {
    final balance = await contract.balanceOf(EthereumAddress.fromHex(addr));

    print(balance.toString());

    // final uri = await contract.uri(tokenId);
    // return '/$uri';
    return balance;
  }

  Uint8List executeCallData(String dest, BigInt amount, Uint8List calldata) {
    final function = rcontract.function('execute');

    return function
        .encodeCall([EthereumAddress.fromHex(dest), amount, calldata]);
  }

  void dispose() {
    // _sub?.cancel();
  }
}
