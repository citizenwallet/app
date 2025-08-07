import 'dart:async';
import 'dart:typed_data';
import 'package:citizenwallet/services/config/config.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart';

import 'package:smartcontracts/accounts.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

Future<AccountFactoryService> accountFactoryServiceFromConfig(Config config,
    {String? customAccountFactory}) async {
  final primaryAccountFactory = config.community.primaryAccountFactory;

  final url = config.getRpcUrl(primaryAccountFactory.chainId.toString(), customAccountFactory);
  // final wsurl =
  //     config.chains[primaryAccountFactory.chainId.toString()]!.node.wsUrl;

  final client = Client();

  final ethClient = Web3Client(
    url,
    client,
    // socketConnector: () =>
    //     WebSocketChannel.connect(Uri.parse(wsurl)).cast<String>(),
  );

  final chainId = await ethClient.getChainId();

  return AccountFactoryService(chainId.toInt(), ethClient,
      customAccountFactory ?? primaryAccountFactory.address);
}

class AccountFactoryService {
  final int chainId;
  final Web3Client client;
  final String addr;
  late AccountFactory contract;
  late DeployedContract rcontract;

  // StreamSubscription<TransferSingle>? _sub;

  AccountFactoryService(this.chainId, this.client, this.addr) {
    contract = AccountFactory(
      address: EthereumAddress.fromHex(addr),
      chainId: chainId,
      client: client,
    );
  }

  Future<void> init() async {
    final abi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/accounts/AccountFactory.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'AccountFactory');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<EthereumAddress> getAddress(String owner) {
    return contract.getAddress(EthereumAddress.fromHex(owner), BigInt.zero);
  }

  Future<bool> needsUpgrade(EthereumAddress account) async {
    // The storage slot of the implementation address (EIP-1967)
    BigInt slot = hexToInt(
        '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc');

    // Get the implementation address
    Uint8List proxyImplementation = await client.getStorage(account, slot);

    final implementationAddress = EthereumAddress(
        Uint8List.fromList(proxyImplementation.slice(12).toList()));

    final code = await client.getCode(implementationAddress);

    if (code.length <= 2) {
      return false;
    }

    final implementation = await contract.accountImplementation();

    final expectedCode = await client.getCode(implementation);

    return bytesToHex(code) != bytesToHex(expectedCode);
  }

  Future<Uint8List> createAccountInitCode(String owner, BigInt amount) async {
    final abi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/accounts/AccountFactory.abi.json');

    final cabi = ContractAbi.fromJson(abi, 'AccountFactory');

    final function = cabi.functions
        .where((element) => element.name == 'createAccount')
        .first;

    final callData =
        function.encodeCall([EthereumAddress.fromHex(owner), BigInt.from(0)]);

    return hexToBytes('$addr${bytesToHex(callData)}');
  }

  void dispose() {
    // _sub?.cancel();
  }
}
