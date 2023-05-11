import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:citizenwallet/services/api/api.dart';
import 'package:citizenwallet/services/station/station.dart';
import 'package:citizenwallet/services/wallet/models/block.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/services/wallet/models/json_rpc.dart';
import 'package:citizenwallet/services/wallet/models/message.dart';
import 'package:citizenwallet/services/wallet/models/signer.dart';
import 'package:citizenwallet/services/wallet/models/transaction.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

final Exception lockedWalletException = Exception('Wallet is locked');

const int defaultPageSize = 10;

Future<WalletService?> walletServiceFromChain(
  BigInt chainId,
  String address,
) async {
  final List rawNativeChains =
      jsonDecode(await rootBundle.loadString('assets/data/native_chains.json'));

  final List<Chain> nativeChains =
      rawNativeChains.map((c) => Chain.fromJson(c)).toList();

  final i = nativeChains.indexWhere((c) => c.chainId == chainId.toInt());
  if (i >= 0) {
    return WalletService.fromAddress(
      nativeChains[i],
      address,
    );
  }

  final List rawChains =
      jsonDecode(await rootBundle.loadString('assets/data/chains.json'));

  final List<Chain> chains = rawChains.map((c) => Chain.fromJson(c)).toList();

  final ii = chains.indexWhere((c) => c.chainId == chainId.toInt());
  if (ii < 0) {
    return null;
  }

  return WalletService.fromAddress(
    chains[ii],
    address,
  );
}

Future<WalletService?> walletServiceFromWallet(
  BigInt chainId,
  String walletFile,
  String password,
) async {
  final List rawNativeChains =
      jsonDecode(await rootBundle.loadString('assets/data/native_chains.json'));

  final List<Chain> nativeChains =
      rawNativeChains.map((c) => Chain.fromJson(c)).toList();

  final i = nativeChains.indexWhere((c) => c.chainId == chainId.toInt());
  if (i >= 0) {
    return WalletService.fromWalletFile(
      nativeChains[i],
      walletFile,
      password,
    );
  }

  final List rawChains =
      jsonDecode(await rootBundle.loadString('assets/data/chains.json'));

  final List<Chain> chains = rawChains.map((c) => Chain.fromJson(c)).toList();

  final ii = chains.indexWhere((c) => c.chainId == chainId.toInt());
  if (ii < 0) {
    return null;
  }

  return WalletService.fromWalletFile(
    chains[ii],
    walletFile,
    password,
  );
}

class WalletService {
  // String? _clientVersion;
  BigInt? _chainId;
  Chain? _chain;
  // Wallet? _wallet;
  EthPrivateKey? _credentials;
  late EthereumAddress _address;
  Uint8List? _publicKey;

  final Client _client = Client();

  late Web3Client _ethClient;
  StationService? _station;
  late APIService _api;

  /// creates a new random private key
  /// init before using
  WalletService(this._chain) {
    final url = _chain!.rpc.first;

    _ethClient = Web3Client(url, _client);
    _api = APIService(baseURL: url);

    // final Random key = Random.secure();

    // _credentials = EthPrivateKey.createRandom(key);
    // _address = _credentials!.address;
  }

  /// creates using an existing private key from a hex string
  /// init before using
  WalletService.fromKey(this._chain, String privateKey) {
    final url = _chain!.rpc.first;

    _ethClient = Web3Client(url, _client);
    _api = APIService(baseURL: url);

    // _credentials = EthPrivateKey.fromHex(privateKey);
    // _address = _credentials!.address;
  }

  /// creates using a wallet file
  /// init before using
  WalletService.fromWalletFile(
    this._chain,
    String walletFile,
    String password,
  ) {
    final url = _chain!.rpc.first;

    _ethClient = Web3Client(url, _client);
    _api = APIService(baseURL: url);

    Wallet wallet = Wallet.fromJson(walletFile, password);

    _address = wallet.privateKey.address;
    _credentials = wallet.privateKey;

    // _wallet = wallet;
  }

  /// creates using a wallet file
  /// init before using
  WalletService.fromAddress(
    this._chain,
    String address,
  ) {
    final url = _chain!.rpc.first;

    _ethClient = Web3Client(url, _client);
    _api = APIService(baseURL: url);

    _address = EthereumAddress.fromHex(address);

    // Wallet wallet = Wallet.fromJson(walletFile, password);

    // _wallet = wallet;
    // _credentials = wallet.privateKey;
  }

  /// creates using a signer
  /// init before using
  WalletService.fromSigner(
    this._chain,
    Signer signer,
  ) {
    final url = _chain!.rpc.first;

    _ethClient = Web3Client(url, _client);
    _api = APIService(baseURL: url);

    // _credentials = signer.privateKey;
    _address = signer.privateKey.address;
  }

  Future<void> init() async {
    // _clientVersion = await _ethClient.getClientVersion();
    _chainId = await _ethClient.getChainId();
  }

  Future<void> initUnlocked() async {
    // _clientVersion = await _ethClient.getClientVersion();
    _chainId = await _ethClient.getChainId();

    final stationUrl = dotenv.get('DEFAULT_STATION_URL');
    await configStation(stationUrl, _credentials!);
  }

  EthPrivateKey? unlock({String? walletFile, String? password}) {
    try {
      if (walletFile == null && password == null && _credentials == null) {
        throw Exception('No wallet file or password provided');
      }

      if (walletFile == null && password == null && _credentials != null) {
        return _credentials;
      }

      if (walletFile == null && password == null) {
        throw Exception('No wallet file or password provided');
      }

      Wallet wallet = Wallet.fromJson(walletFile!, password!);

      return wallet.privateKey;
    } catch (e) {
      print(e);
    }

    return null;
  }

  Future<void> switchChain(Chain chain) {
    dispose();

    _chain = chain;

    final url = _chain!.rpc.first;

    _ethClient = Web3Client(url, _client);
    _api = APIService(baseURL: url);

    return _credentials != null ? initUnlocked() : init();
  }

  Future<Chain?> fetchChainById(BigInt id) async {
    final List rawNativeChains = jsonDecode(
        await rootBundle.loadString('assets/data/native_chains.json'));

    final List<Chain> nativeChains =
        rawNativeChains.map((c) => Chain.fromJson(c)).toList();

    final i = nativeChains.indexWhere((c) => c.chainId == id.toInt());
    if (i >= 0) {
      return nativeChains[i];
    }

    final List rawChains =
        jsonDecode(await rootBundle.loadString('assets/data/chains.json'));

    final List<Chain> chains = rawChains.map((c) => Chain.fromJson(c)).toList();

    final ii = chains.indexWhere((c) => c.chainId == id.toInt());
    if (ii < 0) {
      return null;
    }

    return chains[ii];
  }

  /// makes a jsonrpc request from this wallet
  Future<JSONRPCResponse> _request(JSONRPCRequest body) async {
    final rawRespoonse = await _api.post(body: body);

    final response = JSONRPCResponse.fromJson(rawRespoonse);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response;
  }

  /// retrieve the private key as a v3 wallet
  String toWalletFile(String walletFile, String password) {
    final credentials = unlock(walletFile: walletFile, password: password);
    if (credentials == null) {
      throw lockedWalletException;
    }

    final Random random = Random.secure();
    Wallet wallet = Wallet.createNew(credentials, password, random);

    return wallet.toJson();
  }

  // EthPrivateKey get privateKey {
  //   if (_credentials == null) {
  //     throw lockedWalletException;
  //   }

  //   return _credentials!;
  // }

  /// retrieve the private key as a hex string
  // String get privateKeyHex {
  //   if (_credentials == null) {
  //     throw lockedWalletException;
  //   }

  //   return bytesToHex(_credentials!.privateKey, include0x: true);
  // }

  String get url {
    if (_chain == null) {
      throw Exception('Chain not set');
    }

    return _chain!.rpc.first;
  }

  Uint8List get publicKey {
    if (_publicKey == null) {
      throw lockedWalletException;
    }

    return _publicKey!;
  }

  String get publicKeyHex {
    if (_publicKey == null) {
      throw lockedWalletException;
    }

    return bytesToHex(_publicKey!, include0x: false);
  }

  EthPrivateKey? get privateKey => _credentials;

  /// retrieve chain id
  int get chainId => _chainId!.toInt();

  /// retrieve raw wallet that was used to instantiate this service
  // Wallet? get wallet => _wallet;

  /// retrieve chain symbol
  NativeCurrency get nativeCurrency => _chain!.nativeCurrency;

  /// retrieve the current block number
  Future<int> get blockNumber async => await _ethClient.getBlockNumber();

  /// retrieve the address
  EthereumAddress get address => _address;

  /// retrieves the current balance of the address
  Future<String> get balance async => fromGwei(
      (await _ethClient.getBalance(address)).getValueInUnit(EtherUnit.gwei));

  /// retrieves the transaction count for the address
  Future<int> get transactionCount async =>
      await _ethClient.getTransactionCount(address);

  /// retrieves a block by number
  Future<BlockInformation> getBlock(int? blockNumber) async {
    if (blockNumber == null) {
      return _ethClient.getBlockInformation(blockNumber: 'latest');
    }

    return await _ethClient.getBlockInformation(blockNumber: '$blockNumber');
  }

  /// allows you to listen to new blocks
  Stream<String> get blockStream => _ethClient.addedBlocks();

  /// return a block for a given blockNumber
  Future<WalletBlock?> _getBlockByNumber({int? blockNumber}) async {
    final body = JSONRPCRequest(
      method: 'eth_getBlockByNumber',
      params: [
        blockNumber != null ? '0x${blockNumber.toRadixString(16)}' : 'latest',
        true
      ],
    );

    try {
      final response = await _request(body);

      return WalletBlock.fromJson(response.result);
    } catch (e) {
      // error fetching block
      print(e);
    }

    return null;
  }

  /// return a block for a given hash
  Future<WalletBlock?> _getBlockByHash(String hash) async {
    final body = JSONRPCRequest(
      method: 'eth_getBlockByHash',
      params: [hash, true],
    );

    try {
      final response = await _request(body);

      return WalletBlock.fromJson(response.result);
    } catch (e) {
      // error fetching block
      print(e);
    }

    return null;
  }

  /// get station config
  Future<Chain?> configStation(String url, EthPrivateKey privatekey) async {
    try {
      _station = StationService(
        baseURL: url,
        address: _address.hex,
        requesterKey: privatekey,
      );

      final response = await _station!.hello();

      await sendGasStationTransaction(
        to: '0xe13b2276bb63fde321719bbf6dca9a70fc40efcc',
        amount: '10',
        message: 'hello gas station',
      );

      return response;
    } catch (e) {
      // error fetching block
      print(e);
    }

    return null;
  }

  /// signs a transaction to prepare for sending
  Future<String> _signTransaction({
    required String to,
    required String amount,
    String message = '',
    String? walletFile,
    String? password,
  }) async {
    final credentials = unlock(walletFile: walletFile, password: password);
    if (credentials == null) {
      throw lockedWalletException;
    }

    final parsedAmount = BigInt.from(toGwei(amount));

    final Transaction transaction = Transaction(
      to: EthereumAddress.fromHex(to),
      from: credentials.address,
      value: EtherAmount.fromBigInt(EtherUnit.gwei, parsedAmount),
      data: Message(message: message).toBytes(),
    );

    final tx = await _ethClient.signTransaction(
      credentials,
      transaction,
      chainId: _chainId!.toInt(),
    );

    return bytesToHex(tx);
  }

  /// send signed transaction through gas station
  Future<String> sendGasStationTransaction({
    required String to,
    required String amount,
    String message = '',
    String? walletFile,
    String? password,
  }) async {
    final data = {
      'tx': await _signTransaction(
        to: to,
        amount: amount,
        message: message,
        walletFile: walletFile,
        password: password,
      ),
    };

    final response = await _station!.transaction(
      jsonEncode(data),
    );

    return '';
  }

  /// sends a transaction from the wallet to another
  Future<String> sendTransaction({
    required String to,
    required String amount,
    String message = '',
    String? walletFile,
    String? password,
  }) async {
    final credentials = unlock(walletFile: walletFile, password: password);
    if (credentials == null) {
      throw lockedWalletException;
    }

    final parsedAmount = BigInt.from(toGwei(amount));

    final Transaction transaction = Transaction(
      to: EthereumAddress.fromHex(to),
      from: credentials.address,
      value: EtherAmount.fromBigInt(EtherUnit.gwei, parsedAmount),
      data: Message(message: message).toBytes(),
    );

    return await _ethClient.sendTransaction(
      credentials,
      transaction,
      chainId: _chainId!.toInt(),
    );
  }

  /// retrieves list of latest transactions for this wallet within a limit and offset
  Future<List<WalletTransaction>> transactions({
    int offset = 0,
    int limit = defaultPageSize,
  }) async {
    final List<WalletTransaction> transactions = [];

    final int lastBlock = await _ethClient.getBlockNumber();

    // get the start block number
    final int startBlock =
        max(offset == 0 ? lastBlock : offset, firstBlockNumber);

    // get the end block number
    final int endBlock = max(
      startBlock - limit,
      firstBlockNumber,
    );

    // iterate through blocks
    for (int i = startBlock; i >= endBlock; i--) {
      final WalletBlock? block = await _getBlockByNumber(blockNumber: i);
      if (block == null) {
        continue;
      }

      for (final transaction in block.transactions) {
        // find transactions that are sent or received by this wallet
        if (transaction.from == address || transaction.to == address) {
          transaction.setTimestamp(block.timestamp);
          transaction.setDirection(address);
          transactions.add(transaction);
        }
      }
    }

    return transactions;
  }

  /// retrieves list of transactions for this wallet for a give block hash
  Future<List<WalletTransaction>> transactionsForBlockHash(String hash) async {
    final List<WalletTransaction> transactions = [];

    final WalletBlock? block = await _getBlockByHash(hash);
    if (block == null) {
      return transactions;
    }

    for (final transaction in block.transactions) {
      // find transactions that are sent or received by this wallet
      if (transaction.from == address || transaction.to == address) {
        transaction.setTimestamp(block.timestamp);
        transaction.setDirection(address);
        transactions.insert(0, transaction);
      }
    }

    return transactions;
  }

  /// dispose of resources
  void dispose() {
    _ethClient.dispose();
  }
}
