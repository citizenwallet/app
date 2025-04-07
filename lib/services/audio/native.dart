import 'package:audio_in_app/audio_in_app.dart';
import 'package:citizenwallet/services/audio/audio.dart';

class AudioService implements AudioServiceInterface {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() {
    return _instance;
  }

  AudioService._internal();

  final AudioInApp _audioInApp = AudioInApp();
  bool _muted = false;

  Future<bool> init({bool muted = false}) async {
    _muted = muted;
    return _audioInApp.createNewAudioCache(
      playerId: 'tx_notification',
      route: 'audio/tx_notification.wav',
      audioInAppType: AudioInAppType.determined,
    );
  }

  void setMuted(bool muted) {
    _muted = muted;
  }

  Future<void> txNotification() async {
    if (_muted) {
      return;
    }
    await _audioInApp.play(
      playerId: 'tx_notification',
    );
  }
}
