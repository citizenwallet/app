import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:citizenwallet/services/api/api.dart';
import 'package:citizenwallet/services/wallet/models/block.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/services/wallet/models/json_rpc.dart';
import 'package:citizenwallet/services/wallet/models/message.dart';
import 'package:citizenwallet/services/wallet/models/signer.dart';
import 'package:citizenwallet/services/wallet/models/transaction.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

Future<WalletService?> walletServiceFromChain(
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
  String? _clientVersion;
  BigInt? _chainId;
  Chain? _chain;
  late EthPrivateKey _credentials;
  late EthereumAddress _address;

  final Client _client = Client();

  late Web3Client _ethClient;
  late APIService _api;

  /// creates a new random private key
  /// init before using
  WalletService(this._chain) {
    final url = _chain!.rpc.first;

    _ethClient = Web3Client(url, _client);
    _api = APIService(baseURL: url);

    final Random key = Random.secure();

    _credentials = EthPrivateKey.createRandom(key);
    _address = _credentials.address;
  }

  /// creates using an existing private key from a hex string
  /// init before using
  WalletService.fromKey(this._chain, String privateKey) {
    final url = _chain!.rpc.first;

    _ethClient = Web3Client(url, _client);
    _api = APIService(baseURL: url);

    _credentials = EthPrivateKey.fromHex(privateKey);
    _address = _credentials.address;
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

    _credentials = wallet.privateKey;
    _address = _credentials.address;
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

    _credentials = signer.privateKey;
    _address = _credentials.address;
  }

  Future<void> init() async {
    _clientVersion = await _ethClient.getClientVersion();
    _chainId = await _ethClient.getChainId();
  }

  Future<Chain?> _fetchChainById(BigInt id) async {
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
  String toWalletFile(String password) {
    final Random random = Random.secure();
    Wallet wallet = Wallet.createNew(_credentials, password, random);

    return wallet.toJson();
  }

  EthPrivateKey get privateKey => _credentials;

  /// retrieve the private key as a hex string
  String get privateKeyHex =>
      bytesToHex(_credentials.privateKey, include0x: true);

  Uint8List get publicKey => _credentials.encodedPublicKey;
  String get publicKeyHex =>
      bytesToHex(_credentials.encodedPublicKey, include0x: true);

  /// retrieve chain id
  int get chainId => _chainId!.toInt();

  /// retrieve chain symbol
  NativeCurrency get nativeCurrency => _chain!.nativeCurrency;

  /// retrieve the current block number
  Future<int> get blockNumber async => await _ethClient.getBlockNumber();

  /// retrieve the address
  EthereumAddress get address => _address;

  /// retrieves the current balance of the address
  Future<double> get balance async =>
      (await _ethClient.getBalance(address)).getInEther.toDouble();

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

  /// sends a transaction from the wallet to another
  Future<String> sendTransaction({
    required String to,
    required int amount,
    String message = '',
  }) async {
    final Transaction transaction = Transaction(
      to: EthereumAddress.fromHex(to),
      from: address,
      value: EtherAmount.fromInt(EtherUnit.ether, amount),
      data: Message(message: message).toBytes(),
    );

    return await _ethClient.sendTransaction(
      _credentials,
      transaction,
      chainId: _chainId!.toInt(),
    );
  }

  /// retrieves list of latest transactions for this wallet within a limit and offset
  Future<List<WalletTransaction>> transactions(
      {int offset = 0, int limit = 20}) async {
    final List<WalletTransaction> transactions = [];

    // get the end block number
    final int endBlock = max(
      firstBlockNumber,
      (await _ethClient.getBlockNumber()) - offset,
    );

    // get the start block number
    final int startBlock = max(firstBlockNumber, endBlock - limit);

    // iterate through blocks
    for (int i = startBlock; i < endBlock; i++) {
      final WalletBlock? block = await _getBlockByNumber(blockNumber: i);
      if (block == null) {
        continue;
      }

      for (final transaction in block.transactions) {
        // find transactions that are sent or received by this wallet
        if (transaction.from == address || transaction.to == address) {
          transaction.setTimestamp(block.timestamp);
          transaction.setDirection(address);
          transactions.insert(0, transaction);
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
