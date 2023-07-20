import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:smartcontracts/apps.dart';

import 'package:web3dart/web3dart.dart';

class ProfileV1 {
  String name;
  String description;
  String image;

  ProfileV1({
    this.name = 'Unknown',
    this.description = '',
    this.image = 'assets/logo.png',
  });
}

ProfileContract newProfileContract(
    int chainId, Web3Client client, String addr) {
  return ProfileContract(chainId, client, addr);
}

class ProfileContract {
  final int chainId;
  final Web3Client client;
  final String addr;
  late Profile contract;
  late DeployedContract rcontract;

  ProfileContract(this.chainId, this.client, this.addr) {
    contract = Profile(
      address: EthereumAddress.fromHex(addr),
      chainId: chainId,
      client: client,
    );
  }

  Future<void> init() async {
    final abi = await rootBundle.loadString(
        'packages/smartcontracts/lib/contracts/apps/Profile.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'Profile');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<ProfileV1> get(String addr) async {
    final url = await contract.get(EthereumAddress.fromHex(addr));

    final profile = ProfileV1();

    // fetch profile from url

    // update profile with data

    return profile;
  }

  Future<void> set(
      String addr, ProfileV1 profile, Credentials credentials) async {
    // upload profile to url
    const url = '';

    // set profile url
    await contract.set(
      EthereumAddress.fromHex(addr),
      url,
      credentials: credentials,
    );
  }

  void dispose() {
    // _sub?.cancel();
  }
}
