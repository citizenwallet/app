import 'package:citizenwallet/services/encrypted_preferences/android.dart';
import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/state/android_pin_code/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AndroidPinCodeLogic {
  final PreferencesService _preferences = PreferencesService();
  late AndroidPinCodeState _state;

  AndroidPinCodeLogic(BuildContext context) {
    _state = context.read<AndroidPinCodeState>();
  }

  void onPinCodeChanged() {
    _state.onPinCodeChanged();
  }

  void onConfirmPinCodeChanged() {
    _state.onConfirmPinCodeChanged();
  }

  void toggleObscureText() {
    _state.toggleObscureText();
  }

  Future<bool> configureBackup(String pinCode) async {
    try {
      await getEncryptedPreferencesService().init(
        AndroidEncryptedPreferencesOptions(pin: int.parse(pinCode)),
      );

      _preferences.setAndroidBackupIsConfigured(true);
      _state.setInvalidRecoveryPin(false);
      return true;
    } catch (e) {
      //
    }

    _state.setInvalidRecoveryPin(true);

    return false;
  }

  Future<void> clearDataAndBackups() async {
    try {
      await AndroidEncryptedPreferencesService()
          .init(AndroidEncryptedPreferencesOptions(
        pin: 0,
        fromScratch: true,
      ));

      await _preferences.clear();
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }
  }
}
