import 'dart:async';
import 'dart:typed_data';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:smartcontracts/contracts/apps/Profile.g.dart';

import 'package:web3dart/web3dart.dart';

class ProfileV1 {
  String address;
  String username;
  String name;
  String description;
  String image;
  String imageMedium;
  String imageSmall;

  ProfileV1({
    this.address = '',
    this.username = '',
    this.name = 'Unknown',
    this.description = '',
    this.image = 'assets/icons/profile.svg',
    this.imageMedium = 'assets/icons/profile.svg',
    this.imageSmall = 'assets/icons/profile.svg',
  });

  // from json
  ProfileV1.fromJson(Map<String, dynamic> json)
      : address = json['address'],
        username = json['username'],
        name = json['name'],
        description = json['description'],
        image = json['image'],
        imageMedium = json['imageMedium'],
        imageSmall = json['imageSmall'];

  // to json
  Map<String, dynamic> toJson() => {
        'address': address,
        'username': username,
        'name': name,
        'description': description,
        'image': image,
        'imageMedium': imageMedium,
        'imageSmall': imageSmall,
      };
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
    final abi = await rootBundle
        .loadString('packages/smartcontracts/contracts/apps/Profile.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'Profile');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<String> getURL(String addr) async {
    return contract.get(EthereumAddress.fromHex(addr));
  }

  Future<String> getURLFromUsername(String username) async {
    return contract.getFromUsername(convertStringToUint8List(username));
  }

  Uint8List setCallData(String addr, String username, String url) {
    final function = rcontract.function('set');

    return function.encodeCall(
      [EthereumAddress.fromHex(addr), convertStringToUint8List(username), url],
    );
  }

  void dispose() {
    // _sub?.cancel();
  }
}
