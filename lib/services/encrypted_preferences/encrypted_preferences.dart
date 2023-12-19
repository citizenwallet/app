import 'dart:convert';

import 'package:citizenwallet/services/api/api.dart';
import 'package:citizenwallet/services/config/service.dart';
import 'package:citizenwallet/services/encrypted_preferences/android.dart';
import 'package:citizenwallet/services/encrypted_preferences/apple.dart';
import 'package:citizenwallet/services/encrypted_preferences/web.dart';
import 'package:citizenwallet/services/indexer/signed_request.dart';
import 'package:citizenwallet/services/wallet/contracts/account_factory.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/utils/platform.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

const String versionPrefix = 'w_version_enc_prefs';
const String backupPrefix = 'w_bkp_';

class NotFoundException implements Exception {
  final String message = 'not found';

  NotFoundException();
}

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

abstract class EncryptedPreferencesOptions {}

/// EncryptedPreferencesService defines the interface for encrypted preferences
///
/// This is used to store wallet backups and the implementation is platform specific.
abstract class EncryptedPreferencesService {
  final int _version = 3;

  int get version => _version;

  // init the service
  Future<void> init(EncryptedPreferencesOptions options);

  // migrate the service
  Future<void> migrate(int version);

  // handle wallet backups
  // use the prefix as a query to find a wallet backup
  // use the prefix + wallet address as a way to query the backup
  // store the json as a b64 encoded string, reason: we store the name of the wallet
  // key = wb_$wallet_address, value = $name|$privateKey

  // get all wallet backups
  Future<List<BackupWallet>> getAllWalletBackups();

  // set wallet backup
  Future<void> setWalletBackup(BackupWallet backup);

  // get wallet backup
  Future<BackupWallet?> getWalletBackup(String address, String alias);

  // get wallet backups for alias
  Future<List<BackupWallet>> getWalletBackupsForAlias(String alias);

  // delete wallet backup
  Future<void> deleteWalletBackup(String address, String alias);

  // delete all wallet backups
  Future<void> deleteWalletBackups();
}

EncryptedPreferencesService getEncryptedPreferencesService() {
  if (kIsWeb) {
    return WebEncryptedPreferencesService();
  }

  return isPlatformApple()
      ? AppleEncryptedPreferencesService()
      : AndroidEncryptedPreferencesService();
}

Future<EthereumAddress?> getLegacyAccountAddress(BackupWallet backup) async {
  try {
    final config = await ConfigService().getConfig(backup.alias);

    final legacy4337 = await getLegacy4337Bundlers();

    final legacyConfig = legacy4337.getFromAlias(backup.alias);
    if (legacyConfig == null) {
      return null;
    }

    final legacyAccountFactory = await accountFactoryServiceFromConfig(
      config,
      customAccountFactory: legacyConfig.accountFactoryAddress,
    );

    final account = await legacyAccountFactory.getAddress(backup.address);

    final indexer = APIService(baseURL: config.indexer.url);

    final exists = await accountExists(
      indexer,
      config.indexer.key,
      account.hexEip55,
    );

    if (!exists) {
      // deploy account
      await createAccount(
        indexer,
        config.indexer.key,
        legacyAccountFactory,
        EthPrivateKey.fromHex(backup.privateKey),
      );
    }

    return account;
  } catch (_) {}

  return null;
}

/// check if an account exists
Future<bool> accountExists(
  APIService indexer,
  String indexerKey,
  String account,
) async {
  try {
    final url = '/accounts/$account/exists';

    await indexer.get(
      url: url,
      headers: {
        'Authorization': 'Bearer $indexerKey',
      },
    );

    return true;
  } catch (_) {}

  return false;
}

/// create an account
Future<bool> createAccount(
  APIService indexer,
  String indexerKey,
  AccountFactoryService accountFactory,
  EthPrivateKey customCredentials,
) async {
  try {
    final cred = customCredentials;

    final url = '/accounts/factory/${accountFactory.addr}';

    final encoded = jsonEncode(
      {
        'owner': cred.address.hexEip55,
        'salt': BigInt.zero.toInt(),
      },
    );

    final body = SignedRequest(convertStringToUint8List(encoded));

    final sig =
        await compute(generateSignature, (jsonEncode(body.toJson()), cred));

    await indexer.post(
      url: url,
      headers: {
        'Authorization': 'Bearer $indexerKey',
        'X-Signature': sig,
        'X-Address': cred.address
            .hexEip55, // owner verification since 1271 is impossible at this point
      },
      body: body.toJson(),
    );

    return true;
  } on ConflictException {
    return true;
  } catch (_) {}

  return false;
}
