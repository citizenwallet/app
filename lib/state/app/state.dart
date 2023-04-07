import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:flutter/cupertino.dart';

class AppState extends ChangeNotifier {
  bool _darkMode = false;
  bool get darkMode => _darkMode;
  set darkMode(bool darkMode) {
    _darkMode = darkMode;
    notifyListeners();
  }

  AppState() {
    _darkMode = PreferencesService().darkMode;
  }
}
