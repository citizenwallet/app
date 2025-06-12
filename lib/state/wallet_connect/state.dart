import 'package:flutter/foundation.dart';

class WalletConnectState extends ChangeNotifier {
  Map<String, dynamic> _activeSessions = {};
  bool _isInitialized = false;
  bool _isConnecting = false;
  String? _error;
  bool _isAppActive = true;
  DateTime? _lastActiveTime;
  bool _isConnected = false;

  Map<String, dynamic> get activeSessions => _activeSessions;
  bool get isInitialized => _isInitialized;
  bool get isConnecting => _isConnecting;
  String? get error => _error;
  bool get hasActiveSessions => _activeSessions.isNotEmpty;
  bool get isAppActive => _isAppActive;
  DateTime? get lastActiveTime => _lastActiveTime;
  bool get isConnected => _isConnected;

  void setAppState(bool isActive) {
    _isAppActive = isActive;
    if (isActive) {
      _lastActiveTime = DateTime.now();
    }
    notifyListeners();
  }

  void setConnectionState(bool isConnected) {
    _isConnected = isConnected;
    notifyListeners();
  }

  void setActiveSessions(Map<String, dynamic> sessions) {
    _activeSessions = sessions;
    notifyListeners();
  }

  void addSession(String topic, dynamic session) {
    _activeSessions[topic] = session;
    notifyListeners();
  }

  void removeSession(String topic) {
    _activeSessions.remove(topic);
    notifyListeners();
  }

  void setInitialized(bool initialized) {
    _isInitialized = initialized;
    notifyListeners();
  }

  void setConnecting(bool connecting) {
    _isConnecting = connecting;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void reset() {
    _activeSessions = {};
    _isInitialized = false;
    _isConnecting = false;
    _error = null;
    notifyListeners();
  }
}
