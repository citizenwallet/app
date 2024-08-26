import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter/cupertino.dart';

class SettingsSubRow extends StatelessWidget {
  final String label;

  const SettingsSubRow(
    this.label, {
    super.key,
  });

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
                color: Theme.of(context).colors.subtleText.resolveFrom(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
