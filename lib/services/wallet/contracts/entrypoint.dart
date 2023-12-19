import 'dart:async';
import 'dart:typed_data';
import 'package:citizenwallet/services/wallet/models/userop.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:smartcontracts/accounts.dart';
import 'package:web3dart/web3dart.dart';

class StackupEntryPoint {
  final int chainId;
  final Web3Client client;
  final String addr;
  late TokenEntryPoint contract;
  late DeployedContract rcontract;

  StackupEntryPoint(this.chainId, this.client, this.addr) {
    contract = TokenEntryPoint(
      address: EthereumAddress.fromHex(addr),
      chainId: chainId,
      client: client,
    );
  }

  Future<void> init() async {
    final abi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/accounts/TokenEntryPoint.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'TokenEntryPoint');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<BigInt> getNonce(String addr) async {
    final nonce =
        await contract.getNonce(EthereumAddress.fromHex(addr), BigInt.from(0));

    return nonce;
  }

  Future<Uint8List> getUserOpHash(UserOp userop) async {
    final function = rcontract.function("getUserOpHash");

    final result = await client.call(
        contract: rcontract, function: function, params: [userop.toParams()]);

    return result[0];
  }

  Future<EthereumAddress> paymaster() async {
    final function = rcontract.function('paymaster');

    final result =
        await client.call(contract: rcontract, function: function, params: []);

    return result[0];
  }

  void dispose() {
    // _sub?.cancel();
  }
}
