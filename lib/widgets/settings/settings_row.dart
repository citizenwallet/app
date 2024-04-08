import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

class SettingsRow extends StatelessWidget {
  final String label;
  final String? icon;
  final Color? iconColor;
  final String? subLabel;
  final Widget? trailing;
  final void Function()? onTap;
  final IconData? onTapIcon;

  const SettingsRow({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
    this.subLabel,
    this.trailing,
    this.onTap,
    this.onTapIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 50,
                  margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  decoration: BoxDecoration(
                      color: ThemeColors.background.resolveFrom(context),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      border: Border.all(
                          color: ThemeColors.border.resolveFrom(context))),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: SvgPicture.asset(
                            icon!,
                            colorFilter: iconColor != null
                                ? ColorFilter.mode(
                                    iconColor!,
                                    BlendMode.srcIn,
                                  )
                                : null,
                            semanticsLabel: '$label icon',
                            height: 20,
                            width: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                      if (onTap != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: Icon(
                            onTapIcon ?? CupertinoIcons.forward,
                            color:
                                ThemeColors.subtleEmphasis.resolveFrom(context),
                          ),
                        ),
                    ],
                  ),
                ),
                if (subLabel != null) const SizedBox(height: 5),
                if (subLabel != null)
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                          child: Text(
                            subLabel!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color:
                                  ThemeColors.subtleText.resolveFrom(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
