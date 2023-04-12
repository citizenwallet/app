import 'dart:math';

import 'package:citizenwallet/services/api/api.dart';
import 'package:citizenwallet/services/web3/models.dart';
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class Web3Service {
  late String _clientVersion;
  late BigInt _chainId;
  late EthPrivateKey _credentials;
  late EthereumAddress _address;

  final Client _client = Client();
  final String _url;

  late Web3Client _ethClient;
  late APIService _api;

  /// creates a new random private key
  Web3Service(this._url) {
    _ethClient = Web3Client(_url, _client);
    _api = APIService(baseURL: _url);

    final Random key = Random.secure();

    _credentials = EthPrivateKey.createRandom(key);
    _address = _credentials.address;

    init();
  }

  /// creates using an existing private key from a hex string
  Web3Service.fromKey(this._url, String privateKey) {
    _ethClient = Web3Client(_url, _client);
    _api = APIService(baseURL: _url);

    _credentials = EthPrivateKey.fromHex(privateKey);
    _address = _credentials.address;

    init();
  }

  /// creates using a wallet file
  Web3Service.fromWalletFile(this._url, String walletFile, String password) {
    _ethClient = Web3Client(_url, _client);
    _api = APIService(baseURL: _url);

    Wallet wallet = Wallet.fromJson(walletFile, password);

    _credentials = wallet.privateKey;
    _address = _credentials.address;

    init();
  }

  void init() async {
    _clientVersion = await _ethClient.getClientVersion();
    _chainId = await _ethClient.getChainId();
  }

  /// retrieve the private key as a wallet v3
  String toWalletFile(String password) {
    final Random key = Random.secure();
    Wallet wallet = Wallet.createNew(_credentials, password, key);

    return wallet.toJson();
  }

  /// retrieve the private key as a hex string
  String get privateKeyHex =>
      bytesToHex(_credentials.privateKey, include0x: true);

  /// retrieve the current block number
  Future<int> get blockNumber async => await _ethClient.getBlockNumber();

  /// retrieve the address
  EthereumAddress get address => _address;

  /// retrieves the current balance of the address
  Future<EtherAmount> get balance async => await _ethClient.getBalance(address);

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

  /// return a block for a given number
  Future<Web3Block?> _getBlockByNumber(int blockNumber) async {
    final body = {
      'jsonrpc': '2.0',
      'method': 'eth_getBlockByNumber',
      'params': ['0x${blockNumber.toRadixString(16)}', true],
      'id': _chainId.toInt(),
    };

    try {
      final response = await _api.post(body: body);

      return Web3Block.fromJson(response['result']);
    } catch (e) {
      print(e);
    }

    return null;
  }

  Future<void> testFunc() async {
    final body = {
      'jsonrpc': '2.0',
      'method': 'eth_getBlockByNumber',
      'params': ['latest', true],
      'id': _chainId.toInt(),
    };

    final hs = 100.toRadixString(16);

    try {
      final resp = await _api.post(body: body);
      print(resp);
      final block = Web3Block.fromJson(resp['result']);
      print(block.number);
      for (final transaction in block.transactions) {
        print('transaction: ');
        print(transaction.value);
        print('from: ${transaction.from}');
        print('to: ${transaction.to}');
      }
    } catch (e) {
      print(e);
    }
  }

  /// sends a transaction
  Future<String> sendTransaction({
    required String to,
    required int amount,
  }) async {
    final Transaction transaction = Transaction(
      to: EthereumAddress.fromHex(to),
      from: address,
      value: EtherAmount.fromInt(EtherUnit.wei, amount),
    );

    return await _ethClient.sendTransaction(_credentials, transaction,
        chainId: _chainId.toInt());
  }

  /// retrieves list of transactions for a given address
  Future<List<Web3Transaction>> get transactions async {
    final List<Web3Transaction> transactions = [];

    final int blockNumber = await _ethClient.getBlockNumber();
    // final int transactionCount = await _ethClient.getTransactionCount(address);
    final int startBlock = max(0, blockNumber - 100);

    for (int i = startBlock; i < blockNumber; i++) {
      final Web3Block? block = await _getBlockByNumber(i);
      if (block == null) {
        continue;
      }

      for (final transaction in block.transactions) {
        if (transaction.from == address || transaction.to == address) {
          transactions.add(transaction);
        }
      }
    }

    return transactions;
  }

  /// dispose of resources
  void dispose() {
    _client.close();
    _ethClient.dispose();
  }
}
