import 'package:citizenwallet/theme/provider.dart';
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
                    ? Theme.of(context).colors.subtle.resolveFrom(context)
                    : Theme.of(context).colors.white.resolveFrom(context),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context)
                          .colors
                          .subtleEmphasis
                          .resolveFrom(context)
                      : Theme.of(context)
                          .colors
                          .subtleEmphasis
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
                style: TextStyle(
                  color: Theme.of(context).colors.text,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
