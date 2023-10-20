import 'package:audio_in_app/audio_in_app.dart';

class AudioService {
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
      audioInAppType: AudioInAppType.background,
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
