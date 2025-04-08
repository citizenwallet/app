import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:web3dart/web3dart.dart';

class CommunityModule {
  final int chainId;
  final Web3Client client;
  final String addr;
  late DeployedContract rcontract;

  CommunityModule(this.chainId, this.client, this.addr);

  Future<void> init() async {
    final abi = await rootBundle
        .loadString('packages/contractforge/abi/CommunityModule.json');

    final cabi = ContractAbi.fromJson(abi, 'CommunityModule');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Uint8List getChainIdCallData() {
    final function = rcontract.function('getChainId');

    return function.encodeCall([]);
  }

  void dispose() {
    // _sub?.cancel();
  }
}
