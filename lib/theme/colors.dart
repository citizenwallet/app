import 'package:flutter/cupertino.dart';

class ThemeColors {
  ThemeColors({
    Color primary = originalPrimary,
    Color surfacePrimary = originalSurfacePrimary,
  })  : primary = CupertinoDynamicColor.withBrightness(
          color: primary,
          darkColor: primary,
        ),
        surfacePrimary = CupertinoDynamicColor.withBrightness(
          color: surfacePrimary,
          darkColor: surfacePrimary,
        );

  static const originalPrimary = Color.fromARGB(255, 162, 86, 255);
  static const originalSurfacePrimary = Color.fromARGB(255, 188, 135, 255);

  final white = const CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: CupertinoColors.white,
  );

  final black = const CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.black,
    darkColor: CupertinoColors.black,
  );

  CupertinoDynamicColor primary;
  CupertinoDynamicColor surfacePrimary;

  final secondary = const CupertinoDynamicColor.withBrightness(
    color: Color.fromARGB(255, 241, 159, 5),
    darkColor: Color.fromRGBO(244, 188, 81, 1),
  );

  final success = const CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(7, 153, 98, 1),
    darkColor: Color.fromRGBO(7, 153, 98, 1),
  );

  final danger = const CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.systemRed,
    darkColor: CupertinoColors.systemRed,
  );

  final text = const CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.black,
    darkColor: CupertinoColors.white,
  );

  final subtleText = const CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(143, 138, 157, 1),
    darkColor: Color.fromRGBO(255, 255, 255, 0.75),
  );

  final background = const CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: CupertinoColors.black,
  );

  final backgroundTransparent = const CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(255, 255, 255, 0.25),
    darkColor: Color.fromRGBO(0, 0, 0, 0.25),
  );

  final backgroundTransparent50 = const CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(255, 255, 255, 0.5),
    darkColor: Color.fromRGBO(0, 0, 0, 0.5),
  );

  final backgroundTransparent75 = const CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(255, 255, 255, 0.75),
    darkColor: Color.fromRGBO(0, 0, 0, 0.75),
  );

  final touchable = const CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(50, 50, 50, 1),
    darkColor: Color.fromRGBO(255, 255, 255, 0.8),
  );

  final uiBackground = const CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.extraLightBackgroundGray,
    darkColor: CupertinoColors.black,
  );

  final uiBackgroundAlt = const CupertinoDynamicColor.withBrightness(
    color: Color.fromARGB(255, 255, 255, 255),
    darkColor: Color.fromARGB(255, 30, 30, 30),
  );

  final uiBackgroundAltTransparent50 =
      const CupertinoDynamicColor.withBrightness(
    color: Color.fromARGB(150, 230, 230, 230),
    darkColor: Color.fromARGB(150, 30, 30, 30),
  );

  final uiBackgroundAltTransparent = const CupertinoDynamicColor.withBrightness(
    color: Color.fromARGB(0, 230, 230, 230),
    darkColor: Color.fromARGB(0, 30, 30, 30),
  );

  final surfaceText = const CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: CupertinoColors.black,
  );

  final surfaceSubtle = const CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(255, 255, 255, 0.5),
    darkColor: Color.fromRGBO(50, 50, 50, 0.5),
  );

  final surfaceBackground = const CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(241, 237, 242, 1),
    darkColor: CupertinoColors.white,
  );

  final surfaceBackgroundSubtle = const CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(0, 0, 0, 0.75),
    darkColor: Color.fromRGBO(255, 255, 255, 0.75),
  );

  final border = const CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.systemGrey5,
    darkColor: Color.fromRGBO(50, 50, 50, 1),
  );

  final subtle = const CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(241, 237, 242, 1),
    darkColor: Color.fromRGBO(255, 255, 255, 0.1),
  );

  final subtleEmphasis = const CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(231, 227, 232, 1),
    darkColor: Color.fromRGBO(255, 255, 255, 0.15),
  );

  final subtleSolid = const CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(100, 100, 100, 1),
    darkColor: Color.fromRGBO(150, 150, 150, 1),
  );

  final subtleSolidEmphasis = const CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(150, 150, 150, 1),
    darkColor: Color.fromRGBO(100, 100, 100, 1),
  );

  final transparent = const CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(0, 0, 0, 0),
    darkColor: Color.fromRGBO(255, 255, 255, 0),
  );

  @override
  int get hashCode => primary.hashCode ^ surfacePrimary.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThemeColors &&
        other.primary == primary &&
        other.surfacePrimary == surfacePrimary;
  }
}
