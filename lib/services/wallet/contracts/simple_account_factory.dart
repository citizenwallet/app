import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:smartcontracts/external.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

AccountFactory newAccountFactory(int chainId, Web3Client client, String addr) {
  return AccountFactory(chainId, client, addr);
}

class AccountFactory {
  final int chainId;
  final Web3Client client;
  final String addr;
  late SimpleAccountFactory contract;
  late DeployedContract rcontract;

  // StreamSubscription<TransferSingle>? _sub;

  AccountFactory(this.chainId, this.client, this.addr) {
    contract = SimpleAccountFactory(
      address: EthereumAddress.fromHex(addr),
      chainId: chainId,
      client: client,
    );
  }

  Future<void> init() async {
    final abi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/external/SimpleAccountFactory.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'SimpleAccountFactory');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<String> createAccount(EthPrivateKey cred, String addr) async {
    final account = await contract.createAccount(
        EthereumAddress.fromHex(addr), BigInt.from(0),
        credentials: cred);

    print(account.toString());

    // final uri = await contract.uri(tokenId);
    // return '/$uri';
    return account;
  }

  Future<EthereumAddress> getAddress(String owner) {
    return contract.getAddress(EthereumAddress.fromHex(owner), BigInt.zero);
  }

  Uint8List createAccountInitCode(String owner, BigInt amount) {
    final function = rcontract.function('createAccount');

    final callData =
        function.encodeCall([EthereumAddress.fromHex(owner), amount]);

    return hexToBytes('$addr${bytesToHex(callData)}');
  }

  void dispose() {
    // _sub?.cancel();
  }
}
