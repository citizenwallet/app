import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';

class Picker extends StatelessWidget {
  final List<String> options;
  final String selected;

  final Function(String?) handleSelect;

  const Picker({
    Key? key,
    required this.options,
    required this.selected,
    required this.handleSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<String>(
        backgroundColor: ThemeColors.white,
        thumbColor: ThemeColors.surfacePrimary.resolveFrom(context),
        groupValue: selected,
        children: options.fold(
            <String, Widget>{},
            (previousValue, element) => {
                  ...previousValue,
                  element: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      element,
                      style: const TextStyle(
                        color: ThemeColors.text,
                      ),
                    ),
                  ),
                }),
        onValueChanged: handleSelect);
  }
}
