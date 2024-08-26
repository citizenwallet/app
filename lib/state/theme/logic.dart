import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/state/theme/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ThemeLogic {
  static final ThemeLogic _instance = ThemeLogic._internal();

  factory ThemeLogic() {
    return _instance;
  }

  ThemeLogic._internal();

  final PreferencesService _preferences = PreferencesService();
  late ThemeState _state;

  void init(BuildContext context) {
    _state = context.read<ThemeState>();
  }

  void changeTheme(ColorTheme theme) {
    _state.theme = theme;
  }

  void setDarkMode(bool darkMode) {
    try {
      _preferences.setDarkMode(darkMode);

      _state.darkMode = darkMode;
    } catch (e) {
      //
    }
  }
}
