import 'dart:async';
import 'dart:convert';
import 'dart:io' show WebSocket;

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
  final Duration _reconnectDelay = const Duration(seconds: 2);
  bool _isConnected = false;
  bool _intentionalDisconnect = false;

  Function(WebSocketEvent)? _messageHandler;

  EventService(this._url, this._contractAddress, this._topic);

  Future<void> connect() async {
    print('Connecting to $_url/v1/events/$_contractAddress/$_topic');

    if (_isConnected) return;

    try {
      _ws = await WebSocket.connect('$_url/v1/events/$_contractAddress/$_topic')
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );

      _ws!.pingInterval = const Duration(seconds: 10);
      _isConnected = true;
      _ws!.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      print('Connection error: $e');
      _scheduleReconnect();
    }
  }

  void setMessageHandler(Function(WebSocketEvent) onMessage) {
    _messageHandler = onMessage;
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
    _scheduleReconnect();
  }

  void _onDone() {
    print('WebSocket connection closed');
    _isConnected = false;
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
    _intentionalDisconnect = false;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      print('Attempting to reconnect...');
      connect();
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _isConnected = false;
    _intentionalDisconnect = true;
    await _ws?.close();
  }
}
