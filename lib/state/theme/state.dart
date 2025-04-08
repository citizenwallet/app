import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';

class ThemeState extends ChangeNotifier {
  ThemeColors _colors = ThemeColors();
  ThemeColors get colors => _colors;

  bool _darkMode = false;
  bool get darkMode => _darkMode;

  CupertinoThemeData _cupertinoTheme;

  CupertinoThemeData get cupertinoTheme => _cupertinoTheme;

  ThemeState()
      : _darkMode = PreferencesService().darkMode,
        _cupertinoTheme = CupertinoThemeData(
          primaryColor: ThemeColors.originalPrimary,
          brightness: PreferencesService().darkMode
              ? Brightness.dark
              : Brightness.light,
          scaffoldBackgroundColor: PreferencesService().darkMode
              ? ThemeColors().uiBackgroundAlt.darkColor
              : ThemeColors().uiBackgroundAlt.color,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(
              color: PreferencesService().darkMode
                  ? ThemeColors().text.darkColor
                  : ThemeColors().text.color,
              fontSize: 16,
            ),
          ),
          applyThemeToAll: true,
        );

  set darkMode(bool darkMode) {
    _darkMode = darkMode;

    updateThemeData();

    notifyListeners();
  }

  set theme(ColorTheme theme) {
    final primary = Color(theme.primary);

    // darken the primary color
    const int colorAdjustmentAmount = 40;

    int newR = primary.red - colorAdjustmentAmount;
    if (newR < 0) newR = 0;

    int newG = primary.green - colorAdjustmentAmount;
    if (newG < 0) newG = 0;

    int newB = primary.blue - colorAdjustmentAmount;
    if (newB < 0) newB = 0;

    final darkenedPrimary = Color.fromARGB(255, newR, newG, newB);

    _colors = ThemeColors(
      primary: darkenedPrimary,
      surfacePrimary: primary,
    );

    notifyListeners();
  }

  void updateThemeData() {
    _cupertinoTheme = generateThemeData(
      colors: _colors,
      darkMode: darkMode,
      primaryLight: ThemeColors.originalPrimary,
      primaryDark: ThemeColors.originalPrimary,
    );
  }
}

CupertinoThemeData generateThemeData({
  required ThemeColors colors,
  bool darkMode = false,
  Color primaryLight = ThemeColors.originalPrimary,
  Color primaryDark = ThemeColors.originalPrimary,
}) {
  return CupertinoThemeData(
    primaryColor: darkMode ? primaryDark : primaryLight,
    primaryContrastingColor: darkMode ? colors.white : colors.black,
    brightness: darkMode ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: darkMode
        ? colors.uiBackgroundAlt.darkColor
        : colors.uiBackgroundAlt.color,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(
        color: darkMode ? colors.text.darkColor : colors.text.color,
        fontSize: 16,
      ),
    ),
    applyThemeToAll: true,
  );
}
