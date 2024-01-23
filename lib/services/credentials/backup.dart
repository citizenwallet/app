import 'package:citizenwallet/utils/uint8.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

const String versionPrefix = 'w_version_enc_prefs';
const String backupPrefix = 'w_bkp_';

class BackupWallet {
  final String address;
  final String privateKey;
  final String name;
  final String alias;

  BackupWallet({
    required String address,
    required this.privateKey,
    required this.name,
    required this.alias,
  }) : address = EthereumAddress.fromHex(address).hexEip55;

  BackupWallet.fromJson(Map<String, dynamic> json)
      : address = EthereumAddress.fromHex(json['address']).hexEip55,
        privateKey = json['privateKey'],
        name = json['name'],
        alias = json['alias'] ?? 'app';

  Map<String, dynamic> toJson() => {
        'address': address,
        'privateKey': privateKey,
        'name': name,
        'alias': alias,
      };

  String get legacyHash {
    final bytes = keccak256(convertStringToUint8List(value));

    return bytesToHex(bytes);
  }

  String get hashed {
    final bytes = keccak256(convertStringToUint8List('$address|$alias'));

    return bytesToHex(bytes);
  }

  // legacy properties from old migrations
  String get legacyKey => '$backupPrefix${address.toLowerCase()}';
  String get legacyKey2 =>
      '$backupPrefix$legacyHash}'; // the typo '}' is intentional, a typo was released to production

  // current properties
  String get key => '$backupPrefix$hashed';
  String get value => '$name|$address|$privateKey|$alias';
}
