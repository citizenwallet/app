import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';

class Picker extends StatelessWidget {
  final List<String> options;
  final String selected;

  final Function(String?) handleSelect;

  const Picker({
    super.key,
    required this.options,
    required this.selected,
    required this.handleSelect,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<String>(
        backgroundColor: ThemeColors.white,
        thumbColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        groupValue: selected,
        children: options.fold(
            <String, Widget>{},
            (previousValue, element) => {
                  ...previousValue,
                  element: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      element,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: ThemeColors.text,
                      ),
                    ),
                  ),
                }),
        onValueChanged: handleSelect);
  }
}
