import 'dart:convert';

import 'package:citizenwallet/services/api/api.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/config/service.dart';
import 'package:citizenwallet/services/accounts/backup.dart';
import 'package:citizenwallet/services/db/app/db.dart';
import 'package:citizenwallet/services/indexer/signed_request.dart';
import 'package:citizenwallet/services/wallet/contracts/account_factory.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';

Future<EthereumAddress?> getLegacyAccountAddress(
    LegacyBackupWallet backup) async {
  try {
    // final config = await ConfigService().getConfig(backup.alias);
    final community = await AppDBService().communities.get(backup.alias);

    if (community == null) {
      throw Exception('no community found');
    }

    Config communityConfig = Config.fromJson(community.config);

    final legacy4337 = await getLegacy4337Bundlers();

    final legacyConfig = legacy4337.getFromAlias(backup.alias);
    if (legacyConfig == null) {
      return null;
    }

    final legacyAccountFactory = await accountFactoryServiceFromConfig(
      communityConfig,
      customAccountFactory: legacyConfig.accountFactoryAddress,
    );

    final account = await legacyAccountFactory.getAddress(backup.address);

    final indexer = APIService(
        baseURL: communityConfig
            .chains[communityConfig.tokens.first.chainId.toString()]!.node.url);

    final exists = await accountExists(indexer, account.hexEip55);

    if (!exists) {
      // deploy account
      await createAccount(
        indexer,
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
  String account,
) async {
  try {
    final url = '/accounts/$account/exists';

    await indexer.get(
      url: url,
    );

    return true;
  } catch (_) {}

  return false;
}

/// create an account
Future<bool> createAccount(
  APIService indexer,
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
