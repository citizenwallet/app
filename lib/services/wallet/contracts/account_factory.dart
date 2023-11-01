import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:smartcontracts/accounts.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

AccountFactoryService newAccountFactory(
    int chainId, Web3Client client, String addr) {
  return AccountFactoryService(chainId, client, addr);
}

class AccountFactoryService {
  final int chainId;
  final Web3Client client;
  final String addr;
  late AccountFactory contract;
  late DeployedContract rcontract;

  // StreamSubscription<TransferSingle>? _sub;

  AccountFactoryService(this.chainId, this.client, this.addr) {
    contract = AccountFactory(
      address: EthereumAddress.fromHex(addr),
      chainId: chainId,
      client: client,
    );
  }

  Future<void> init() async {
    final abi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/accounts/AccountFactory.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'AccountFactory');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<String> createAccount(EthPrivateKey cred, String addr) async {
    final account = await contract.createAccount(
        EthereumAddress.fromHex(addr), BigInt.from(0),
        credentials: cred);

    // final uri = await contract.uri(tokenId);
    // return '/$uri';
    return account;
  }

  Future<EthereumAddress> getAddress(String owner) {
    return contract.getAddress(EthereumAddress.fromHex(owner), BigInt.zero);
  }

  Future<BigInt> getNonce(String sender) async {
    return contract.getNonce(EthereumAddress.fromHex(sender), BigInt.zero);
  }

  Future<Uint8List> createAccountInitCode(String owner, BigInt amount) async {
    // final function = rcontract.function('createAccount');

    final abi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/accounts/AccountFactory.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'AccountFactory');

    final function = cabi.functions
        .where((element) => element.name == 'createAccount')
        .first;

    final callData =
        function.encodeCall([EthereumAddress.fromHex(owner), BigInt.from(0)]);

    return hexToBytes('$addr${bytesToHex(callData)}');
  }

  void dispose() {
    // _sub?.cancel();
  }
}
