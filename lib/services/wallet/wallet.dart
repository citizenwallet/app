import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:citizenwallet/services/api/api.dart';
import 'package:citizenwallet/services/indexer/pagination.dart';
import 'package:citizenwallet/services/station/station.dart';
import 'package:citizenwallet/services/wallet/contracts/entrypoint.dart';
import 'package:citizenwallet/services/wallet/contracts/erc20.dart';
import 'package:citizenwallet/services/wallet/contracts/simple_account.dart';
import 'package:citizenwallet/services/wallet/contracts/simple_account_factory.dart';
import 'package:citizenwallet/services/wallet/models/block.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/services/wallet/models/json_rpc.dart';
import 'package:citizenwallet/services/wallet/models/message.dart';
import 'package:citizenwallet/services/wallet/models/paymaster_data.dart';
import 'package:citizenwallet/services/wallet/models/signer.dart';
import 'package:citizenwallet/services/wallet/models/transaction.dart';
import 'package:citizenwallet/services/wallet/models/userop.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:smartcontracts/contracts/standards/ERC20.g.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  late EthereumAddress _account;
  Uint8List? _publicKey;

  late StackupEntryPoint _contractEntryPoint;
  late AccountFactory _contractAccountFactory;
  late ERC20Contract _contractToken;
  late SimpleAccount _contractAccount;

  final Client _client = Client();

  final _url = dotenv.get('NODE_URL');

  late Web3Client _ethClient;
  // StationService? _station;
  late APIService _api;
  final APIService _indexer = APIService(baseURL: dotenv.get('INDEXER_URL'));
  final APIService _bundlerRPC =
      APIService(baseURL: dotenv.get('ERC4337_RPC_URL'));
  final APIService _paymasterRPC =
      APIService(baseURL: dotenv.get('ERC4337_PAYMASTER_RPC_URL'));
  final String _paymasterType = dotenv.get('ERC4337_PAYMASTER_TYPE');
  final APIService _dataRPC =
      APIService(baseURL: dotenv.get('ERC4337_DATA_URL'));

  /// creates a new random private key
  /// init before using
  WalletService(this._chain) {
    _ethClient = Web3Client(
      _url,
      _client,
    );
    _api = APIService(baseURL: _url);

    // final Random key = Random.secure();

    // _credentials = EthPrivateKey.createRandom(key);
    // _address = _credentials!.address;
  }

  /// creates using an existing private key from a hex string
  /// init before using
  WalletService.fromKey(this._chain, String privateKey) {
    _ethClient = Web3Client(_url, _client);
    _api = APIService(baseURL: _url);

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
    _ethClient = Web3Client(_url, _client);
    _api = APIService(baseURL: _url);

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
    _ethClient = Web3Client(_url, _client);
    _api = APIService(baseURL: _url);

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
    _ethClient = Web3Client(_url, _client);
    _api = APIService(baseURL: _url);

    // _credentials = signer.privateKey;
    _address = signer.privateKey.address;
  }

  Future<void> init(String eaddr, String afaddr, String taddr) async {
    // _clientVersion = await _ethClient.getClientVersion();
    _chainId = await _ethClient.getChainId();

    await initContracts(eaddr, afaddr, taddr);
  }

  Future<void> initUnlocked(String eaddr, String afaddr, String taddr) async {
    // _clientVersion = await _ethClient.getClientVersion();
    _chainId = await _ethClient.getChainId();

    await initContracts(eaddr, afaddr, taddr);
  }

  Future<void> initContracts(String eaddr, String afaddr, String taddr) async {
    _contractEntryPoint = newEntryPoint(chainId, _ethClient, eaddr);
    await _contractEntryPoint.init();

    _contractAccountFactory = newAccountFactory(chainId, _ethClient, afaddr);
    await _contractAccountFactory.init();

    final credentials = unlock();
    if (credentials == null) {
      throw lockedWalletException;
    }

    _account =
        await _contractAccountFactory.getAddress(credentials.address.hex);

    _contractToken = newERC20Contract(chainId, _ethClient, taddr);
    await _contractToken.init();

    _contractAccount = newSimpleAccount(chainId, _ethClient, _account.hex);
    await _contractAccount.init();
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

  Future<void> switchChain(
    Chain chain,
    String eaddr,
    String afaddr,
    String taddr,
  ) {
    dispose();

    _chain = chain;

    _ethClient = Web3Client(_url, _client);
    _api = APIService(baseURL: _url);

    return _credentials != null
        ? initUnlocked(eaddr, afaddr, taddr)
        : init(eaddr, afaddr, taddr);
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

  String get url => _url;

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

  /// retrieve the account related to this address
  EthereumAddress get account => _account;

  /// retrieves the current balance of the address
  Future<String> get balance async =>
      fromUnit(await _contractToken.getBalance(_account.hex));

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

  /// ERC 4337

  /// makes a jsonrpc request from this wallet
  Future<SUJSONRPCResponse> _requestPaymaster(SUJSONRPCRequest body) async {
    final rawRespoonse = await _paymasterRPC.post(body: body);

    final response = SUJSONRPCResponse.fromJson(rawRespoonse);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response;
  }

  /// makes a jsonrpc request from this wallet
  Future<SUJSONRPCResponse> _requestBundler(SUJSONRPCRequest body) async {
    final rawRespoonse = await _bundlerRPC.post(body: body);

    final response = SUJSONRPCResponse.fromJson(rawRespoonse);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response;
  }

  /// return paymaster data for constructing a user op
  Future<PaymasterData?> _getPaymasterData(
    UserOp userop,
    String eaddr,
    String ptype,
  ) async {
    final body = SUJSONRPCRequest(
      method: 'pm_sponsorUserOperation',
      params: [
        userop.toJson(),
        eaddr,
        {'type': ptype},
      ],
    );

    try {
      final response = await _requestPaymaster(body);

      return PaymasterData.fromJson(response.result);
    } catch (e) {
      // error fetching block
      print(e);
    }

    return null;
  }

  /// ERC 20 token methods

  /// listen to erc20 transfer events
  Stream<Transfer> get erc20TransferStream =>
      _contractToken.listen(const BlockNum.current());

  /// fetch erc20 transfer events
  ///
  /// [limit] number of seconds to go back, uses block time to calculate
  ///
  /// [toBlock] block number to fetch up to, leave blank to use current block
  Future<(List<TransferEvent>, Pagination)> fetchErc20Transfers(
      {int? offset, int? limit, DateTime? maxDate}) async {
    try {
      final List<TransferEvent> tx = [];

      var url = '/logs/transfers/${_contractToken.addr}/${_account.hex}?';
      if (offset != null) {
        url += '&offset=$offset';
      }
      if (limit != null) {
        url += '&limit=$limit';
      }
      if (maxDate != null) {
        url +=
            '&maxDate=${Uri.encodeComponent(maxDate.toUtc().toIso8601String())}';
      }

      final response = await _indexer.get(url: url, headers: {
        'Authorization': 'Bearer ${dotenv.get('INDEXER_KEY')}',
      });

      // convert response array into TransferEvent list
      for (final item in response['array']) {
        tx.add(TransferEvent.fromJson(item));
      }

      return (tx, Pagination.fromJson(response['meta']));
    } catch (e) {
      print(e);
    }

    return (<TransferEvent>[], Pagination.empty());
  }

  /// submit a user op
  Future<String?> _submitUserOp(
    UserOp userop,
    String eaddr,
  ) async {
    final body = SUJSONRPCRequest(
      method: 'eth_sendUserOperation',
      params: [userop.toJson(), eaddr],
    );

    try {
      final response = await _requestBundler(body);

      return response.result;
    } catch (e) {
      // error fetching block
      print(e);
    }

    return null;
  }

  /// retrieve a user op by hash and return its hash
  Future<String?> _fetchUserOp(
    String hash,
  ) async {
    try {
      final response = await _dataRPC.get(
        url: '/$hash',
        headers: {
          'SU-ACCESS-KEY': dotenv.get('ERC4337_SU_ACCESS_KEY'),
        },
      );

      return response.data.transactionHash;
    } catch (e) {
      // error fetching block
      print(e);
    }

    return null;
  }

  /// transfer erc20 tokens to an address
  Future<String?> transferErc20(String to, BigInt amount) async {
    try {
      // safely retrieve credentials if unlocks
      final credentials = unlock();
      if (credentials == null) {
        throw lockedWalletException;
      }

      // instantiate user op with default values
      final userop = UserOp.defaultUserOp();

      // use the account hex as the sender
      userop.sender = _account.hex;

      // determine the appropriate nonce
      final nonce = await _contractEntryPoint.getNonce(_account.hex);
      userop.nonce = nonce;

      // if it's the first user op from this account, we need to deploy the account contract
      if (nonce == BigInt.zero) {
        // construct the init code to deploy the account
        userop.initCode = _contractAccountFactory.createAccountInitCode(
          credentials.address.hex,
          BigInt.zero,
        );
      }

      // set the appropriate call data for the transfer
      // we need to call account.execute which will call token.transfer
      userop.callData = _contractAccount.executeCallData(
        _contractToken.addr,
        BigInt.zero,
        _contractToken.transferCallData(
          to,
          EtherAmount.fromBigInt(EtherUnit.kwei, amount).getInWei,
        ),
      );

      // set the appropriate gas fees based on network
      final fees = await _ethClient.getGasInEIP1559();
      if (fees.isEmpty) {
        throw Exception('unable to estimate fees');
      }

      final fee = fees.first;

      userop.maxPriorityFeePerGas = fee.maxPriorityFeePerGas;
      userop.maxFeePerGas = fee.maxFeePerGas;

      // submit the user op to the paymaster in order to receive information to complete the user op
      final paymasterData = await _getPaymasterData(
        userop,
        _contractEntryPoint.addr,
        _paymasterType,
      );

      if (paymasterData == null) {
        throw Exception('paymaster data is null');
      }

      // add the received data to the user op
      userop.paymasterAndData = paymasterData.paymasterAndData;
      userop.preVerificationGas = paymasterData.preVerificationGas;
      userop.verificationGasLimit = paymasterData.verificationGasLimit;
      userop.callGasLimit = paymasterData.callGasLimit;

      // now we can sign the user op
      userop.generateSignature(credentials, _contractEntryPoint.addr, chainId);

      // send the user op
      await _submitUserOp(userop, _contractEntryPoint.addr);

      return null;
    } catch (e) {
      print(e);
    }

    return null;
  }

  /// ********************

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
  // Future<Chain?> configStation(String url, EthPrivateKey privatekey) async {
  //   try {
  //     _station = StationService(
  //       baseURL: url,
  //       address: _address.hex,
  //       requesterKey: privatekey,
  //     );

  //     final response = await _station!.hello();

  //     // await sendGasStationTransaction(
  //     //   to: '0xe13b2276bb63fde321719bbf6dca9a70fc40efcc',
  //     //   amount: '10',
  //     //   message: 'hello gas station',
  //     // );

  //     return response;
  //   } catch (e) {
  //     // error fetching block
  //     print(e);
  //   }

  //   return null;
  // }

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

    final parsedAmount = toUnit(amount);

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
      'data': await _signTransaction(
        to: to,
        amount: amount,
        message: message,
        walletFile: walletFile,
        password: password,
      ),
    };

    // final response = await _station!.transaction(
    //   jsonEncode(data),
    // );

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

    final parsedAmount = toUnit(amount);

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
