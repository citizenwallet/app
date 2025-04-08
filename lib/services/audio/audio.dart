export 'package:citizenwallet/services/audio/native.dart'
    if (dart.library.html) 'package:citizenwallet/services/audio/web.dart';

abstract class AudioServiceInterface {
  Future<bool> init({bool muted = false});
  void setMuted(bool muted);
  Future<void> txNotification();
}
