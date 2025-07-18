import 'dart:convert';

import 'package:citizenwallet/services/api/api.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/indexer/pagination.dart';
import 'package:citizenwallet/services/indexer/push_update_request.dart';
import 'package:citizenwallet/services/indexer/signed_request.dart';
import 'package:citizenwallet/services/engine/utils.dart';
import 'package:citizenwallet/services/sigauth/sigauth.dart';
import 'package:citizenwallet/services/wallet/contracts/erc20.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/contracts/simpleFaucet.dart';
import 'package:citizenwallet/services/wallet/contracts/cards/card_manager.dart';
import 'package:citizenwallet/services/wallet/contracts/cards/safe_card_manager.dart';
import 'package:citizenwallet/services/wallet/contracts/cards/interface.dart';
import 'package:citizenwallet/services/wallet/contracts/accessControl.dart';
import 'package:citizenwallet/services/wallet/gas.dart';
import 'package:citizenwallet/services/wallet/models/json_rpc.dart';
import 'package:citizenwallet/services/wallet/models/paymaster_data.dart';
import 'package:citizenwallet/services/wallet/models/userop.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

/// given a tx hash, waits for the tx to be mined
Future<bool> waitForTxSuccess(
  Config config,
  String txHash, {
  int retryCount = 0,
  int maxRetries = 20,
}) async {
  if (retryCount >= maxRetries) {
    return false;
  }

  final ethClient = config.ethClient;

  final receipt = await ethClient.getTransactionReceipt(txHash);
  if (receipt?.status != true) {
    // there is either no receipt or the tx is still not confirmed

    // increment the retry count
    final nextRetryCount = retryCount + 1;

    // wait for a bit before retrying
    await delay(Duration(milliseconds: 250 * (nextRetryCount)));

    // retry
    return waitForTxSuccess(
      config,
      txHash,
      retryCount: nextRetryCount,
      maxRetries: maxRetries,
    );
  }

  return true;
}

/// construct transfer call data
Uint8List tokenTransferCallData(
  Config config,
  EthereumAddress from,
  String to,
  BigInt amount, {
  BigInt? tokenId,
}) {
  if (config.getPrimaryToken().standard == 'erc20') {
    return config.token20Contract.transferCallData(to, amount);
  } else if (config.getPrimaryToken().standard == 'erc1155') {
    return config.token1155Contract
        .transferCallData(from.hexEip55, to, tokenId ?? BigInt.zero, amount);
  }

  return Uint8List.fromList([]);
}

String transferEventStringSignature(Config config) {
  if (config.getPrimaryToken().standard == 'erc20') {
    return config.token20Contract.transferEventStringSignature;
  } else if (config.getPrimaryToken().standard == 'erc1155') {
    return config.token1155Contract.transferEventStringSignature;
  }

  return '';
}

String transferEventSignature(Config config) {
  if (config.getPrimaryToken().standard == 'erc20') {
    return config.token20Contract.transferEventSignature;
  } else if (config.getPrimaryToken().standard == 'erc1155') {
    return config.token1155Contract.transferEventSignature;
  }

  return '';
}

/// retrieves the current balance of the address
Future<String> getBalance(
  Config config,
  EthereumAddress addr, {
  BigInt? tokenId,
}) async {
  try {
    final tokenStandard = config.getPrimaryToken().standard;

    BigInt balance = BigInt.zero;
    switch (tokenStandard) {
      case 'erc20':
        balance =
            await config.token20Contract.getBalance(addr.hexEip55).timeout(
                  const Duration(seconds: 4),
                );

        break;
      case 'erc1155':
        balance = await config.token1155Contract
            .getBalance(addr.hexEip55, tokenId ?? BigInt.zero)
            .timeout(
              const Duration(seconds: 4),
            );
        break;
    }

    return balance.toString();
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return '0';
}

/// get profile data
Future<ProfileV1?> getProfile(Config config, String addr) async {
  try {
    final url = await config.profileContract.getURL(addr);

    final profileData = await config.ipfsService.get(url: '/$url');

    final profile = ProfileV1.fromJson(profileData);

    profile.parseIPFSImageURLs(config.ipfs.url);

    return profile;
  } catch (exception) {
    //
  }

  return null;
}

/// get profile data by username
Future<ProfileV1?> getProfileByUsername(Config config, String username) async {
  try {
    final url = await config.profileContract.getURLFromUsername(username);

    final profileData = await config.ipfsService.get(url: '/$url');

    final profile = ProfileV1.fromJson(profileData);

    profile.parseIPFSImageURLs(config.ipfs.url);

    return profile;
  } catch (exception) {
    //
  }

  return null;
}

/// profileExists checks whether there is a profile for this username
Future<bool> profileExists(Config config, String username) async {
  try {
    final url = await config.profileContract.getURLFromUsername(username)
        .timeout(const Duration(seconds: 10));

    return url != '';
  } catch (exception) {
    //
  }

  return false;
}

/// get profile data
Future<ProfileV1?> getProfileFromUrl(Config config, String url) async {
  try {
    final profileData = await config.ipfsService.get(url: '/$url');

    final profile = ProfileV1.fromJson(profileData);

    profile.parseIPFSImageURLs(config.ipfs.url);

    return profile;
  } catch (exception) {
    //
  }

  return null;
}

/// set profile data
Future<String?> setProfile(
  Config config,
  EthereumAddress account,
  EthPrivateKey credentials,
  ProfileRequest profile, {
  required List<int> image,
  required String fileType,
}) async {
  try {
    final url =
        '/v1/profiles/${config.profileContract.addr}/${account.hexEip55}';

    final json = jsonEncode(
      profile.toJson(),
    );

    final body = SignedRequest(convertBytesToUint8List(utf8.encode(json)));

    final sig = await compute(
        generateSignature, (jsonEncode(body.toJson()), credentials));

    final resp = await config.engineIPFSService.filePut(
      url: url,
      file: image,
      fileType: fileType,
      headers: {
        'X-Signature': sig,
        'X-Address': account.hexEip55,
      },
      body: body.toJson(),
    );

    final String profileUrl = resp['object']['ipfs_url'];

    final calldata = config.profileContract
        .setCallData(account.hexEip55, profile.username, profileUrl);

    final (_, userop) = await prepareUserop(
      config,
      account,
      credentials,
      [config.profileContract.addr],
      [calldata],
    );

    final txHash = await submitUserop(config, userop);
    if (txHash == null) {
      throw Exception('profile update failed');
    }

    final success = await waitForTxSuccess(config, txHash);
    if (!success) {
      throw Exception('transaction failed');
    }

    return profileUrl;
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return null;
}

/// update profile data
Future<String?> updateProfile(Config config, EthereumAddress account,
    EthPrivateKey credentials, ProfileV1 profile) async {
  try {
    final url =
        '/v1/profiles/${config.profileContract.addr}/${account.hexEip55}';

    final json = jsonEncode(
      profile.toJson(),
    );

    final body = SignedRequest(convertBytesToUint8List(utf8.encode(json)));

    final sig = await compute(
        generateSignature, (jsonEncode(body.toJson()), credentials));

    final resp = await config.engineIPFSService.patch(
      url: url,
      headers: {
        'X-Signature': sig,
        'X-Address': account.hexEip55,
      },
      body: body.toJson(),
    );

    final String profileUrl = resp['object']['ipfs_url'];

    final calldata = config.profileContract
        .setCallData(account.hexEip55, profile.username, profileUrl);

    final (_, userop) = await prepareUserop(
      config,
      account,
      credentials,
      [config.profileContract.addr],
      [calldata],
    );

    final txHash = await submitUserop(config, userop);
    if (txHash == null) {
      throw Exception('profile update failed');
    }

    final success = await waitForTxSuccess(config, txHash);
    if (!success) {
      throw Exception('transaction failed');
    }

    return profileUrl;
  } catch (_) {}

  return null;
}

/// set profile data
Future<bool> deleteCurrentProfile(
  Config config,
  EthereumAddress account,
  EthPrivateKey credentials,
) async {
  try {
    final url =
        '/v1/profiles/${config.profileContract.addr}/${account.hexEip55}';

    final encoded = jsonEncode(
      {
        'account': account.hexEip55,
        'date': DateTime.now().toUtc().toIso8601String(),
      },
    );

    final body = SignedRequest(convertStringToUint8List(encoded));

    final sig = await compute(
        generateSignature, (jsonEncode(body.toJson()), credentials));

    await config.engineIPFSService.delete(
      url: url,
      headers: {
        'X-Signature': sig,
        'X-Address': account.hexEip55,
      },
      body: body.toJson(),
    );

    return true;
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return false;
}

/// check if an account exists
Future<bool> accountExists(
  Config config,
  EthereumAddress account,
) async {
  try {
    final url = '/v1/accounts/${account.hexEip55}/exists';

    await config.engine.get(
      url: url,
    );

    return true;
  } catch (_) {}

  return false;
}

/// create an account
Future<bool> createAccount(
  Config config,
  EthereumAddress account,
  EthPrivateKey credentials,
) async {
  try {
    final exists = await accountExists(config, account);
    if (exists) {
      return true;
    }

    final simpleAccount = await config.getSimpleAccount(account.hexEip55);

    Uint8List calldata = simpleAccount.transferOwnershipCallData(
      credentials.address.hexEip55,
    );
    if (config.getPaymasterType() == 'cw-safe') {
      calldata = config.communityModuleContract.getChainIdCallData();
    }

    final (_, userop) = await prepareUserop(
      config,
      account,
      credentials,
      [account.hexEip55],
      [calldata],
    );

    final txHash = await submitUserop(
      config,
      userop,
    );
    if (txHash == null) {
      throw Exception('failed to submit user op');
    }

    final success = await waitForTxSuccess(config, txHash);
    if (!success) {
      throw Exception('transaction failed');
    }

    return true;
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return false;
}

/// makes a jsonrpc request from this wallet
Future<SUJSONRPCResponse> requestPaymaster(
  Config config,
  SUJSONRPCRequest body, {
  bool legacy = false,
}) async {
  final rawResponse = await config.engineRPC.post(
    body: body,
  );

  final response = SUJSONRPCResponse.fromJson(rawResponse);

  if (response.error != null) {
    throw Exception(response.error!.message);
  }

  return response;
}

/// return paymaster data for constructing a user op
Future<(PaymasterData?, Exception?)> getPaymasterData(
  Config config,
  UserOp userop,
  String eaddr,
  String ptype, {
  bool legacy = false,
}) async {
  final body = SUJSONRPCRequest(
    method: 'pm_sponsorUserOperation',
    params: [
      userop.toJson(),
      eaddr,
      {'type': ptype},
    ],
  );

  try {
    final response = await requestPaymaster(config, body, legacy: legacy);

    return (PaymasterData.fromJson(response.result), null);
  } catch (exception) {
    final strerr = exception.toString();

    if (strerr.contains(gasFeeErrorMessage)) {
      return (null, NetworkCongestedException());
    }

    if (strerr.contains(invalidBalanceErrorMessage)) {
      return (null, NetworkInvalidBalanceException());
    }
  }

  return (null, NetworkUnknownException());
}

/// return paymaster data for constructing a user op
Future<(List<PaymasterData>, Exception?)> getPaymasterOOData(
  Config config,
  UserOp userop,
  String eaddr,
  String ptype, {
  bool legacy = false,
  int count = 1,
}) async {
  final body = SUJSONRPCRequest(
    method: 'pm_ooSponsorUserOperation',
    params: [
      userop.toJson(),
      eaddr,
      {'type': ptype},
      count,
    ],
  );

  try {
    final response = await requestPaymaster(config, body, legacy: legacy);

    final List<dynamic> data = response.result;
    if (data.isEmpty) {
      throw Exception('empty paymaster data');
    }

    if (data.length != count) {
      throw Exception('invalid paymaster data');
    }

    return (data.map((item) => PaymasterData.fromJson(item)).toList(), null);
  } catch (exception) {
    final strerr = exception.toString();

    if (strerr.contains(gasFeeErrorMessage)) {
      return (<PaymasterData>[], NetworkCongestedException());
    }

    if (strerr.contains(invalidBalanceErrorMessage)) {
      return (<PaymasterData>[], NetworkInvalidBalanceException());
    }
  }

  return (<PaymasterData>[], NetworkUnknownException());
}

/// prepare a userop for with calldata
Future<(String, UserOp)> prepareUserop(
  Config config,
  EthereumAddress account,
  EthPrivateKey credentials,
  List<String> dest,
  List<Uint8List> calldata, {
  EthPrivateKey? customCredentials,
  BigInt? customNonce,
  bool deploy = true,
  BigInt? value,
}) async {
  try {
    final cred = customCredentials ?? credentials;

    EthereumAddress acc = account;
    if (customCredentials != null) {
      acc = await getAccountAddress(config, customCredentials.address.hexEip55);
    }

    // instantiate user op with default values
    final userop = UserOp.defaultUserOp();

    // use the account hex as the sender
    userop.sender = acc.hexEip55;

    // determine the appropriate nonce
    BigInt nonce = customNonce ?? await config.getNonce(acc.hexEip55);

    final paymasterType = config.getPaymasterType();

    // if it's the first user op from this account, we need to deploy the account contract
    if (nonce == BigInt.zero && deploy) {
      bool exists = false;
      if (paymasterType == 'payg') {
        // solves edge case with legacy account migration
        exists = await accountExists(config, acc);
      }

      if (!exists) {
        final accountFactory = config.accountFactoryContract;

        // construct the init code to deploy the account
        userop.initCode = await accountFactory.createAccountInitCode(
          cred.address.hexEip55,
          BigInt.zero,
        );
      } else {
        // try again in case the account was created in the meantime
        nonce = customNonce ??
            await config.entryPointContract.getNonce(acc.hexEip55);
      }
    }

    userop.nonce = nonce;

    // set the appropriate call data for the transfer
    // we need to call account.execute which will call token.transfer
    switch (paymasterType) {
      case 'payg':
      case 'cw':
        {
          final simpleAccount = await config.getSimpleAccount(acc.hexEip55);

          userop.callData = dest.length > 1 && calldata.length > 1
              ? simpleAccount.executeBatchCallData(
                  dest,
                  calldata,
                )
              : simpleAccount.executeCallData(
                  dest[0],
                  value ?? BigInt.zero,
                  // value ?? BigInt.zero,
                  calldata[0],
                );
          break;
        }
      case 'cw-safe':
        {
          final safeAccount = await config.getSafeAccount(acc.hexEip55);
          userop.callData = safeAccount.executeCallData(
            dest[0],
            value ?? BigInt.zero,
            // value ?? BigInt.zero,
            calldata[0],
          );
          break;
        }
    }

    // submit the user op to the paymaster in order to receive information to complete the user op
    List<PaymasterData> paymasterOOData = [];
    Exception? paymasterErr;
    final useAccountNonce =
        (nonce == BigInt.zero || paymasterType == 'payg') && deploy;

    if (useAccountNonce) {
      // if it's the first user op, we should use a normal paymaster signature
      PaymasterData? paymasterData;
      (paymasterData, paymasterErr) = await getPaymasterData(
        config,
        userop,
        config.entryPointContract.addr,
        paymasterType,
      );

      if (paymasterData != null) {
        paymasterOOData.add(paymasterData);
      }
    } else {
      // if it's not the first user op, we should use an out of order paymaster signature
      (paymasterOOData, paymasterErr) = await getPaymasterOOData(
        config,
        userop,
        config.entryPointContract.addr,
        paymasterType,
      );
    }

    if (paymasterErr != null) {
      throw paymasterErr;
    }

    if (paymasterOOData.isEmpty) {
      throw Exception('unable to get paymaster data');
    }

    final paymasterData = paymasterOOData.first;
    if (!useAccountNonce) {
      // use the nonce received from the paymaster
      userop.nonce = paymasterData.nonce;
    }

    // add the received data to the user op
    userop.paymasterAndData = paymasterData.paymasterAndData;
    userop.preVerificationGas = paymasterData.preVerificationGas;
    userop.verificationGasLimit = paymasterData.verificationGasLimit;
    userop.callGasLimit = paymasterData.callGasLimit;

    // get the hash of the user op
    final hash = await config.entryPointContract.getUserOpHash(userop);

    // now we can sign the user op
    userop.generateSignature(cred, hash);

    return (bytesToHex(hash, include0x: true), userop);
  } catch (_) {
    rethrow;
  }
}

/// submit a user op
Future<String?> submitUserop(
  Config config,
  UserOp userop, {
  EthPrivateKey? customCredentials,
  Map<String, dynamic>? data,
  TransferData? extraData,
}) async {
  try {
    final entryPoint = config.entryPointContract;

    final params = [userop.toJson(), entryPoint.addr];
    if (data != null) {
      params.add(data);
    }
    if (data != null && extraData != null) {
      params.add(extraData.toJson());
    }

    final body = SUJSONRPCRequest(
      method: 'eth_sendUserOperation',
      params: params,
    );

    final response = await requestBundler(config, body);

    return response.result as String;
  } catch (exception, s) {
    debugPrint('error: $exception');
    debugPrint('stack trace: $s');

    final strerr = exception.toString();

    if (strerr.contains(gasFeeErrorMessage)) {
      throw NetworkCongestedException();
    }

    if (strerr.contains(invalidBalanceErrorMessage)) {
      throw NetworkInvalidBalanceException();
    }
  }

  throw NetworkUnknownException();
}

/// makes a jsonrpc request from this wallet
Future<SUJSONRPCResponse> requestBundler(
    Config config, SUJSONRPCRequest body) async {
  final rawResponse = await config.engineRPC.post(
    body: body,
  );

  debugPrint('rawResponse: ${rawResponse.toString()}');

  final response = SUJSONRPCResponse.fromJson(rawResponse);

  if (response.error != null) {
    debugPrint('error: ${response.error!.message}');
    throw Exception(response.error!.message);
  }

  return response;
}

/// fetch erc20 transfer events
Future<(List<TransferEvent>, Pagination)> fetchErc20Transfers(
  Config config,
  String addr, {
  required int offset,
  required int limit,
  required DateTime maxDate,
}) async {
  try {
    final List<TransferEvent> tx = [];

    const path = '/v1/logs';

    final eventSignature = config.getPrimaryToken().standard == 'erc20'
        ? config.token20Contract.transferEventSignature
        : config.token1155Contract.transferEventSignature;

    final dataQueryParams = buildQueryParams([
      {
        'key': 'from',
        'value': addr,
      },
    ], or: [
      {
        'key': 'to',
        'value': addr,
      },
    ]);

    final tokenAddr = config.getPrimaryToken().standard == 'erc20'
        ? config.token20Contract.addr
        : config.token1155Contract.addr;

    final url =
        '$path/$tokenAddr/$eventSignature?offset=$offset&limit=$limit&maxDate=${Uri.encodeComponent(maxDate.toUtc().toIso8601String())}&$dataQueryParams';

    final response = await config.engine.get(url: url);

    // convert response array into TransferEvent list
    for (final item in response['array']) {
      final log = Log.fromJson(item);

      tx.add(TransferEvent.fromLog(log,
          standard: config.getPrimaryToken().standard));
    }

    return (tx, Pagination.fromJson(response['meta']));
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return (<TransferEvent>[], Pagination.empty());
}

/// fetch new erc20 transfer events
Future<List<TransferEvent>?> fetchNewErc20Transfers(
  Config config,
  String addr,
  DateTime fromDate,
) async {
  try {
    final List<TransferEvent> tx = [];

    const path = 'logs/v2/transfers';

    final tokenAddr = config.getPrimaryToken().standard == 'erc20'
        ? config.token20Contract.addr
        : config.token1155Contract.addr;

    final url =
        '/$path/$tokenAddr/$addr/new?limit=10&fromDate=${Uri.encodeComponent(fromDate.toUtc().toIso8601String())}';

    final response = await config.engine.get(url: url);

    // convert response array into TransferEvent list
    for (final item in response['array']) {
      tx.add(TransferEvent.fromJson(item));
    }

    return tx;
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return null;
}

/// construct erc20 transfer call data
Uint8List tokenMintCallData(
  Config config,
  String to,
  BigInt amount, {
  BigInt? tokenId,
}) {
  if (config.getPrimaryToken().standard == 'erc20') {
    return config.token20Contract.mintCallData(to, amount);
  } else if (config.getPrimaryToken().standard == 'erc1155') {
    return config.token1155Contract
        .mintCallData(to, amount, tokenId ?? BigInt.zero);
  }

  return Uint8List.fromList([]);
}

/// construct simple faucet redeem call data
Future<Uint8List> simpleFaucetRedeemCallData(
  Config config,
  String address,
) async {
  final chain = config.chains.values.first;
  final contract = SimpleFaucetContract(chain.id, config.ethClient, address);

  await contract.init();

  return contract.redeemCallData();
}

/// fetch simple faucet redeem amount
Future<BigInt> getFaucetRedeemAmount(Config config, String address) async {
  final chain = config.chains.values.first;
  final contract = SimpleFaucetContract(chain.id, config.ethClient, address);

  await contract.init();

  return contract.getAmount();
}

/// updates the push token for the current account
Future<bool> updatePushToken(
  Config config,
  EthereumAddress account,
  EthPrivateKey credentials,
  String token, {
  EthPrivateKey? customCredentials,
}) async {
  try {
    final cred = customCredentials ?? credentials;

    EthereumAddress acc = account;
    if (customCredentials != null) {
      acc = await getAccountAddress(config, customCredentials.address.hexEip55);
    }

    final tokenAddr = config.getPrimaryToken().standard == 'erc20'
        ? config.token20Contract.addr
        : config.token1155Contract.addr;

    final url = '/v1/push/$tokenAddr/${acc.hexEip55}';

    final encoded = jsonEncode(
      PushUpdateRequest(token, acc.hexEip55).toJson(),
    );

    final body = SignedRequest(convertStringToUint8List(encoded));

    final sig =
        await compute(generateSignature, (jsonEncode(body.toJson()), cred));

    await config.engine.put(
      url: url,
      headers: {
        'X-Signature': sig,
        'X-Address': acc.hexEip55,
      },
      body: body.toJson(),
    );

    return true;
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return false;
}

/// removes the push token for the current account
Future<bool> removePushToken(
  Config config,
  EthereumAddress account,
  EthPrivateKey credentials,
  String token, {
  EthPrivateKey? customCredentials,
}) async {
  try {
    final cred = customCredentials ?? credentials;

    EthereumAddress acc = account;
    if (customCredentials != null) {
      acc = await getAccountAddress(config, customCredentials.address.hexEip55);
    }

    final tokenAddr = config.getPrimaryToken().standard == 'erc20'
        ? config.token20Contract.addr
        : config.token1155Contract.addr;

    final url = '/v1/push/$tokenAddr/${acc.hexEip55}/$token';

    final encoded = jsonEncode(
      {
        'account': acc.hexEip55,
        'date': DateTime.now().toUtc().toIso8601String(),
      },
    );

    final body = SignedRequest(convertStringToUint8List(encoded));

    final sig =
        await compute(generateSignature, (jsonEncode(body.toJson()), cred));

    await config.engine.delete(
      url: url,
      headers: {
        'X-Signature': sig,
        'X-Address': acc.hexEip55,
      },
      body: body.toJson(),
    );

    return true;
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return false;
}

/// check if an account is a minter
Future<bool> isMinter(Config config, EthereumAddress account) async {
  try {
    final chain = config.chains.values.first;
    final tokenAddress = config.getPrimaryToken().address;

    final accessControl = AccessControlUpgradeableContract(
      chain.id,
      config.ethClient,
      tokenAddress,
    );
    await accessControl.init();

    return await accessControl.isMinter(account.hexEip55);
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return false;
}

/// dispose of resources
void disposeWallet(Config config) {
  config.ethClient.dispose();
}

/// get sigauth connection
SigAuthConnection getSigAuthConnection(
  Config config,
  EthereumAddress account,
  EthPrivateKey credentials,
  String redirect,
) {
  final _sigAuth = SigAuthService(
    credentials: credentials,
    address: account,
    redirect: redirect,
  );

  return _sigAuth.connect();
}

/// get account address
Future<EthereumAddress> getAccountAddress(
  Config config,
  String addr, {
  bool legacy = false,
  bool cache = true,
}) async {
  final accountFactory = config.accountFactoryContract;
  return await accountFactory.getAddress(addr);
}

/// upgrade an account
Future<String?> upgradeAccount(
  Config config,
  EthereumAddress account,
  EthPrivateKey credentials,
) async {
  try {
    final accountFactory = config.accountFactoryContract;

    final url =
        '/accounts/factory/${accountFactory.addr}/sca/${account.hexEip55}';

    final encoded = jsonEncode(
      {
        'owner': credentials.address.hexEip55,
        'salt': BigInt.zero.toInt(),
      },
    );

    final body = SignedRequest(convertStringToUint8List(encoded));

    final sig = await compute(
        generateSignature, (jsonEncode(body.toJson()), credentials));

    final response = await config.engine.patch(
      url: url,
      headers: {
        'X-Signature': sig,
        'X-Address': account.hexEip55,
      },
      body: body.toJson(),
    );

    final implementation = response['object']['account_implementation'];
    if (implementation == "0x0000000000000000000000000000000000000000") {
      throw Exception('invalid implementation');
    }

    return implementation;
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return null;
}

/// get card hash
Future<Uint8List> getCardHash(
  Config config,
  String serial, {
  bool local = true,
}) async {
  final primaryCardManager = config.getPrimaryCardManager();

  if (primaryCardManager == null) {
    throw Exception('Card manager not initialized');
  }

  AbstractCardManagerContract cardManager;

  if (primaryCardManager.type == CardManagerType.classic) {
    cardManager = CardManagerContract(
      primaryCardManager.chainId,
      config.ethClient,
      primaryCardManager.address,
    );
  } else if (primaryCardManager.type == CardManagerType.safe &&
      primaryCardManager.instanceId != null) {
    final instanceId = primaryCardManager.instanceId!;
    cardManager = SafeCardManagerContract(
      keccak256(convertStringToUint8List(instanceId)),
      primaryCardManager.chainId,
      config.ethClient,
      primaryCardManager.address,
    );
  } else {
    throw Exception('Invalid card manager configuration');
  }

  await cardManager.init();
  return await cardManager.getCardHash(serial, local: local);
}

/// get card address
Future<EthereumAddress> getCardAddress(
  Config config,
  Uint8List hash,
) async {
  final primaryCardManager = config.getPrimaryCardManager();

  if (primaryCardManager == null) {
    throw Exception('Card manager not initialized');
  }

  AbstractCardManagerContract cardManager;

  if (primaryCardManager.type == CardManagerType.classic) {
    cardManager = CardManagerContract(
      primaryCardManager.chainId,
      config.ethClient,
      primaryCardManager.address,
    );
  } else if (primaryCardManager.type == CardManagerType.safe &&
      primaryCardManager.instanceId != null) {
    final instanceId = primaryCardManager.instanceId!;
    cardManager = SafeCardManagerContract(
      keccak256(convertStringToUint8List(instanceId)),
      primaryCardManager.chainId,
      config.ethClient,
      primaryCardManager.address,
    );
  } else {
    throw Exception('Invalid card manager configuration');
  }

  await cardManager.init();
  return await cardManager.getCardAddress(hash);
}

/// estimate gas prices using EIP1559
Future<EIP1559GasPrice?> estimateGasPrice(
  Config config,
) async {
  try {
    final chain = config.chains.values.first;
    final rpcUrl = config.getRpcUrl(chain.id.toString());
    final rpc = APIService(baseURL: rpcUrl);

    final estimator = EIP1559GasPriceEstimator(
      rpc,
      config.ethClient,
      gasExtraPercentage:
          config.getPrimaryAccountAbstractionConfig().gasExtraPercentage,
    );

    return await estimator.estimate;
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return null;
}

// Future<EthereumAddress> getTwoFAAddress(
//   Config config,
//   String source,
//   String type,
// ) async {
//   final provider = EthereumAddress.fromHex(
//       config.getPrimarySessionManager().providerAddress);
//   final salt = generateSessionSalt(source, type);
//   return await config.twoFAFactoryContract.getAddress(provider, salt);
// }
