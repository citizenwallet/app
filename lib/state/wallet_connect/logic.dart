import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/wallet_connect/wallet_kit.dart';
import 'package:citizenwallet/widgets/wallet_transaction_modal.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:flutter/cupertino.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/notifications/state.dart';
import 'package:citizenwallet/state/wallet_connect/state.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class WalletKitLogic {
  final WalletKitService _service = WalletKitService();
  SessionProposalEvent? _currentProposal;
  BuildContext? _context;
  NotificationsLogic? _notificationsLogic;
  Config? _config;
  WalletConnectState? _state;
  static const Duration _reconnectTimeout = Duration(seconds: 5);

  ReownWalletKit? get connectClient => _service.client;
  SessionProposalEvent? get currentProposal => _currentProposal;

  void setContext(BuildContext context) {
    _context = context;
    _notificationsLogic = NotificationsLogic(context);
    _state = context.read<WalletConnectState>();
    _updateSessions();
  }

  Future<void> initialize(Config? config) async {
    try {
      _config = config;
      await _service.initialize(config: config);
      _setupEventListeners();
      await _updateSessions();
      debugPrint('WalletKit initialized successfully');
    } catch (e) {
      debugPrint('Error initializing WalletKit: $e');
      rethrow;
    }
  }

  void _setupEventListeners() {
    _service.onSessionProposal((event) {
      if (event != null) {
        _currentProposal = event;
      }
    });

    _service.onSessionRequest((event) {
      if (event != null && _state?.isAppActive == true) {
        _state?.setAppState(true);
        _updateSessions();
      }
    });

    _service.client?.onSessionDelete.subscribe((event) {
      if (event != null) {
        _updateSessions();
        if (_state?.hasActiveSessions == false) {
          _state?.setConnectionState(false);
        }
      }
    });
  }

  Future<void> _updateSessions() async {
    if (_state == null) return;

    try {
      final sessions = await _service.client?.getActiveSessions();
      if (sessions != null) {
        final Map<String, dynamic> uniqueSessions = {};
        final Set<String> processedDapps = {};

        for (var entry in sessions.entries) {
          final session = entry.value;
          final peerName = session.peer.metadata.name;
          final peerUrl = session.peer.metadata.url;

          if (peerName == null || peerUrl == null) continue;

          // Create a unique identifier for the dApp
          final dappIdentifier = '$peerName-$peerUrl';
          
          // If we haven't seen this dApp before, add its session
          if (!processedDapps.contains(dappIdentifier)) {
            uniqueSessions[entry.key] = session;
            processedDapps.add(dappIdentifier);
            debugPrint('Added session for dApp: $peerName ($peerUrl)');
          } else {
            debugPrint('Skipping duplicate session for dApp: $peerName ($peerUrl)');
          }
        }

        _state!.setActiveSessions(uniqueSessions);
        debugPrint('Updated sessions. Total unique sessions: ${uniqueSessions.length}');
      }
    } catch (e) {
      debugPrint('Error updating sessions: $e');
    }
  }

  Future<void> updateSessions() async {
    await _updateSessions();
  }

  void setAppState(bool isActive) {
    print('🔄 App state changing to: ${isActive ? "ACTIVE" : "INACTIVE"}');
    _state?.setAppState(isActive);
    if (isActive) {
      _handleAppForeground();
    } else {
      _handleAppBackground();
    }
  }

  Future<void> _handleAppBackground() async {
    // No automatic disconnection when app goes to background
  }

  Future<void> _handleAppForeground() async {
    try {
      await _reconnectSessions();
      await _updateSessions();
    } catch (e) {
      debugPrint('Error reconnecting sessions: $e');
    }
  }

  Future<void> _reconnectSessions() async {
    if (_state?.hasActiveSessions == true) {
      _state?.setConnecting(true);
      try {
        await Future.delayed(_reconnectTimeout);

        final sessions = await _service.client?.getActiveSessions();
        if (sessions != null && sessions.isNotEmpty) {
          _state?.setConnectionState(true);
        } else {
          _state?.setConnectionState(false);
        }
      } catch (e) {
        _state?.setConnectionState(false);
        debugPrint('Error during session reconnection: $e');
      } finally {
        _state?.setConnecting(false);
      }
    } else {
      debugPrint('No active sessions to reconnect');
    }
  }

  Future<void> registerWallet(String address) async {
    if (connectClient == null) {
      await initialize(_config);
    }

    _service.registerWallet(
      address,
      methodHandlers: {
        'personal_sign': (String topic, dynamic params) =>
            _personalSignHandler(topic, params),
        'eth_sendTransaction': (String topic, dynamic params) =>
            _ethSendTransactionHandler(topic, params),
      },
    );

    await _updateSessions();
  }

  Future<void> pairWithDapp(String uri) async {
    if (connectClient == null) {
      await initialize(_config);
    }

    await _service.pair(uri);
    await _updateSessions();
  }

  Future<void> approveSession() async {
    _service.onSessionProposal((SessionProposalEvent? event) async {
      if (event != null) {
        await _service.approveSession(
          id: event.id,
          namespaces: event.params.generatedNamespaces ?? {},
        );
        await _updateSessions();
      }
    });
  }

  Future<void> rejectSession() async {
    _service.onSessionProposal((SessionProposalEvent? event) async {
      if (event != null) {
        await _service.rejectSession(
          id: event.id,
          reason: Errors.getSdkError(Errors.USER_REJECTED).toSignError(),
        );
        await _updateSessions();
      }
    });
  }

  Future<void> respondSessionRequest({
    required String topic,
    required JsonRpcResponse response,
  }) async {
    await _service.respondSessionRequest(topic: topic, response: response);
  }

  Future<void> updateSession({
    required String topic,
    required Map<String, Namespace> namespaces,
  }) async {
    await _service.updateSession(topic: topic, namespaces: namespaces);
  }

  Future<void> extendSession({
    required String topic,
  }) async {
    await _service.extendSession(topic: topic);
  }

  Future<void> disconnectSession({
    required String topic,
    required ReownSignError reason,
  }) async {
    try {
      await _service.disconnectSession(topic: topic, reason: reason);
      // Update sessions immediately after disconnection
      await _updateSessions();
      debugPrint('Successfully disconnected session: $topic');
    } catch (e) {
      debugPrint('Error disconnecting session $topic: $e');
      rethrow;
    }
  }

  Future<void> disconnectAllSessions() async {
    try {
      final sessions = await _service.client?.getActiveSessions();
      if (sessions != null && sessions.isNotEmpty) {
        for (final topic in sessions.keys) {
          try {
            await _service.disconnectSession(
              topic: topic,
              reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
            );
            debugPrint('Disconnected session: $topic');
          } catch (e) {
            debugPrint('Error disconnecting session $topic: $e');
          }
        }
        _state?.setActiveSessions({});
        debugPrint('All sessions disconnected');
      }
    } catch (e) {
      debugPrint('Error getting active sessions: $e');
    }
  }

  Future<void> emitSessionEvent({
    required String topic,
    required String chainId,
    required SessionEventParams event,
  }) async {
    await _service.emitSessionEvent(
      topic: topic,
      chainId: chainId,
      event: event,
    );
  }

  List<SessionRequest> getPendingRequests() {
    return _service.getPendingRequests();
  }

  void onSessionProposal(Function(SessionProposalEvent?) callback) {
    _service.onSessionProposal(callback);
  }

  void onSessionRequest(Function(SessionRequestEvent?) callback) {
    _service.onSessionRequest(callback);
  }

  Future<void> _personalSignHandler(String topic, dynamic params) async {
    return await _service.personalSignHandler(topic, params, true);
  }

  Future<void> _ethSendTransactionHandler(String topic, dynamic params) async {
    final SessionRequest request = _service.getPendingRequests().last;

    if (_context == null) {
      return await _service.ethSendTransactionHandler(topic, params, false);
    }

    final sessions = await _service.client?.getActiveSessions();
    final currentSession = sessions?[topic];

    if (currentSession == null) {
      debugPrint('No active session found for topic: $topic');
      return await _service.ethSendTransactionHandler(topic, params, false);
    }

    final bool? result = await showCupertinoModalPopup<bool>(
      context: _context!,
      barrierDismissible: false,
      builder: (BuildContext context) => WalletTransactionModal(
        message:
            'You are about to do a transaction with ${currentSession.peer.metadata.name}',
        onConfirm: () async {
          await _service.ethSendTransactionHandler(topic, params, true);
          Navigator.of(_context!).pop(true);
        },
        onCancel: () async {
          await _service.ethSendTransactionHandler(topic, params, false);
          Navigator.of(_context!).pop(false);
        },
        uri: currentSession.peer.metadata.url,
      ),
    );

    if (_notificationsLogic != null) {
      if (result != null && result) {
        _notificationsLogic!
            .toastShow('Transaction approved', type: ToastType.success);
      } else {
        _notificationsLogic!
            .toastShow('Transaction rejected', type: ToastType.error);
      }
    }

    return;
  }
}
