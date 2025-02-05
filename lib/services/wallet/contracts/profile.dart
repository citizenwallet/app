import 'dart:async';
import 'dart:typed_data';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:smartcontracts/contracts/apps/Profile.g.dart';

import 'package:web3dart/web3dart.dart';

const String ipfsPrefix = 'ipfs://';

class ProfileRequest {
  String account;
  String username;
  String name;
  String description;

  ProfileRequest({
    this.account = '',
    this.username = '',
    this.name = '',
    this.description = '',
  });

  // from ProfileV1
  ProfileRequest.fromProfileV1(
    ProfileV1 profile, {
    this.account = '',
    this.username = '',
    this.name = '',
    this.description = '',
  }) {
    account = profile.account;
    username = profile.username;
    name = profile.name;
    description = profile.description;
  }

  // to json
  Map<String, dynamic> toJson() => {
        'account': account,
        'username': username,
        'name': name,
        'description': description,
      };
}

class ProfileV1 {
  String account;
  String username;
  String name;
  String description;
  String image;
  String imageMedium;
  String imageSmall;

  ProfileV1({
    this.account = '',
    this.username = '@anonymous',
    this.name = 'Anonymous',
    this.description = '',
    this.image = 'assets/icons/profile.svg',
    this.imageMedium = 'assets/icons/profile.svg',
    this.imageSmall = 'assets/icons/profile.svg',
  });

  // from json
  ProfileV1.fromJson(Map<String, dynamic> json)
      : account = json['account'],
        username = json['username'],
        name = json['name'],
        description = json['description'] ?? '',
        image = json['image'],
        imageMedium = json['image_medium'],
        imageSmall = json['image_small'];

  // from map
  ProfileV1.fromMap(Map<String, dynamic> json)
      : account = json['account'],
        username = json['username'],
        name = json['name'],
        description = json['description'] ?? '',
        image = json['image'],
        imageMedium = json['imageMedium'],
        imageSmall = json['imageSmall'];

  // to json
  Map<String, dynamic> toJson() => {
        'account': account,
        'username': username,
        'name': name,
        'description': description,
        'image': image,
        'image_medium': imageMedium,
        'image_small': imageSmall,
      };

  // with copy
  ProfileV1 copyWith({
    String? account,
    String? username,
    String? name,
    String? description,
    String? image,
    String? imageMedium,
    String? imageSmall,
  }) {
    return ProfileV1(
      account: account ?? this.account,
      username: username ?? this.username,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      imageMedium: imageMedium ?? this.imageMedium,
      imageSmall: imageSmall ?? this.imageSmall,
    );
  }

  void parseIPFSImageURLs(String url) {
    image = image.replaceFirst(ipfsPrefix, '$url/');
    imageMedium = imageMedium.replaceFirst(ipfsPrefix, '$url/');
    imageSmall = imageSmall.replaceFirst(ipfsPrefix, '$url/');
  }

  void updateUsername(String username) {
    this.username = username;
  }

  // check equality
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileV1 &&
          runtimeType == other.runtimeType &&
          account == other.account &&
          username == other.username &&
          name == other.name &&
          description == other.description &&
          image == other.image &&
          imageMedium == other.imageMedium &&
          imageSmall == other.imageSmall;

  @override
  int get hashCode => super.hashCode;
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
    return contract.getFromUsername(
        convertStringToUint8List(username, forcePadLength: 32));
  }

  Uint8List setCallData(String addr, String username, String url) {
    final function = rcontract.function('set');

    return function.encodeCall(
      [
        EthereumAddress.fromHex(addr),
        convertStringToUint8List(username, forcePadLength: 32),
        url
      ],
    );
  }

  void dispose() {
    // _sub?.cancel();
  }
}
