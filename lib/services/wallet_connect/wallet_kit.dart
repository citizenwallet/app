import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

import 'package:citizenwallet/models/contract_data.dart';
import 'package:citizenwallet/models/extended_abi_item.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:convert/convert.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:web3dart/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:citizenwallet/services/config/config.dart';

final List<String> supportedChains = [
  'eip155:100',
];

final List<String> supportedMethods = [
  "eth_sign",
  "eth_signTransaction",
  "eth_sendTransaction",
  "personal_sign",
];

final List<String> supportedEvents = [
  "chainChanged",
  "accountsChanged",
  "message",
  "disconnect",
  "connect",
];

class WalletKitService {
  static final WalletKitService _instance = WalletKitService._internal();

  factory WalletKitService() {
    return _instance;
  }

  WalletKitService._internal();

  ReownWalletKit? _connectClient;

  ReownWalletKit? get client => _connectClient;

  Future<ReownWalletKit> initialize() async {
    if (_connectClient != null) {
      return _connectClient!;
    }

    final projectId = dotenv.env['PUBLIC_REOWN_PROJECT_ID'] ?? '';

    _connectClient = await ReownWalletKit.createInstance(
      projectId: projectId,
      metadata: PairingMetadata(
        name: 'Citizen Wallet',
        description: 'A mobile wallet for your community',
        url: 'https://citizenwallet.xyz',
        icons: ['https://citizenwallet.xyz/logo.png'],
        redirect: Redirect(
          native: 'citizenwallet://',
          universal: 'https://citizenwallet.xyz',
        ),
      ),
    );

    _setupEventListeners();
    return _connectClient!;
  }

  void _setupEventListeners() {
    if (_connectClient == null) return;

    _connectClient!.onSessionProposal.subscribe((event) {
      // Event is handled in WalletKitLogic
    });

    _connectClient!.onSessionDelete.subscribe((event) {
      if (event != null) {
        debugPrint('Session deleted: ${event.topic}');
      }
    });

    _connectClient!.onSessionRequest.subscribe((event) {
      if (event != null) {
        debugPrint(
            'Session request received: ${event.id}, method: ${event.method}');
      }
    });
  }

  void registerWallet(
    String address, {
    Map<String, dynamic Function(String, dynamic)>? methodHandlers,
  }) {
    if (_connectClient == null) throw Exception('WalletKit not initialized');

    for (final chainId in supportedChains) {
      registerAccount(
        chainId: chainId,
        accountAddress: address,
      );

      if (methodHandlers != null) {
        for (final method in supportedMethods) {
          if (methodHandlers.containsKey(method)) {
            registerRequestHandler(
              chainId: chainId,
              method: method,
              handler: methodHandlers[method]!,
            );
          }
        }
      }

      for (final event in supportedEvents) {
        registerEventEmitter(
          chainId: chainId,
          event: event,
        );
      }
    }
  }

  void registerAccount({
    required String chainId,
    required String accountAddress,
  }) {
    _connectClient?.registerAccount(
      chainId: chainId,
      accountAddress: accountAddress,
    );
  }

  void registerRequestHandler({
    required String chainId,
    required String method,
    required dynamic Function(String, dynamic) handler,
  }) {
    _connectClient?.registerRequestHandler(
      chainId: chainId,
      method: method,
      handler: handler,
    );
  }

  void registerEventEmitter({
    required String chainId,
    required String event,
  }) {
    _connectClient?.registerEventEmitter(
      chainId: chainId,
      event: event,
    );
  }

  Future<void> pair(String uri) async {
    if (_connectClient == null) throw Exception('WalletKit not initialized');
    await _connectClient!.pair(
      uri: Uri.parse(uri),
    );
  }

  Future<void> approveSession({
    required int id,
    required Map<String, Namespace> namespaces,
  }) async {
    if (_connectClient == null) throw Exception('WalletKit not initialized');
    await _connectClient!.approveSession(
      id: id,
      namespaces: namespaces,
    );
  }

  Future<void> rejectSession({
    required int id,
    required ReownSignError reason,
  }) async {
    if (_connectClient == null) throw Exception('WalletKit not initialized');
    await _connectClient!.rejectSession(
      id: id,
      reason: reason,
    );
  }

  Future<void> respondSessionRequest({
    required String topic,
    required JsonRpcResponse response,
  }) async {
    if (_connectClient == null) throw Exception('WalletKit not initialized');
    await _connectClient!.respondSessionRequest(
      topic: topic,
      response: response,
    );
  }

  Future<void> updateSession({
    required String topic,
    required Map<String, Namespace> namespaces,
  }) async {
    if (_connectClient == null) throw Exception('WalletKit not initialized');
    await _connectClient!.updateSession(
      topic: topic,
      namespaces: namespaces,
    );
  }

  Future<void> extendSession({
    required String topic,
  }) async {
    if (_connectClient == null) throw Exception('WalletKit not initialized');
    await _connectClient!.extendSession(
      topic: topic,
    );
  }

  Future<void> disconnectSession({
    required String topic,
    required ReownSignError reason,
  }) async {
    if (_connectClient == null) throw Exception('WalletKit not initialized');
    await _connectClient!.disconnectSession(
      topic: topic,
      reason: reason,
    );
  }

  Future<void> emitSessionEvent({
    required String topic,
    required String chainId,
    required SessionEventParams event,
  }) async {
    if (_connectClient == null) throw Exception('WalletKit not initialized');
    await _connectClient!.emitSessionEvent(
      topic: topic,
      chainId: chainId,
      event: event,
    );
  }

  List<SessionRequest> getPendingRequests() {
    if (_connectClient == null) throw Exception('WalletKit not initialized');
    return _connectClient!.pendingRequests.getAll();
  }

  void onSessionProposal(Function(SessionProposalEvent?) callback) {
    if (_connectClient == null) throw Exception('WalletKit not initialized');
    _connectClient!.onSessionProposal.subscribe(callback);
  }

  void onSessionRequest(Function(SessionRequestEvent?) callback) {
    if (_connectClient == null) throw Exception('WalletKit not initialized');
    _connectClient!.onSessionRequest.subscribe(callback);
  }

  Future<void> personalSignHandler(String topic, dynamic params, bool? approve,
      EthPrivateKey? credentials) async {
    if (_connectClient == null) throw Exception('WalletKit not initialized');

    final SessionRequest request =
        _connectClient!.pendingRequests.getAll().last;
    final int requestId = request.id;

    final decoded = hex.decode(params.first.substring(2));
    final message = utf8.decode(decoded);

    if (approve == true && credentials != null) {
      final signature = bytesToHex(
        credentials.signPersonalMessageToUint8List(
          keccak256(utf8.encode(message)),
        ),
        include0x: true,
      );

      return _connectClient!.respondSessionRequest(
        topic: topic,
        response: JsonRpcResponse(
          id: requestId,
          jsonrpc: '2.0',
          result: signature,
        ),
      );
    } else {
      return _connectClient!.respondSessionRequest(
        topic: topic,
        response: JsonRpcResponse(
          id: requestId,
          jsonrpc: '2.0',
          error:
              const JsonRpcError(code: 5001, message: 'User rejected method'),
        ),
      );
    }
  }

  Future<void> ethSendTransactionHandler(
      String topic,
      dynamic params,
      bool approve,
      Config? config,
      EthereumAddress? account,
      EthPrivateKey? credentials) async {
    if (_connectClient == null) throw Exception('WalletKit not initialized');

    final SessionRequest request =
        _connectClient!.pendingRequests.getAll().last;
    final int requestId = request.id;
    final String chainId = request.chainId;

    final transaction = (params as List<dynamic>).first as Map<String, dynamic>;

    if (approve == true &&
        config != null &&
        account != null &&
        credentials != null) {
      final data = transaction['data'] != null
          ? hexToBytes(transaction['data'])
          : Uint8List(0);

      BigInt value;
      try {
        final valueStr = transaction['value']?.toString() ?? '0';
        if (valueStr.startsWith('0x')) {
          value = BigInt.parse(valueStr.substring(2), radix: 16);
        } else {
          value = BigInt.parse(valueStr);
        }
      } catch (e) {
        value = BigInt.zero;
      }

      final (hash, userop) = await prepareUserop(
        config,
        account,
        credentials,
        [transaction['to']],
        [data],
        value: value,
        accountFactoryAddress: config.community.primaryAccountFactory.address,
      );

      final txHash = await submitUserop(
        config,
        userop,
      );

      if (txHash != null && userop.isFirst()) {
        await waitForTxSuccess(config, txHash).then((value) {});
      }

      return _connectClient!.respondSessionRequest(
        topic: topic,
        response: JsonRpcResponse(
          id: requestId,
          jsonrpc: '2.0',
          result: txHash,
        ),
      );
    } else {
      return _connectClient!.respondSessionRequest(
        topic: topic,
        response: JsonRpcResponse(
          id: requestId,
          jsonrpc: '2.0',
          error:
              const JsonRpcError(code: 5001, message: 'User rejected method'),
        ),
      );
    }
  }

  Future<ContractData?> getContractDetails(String address) async {
    final apiKey = dotenv.env['PUBLIC_GNOSIS_SCAN_API_KEY'] ??
        'ZN5GXS2JRUU7TRUMRMU4X1MS2AKTR83E1C';

    const explorerApi = "https://api.gnosisscan.io/api";

    var response = await http.get(Uri.parse(
      '$explorerApi?module=contract&action=getsourcecode&address=$address&apikey=$apiKey',
    ));

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);

    if (data['status'] != "1" ||
        data['message'] != "OK" ||
        data['result'].isEmpty ||
        data['result'][0]['ContractName'] == null) {
      debugPrint("Failed to fetch contract details: ${data['message']}");
      return null;
    }

    var result = data['result'][0];

    final implementation = result['Implementation'];
    if (implementation != null && implementation != "") {
      response = await http.get(Uri.parse(
        '$explorerApi?module=contract&action=getsourcecode&address=$implementation&apikey=$apiKey',
      ));
      final data2 = jsonDecode(response.body);

      if (data2['status'] != "1" ||
          data2['message'] != "OK" ||
          data2['result'].isEmpty ||
          data2['result'][0]['ContractName'] == null) {
        debugPrint("Failed to fetch contract details: ${data2['message']}");
        return null;
      }

      result = data2['result'][0];
    }
    return ContractData.fromJson(result);
  }

  List<ExtendedAbiItem> parseAbi(String rawAbi) {
    final List<dynamic> abi = jsonDecode(rawAbi);

    return abi.where((v) => v['type'] == 'function').map<ExtendedAbiItem>((v) {
      final name = v['name'];
      final inputs = v['inputs'] as List<dynamic>;

      final id =
          "$name(${inputs.map((input) => "${input['name']} ${input['type']}").join(',')})";

      final signatureString =
          "$name(${inputs.map((input) => input['type']).join(',')})";

      final signature =
          '0x${bytesToHex(keccakUtf8(signatureString)).substring(0, 8)}';

      final item = ExtendedAbiItem(
        name: name,
        type: v['type'],
        inputs: inputs,
        id: id,
        signature: signature,
        selected: false,
      );

      return item;
    }).toList();
  }

  String? getTransactionTypeFromAbi(String rawAbi, String data) {
    if (data.isEmpty || !data.startsWith('0x') || data.length < 10) {
      return null;
    }
    final selector = data.substring(0, 10);
    final abiItems = parseAbi(rawAbi);
    final matched = abiItems.firstWhere(
      (item) => item.signature == selector,
      orElse: () => ExtendedAbiItem(
        name: '',
        type: '',
        inputs: [],
        id: '',
        signature: '',
        selected: false,
      ),
    );

    final name = matched.name.toLowerCase();
    if (name.contains('mint')) return 'mint';
    if (name.contains('burn')) return 'burn';
    if (name.contains('transfer')) return 'transfer';

    return matched.name;
  }
}
