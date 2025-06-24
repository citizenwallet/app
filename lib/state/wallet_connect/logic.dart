import 'package:citizenwallet/services/wallet_connect/wallet_kit.dart';
import 'package:citizenwallet/widgets/wallet_transaction_modal.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:flutter/cupertino.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/notifications/state.dart';
import 'package:citizenwallet/state/wallet_connect/state.dart';
import 'package:provider/provider.dart';
import 'package:citizenwallet/widgets/wallet_session_approval.dart';
import 'dart:async';

class WalletKitLogic with WidgetsBindingObserver {
  final WalletKitService _service = WalletKitService();
  SessionProposalEvent? _currentProposal;
  Completer<SessionProposalEvent?>? _proposalCompleter;
  BuildContext? _context;
  NotificationsLogic? _notificationsLogic;
  WalletConnectState? _state;

  ReownWalletKit? get connectClient => _service.client;
  SessionProposalEvent? get currentProposal => _currentProposal;

  Future<SessionProposalEvent?> waitForProposal() async {
    if (_currentProposal != null) {
      return _currentProposal;
    }

    _proposalCompleter = Completer<SessionProposalEvent?>();
    return _proposalCompleter?.future;
  }

  void setContext(BuildContext context) {
    _context = context;
    _notificationsLogic = NotificationsLogic(context);
    _state = context.read<WalletConnectState>();
  }

  Future<void> initialize() async {
    try {
      await _service.initialize();
      _setupEventListeners();
      await _updateSessions();
      debugPrint('WalletKit initialized successfully');
    } catch (e) {
      debugPrint('Error initializing WalletKit: $e');
      rethrow;
    }
  }

  Future<void> restoreSessions() async {
    try {
      _state?.setConnecting(true);
      _state?.setError(null);

      if (_service.client == null) {
        await _service.initialize();
        _setupEventListeners();
      }

      await _updateSessions();
      final sessions = _service.client?.getActiveSessions();
      if (sessions != null && sessions.isNotEmpty) {
        _state?.setActiveSessions(sessions);
        _state?.setConnectionState(true);
        _state?.setInitialized(true);
      } else {
        _state?.setActiveSessions({});
        _state?.setConnectionState(false);
        _state?.setInitialized(true);
      }
    } catch (e) {
      debugPrint('Error restoring sessions: $e');
      _state?.setConnectionState(false);
      _state?.setActiveSessions({});
    }
  }

  void _setupEventListeners() {
    _service.onSessionProposal((event) {
      if (event != null) {
        _currentProposal = event;
        _proposalCompleter?.complete(event);
      }
    });

    _service.onSessionRequest((event) {
      if (event != null && _state?.isAppActive == true) {
        _state?.setAppState(true);
        _updateSessions();
      }
    });

    _service.client?.onSessionDelete.subscribe((event) {
      _updateSessions();
      if (_state?.hasActiveSessions == false) {
        _state?.setConnectionState(false);
      }
    });
  }

  Future<void> _updateSessions() async {
    if (_state == null) return;

    try {
      final sessions = _service.client?.getActiveSessions();
      if (sessions != null) {
        _state!.setActiveSessions(sessions);
        _state!.setConnectionState(sessions.isNotEmpty);
        debugPrint('Updated sessions. Total sessions: ${sessions.length}');
      } else {
        _state!.setActiveSessions({});
        _state!.setConnectionState(false);
        debugPrint('No sessions found');
      }
    } catch (e) {
      debugPrint('Error updating sessions: $e');
      _state!.setActiveSessions({});
      _state!.setConnectionState(false);
    }
  }

  Future<void> updateSessions() async {
    await _updateSessions();
  }

  void setAppState(bool isActive) {
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
    try {
      _state?.setConnecting(true);

      if (_service.client == null) {
        await _service.initialize();
        _setupEventListeners();
      }

      final sessions = _service.client?.getActiveSessions();
      if (sessions != null && sessions.isNotEmpty) {
        debugPrint('Found ${sessions.length} active sessions to restore');
        _state?.setConnectionState(true);
        _state?.setActiveSessions(sessions);
      } else {
        debugPrint('No active sessions found');
        _state?.setConnectionState(false);
        _state?.setActiveSessions({});
      }
    } catch (e) {
      _state?.setConnectionState(false);
      _state?.setActiveSessions({});
      debugPrint('Error during session reconnection: $e');
    } finally {
      _state?.setConnecting(false);
    }
  }

  Future<void> registerWallet(String address) async {
    if (connectClient == null) {
      await initialize();
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
  }

  Future<void> pairWithDapp(String uri) async {
    if (connectClient == null) {
      await initialize();
    }

    _currentProposal = null;
    _proposalCompleter = null;

    await _service.pair(uri);
    await _updateSessions();
  }

  Future<void> approveSession() async {
    final proposal = await waitForProposal();
    if (proposal == null || _context == null) {
      throw Exception('No proposal available or context not set');
    }

    final shouldApprove = await showCupertinoModalPopup<bool>(
      context: _context!,
      barrierDismissible: false,
      builder: (BuildContext context) => WalletSessionApprovalModal(
        sessionProposal: proposal,
        onConfirm: () async {
          try {
            await _service.approveSession(
              id: proposal.id,
              namespaces: proposal.params.generatedNamespaces ?? {},
            );
            await _updateSessions();

            if (_context != null) {
              _notificationsLogic?.toastShow('Successfully approved session',
                  type: ToastType.success);
            }

            _currentProposal = null;
            _proposalCompleter = null;

            Navigator.of(context).pop(true);
          } catch (e) {
            _notificationsLogic?.toastShow('Failed to approve session',
                type: ToastType.error);
            Navigator.of(context).pop(false);
          }
        },
        onCancel: () async {
          await rejectSession();
          _currentProposal = null;
          _proposalCompleter = null;

          Navigator.of(context).pop(true);
          if (_context != null) {
            _notificationsLogic?.toastShow('Successfully rejected session',
                type: ToastType.success);
          }
        },
      ),
    );

    if (shouldApprove != true) {
      _currentProposal = null;
      _proposalCompleter = null;
      throw Exception('Session approval was cancelled');
    }
  }

  Future<void> rejectSession() async {
    if (_currentProposal == null) {
      throw Exception('No proposal available to reject');
    }

    try {
      await _service.rejectSession(
        id: _currentProposal!.id,
        reason: Errors.getSdkError(Errors.USER_REJECTED).toSignError(),
      );
      await _updateSessions();
    } catch (e) {
      debugPrint('Error rejecting session: $e');
      rethrow;
    }
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
      await _updateSessions();
      debugPrint('Successfully disconnected session: $topic');
    } catch (e) {
      debugPrint('Error disconnecting session $topic: $e');
      rethrow;
    }
  }

  Future<void> disconnectAllSessions() async {
    try {
      final sessions = _service.client?.getActiveSessions();
      if (sessions != null && sessions.isNotEmpty) {
        for (final topic in sessions.keys) {
          try {
            await _service.disconnectSession(
              topic: topic,
              reason:
                  Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
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
    if (_context == null) {
      debugPrint('Context is null, returning early: $topic');
    }

    final sessions = _service.client?.getActiveSessions();
    final currentSession = sessions?[topic];

    if (currentSession == null) {
      debugPrint('No active session found for topic: $topic');
      return await _service.ethSendTransactionHandler(topic, params, false);
    }

    final List<dynamic> paramsList = params as List<dynamic>;
    if (paramsList.isEmpty) {
      throw Exception('No transaction parameters provided');
    }
    final transaction = paramsList[0] as Map<String, dynamic>;

    String? transactionType;
    try {
      final contractData = await _service.getContractDetails(transaction['to']);
      if (contractData != null && contractData.abi != null) {
        transactionType = _service.getTransactionTypeFromAbi(
          contractData.abi,
          transaction['data'] ?? '',
        );
      } else {
        transactionType = 'unknown';
      }
    } catch (e) {
      transactionType = 'unknown';
    }

    final bool? result = await showCupertinoModalPopup<bool>(
      context: _context!,
      barrierDismissible: false,
      builder: (BuildContext context) => WalletTransactionModal(
        event: currentSession,
        transactionType: transactionType ?? '',
        onConfirm: () async {
          await _service.ethSendTransactionHandler(topic, params, true);
          Navigator.of(_context!).pop(true);
        },
        onCancel: () async {
          await _service.ethSendTransactionHandler(topic, params, false);
          Navigator.of(_context!).pop(false);
        },
      ),
    );

    if (result == true) {
      _notificationsLogic?.toastShow('Transaction approved',
          type: ToastType.success);
    } else {
      _notificationsLogic?.toastShow('Transaction rejected',
          type: ToastType.error);
    }
    return;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only handle foreground if context is available
      if (_context != null) {
        _handleAppForeground();
      }
    } else if (state == AppLifecycleState.inactive) {
      _handleAppBackground();
    }
  }
}
