import 'dart:convert';

import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/services/api/api.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/config/service.dart';
import 'package:citizenwallet/services/indexer/pagination.dart';
import 'package:citizenwallet/services/indexer/push_update_request.dart';
import 'package:citizenwallet/services/indexer/signed_request.dart';
import 'package:citizenwallet/services/indexer/status_update_request.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/wallet/contracts/entrypoint.dart';
import 'package:citizenwallet/services/wallet/contracts/erc20.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/contracts/simple_account.dart';
import 'package:citizenwallet/services/wallet/contracts/account_factory.dart';
import 'package:citizenwallet/services/wallet/gas.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/services/wallet/models/json_rpc.dart';
import 'package:citizenwallet/services/wallet/models/paymaster_data.dart';
import 'package:citizenwallet/services/wallet/models/userop.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();

  factory WalletService() {
    return _instance;
  }

  final PreferencesService _pref = PreferencesService();

  bool _useLegacyBundlers = false;

  BigInt? _chainId;
  late NativeCurrency currency;

  late Client _client;

  late String _indexerKey;

  late String _alias;
  late String _url;
  late String _wsurl;
  late Web3Client _ethClient;

  late String ipfsUrl;
  late APIService _ipfs;
  late APIService _indexer;
  late APIService _indexerIPFS;

  late APIService _rpc;
  late APIService _bundlerRPC;
  late APIService _paymasterRPC;
  late String _paymasterType;

  late Legacy4337Bundlers _legacy4337Bundlers;

  late EIP1559GasPriceEstimator _gasPriceEstimator;

  late Map<String, String> erc4337Headers;

  WalletService._internal() {
    _client = Client();
  }

  // Declare variables using the `late` keyword, which means they will be initialized at a later time.
// The variables are related to Ethereum blockchain development.
  late EthPrivateKey
      _credentials; // Represents a private key for an Ethereum account.
  late EthereumAddress _account; // Represents an Ethereum address.
  late StackupEntryPoint
      _contractEntryPoint; // Represents the entry point for a smart contract on the Ethereum blockchain.
  late AccountFactoryService
      _contractAccountFactory; // Represents a factory for creating Ethereum accounts.
  late ERC20Contract
      _contractToken; // Represents a smart contract for an ERC20 token on the Ethereum blockchain.
  late SimpleAccount _contractAccount; // Represents a simple Ethereum account.
  late ProfileContract
      _contractProfile; // Represents a smart contract for a user profile on the Ethereum blockchain.

  // legacy contracts
  late StackupEntryPoint _contractLegacyEntryPoint;
  late AccountFactoryService _contractLegacyAccountFactory;
  late APIService _bundlerLegacyRPC;
  late APIService _paymasterLegacyRPC;
  late String _paymasterLegacyType;

  EthPrivateKey get credentials => _credentials;
  EthereumAddress get address => _credentials.address;
  EthereumAddress get account => _account;

  /// retrieves the current balance of the address
  Future<String> get balance async {
    try {
      final b = await _contractToken.getBalance(_account.hexEip55).timeout(
            const Duration(seconds: 2),
          );

      _pref.setBalance(_account.hexEip55, b.toString());

      return b.toString();
    } catch (e) {
      //
    }

    return _pref.getBalance(_account.hexEip55) ?? '0.0';
  }

  /// retrieve chain id
  int get chainId => _chainId != null ? _chainId!.toInt() : 0;
  String get alias => _alias;

  String get erc20Address => _contractToken.addr;
  String get profileAddress => _contractProfile.addr;

  Future<BigInt> get accountNonce async =>
      getEntryPointContract().getNonce(_account.hexEip55);

  Future<void> init(
    EthereumAddress account,
    EthPrivateKey privateKey,
    NativeCurrency currency,
    Config config, {
    void Function(String)? onNotify,
    void Function(bool)? onFinished,
  }) async {
    _indexerKey = config.indexer.key;

    _alias = config.community.alias;
    _url = config.node.url;
    _wsurl = config.node.wsUrl;

    _ethClient = Web3Client(
      _url,
      _client,
      socketConnector: () =>
          WebSocketChannel.connect(Uri.parse(_wsurl)).cast<String>(),
    );

    ipfsUrl = config.ipfs.url;
    _ipfs = APIService(baseURL: ipfsUrl);
    _indexer = APIService(baseURL: config.indexer.url);
    _indexerIPFS = APIService(baseURL: config.indexer.ipfsUrl);

    _rpc = APIService(baseURL: config.node.url);
    _bundlerRPC = APIService(
        baseURL: config.erc4337.paymasterAddress != null
            ? '${config.erc4337.rpcUrl}/${config.erc4337.paymasterAddress}'
            : config.erc4337.rpcUrl);
    _paymasterRPC = APIService(
        baseURL: config.erc4337.paymasterAddress != null
            ? '${config.erc4337.paymasterRPCUrl}/${config.erc4337.paymasterAddress}'
            : config.erc4337.paymasterRPCUrl);
    _paymasterType = config.erc4337.paymasterType;

    _gasPriceEstimator = EIP1559GasPriceEstimator(
      _rpc,
      _ethClient,
      gasExtraPercentage: config.erc4337.gasExtraPercentage,
    );

    erc4337Headers = {};
    if (!kIsWeb || kDebugMode) {
      // on native, we need to set the origin header
      erc4337Headers['Origin'] = dotenv.get('ORIGIN_HEADER');
    }

    _credentials = privateKey;

    final cachedChainId = _pref.getChainIdForAlias(config.community.alias);
    _chainId = cachedChainId != null
        ? BigInt.parse(cachedChainId)
        : await _ethClient.getChainId();
    await _pref.setChainIdForAlias(
        config.community.alias, _chainId!.toString());

    this.currency = currency;

    _legacy4337Bundlers = await getLegacy4337Bundlers();

    await _initContracts(
      account,
      config.community.alias,
      config.erc4337.entrypointAddress,
      config.erc4337.accountFactoryAddress,
      config.token.address,
      config.profile.address,
    );

    await _initLegacyContracts();
    await _initLegacyRPCs();

    _initAccount(onNotify, onFinished);
  }

  Future<void> initWeb(
    EthereumAddress account,
    EthPrivateKey privateKey,
    NativeCurrency currency,
    Config config, {
    bool legacy = false,
  }) async {
    _useLegacyBundlers = legacy;

    _indexerKey = config.indexer.key;

    _alias = config.community.alias;
    _url = config.node.url;
    _wsurl = config.node.wsUrl;

    _ethClient = Web3Client(
      _url,
      _client,
      socketConnector: () =>
          WebSocketChannel.connect(Uri.parse(_wsurl)).cast<String>(),
    );

    ipfsUrl = config.ipfs.url;
    _ipfs = APIService(baseURL: ipfsUrl);
    _indexer = APIService(baseURL: config.indexer.url);
    _indexerIPFS = APIService(baseURL: config.indexer.ipfsUrl);

    _rpc = APIService(baseURL: config.node.url);
    _bundlerRPC = APIService(
        baseURL: config.erc4337.paymasterAddress != null
            ? '${config.erc4337.rpcUrl}/${config.erc4337.paymasterAddress}'
            : config.erc4337.rpcUrl);
    _paymasterRPC = APIService(
        baseURL: config.erc4337.paymasterAddress != null
            ? '${config.erc4337.paymasterRPCUrl}/${config.erc4337.paymasterAddress}'
            : config.erc4337.paymasterRPCUrl);
    _paymasterType = config.erc4337.paymasterType;

    _gasPriceEstimator = EIP1559GasPriceEstimator(
      _rpc,
      _ethClient,
      gasExtraPercentage: config.erc4337.gasExtraPercentage,
    );

    erc4337Headers = {};
    if (!kIsWeb || kDebugMode) {
      // on native, we need to set the origin header
      erc4337Headers['Origin'] = dotenv.get('ORIGIN_HEADER');
    }

    _credentials = privateKey;

    final cachedChainId = _pref.getChainIdForAlias(config.community.alias);
    _chainId = cachedChainId != null
        ? BigInt.parse(cachedChainId)
        : await _ethClient.getChainId();
    await _pref.setChainIdForAlias(
        config.community.alias, _chainId!.toString());

    this.currency = currency;

    _legacy4337Bundlers = await getLegacy4337Bundlers();

    await _initContracts(
      account,
      config.community.alias,
      config.erc4337.entrypointAddress,
      config.erc4337.accountFactoryAddress,
      config.token.address,
      config.profile.address,
    );

    await _initLegacyContracts();
    await _initLegacyRPCs();
  }

  /// Initializes the Ethereum smart contracts used by the wallet.
  ///
  /// [account] The account address
  /// [alias] The community alias
  /// [eaddr] The Ethereum address of the entry point for the smart contract.
  /// [afaddr] The Ethereum address of the account factory smart contract.
  /// [taddr] The Ethereum address of the ERC20 token smart contract.
  /// [prfaddr] The Ethereum address of the user profile smart contract.
  Future<void> _initContracts(
    EthereumAddress account,
    String alias,
    String eaddr,
    String afaddr,
    String taddr,
    String prfaddr,
  ) async {
    // Get the Ethereum address for the current account.
    // _account = EthereumAddress.fromHex(account);
    _account = account;
    await _pref.setAccountAddress(
      _credentials.address.hexEip55,
      address.hexEip55,
    );

    // Create a new simple account instance and initialize it.
    _contractAccount = SimpleAccount(chainId, _ethClient, _account.hexEip55);
    await _contractAccount.init();

    // Create a new entry point instance and initialize it.
    _contractEntryPoint = StackupEntryPoint(chainId, _ethClient, eaddr);
    await _contractEntryPoint.init();

    // Create a new account factory instance and initialize it.
    _contractAccountFactory =
        AccountFactoryService(chainId, _ethClient, afaddr);
    await _contractAccountFactory.init();

    // Create a new ERC20 token contract instance and initialize it.
    _contractToken = ERC20Contract(chainId, _ethClient, taddr);
    await _contractToken.init();

    // Create a new user profile contract instance and initialize it.
    _contractProfile = ProfileContract(chainId, _ethClient, prfaddr);
    await _contractProfile.init();
  }

  /// Initializes the Legacy Ethereum smart contracts used by the wallet.
  Future<void> _initLegacyContracts() async {
    final legacyConfig = _legacy4337Bundlers.get(chainId.toString());

    // Create a new entry point instance and initialize it.
    _contractLegacyEntryPoint =
        StackupEntryPoint(chainId, _ethClient, legacyConfig.entrypointAddress);
    await _contractLegacyEntryPoint.init();

    // Create a new account factory instance and initialize it.
    _contractLegacyAccountFactory = AccountFactoryService(
        chainId, _ethClient, legacyConfig.accountFactoryAddress);
    await _contractLegacyAccountFactory.init();
  }

  /// Initializes the Legacy RPCs used by the wallet.
  Future<void> _initLegacyRPCs() async {
    final legacyConfig = _legacy4337Bundlers.get(chainId.toString());

    _bundlerLegacyRPC = APIService(baseURL: legacyConfig.rpcUrl);
    _paymasterLegacyRPC = APIService(baseURL: legacyConfig.paymasterRPCUrl);
    _paymasterLegacyType = legacyConfig.paymasterType;
  }

  Future<void> _initAccount(
    void Function(String)? onNotify,
    void Function(bool)? onFinished,
  ) async {
    try {
      // purely checking if there is byte code
      final exists = await accountExists();
      if (!exists) {
        _useLegacyBundlers = false;
        await createAccount();
      }

      _useLegacyBundlers = await _contractAccount.isLegacy();

      // call the upgrade function on our API, it will return the new implementation address
      final implementation = await upgradeAccount();

      if (implementation != null) {
        onNotify?.call('Upgrading account...');
        // upgrade the account to the new implementation address
        final calldata = _contractAccount.upgradeToCallData(implementation);

        final (_, userop) = await prepareUserop(
          [_account.hexEip55],
          [calldata],
          deploy: false,
        );

        final success = await submitUserop(
          userop,
        );

        if (!success) {
          return;
        }

        _useLegacyBundlers = false;

        onNotify?.call('Account upgraded...');
      }

      onFinished?.call(true);
      return;
    } catch (_) {}

    _useLegacyBundlers = true;

    onFinished?.call(false);
  }

  StackupEntryPoint getEntryPointContract({bool legacy = false}) {
    return _useLegacyBundlers || legacy
        ? _contractLegacyEntryPoint
        : _contractEntryPoint;
  }

  AccountFactoryService getAccounFactoryContract({bool legacy = false}) {
    return _useLegacyBundlers || legacy
        ? _contractLegacyAccountFactory
        : _contractAccountFactory;
  }

  APIService getBundlerRPC({bool legacy = false}) {
    return _useLegacyBundlers || legacy ? _bundlerLegacyRPC : _bundlerRPC;
  }

  APIService getPaymasterRPC({bool legacy = false}) {
    return _useLegacyBundlers || legacy ? _paymasterLegacyRPC : _paymasterRPC;
  }

  String getPaymasterType({bool legacy = false}) {
    return _useLegacyBundlers || legacy ? _paymasterLegacyType : _paymasterType;
  }

  /// fetches the balance of a given address
  Future<String> getBalance(String addr) async {
    final b = await _contractToken.getBalance(addr);
    return fromDoubleUnit(
      b.toString(),
      decimals: currency.decimals,
    );
  }

  /// set profile data
  Future<String?> setProfile(
    ProfileRequest profile, {
    required List<int> image,
    required String fileType,
  }) async {
    try {
      final url = '/profiles/v2/$profileAddress/${_account.hexEip55}';

      final json = jsonEncode(
        profile.toJson(),
      );

      final body = SignedRequest(convertBytesToUint8List(utf8.encode(json)));

      final sig = await compute(
          generateSignature, (jsonEncode(body.toJson()), _credentials));

      final resp = await _indexerIPFS.filePut(
        url: url,
        file: image,
        fileType: fileType,
        headers: {
          'Authorization': 'Bearer $_indexerKey',
          'X-Signature': sig,
          'X-Address': _account.hexEip55,
        },
        body: body.toJson(),
      );

      final String profileUrl = resp['object']['ipfs_url'];

      final calldata = _contractProfile.setCallData(
          _account.hexEip55, profile.username, profileUrl);

      final (_, userop) = await prepareUserop([profileAddress], [calldata]);

      final success = await submitUserop(userop);
      if (!success) {
        throw Exception('profile update failed');
      }

      return profileUrl;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  /// update profile data
  Future<String?> updateProfile(ProfileV1 profile) async {
    try {
      final url = '/profiles/v2/$profileAddress/${_account.hexEip55}';

      final json = jsonEncode(
        profile.toJson(),
      );

      final body = SignedRequest(convertBytesToUint8List(utf8.encode(json)));

      final sig = await compute(
          generateSignature, (jsonEncode(body.toJson()), _credentials));

      final resp = await _indexerIPFS.patch(
        url: url,
        headers: {
          'Authorization': 'Bearer $_indexerKey',
          'X-Signature': sig,
          'X-Address': _account.hexEip55,
        },
        body: body.toJson(),
      );

      final String profileUrl = resp['object']['ipfs_url'];

      final calldata = _contractProfile.setCallData(
          _account.hexEip55, profile.username, profileUrl);

      final (_, userop) = await prepareUserop([profileAddress], [calldata]);

      final success = await submitUserop(userop);
      if (!success) {
        throw Exception('profile update failed');
      }

      return profileUrl;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  /// set profile data
  Future<bool> unpinCurrentProfile() async {
    try {
      final url = '/profiles/v2/$profileAddress/${_account.hexEip55}';

      final encoded = jsonEncode(
        {
          'account': _account.hexEip55,
          'date': DateTime.now().toUtc().toIso8601String(),
        },
      );

      final body = SignedRequest(convertStringToUint8List(encoded));

      final sig = await compute(
          generateSignature, (jsonEncode(body.toJson()), _credentials));

      await _indexerIPFS.delete(
        url: url,
        headers: {
          'Authorization': 'Bearer $_indexerKey',
          'X-Signature': sig,
          'X-Address': _account.hexEip55,
        },
        body: body.toJson(),
      );

      return true;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return false;
  }

  /// get profile data
  Future<ProfileV1?> getProfile(String addr) async {
    try {
      final url = await _contractProfile.getURL(addr);

      final profileData = await _ipfs.get(url: '/$url');

      final profile = ProfileV1.fromJson(profileData);

      profile.parseIPFSImageURLs(ipfsUrl);

      return profile;
    } catch (exception) {
      //
    }

    return null;
  }

  /// get profile data
  Future<ProfileV1?> getProfileFromUrl(String url) async {
    try {
      final profileData = await _ipfs.get(url: '/$url');

      final profile = ProfileV1.fromJson(profileData);

      profile.parseIPFSImageURLs(ipfsUrl);

      return profile;
    } catch (exception) {
      //
    }

    return null;
  }

  /// get profile data by username
  Future<ProfileV1?> getProfileByUsername(String username) async {
    try {
      final url = await _contractProfile.getURLFromUsername(username);

      final profileData = await _ipfs.get(url: '/$url');

      final profile = ProfileV1.fromJson(profileData);

      profile.parseIPFSImageURLs(ipfsUrl);

      return profile;
    } catch (exception) {
      //
    }

    return null;
  }

  /// profileExists checks whether there is a profile for this username
  Future<bool> profileExists(String username) async {
    try {
      final url = await _contractProfile.getURLFromUsername(username);

      return url != '';
    } catch (exception) {
      //
    }

    return false;
  }

  /// Accounts

  /// check if an account exists
  Future<bool> accountExists({
    String? account,
  }) async {
    try {
      final url = '/accounts/${account ?? _account.hexEip55}/exists';

      await _indexer.get(
        url: url,
        headers: {
          'Authorization': 'Bearer $_indexerKey',
        },
      );

      return true;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return false;
  }

  /// create an account
  Future<bool> createAccount({
    EthPrivateKey? customCredentials,
  }) async {
    try {
      final cred = customCredentials ?? _credentials;

      final accountFactory = getAccounFactoryContract();

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

      await _indexer.post(
        url: url,
        headers: {
          'Authorization': 'Bearer $_indexerKey',
          'X-Signature': sig,
          'X-Address': cred.address
              .hexEip55, // owner verification since 1271 is impossible at this point
        },
        body: body.toJson(),
      );

      return true;
    } on ConflictException {
      return true;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return false;
  }

  /// upgrade an account
  Future<String?> upgradeAccount() async {
    try {
      final accountFactory = _contractAccountFactory;

      final url =
          '/accounts/factory/${accountFactory.addr}/sca/${_account.hexEip55}';

      final encoded = jsonEncode(
        {
          'owner': _credentials.address.hexEip55,
          'salt': BigInt.zero.toInt(),
        },
      );

      final body = SignedRequest(convertStringToUint8List(encoded));

      final sig = await compute(
          generateSignature, (jsonEncode(body.toJson()), _credentials));

      final response = await _indexer.patch(
        url: url,
        headers: {
          'Authorization': 'Bearer $_indexerKey',
          'X-Signature': sig,
          'X-Address': _account.hexEip55,
        },
        body: body.toJson(),
      );

      final implementation = response['object']['account_implementation'];
      if (implementation == "0x0000000000000000000000000000000000000000") {
        throw Exception('invalid implementation');
      }

      return implementation;
    } on ConflictException {
      // account is already up to date
      return null;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  /// Transactions

  /// fetch erc20 transfer events
  ///
  /// [offset] number of transfers to skip
  ///
  /// [limit] number of transferst to fetch
  ///
  /// [maxDate] fetch transfers up to this date
  Future<(List<TransferEvent>, Pagination)> fetchErc20Transfers({
    required int offset,
    required int limit,
    required DateTime maxDate,
  }) async {
    try {
      final List<TransferEvent> tx = [];

      final path = _useLegacyBundlers ? 'logs/transfers' : 'logs/v2/transfers';

      final url =
          '/$path/${_contractToken.addr}/${_account.hexEip55}?offset=$offset&limit=$limit&maxDate=${Uri.encodeComponent(maxDate.toUtc().toIso8601String())}';

      final response = await _indexer.get(url: url, headers: {
        'Authorization': 'Bearer $_indexerKey',
      });

      // convert response array into TransferEvent list
      for (final item in response['array']) {
        tx.add(TransferEvent.fromJson(item));
      }

      return (tx, Pagination.fromJson(response['meta']));
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return (<TransferEvent>[], Pagination.empty());
  }

  /// fetch new erc20 transfer events
  ///
  /// [fromDate] fetches transfers from this date
  Future<List<TransferEvent>?> fetchNewErc20Transfers(DateTime fromDate) async {
    try {
      final List<TransferEvent> tx = [];

      final path = _useLegacyBundlers ? 'logs/transfers' : 'logs/v2/transfers';

      final url =
          '/$path/${_contractToken.addr}/${_account.hexEip55}/new?limit=10&fromDate=${Uri.encodeComponent(fromDate.toUtc().toIso8601String())}';

      final response = await _indexer.get(url: url, headers: {
        'Authorization': 'Bearer $_indexerKey',
      });

      // convert response array into TransferEvent list
      for (final item in response['array']) {
        tx.add(TransferEvent.fromJson(item));
      }

      return tx;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  /// construct erc20 transfer call data
  Uint8List erc20TransferCallData(
    String to,
    BigInt amount,
  ) {
    return _contractToken.transferCallData(
      to,
      amount,
    );
  }

  /// Account Abstraction

  // get account address
  Future<EthereumAddress> getAccountAddress(
    String addr, {
    bool legacy = false,
    bool cache = true,
  }) async {
    final prefKey = addr;
    final cachedAccAddress = _pref.getAccountAddress(prefKey);

    EthereumAddress address;
    if (!cache || cachedAccAddress == null) {
      final accountFactory = getAccounFactoryContract(legacy: legacy);

      address = await accountFactory.getAddress(addr);
    } else {
      address = EthereumAddress.fromHex(cachedAccAddress);
    }
    await _pref.setAccountAddress(
      prefKey,
      address.hexEip55,
    );
    return address;
  }

  setAccountAddress(EthereumAddress address) async {
    final prefKey = _credentials.address.hexEip55;
    await _pref.setAccountAddress(
      prefKey,
      address.hexEip55,
    );
  }

  /// Submits a user operation to the Ethereum network.
  ///
  /// This function sends a JSON-RPC request to the ERC4337 bundler. The entrypoint is specified by the
  /// [eaddr] parameter, with the [eth_sendUserOperation] method and the given
  /// [userop] parameter. If the request is successful, the function returns a
  /// tuple containing the transaction hash as a string and `null`. If the request
  /// fails, the function returns a tuple containing `null` and an exception
  /// object representing the type of error that occurred.
  ///
  /// If the request fails due to a network congestion error, the function returns
  /// a [NetworkCongestedException] object. If the request fails due to an invalid
  /// balance error, the function returns a [NetworkInvalidBalanceException]
  /// object. If the request fails for any other reason, the function returns a
  /// [NetworkUnknownException] object.
  ///
  /// [userop] The user operation to submit to the Ethereum network.
  /// [eaddr] The Ethereum address of the node to send the request to.
  /// A tuple containing the transaction hash as a string and [null] if
  ///         the request was successful, or [null] and an exception object if the
  ///         request failed.
  Future<(String?, Exception?)> _submitUserOp(
    UserOp userop,
    String eaddr, {
    bool legacy = false,
    TransferData? data,
  }) async {
    final params = [userop.toJson(), eaddr];
    if (!legacy && data != null) {
      params.add(data.toJson());
    }

    final body = SUJSONRPCRequest(
      method: 'eth_sendUserOperation',
      params: params,
    );

    try {
      final response = await _requestBundler(body, legacy: legacy);

      return (response.result as String, null);
    } catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );

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

  /// makes a jsonrpc request from this wallet
  Future<SUJSONRPCResponse> _requestPaymaster(
    SUJSONRPCRequest body, {
    bool legacy = false,
  }) async {
    final paymasterRPC = getPaymasterRPC(legacy: legacy);

    final rawResponse = await paymasterRPC.post(
      body: body,
      headers: erc4337Headers,
    );

    final response = SUJSONRPCResponse.fromJson(rawResponse);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response;
  }

  /// makes a jsonrpc request from this wallet
  Future<SUJSONRPCResponse> _requestBundler(
    SUJSONRPCRequest body, {
    bool legacy = false,
  }) async {
    final rawResponse = await getBundlerRPC(legacy: legacy).post(
      body: body,
      headers: erc4337Headers,
    );

    final response = SUJSONRPCResponse.fromJson(rawResponse);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response;
  }

  /// return paymaster data for constructing a user op
  Future<(PaymasterData?, Exception?)> _getPaymasterData(
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
      final response = await _requestPaymaster(body, legacy: legacy);

      return (PaymasterData.fromJson(response.result), null);
    } catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );

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

  /// prepare a userop for with calldata
  Future<(String, UserOp)> prepareUserop(
    List<String> dest,
    List<Uint8List> calldata, {
    EthPrivateKey? customCredentials,
    BigInt? customNonce,
    bool legacy = false,
    bool deploy = true,
  }) async {
    try {
      final cred = customCredentials ?? _credentials;
      bool isLegacy = legacy;

      EthereumAddress acc = _account;
      if (customCredentials != null) {
        acc = await getAccountAddress(
          customCredentials.address.hexEip55,
        );

        final exists = await accountExists(account: acc.hexEip55);

        if (exists) {
          // check if this account does not support a token entrypoint
          isLegacy =
              await SimpleAccount(chainId, _ethClient, acc.hexEip55).isLegacy();
        }
      }
      final StackupEntryPoint entryPoint =
          getEntryPointContract(legacy: isLegacy);

      // instantiate user op with default values
      final userop = UserOp.defaultUserOp();

      // use the account hex as the sender
      userop.sender = acc.hexEip55;

      // determine the appropriate nonce
      BigInt nonce = customNonce ?? await entryPoint.getNonce(acc.hexEip55);
      userop.nonce = nonce;

      // if it's the first user op from this account, we need to deploy the account contract
      if (nonce == BigInt.zero && deploy) {
        bool exists = false;
        if (getPaymasterType(legacy: isLegacy) == 'payg') {
          // solves edge case with legacy account migration
          exists = await accountExists(account: acc.hexEip55);
        }

        if (!exists) {
          final accountFactory = getAccounFactoryContract(legacy: isLegacy);

          // construct the init code to deploy the account
          userop.initCode = await accountFactory.createAccountInitCode(
            cred.address.hexEip55,
            BigInt.zero,
          );
        }
      }

      // set the appropriate call data for the transfer
      // we need to call account.execute which will call token.transfer
      userop.callData = dest.length > 1 && calldata.length > 1
          ? _contractAccount.executeBatchCallData(
              dest,
              calldata,
            )
          : _contractAccount.executeCallData(
              dest[0],
              BigInt.zero,
              calldata[0],
            );

      // set the appropriate gas fees based on network
      final fees = await _gasPriceEstimator.estimate;
      if (fees == null) {
        throw Exception('unable to estimate fees');
      }

      userop.maxPriorityFeePerGas =
          fees.maxPriorityFeePerGas * BigInt.from(calldata.length);
      userop.maxFeePerGas = fees.maxFeePerGas * BigInt.from(calldata.length);

      // submit the user op to the paymaster in order to receive information to complete the user op
      final (paymasterData, paymasterErr) = await _getPaymasterData(
        userop,
        entryPoint.addr,
        getPaymasterType(legacy: isLegacy),
        legacy: isLegacy,
      );

      if (paymasterErr != null) {
        throw paymasterErr;
      }

      if (paymasterData == null) {
        throw Exception('unable to get paymaster data');
      }

      // add the received data to the user op
      userop.paymasterAndData = paymasterData.paymasterAndData;
      userop.preVerificationGas = paymasterData.preVerificationGas;
      userop.verificationGasLimit = paymasterData.verificationGasLimit;
      userop.callGasLimit = paymasterData.callGasLimit;

      // get the hash of the user op
      final hash = await entryPoint.getUserOpHash(userop);

      // now we can sign the user op
      userop.generateSignature(cred, hash);

      return (bytesToHex(hash, include0x: true), userop);
    } catch (_) {
      rethrow;
    }
  }

  /// submit a user op
  Future<bool> submitUserop(
    UserOp userop, {
    EthPrivateKey? customCredentials,
    bool legacy = false,
    TransferData? data,
  }) async {
    try {
      bool isLegacy = legacy;

      EthereumAddress acc = _account;
      if (customCredentials != null) {
        acc = await getAccountAddress(
          customCredentials.address.hexEip55,
        );

        final exists = await accountExists(account: acc.hexEip55);

        if (exists) {
          // check if this account does not support a token entrypoint
          isLegacy =
              await SimpleAccount(chainId, _ethClient, acc.hexEip55).isLegacy();
        }
      }
      final entryPoint = getEntryPointContract(legacy: isLegacy);

      // send the user op
      final (result, useropErr) = await _submitUserOp(
        userop,
        entryPoint.addr,
        legacy: isLegacy,
        data: data,
      );
      if (useropErr != null) {
        throw useropErr;
      }

      return result != null;
    } catch (e) {
      rethrow;
    }
  }

  /// updates the push token for the current account
  ///
  /// [token] the push token
  /// [customCredentials] optional credentials to use
  Future<bool> updatePushToken(
    String token, {
    EthPrivateKey? customCredentials,
  }) async {
    try {
      final cred = customCredentials ?? _credentials;

      EthereumAddress acc = _account;
      if (customCredentials != null) {
        acc = await getAccountAddress(
          customCredentials.address.hexEip55,
        );
      }

      final url = '/push/${_contractToken.addr}/${acc.hexEip55}';

      final encoded = jsonEncode(
        PushUpdateRequest(token, acc.hexEip55).toJson(),
      );

      final body = SignedRequest(convertStringToUint8List(encoded));

      final sig =
          await compute(generateSignature, (jsonEncode(body.toJson()), cred));

      await _indexer.put(
        url: url,
        headers: {
          'Authorization': 'Bearer $_indexerKey',
          'X-Signature': sig,
          'X-Address': acc.hexEip55,
        },
        body: body.toJson(),
      );

      return true;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return false;
  }

  /// removes the push token for the current account
  ///
  /// [token] the push token
  /// [customCredentials] optional credentials to use
  Future<bool> removePushToken(
    String token, {
    EthPrivateKey? customCredentials,
  }) async {
    try {
      final cred = customCredentials ?? _credentials;

      EthereumAddress acc = _account;
      if (customCredentials != null) {
        acc = await getAccountAddress(
          customCredentials.address.hexEip55,
        );
      }

      final url = '/push/${_contractToken.addr}/${acc.hexEip55}/$token';

      final encoded = jsonEncode(
        {
          'account': acc.hexEip55,
          'date': DateTime.now().toUtc().toIso8601String(),
        },
      );

      final body = SignedRequest(convertStringToUint8List(encoded));

      final sig =
          await compute(generateSignature, (jsonEncode(body.toJson()), cred));

      await _indexer.delete(
        url: url,
        headers: {
          'Authorization': 'Bearer $_indexerKey',
          'X-Signature': sig,
          'X-Address': acc.hexEip55,
        },
        body: body.toJson(),
      );

      return true;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return false;
  }

  /// dispose of resources
  void dispose() {
    _ethClient.dispose();
  }
}
