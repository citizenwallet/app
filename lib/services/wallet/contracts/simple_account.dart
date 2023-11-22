import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:web3dart/web3dart.dart';

class SimpleAccount {
  final int chainId;
  final Web3Client client;
  final String addr;
  // late DERC20 contract;
  late DeployedContract rcontract;

  // StreamSubscription<TransferSingle>? _sub;

  SimpleAccount(this.chainId, this.client, this.addr) {
    // contract = DERC20(
    //   address: EthereumAddress.fromHex(addr),
    //   chainId: chainId,
    //   client: client,
    // );
  }

  Future<void> init() async {
    final abi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/accounts/Account.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'Account');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<EthereumAddress> tokenEntryPoint() async {
    final function = rcontract.function('tokenEntryPoint');

    final result =
        await client.call(contract: rcontract, function: function, params: []);

    return result[0];
  }

  Uint8List executeCallData(String dest, BigInt amount, Uint8List calldata) {
    final function = rcontract.function('execute');

    return function
        .encodeCall([EthereumAddress.fromHex(dest), amount, calldata]);
  }

  Uint8List executeBatchCallData(
    List<String> dest,
    List<Uint8List> calldata,
  ) {
    final function = rcontract.function('executeBatch');

    return function.encodeCall([
      dest.map((d) => EthereumAddress.fromHex(d)).toList(),
      calldata,
    ]);
  }

  Uint8List upgradeToCallData(String implementation) {
    final function = rcontract.function('upgradeTo');

    return function.encodeCall([EthereumAddress.fromHex(implementation)]);
  }

  void dispose() {
    // _sub?.cancel();
  }
}
