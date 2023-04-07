import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class AppLogic {
  final PreferencesService _preferences = PreferencesService();
  late AppState _appState;

  AppLogic(BuildContext context) {
    _appState = context.read<AppState>();
  }

  void setDarkMode(bool darkMode) {
    _preferences.setDarkMode(darkMode);

    _appState.darkMode = darkMode;
  }
}
