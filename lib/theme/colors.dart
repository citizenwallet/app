import 'package:flutter/cupertino.dart';
import 'package:citizenwallet/services/config/config.dart';

class ThemeColors {
  static CommunityThemeConfig _theme = CommunityThemeConfig(
    primary: originalSurfacePrimary,
  );

  static const originalPrimary = Color.fromARGB(255, 162, 86, 255);
  static const originalSurfacePrimary = Color.fromARGB(255, 188, 135, 255);

  static setTheme(CommunityThemeConfig theme) {
    _theme = theme;

    // darken the primary color
    const int colorAdjustmentAmount = 40;

    int newR = _theme.primary.red - colorAdjustmentAmount;
    if (newR < 0) newR = 0;

    int newG = _theme.primary.green - colorAdjustmentAmount;
    if (newG < 0) newG = 0;

    int newB = _theme.primary.blue - colorAdjustmentAmount;
    if (newB < 0) newB = 0;

    _primary = CupertinoDynamicColor.withBrightness(
      color: Color.fromARGB(255, newR, newG, newB),
      darkColor: Color.fromARGB(255, newR, newG, newB),
    );
  }

  static const white = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: CupertinoColors.white,
  );

  static const black = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.black,
    darkColor: CupertinoColors.black,
  );

  static CupertinoDynamicColor _primary =
      const CupertinoDynamicColor.withBrightness(
    color: originalPrimary,
    darkColor: originalPrimary,
  );

  static get primary => _primary;

  static CupertinoDynamicColor get surfacePrimary =>
      CupertinoDynamicColor.withBrightness(
        color: _theme.primary,
        darkColor: _theme.primary,
      );

  static const secondary = CupertinoDynamicColor.withBrightness(
    color: Color.fromARGB(255, 241, 159, 5),
    darkColor: Color.fromRGBO(244, 188, 81, 1),
  );

  static const success = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(7, 153, 98, 1),
    darkColor: Color.fromRGBO(7, 153, 98, 1),
  );

  static const danger = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.systemRed,
    darkColor: CupertinoColors.systemRed,
  );

  static const text = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.black,
    darkColor: CupertinoColors.white,
  );

  static const subtleText = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(0, 0, 0, 0.75),
    darkColor: Color.fromRGBO(255, 255, 255, 0.75),
  );

  static const background = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: CupertinoColors.black,
  );

  static const backgroundTransparent = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(255, 255, 255, 0.25),
    darkColor: Color.fromRGBO(0, 0, 0, 0.25),
  );

  static const backgroundTransparent50 = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(255, 255, 255, 0.5),
    darkColor: Color.fromRGBO(0, 0, 0, 0.5),
  );

  static const backgroundTransparent75 = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(255, 255, 255, 0.75),
    darkColor: Color.fromRGBO(0, 0, 0, 0.75),
  );

  static const touchable = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(50, 50, 50, 1),
    darkColor: Color.fromRGBO(255, 255, 255, 0.8),
  );

  static const uiBackground = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.extraLightBackgroundGray,
    darkColor: CupertinoColors.black,
  );

  static const uiBackgroundAlt = CupertinoDynamicColor.withBrightness(
    color: Color.fromARGB(255, 230, 230, 230),
    darkColor: Color.fromARGB(255, 30, 30, 30),
  );

  static const uiBackgroundAltTransparent50 =
      CupertinoDynamicColor.withBrightness(
    color: Color.fromARGB(150, 230, 230, 230),
    darkColor: Color.fromARGB(150, 30, 30, 30),
  );

  static const uiBackgroundAltTransparent =
      CupertinoDynamicColor.withBrightness(
    color: Color.fromARGB(0, 230, 230, 230),
    darkColor: Color.fromARGB(0, 30, 30, 30),
  );

  static const surfaceText = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: CupertinoColors.black,
  );

  static const surfaceSubtle = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(255, 255, 255, 0.5),
    darkColor: Color.fromRGBO(50, 50, 50, 0.5),
  );

  static const surfaceBackground = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.black,
    darkColor: CupertinoColors.white,
  );

  static const surfaceBackgroundSubtle = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(0, 0, 0, 0.75),
    darkColor: Color.fromRGBO(255, 255, 255, 0.75),
  );

  static const border = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.systemGrey5,
    darkColor: Color.fromRGBO(50, 50, 50, 1),
  );

  static const subtle = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(0, 0, 0, 0.05),
    darkColor: Color.fromRGBO(255, 255, 255, 0.1),
  );

  static const subtleEmphasis = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(0, 0, 0, 0.15),
    darkColor: Color.fromRGBO(255, 255, 255, 0.15),
  );

  static const subtleSolid = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(100, 100, 100, 1),
    darkColor: Color.fromRGBO(150, 150, 150, 1),
  );

  static const subtleSolidEmphasis = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(150, 150, 150, 1),
    darkColor: Color.fromRGBO(100, 100, 100, 1),
  );

  static const transparent = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(0, 0, 0, 0),
    darkColor: Color.fromRGBO(255, 255, 255, 0),
  );
}
