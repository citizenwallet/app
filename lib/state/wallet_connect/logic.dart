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
  Timer? _inactiveCheckTimer;
  static const Duration _inactiveTimeout = Duration(minutes: 5);
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
      print('WalletKit initialized successfully');
    } catch (e) {
      print('Error initializing WalletKit: $e');
      rethrow;
    }
  }

  void _setupEventListeners() {
    _service.onSessionProposal((event) {
      if (event != null) {
        _currentProposal = event;
        print('📝 Received session proposal: ${event.params.requiredNamespaces}');
      }
    });

    _service.onSessionRequest((event) {
      if (event != null && _state?.isAppActive == true) {
        print('📨 Received session request while app is active');
        _state?.setAppState(true);
        _updateSessions();
      }
    });

    _service.client?.onSessionDelete.subscribe((event) {
      if (event != null) {
        print('🗑️ Session deleted: ${event.topic}');
        _updateSessions();
        if (_state?.hasActiveSessions == false) {
          print('🔌 No active sessions remaining, updating connection state');
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

        for (var entry in sessions.entries) {
          final session = entry.value;
          final peerName = session.peer.metadata.name;
          final peerUrl = session.peer.metadata.url;

          if (peerName == null || peerUrl == null) continue;

          bool isDuplicate = false;
          for (var existingSession in uniqueSessions.values) {
            if (existingSession.peer.metadata.name == peerName &&
                existingSession.peer.metadata.url == peerUrl) {
              isDuplicate = true;
              break;
            }
          }

          if (!isDuplicate) {
            uniqueSessions[entry.key] = session;
          }
        }

        _state!.setActiveSessions(uniqueSessions);
        print(
            'Updated active sessions: ${uniqueSessions.length} unique sessions');
      }
    } catch (e) {
      print('Error updating sessions: $e');
    }
  }

  Future<void> updateSessions() async {
    await _updateSessions();
  }

  void setAppState(bool isActive) {
    print('🔄 App state changing to: ${isActive ? "ACTIVE" : "INACTIVE"}');
    _state?.setAppState(isActive);
    if (isActive) {
      _startInactiveCheckTimer();
      _handleAppForeground();
    } else {
      _handleAppBackground();
    }
  }

  Future<void> _handleAppBackground() async {
    print('📱 App going to BACKGROUND');
    _checkInactiveTimeout();
    _state?.setConnectionState(false);
    print('🔌 Connection state set to: DISCONNECTED');
  }

  Future<void> _handleAppForeground() async {
    print('📱 App coming to FOREGROUND');
    try {
      print('🔄 Attempting to reconnect sessions...');
      await _reconnectSessions();
      await _updateSessions();
    } catch (e) {
      print('❌ Error reconnecting sessions: $e');
    }
  }

  Future<void> _reconnectSessions() async {
    if (_state?.hasActiveSessions == true) {
      print('🔌 Found active sessions, attempting reconnection...');
      _state?.setConnecting(true);
      try {
        print('⏳ Waiting for network stability (${_reconnectTimeout.inSeconds}s)...');
        await Future.delayed(_reconnectTimeout);
        
        final sessions = await _service.client?.getActiveSessions();
        if (sessions != null && sessions.isNotEmpty) {
          _state?.setConnectionState(true);
          print('✅ Successfully reconnected ${sessions.length} sessions');
        } else {
          _state?.setConnectionState(false);
          print('⚠️ No active sessions found during reconnection');
        }
      } catch (e) {
        _state?.setConnectionState(false);
        print('❌ Error during session reconnection: $e');
      } finally {
        _state?.setConnecting(false);
      }
    } else {
      print('ℹ️ No active sessions to reconnect');
    }
  }

  void _startInactiveCheckTimer() {
    print('⏰ Starting inactive check timer');
    _inactiveCheckTimer?.cancel();
    _inactiveCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_state?.isAppActive == false) {
        print('⏰ Checking inactive timeout...');
        _checkInactiveTimeout();
      }
    });
  }

  Future<void> _checkInactiveTimeout() async {
    if (_state?.isAppActive == false && _state?.lastActiveTime != null) {
      final inactiveDuration = DateTime.now().difference(_state!.lastActiveTime!);
      print('⏱️ App inactive for: ${inactiveDuration.inMinutes} minutes');
      if (inactiveDuration > _inactiveTimeout) {
        print('⚠️ App inactive for more than 5 minutes, disconnecting all sessions');
        await disconnectAllSessions();
        _inactiveCheckTimer?.cancel();
        print('⏰ Inactive check timer cancelled');
      }
    }
  }

  Future<void> disconnectAllSessions() async {
    try {
      final sessions = await _service.client?.getActiveSessions();
      if (sessions != null && sessions.isNotEmpty) {
        print('Disconnecting ${sessions.length} active sessions');

        for (final topic in sessions.keys) {
          try {
            await disconnectSession(
              topic: topic,
              reason:
                  Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
            );
            print('Successfully disconnected session: $topic');
          } catch (e) {
            print('Error disconnecting session $topic: $e');
          }
        }
        _state?.setActiveSessions({});
      }
    } catch (e) {
      print('Error getting active sessions: $e');
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
    print('Wallet registered: $address');
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
    await _service.disconnectSession(topic: topic, reason: reason);
    await _updateSessions();
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
      print('No context available for showing transaction popup');
      return await _service.ethSendTransactionHandler(topic, params, false);
    }

    final sessions = await _service.client?.getActiveSessions();
    final currentSession = sessions?[topic];

    if (currentSession == null) {
      print('No active session found for topic: $topic');
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
