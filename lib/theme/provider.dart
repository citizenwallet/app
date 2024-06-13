import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';

class Theme extends InheritedWidget {
  final ThemeColors colors;

  const Theme({
    super.key,
    required this.colors,
    required super.child,
  });

  static Theme of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Theme>()!;
  }

  @override
  bool updateShouldNotify(Theme oldWidget) {
    return oldWidget.colors != colors;
  }
}
