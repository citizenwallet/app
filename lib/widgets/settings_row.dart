import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';

class SettingsRow extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final void Function()? onTap;

  const SettingsRow({
    super.key,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                  color: ThemeColors.background.resolveFrom(context),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  border: Border.all(
                      color: ThemeColors.border.resolveFrom(context))),
              constraints: const BoxConstraints(
                minHeight: 60,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                  if (onTap != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                      child: Icon(
                        CupertinoIcons.forward,
                        color: ThemeColors.text.resolveFrom(context),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
