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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: options.map((option) {
          final isSelected = selected == option;

          return GestureDetector(
            onTap: () => handleSelect(option),
            child: AnimatedContainer(
              key: Key(option),
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? ThemeColors.subtle.resolveFrom(context)
                    : ThemeColors.white.resolveFrom(context),
                border: Border.all(
                  color: isSelected
                      ? ThemeColors.subtleEmphasis.resolveFrom(context)
                      : ThemeColors.subtleEmphasis
                          .resolveFrom(context)
                          .withOpacity(0),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              child: Text(
                option,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ThemeColors.text,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    return CupertinoSlidingSegmentedControl<String>(
        backgroundColor: ThemeColors.white,
        thumbColor: ThemeColors.subtle.resolveFrom(context),
        groupValue: selected,
        children: options.fold(
            <String, Widget>{},
            (previousValue, element) => {
                  ...previousValue,
                  element: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: ThemeColors.subtle.resolveFrom(context),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
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
