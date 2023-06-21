import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';

class SettingsSubRow extends StatelessWidget {
  final String label;

  const SettingsSubRow(
    this.label, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: ThemeColors.subtleText.resolveFrom(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
