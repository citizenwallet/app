import 'package:citizenwallet/services/audio/audio.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/push/push.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/notifications/state.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class NotificationsLogic {
  final NotificationsState _state;

  final PreferencesService _prefs = PreferencesService();
  final PushService _push = PushService();
  final AudioService _audio = AudioService();
  final WalletService _wallet = WalletService();

  NotificationsLogic(BuildContext context)
      : _state = context.read<NotificationsState>();

  void init() async {
    try {
      final systemEnabled = await _push.isEnabled();
      bool enabled = _prefs.pushNotifications(_wallet.account.hexEip55);

      if (!systemEnabled) {
        final allowed = await _push.requestPermissions();
        if (!allowed) {
          return;
        }

        enabled = true;
      }

      if (!systemEnabled && !enabled) {
        return;
      }

      // enable push
      _state.setPush(true);
      await _push.start(onToken, onMessage);
      _prefs.setPushNotifications(_wallet.account.hexEip55, true);
    } catch (e) {
      //
    }
  }

  void checkPushPermissions() async {
    try {
      final systemEnabled = await _push.isEnabled();
      final enabled = _prefs.pushNotifications(_wallet.account.hexEip55);

      _state.setPush(systemEnabled && enabled);
    } catch (e) {
      //
    }
  }

  void show(String title, {bool playSound = false}) {
    if (playSound) _audio.txNotification();
    _state.show(title);
  }

  void hide() {
    _state.hide();
  }

  void onMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      final message = notification.body ?? notification.title;
      if (message != null) {
        // show(message, playSound: !_prefs.muted);
      }
    }
  }

  Future<void> onToken(String token) async {
    try {
      final updated = await _wallet.updatePushToken(token);
      if (!updated) {
        throw Exception('Failed to update push token');
      }
    } catch (e) {
      //
    }
  }

  Future<void> togglePushNotifications() async {
    try {
      final systemEnabled = await _push.isEnabled();
      final enabled = _prefs.pushNotifications(_wallet.account.hexEip55);

      if (systemEnabled && enabled) {
        // disable push
        _state.setPush(false);
        await _push.stop();
        _prefs.setPushNotifications(_wallet.account.hexEip55, false);

        final token = await _push.token;
        if (token == null) {
          return;
        }

        final updated = await _wallet.removePushToken(token);
        if (!updated) {
          throw Exception('Failed to update push token');
        }
        return;
      }

      if (!systemEnabled) {
        final allowed = await _push.requestPermissions();
        if (!allowed) {
          return;
        }
      }

      // enable push
      _state.setPush(true);
      await _push.start(onToken, onMessage);
      _prefs.setPushNotifications(_wallet.account.hexEip55, true);
    } catch (e) {
      //
    }
  }
}
