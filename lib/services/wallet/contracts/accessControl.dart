import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:smartcontracts/contracts/standards/IAccessControlUpgradeable.g.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class AccessControlUpgradeableContract {
  final int chainId;
  final Web3Client client;
  final String addr;
  late IAccessControlUpgradeable contract;
  late DeployedContract rcontract;

  final Uint8List minterRole =
      keccak256(Uint8List.fromList('MINTER_ROLE'.codeUnits));

  AccessControlUpgradeableContract(this.chainId, this.client, this.addr) {
    contract = IAccessControlUpgradeable(
      address: EthereumAddress.fromHex(addr),
      chainId: chainId,
      client: client,
    );
  }

  Future<void> init() async {
    final abi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/standards/IAccessControlUpgradeable.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'ERC20');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<bool> hasRole(Uint8List role, String address) async {
    bool hasRole = false;

    try {
      hasRole = await contract
          .hasRole(role, EthereumAddress.fromHex(address))
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      //
    }
    return hasRole;
  }

  Future<bool> isMinter(String address) async {
    bool isMinter = false;

    try {
      isMinter = await hasRole(minterRole, address);
    } catch (_) {
      //
    }

    return isMinter;
  }

  void dispose() {}
}
