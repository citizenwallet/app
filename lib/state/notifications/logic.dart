import 'package:citizenwallet/services/audio/audio.dart';
import 'package:citizenwallet/state/notifications/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class NotificationsLogic {
  final NotificationsState _state;

  final AudioService _audio = AudioService();

  NotificationsLogic(BuildContext context)
      : _state = context.read<NotificationsState>();

  void show(String title, {bool playSound = false}) {
    if (playSound) _audio.txNotification();
    _state.show(title);
  }

  void hide() {
    _state.hide();
  }
}
