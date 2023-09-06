import 'package:flutter/cupertino.dart';

class ThemeColors {
  static const white = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: CupertinoColors.white,
  );

  static const black = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.black,
    darkColor: CupertinoColors.black,
  );

  static const primary = CupertinoDynamicColor.withBrightness(
    color: Color.fromARGB(255, 162, 86, 255),
    darkColor: Color.fromARGB(255, 162, 86, 255),
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

  static const surfacePrimary = CupertinoDynamicColor.withBrightness(
    color: Color.fromARGB(255, 188, 135, 255),
    darkColor: Color.fromARGB(255, 188, 135, 255),
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
