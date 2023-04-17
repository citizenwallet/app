import 'package:flutter/cupertino.dart';

class ThemeColors {
  static const primary = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(7, 153, 98, 1),
    darkColor: Color.fromRGBO(7, 153, 98, 1),
  );

  static const secondary = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(244, 188, 81, 1),
    darkColor: Color.fromRGBO(244, 188, 81, 1),
  );

  static const text = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.black,
    darkColor: CupertinoColors.white,
  );

  static const background = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: CupertinoColors.black,
  );

  static const uiBackground = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.extraLightBackgroundGray,
    darkColor: CupertinoColors.black,
  );

  static const surfaceText = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: CupertinoColors.black,
  );

  static const surfaceSubtle = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(255, 255, 255, 0.5),
    darkColor: Color.fromRGBO(50, 50, 50, 1),
  );

  static const surfaceBackground = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.black,
    darkColor: CupertinoColors.white,
  );

  static const border = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.systemGrey5,
    darkColor: Color.fromRGBO(50, 50, 50, 1),
  );

  static const subtle = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(0, 0, 0, 0.1),
    darkColor: Color.fromRGBO(255, 255, 255, 0.1),
  );
}
