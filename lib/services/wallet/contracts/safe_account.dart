import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:web3dart/web3dart.dart';

class SafeAccount {
  final int chainId;
  final Web3Client client;
  final String addr;
  late DeployedContract rcontract;

  // StreamSubscription<TransferSingle>? _sub;

  SafeAccount(this.chainId, this.client, this.addr);

  Future<void> init() async {
    final abi =
        await rootBundle.loadString('packages/contractforge/abi/Safe.json');

    final cabi = ContractAbi.fromJson(abi, 'Safe');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Uint8List executeCallData(String dest, BigInt amount, Uint8List calldata) {
    final function = rcontract.function('execTransactionFromModule');

    return function.encodeCall(
        [EthereumAddress.fromHex(dest), amount, calldata, BigInt.zero]);
  }

  Uint8List executeBatchCallData(
    List<String> dest,
    List<Uint8List> calldata,
  ) {
    return Uint8List.fromList([]);
  }

  Uint8List transferOwnershipCallData(String newOwner) {
    final function = rcontract.function('transferOwnership');

    return function.encodeCall([EthereumAddress.fromHex(newOwner)]);
  }

  Uint8List upgradeToCallData(String implementation) {
    final function = rcontract.function('upgradeTo');

    return function.encodeCall([EthereumAddress.fromHex(implementation)]);
  }

  void dispose() {
    // _sub?.cancel();
  }
}
