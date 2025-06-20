import 'dart:async';
import 'dart:convert';
import 'dart:io' show WebSocket;

import 'package:citizenwallet/utils/delay.dart';

enum EventServiceState {
  disconnected,
  connecting,
  connected,
  error,
}

class WebSocketEvent {
  final String poolId;
  final String type;
  final String id;
  final String dataType;
  final Map<String, dynamic> data;

  WebSocketEvent({
    required this.poolId,
    required this.type,
    required this.id,
    required this.dataType,
    required this.data,
  });

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketEvent(
      poolId: json['pool_id'],
      type: json['type'],
      id: json['id'],
      dataType: json['data_type'],
      data: json['data'],
    );
  }

  static WebSocketEvent? tryParse(String message) {
    try {
      final jsonData = json.decode(message);
      return WebSocketEvent.fromJson(jsonData);
    } catch (e) {
      print('Error parsing WebSocket message: $e');
      return null;
    }
  }
}

class EventService {
  final String _url;
  final String _contractAddress;
  final String _topic;
  WebSocket? _ws;
  Timer? _reconnectTimer;
  final Duration _reconnectMaxSeconds = const Duration(seconds: 20);
  final Duration _reconnectDelay = const Duration(seconds: 2);
  bool _isConnected = false;
  bool _intentionalDisconnect = false;

  Function(WebSocketEvent)? _messageHandler;
  Function(EventServiceState)? _stateHandler;

  EventService(this._url, this._contractAddress, this._topic);

  bool get isOffline => _isConnected == false;

  Future<void> connect({Duration? reconnectDelay}) async {
    print('Connecting to $_url/v1/events/$_contractAddress/$_topic');

    if (_isConnected) {
      _onStateChange(EventServiceState.connected);
      return;
    }
    ;

    try {
      _ws = await WebSocket.connect('$_url/v1/events/$_contractAddress/$_topic')
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );

      _ws!.pingInterval = const Duration(seconds: 10);
      _isConnected = true;
      _onStateChange(EventServiceState.connected);

      _ws!.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      print('Connection error: $e');
      _isConnected = false;
      _onStateChange(EventServiceState.error);
      Duration delay = Duration(seconds: _reconnectDelay.inSeconds);
      if (reconnectDelay != null && reconnectDelay >= _reconnectMaxSeconds) {
        delay = Duration(seconds: reconnectDelay.inSeconds);
      }

      if (reconnectDelay != null && reconnectDelay < _reconnectMaxSeconds) {
        delay = Duration(seconds: reconnectDelay.inSeconds + 2);
      }

      _scheduleReconnect(reconnectDelay: delay);
    }
  }

  void setMessageHandler(Function(WebSocketEvent) onMessage) {
    _messageHandler = onMessage;
  }

  void setStateHandler(Function(EventServiceState) onStateChange) {
    _stateHandler = onStateChange;
  }

  void _onStateChange(EventServiceState state) {
    _stateHandler?.call(state);
  }

  void _onMessage(dynamic message) {
    print('Received message: $message');

    if (message is String) {
      final event = WebSocketEvent.tryParse(message);
      if (event != null) {
        // Handle the parsed event
        print('Parsed WebSocketEvent: ${event.type} - ${event.id}');
        _messageHandler?.call(event);
      } else {
        print('Failed to parse WebSocket message');
      }
    } else {
      print('Received non-string message');
    }
  }

  void _onError(error) {
    print('WebSocket error: $error');
    _isConnected = false;
    _onStateChange(EventServiceState.error);

    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    } else {
      print('Skipping reconnect due to intentional disconnect');
    }
  }

  void _onDone() {
    print('WebSocket connection closed');
    _isConnected = false;
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    } else {
      _onStateChange(EventServiceState.disconnected);
    }
    _intentionalDisconnect = false;
  }

  void _scheduleReconnect({Duration? reconnectDelay}) {
    if (_intentionalDisconnect) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay ?? _reconnectDelay, () async {
      print('Attempting to reconnect...');

      _onStateChange(EventServiceState.connecting);

      await delay(const Duration(seconds: 1));

      connect(reconnectDelay: reconnectDelay);
    });
  }

  Future<void> disconnect() async {
    print('Disconnecting from $_url/v1/events/$_contractAddress/$_topic');
    _reconnectTimer?.cancel();
    _isConnected = false;
    _intentionalDisconnect = true;
    await _ws?.close();
    _onStateChange(EventServiceState.disconnected);
  }
}
