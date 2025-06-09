import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:convert/convert.dart';
import 'package:flutter/cupertino.dart';
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
  Config? _config;

  ReownWalletKit? get client => _connectClient;

  Future<ReownWalletKit> initialize({Config? config}) async {
    if (_connectClient != null) {
      return _connectClient!;
    }

    _config = config;

    final projectId = dotenv.env['PUBLIC_REOWN_PROJECT_ID'] ?? '';
    final community = _config?.community;

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
      debugPrint('Session proposal received: ${event.id}');
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

  Future<void> personalSignHandler(
      String topic, dynamic params, bool? approve) async {
    if (_connectClient == null) throw Exception('WalletKit not initialized');

    final SessionRequest request =
        _connectClient!.pendingRequests.getAll().last;
    final int requestId = request.id;

    final decoded = hex.decode(params.first.substring(2));
    final message = utf8.decode(decoded);

    if (approve == true) {
      final walletService = WalletService();

      final credentials = walletService.credentials;

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
      String topic, dynamic params, bool approve) async {
    if (_connectClient == null) throw Exception('WalletKit not initialized');

    final SessionRequest request =
        _connectClient!.pendingRequests.getAll().last;
    final int requestId = request.id;
    final String chainId = request.chainId;

    final transaction = (params as List<dynamic>).first as Map<String, dynamic>;

    if (approve == true) {
      final walletService = WalletService();

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

      final (hash, userop) = await walletService.prepareUserop(
        [transaction['to']],
        [data],
        value: value,
      );

      final txHash = await walletService.submitUserop(
        userop,
        data: {'data': transaction['data']},
      );

      if (userop.isFirst()) {
        await walletService.waitForTxSuccess(txHash!).then((value) {});
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
}
