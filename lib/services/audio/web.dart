import 'package:citizenwallet/services/audio/audio.dart';

class AudioService implements AudioServiceInterface {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() {
    return _instance;
  }

  AudioService._internal();

  Future<bool> init({bool muted = false}) {
    return Future(() => true);
  }

  void setMuted(bool muted) {}
  Future<void> txNotification() {
    return Future(() => null);
  }
}
