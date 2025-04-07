import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

class PushService {
  static final PushService _instance = PushService._internal();

  factory PushService() {
    return _instance;
  }

  PushService._internal();

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  Future<void> start(
    Future<void> Function(String token) onToken,
    void Function(RemoteMessage)? onMessage,
  ) async {
    final accepted = await requestPermissions();

    if (!accepted) {
      return;
    }

    await _setupToken(onToken, onMessage);
  }

  Future<void> stop() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
  }

  Future<String?> get token async {
    return await isEnabled()
        ? await FirebaseMessaging.instance.getToken()
        : null;
  }

  Future<void> _setupToken(
    Future<void> Function(String token) onToken,
    void Function(RemoteMessage)? onMessage,
  ) async {
    // Get the token each time the application loads
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      // Save the initial token to the database
      await onToken(token);
    }

    // Any time the token refreshes, store this in the database too.
    await _tokenSubscription?.cancel();
    _tokenSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

    // Any time a message arrives, handle it
    _messageSubscription?.cancel();
    _messageSubscription = FirebaseMessaging.onMessage.listen(onMessage);
  }

  Future<void> _deleteToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      return;
    }

    await FirebaseMessaging.instance.deleteToken();
  }

  Future<bool> requestPermissions() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<void> revokePermissions() async {
    _deleteToken();
  }

  Future<bool> isEnabled() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.getNotificationSettings();

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}
